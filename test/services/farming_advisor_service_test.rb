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
end
