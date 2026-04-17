require "test_helper"

class FarmingPriorityServiceTest < ActiveSupport::TestCase
  test "ranks sources by material count descending" do
    results = {
      1 => { sources: { "Moonlit Groves" => { source_type: "forgery_challenge", waveplate_cost_per_run: 40 } } },
      2 => { sources: { "Moonlit Groves" => { source_type: "forgery_challenge", waveplate_cost_per_run: 40 } } },
      3 => { sources: { "Simulation Training" => { source_type: "simulation_challenge", waveplate_cost_per_run: 40 } } },
      4 => { sources: { "Tacet Field" => { source_type: "boss_challenge", waveplate_cost_per_run: 60 } } }
    }

    priority = FarmingPriorityService.call(results)

    assert_equal [ "forgery_challenge", "simulation_challenge", "boss_challenge" ],
                  priority.map { |e| e[:source_type] }
  end

  test "breaks ties by waveplate cost ascending" do
    results = {
      1 => { sources: { "Tacet Field" => { source_type: "boss_challenge", waveplate_cost_per_run: 60 } } },
      2 => { sources: { "Simulation Training" => { source_type: "simulation_challenge", waveplate_cost_per_run: 40 } } }
    }

    priority = FarmingPriorityService.call(results)

    assert_equal "simulation_challenge", priority.first[:source_type]
    assert_equal "boss_challenge",       priority.last[:source_type]
  end

  test "returns correct material count per source type" do
    results = {
      1 => { sources: { "Moonlit Groves" => { source_type: "forgery_challenge", waveplate_cost_per_run: 40 } } },
      2 => { sources: { "Moonlit Groves" => { source_type: "forgery_challenge", waveplate_cost_per_run: 40 } } }
    }

    priority = FarmingPriorityService.call(results)

    assert_equal 1,    priority.length
    assert_equal 2,    priority.first[:material_count]
  end

  test "returns correct waveplate cost per source type" do
    results = {
      1 => { sources: { "Moonlit Groves" => { source_type: "forgery_challenge", waveplate_cost_per_run: 40 } } }
    }

    route = FarmingPriorityService.call(results)

    assert_equal 40, route.first[:waveplate_cost]
  end

  test "deduplicates sources of the same type for a single material" do
    results = {
      1 => { sources: {
        "Moonlit Groves"      => { source_type: "forgery_challenge", waveplate_cost_per_run: 40 },
        "Abyss of Sacrifice"  => { source_type: "forgery_challenge", waveplate_cost_per_run: 40 }
      } }
    }

    route = FarmingPriorityService.call(results)

    assert_equal 1, route.length
    assert_equal 1, route.first[:material_count]
  end

  test "resolves known source types to human-readable labels" do
    results = {
      1 => { sources: { "Moonlit Groves" => { source_type: "forgery_challenge", waveplate_cost_per_run: 40 } } }
    }

    route = FarmingPriorityService.call(results)

    assert_equal "Forgery Challenge", route.first[:source_label]
  end

  test "falls back to humanized string for unknown source types" do
    results = {
      1 => { sources: { "Some New Source" => { source_type: "some_new_type", waveplate_cost_per_run: 40 } } }
    }

    route = FarmingPriorityService.call(results)

    assert_equal "Some new type", route.first[:source_label]
  end

  test "returns empty array when results is empty" do
    assert_empty FarmingPriorityService.call({})
  end

  test "returns empty array when all materials have no sources" do
    results = {
      1 => { sources: {} },
      2 => { sources: {} }
    }

    assert_empty FarmingPriorityService.call(results)
  end

  test "counts each source type once when a material has sources of different types" do
    results = {
      1 => { sources: {
        "Moonlit Groves" => { source_type: "forgery_challenge", waveplate_cost_per_run: 40 },
        "Tacet Field"    => { source_type: "boss_challenge",    waveplate_cost_per_run: 60 }
      } }
    }

    route = FarmingPriorityService.call(results)

    assert_equal 2, route.length
    assert_equal 1, route.find { |e| e[:source_type] == "forgery_challenge" }[:material_count]
    assert_equal 1, route.find { |e| e[:source_type] == "boss_challenge" }[:material_count]
  end
end
