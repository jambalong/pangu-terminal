require "test_helper"

class FarmingAdvisorServiceTest < ActiveSupport::TestCase
  setup do
    @shell_credit = Material.find_by!(name: "Shell Credit")
    @lf_whisperin_core = Material.find_by!(name: "LF Whisperin Core")

    @results = {
      @shell_credit.id => {
        material: @shell_credit,
        deficit: 25480,
        sources: { "Simulation Training" => { estimated_runs: 6, waveplate_cost: 240 } }
      },
      @lf_whisperin_core.id => {
        material: @lf_whisperin_core,
        deficit: 6,
        sources: { "Forgery Challenge" => { estimated_runs: 2, waveplate_cost: 80 } }
      }
    }

    @farming_priority = [
      { source_label: "Simulation Challenge", source_type: "simulation_challenge", material_count: 1, waveplate_cost: 40 },
      { source_label: "Forgery Challenge", source_type: "forgery_challenge", material_count: 1, waveplate_cost: 40 }
    ]

    @chain_coverage = {}
  end

  test "returns stub advice string" do
    result = FarmingAdvisorService.call(
      results: @results,
      farming_priority: @farming_priority,
      chain_coverage: @chain_coverage
    )

    assert_equal "Stub farming advice.", result
  end

  # Swaps in a real cache and a counting LlmClient.ask; the suite default is a null store.
  def with_cache_and_llm(responses)
    original_cache = Rails.cache
    original_ask = LlmClient.method(:ask)
    calls = []
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    LlmClient.define_singleton_method(:ask) { |prompt| calls << prompt; responses.shift }
    yield calls
  ensure
    LlmClient.define_singleton_method(:ask, original_ask)
    Rails.cache = original_cache
  end

  def advise
    FarmingAdvisorService.call(
      results: @results,
      farming_priority: @farming_priority,
      chain_coverage: @chain_coverage
    )
  end

  test "caches advice for identical optimizer state" do
    with_cache_and_llm([ "First advice.", "Second advice." ]) do |calls|
      assert_equal "First advice.", advise
      assert_equal "First advice.", advise
      assert_equal 1, calls.size
    end
  end

  test "asks again when the deficits change" do
    with_cache_and_llm([ "First advice.", "Second advice." ]) do |calls|
      assert_equal "First advice.", advise
      @results[@shell_credit.id][:deficit] = 100
      assert_equal "Second advice.", advise
      assert_equal 2, calls.size
    end
  end

  test "does not cache the fallback message" do
    with_cache_and_llm([ LlmClient::FALLBACK_MESSAGE, "Recovered advice." ]) do |calls|
      assert_equal LlmClient::FALLBACK_MESSAGE, advise
      assert_equal "Recovered advice.", advise
      assert_equal 2, calls.size
    end
  end

  test "returns nil when results are blank" do
    result = FarmingAdvisorService.call(
      results: {},
      farming_priority: @farming_priority,
      chain_coverage: @chain_coverage
    )

    assert_nil result
  end

  test "still runs when farming priority is blank" do
    result = FarmingAdvisorService.call(
      results: @results,
      farming_priority: [],
      chain_coverage: @chain_coverage
    )

    assert_equal "Stub farming advice.", result
  end

  test "includes material type in formatted deficits" do
    service = FarmingAdvisorService.new(
      results: @results,
      farming_priority: @farming_priority,
      chain_coverage: @chain_coverage
    )

    prompt = service.send(:prompt)
    assert_match @shell_credit.material_type, prompt
  end

  test "includes chain coverage in formatted deficits when present" do
    cadence_blossom = Material.find_by!(name: "Cadence Blossom")
    results_with_synth = {
      cadence_blossom.id => {
        material: cadence_blossom,
        deficit: 3,
        sources: { "Forgery Challenge" => { estimated_runs: 2, waveplate_cost: 80 } }
      }
    }
    chain_coverage = { cadence_blossom.id => 3 }

    service = FarmingAdvisorService.new(
      results: results_with_synth,
      farming_priority: @farming_priority,
      chain_coverage: chain_coverage
    )

    prompt = service.send(:prompt)
    assert_match "synthesis fully covers this deficit -- no farming needed", prompt
  end

  def advisor(plan_names)
    FarmingAdvisorService.new(results: @results, farming_priority: @farming_priority, chain_coverage: @chain_coverage, plan_names: plan_names)
  end

  test "a single plan's prompt has no priority note and is unchanged by plan names" do
    without_names = FarmingAdvisorService.new(results: @results, farming_priority: @farming_priority, chain_coverage: @chain_coverage)

    assert_equal without_names.cache_key, advisor([ "Aemeath" ]).cache_key
    assert_not_includes advisor([ "Aemeath" ]).send(:prompt), "priority order"
  end

  test "several plans put their priority order into the prompt" do
    prompt = advisor([ "Aemeath", "Kumokiri" ]).send(:prompt)

    assert_includes prompt, "plans in priority order (earlier plans come first): 1. Aemeath, 2. Kumokiri."
    assert_includes prompt, "favor the materials the earlier plans need"
  end

  test "reordering the plans changes the advice key, so it is regenerated" do
    assert_not_equal advisor([ "Aemeath", "Kumokiri" ]).cache_key, advisor([ "Kumokiri", "Aemeath" ]).cache_key
  end

  test "the prompt keeps its structure with and without the note" do
    plain = advisor([]).send(:prompt)
    noted = advisor([ "A", "B" ]).send(:prompt)

    assert_match(/synthesis opportunities:\n\S.*\n\nNote: materials/m, plain)
    assert_match(/priority order[^\n]*\nWhen two farming options[^\n]*\n\nNote: materials/, noted)
    assert plain.lines.all? { |line| line == "\n" || !line.start_with?(" ") }, "no stray indentation"
  end
end
