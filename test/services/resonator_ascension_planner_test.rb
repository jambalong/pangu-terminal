require "test_helper"

class ResonatorAscensionPlannerTest < ActiveSupport::TestCase
  setup do
    @chisa = Resonator.find_by!(name: "Chisa")
    @base_params = {
      resonator: @chisa,
      current_level: 1, target_level: 1,
      current_ascension_rank: 0, target_ascension_rank: 0,
      current_skill_levels: {
        basic_attack: 1, resonance_skill: 1,
        forte_circuit: 1, resonance_liberation: 1, intro_skill: 1
      },
      target_skill_levels: {
        basic_attack: 1, resonance_skill: 1,
        forte_circuit: 1, resonance_liberation: 1, intro_skill: 1
      },
      forte_node_upgrades: {
        basic_attack_node_1: 0, basic_attack_node_2: 0,
        resonance_skill_node_1: 0, resonance_skill_node_2: 0,
        forte_circuit_node_1: 0, forte_circuit_node_2: 0,
        resonance_liberation_node_1: 0, resonance_liberation_node_2: 0,
        intro_skill_node_1: 0, intro_skill_node_2: 0
      }
    }
  end

  test "raises ValidationError when nothing has changed" do
    assert_validation_error({}, "Nothing changed")
  end

  test "raises ValidationError when target level is below current level" do
    assert_validation_error(
      { current_level: 20, target_level: 19 },
      "Target level"
    )
  end

  test "raises ValidationError when target ascension rank is below current rank" do
    assert_validation_error(
      { current_level: 20, target_level: 20, current_ascension_rank: 1 },
      "Target rank"
    )
  end

  test "raises ValidationError when current level is below 1" do
    assert_validation_error(
      { current_level: 0, target_level: 20, target_ascension_rank: 0 },
      "Must be 1-90"
    )
  end

  test "raises ValidationError when target level is above 90" do
    assert_validation_error(
      { current_level: 1, target_level: 91, target_ascension_rank: 6 },
      "Must be 1-90"
    )
  end

  test "raises ValidationError when current skill level is below 1" do
    assert_validation_error(
      { current_skill_levels: { basic_attack: 0 } },
      "Must be 1-10"
    )
  end

  test "raises ValidationError when target skill level is above 10" do
    assert_validation_error(
      { target_skill_levels: { basic_attack: 11 } },
      "Must be 1-10"
    )
  end

  test "raises ValidationError when target skill level is below current skill level" do
    assert_validation_error(
      {
        current_skill_levels: { basic_attack: 10 },
        target_skill_levels: { basic_attack: 1 }
      },
      "Basic Attack: target"
    )
  end

  test "raises ValidationError when current level is above ascension cap" do
    assert_validation_error(
      { current_level: 21, target_level: 21, target_ascension_rank: 1 },
      "exceeds max"
    )
  end

  test "raises ValidationError when level is below ascension minimum" do
    assert_validation_error(
      { current_level: 1, target_level: 20, current_ascension_rank: 1, target_ascension_rank: 1 },
      "needs at least level"
    )
  end

  test "raises ValidationError when forte node key is invalid" do
    assert_validation_error(
      { target_level: 20, forte_node_upgrades: { invalid_node: 1 } },
      "Invalid forte node"
    )
  end

  test "raises ValidationError when forte node state is not 0 or 1" do
    assert_validation_error(
      { target_level: 20, forte_node_upgrades: { basic_attack_node_1: 7 } },
      "state must be 0 or 1"
    )
  end

  test "calculates correct credit and potion for leveling 1 to 20" do
    result = call_planner({ target_level: 20 })

    shell_credit_id = Material.find_by!(name: "Shell Credit").id
    basic_potion_id = Material.find_by!(name: "Basic Resonance Potion").id

    assert_equal 11652, result[shell_credit_id]
    assert_equal 33, result[basic_potion_id]
  end

  test "returns no potion or credit cost when level does not change" do
    result = call_planner({ current_level: 20, target_level: 20, target_ascension_rank: 1 })

    shell_credit_id = Material.find_by!(name: "Shell Credit").id
    basic_potion_id = Material.find_by!(name: "Basic Resonance Potion").id

    assert_equal 5000, result[shell_credit_id]
    assert_equal 0, result[basic_potion_id]
  end

  test "calculates correct ascension materials for rank 0 to 1" do
    result = call_planner({ current_level: 20, target_level: 20, target_ascension_rank: 1 })

    shell_credit_id = Material.find_by!(name: "Shell Credit").id
    polygon_core_id = Material.find_by!(name: "LF Polygon Core").id

    assert_equal 5000, result[shell_credit_id]
    assert_equal 4, result[polygon_core_id]
  end

  test "calculates correct ascension materials for rank 0 to 6" do
    result = call_planner({ current_level: 1, target_level: 90, target_ascension_rank: 6 })

    shell_credit_id = Material.find_by!(name: "Shell Credit").id
    lf_polygon_core_id = Material.find_by!(name: "LF Polygon Core").id
    mf_polygon_core_id = Material.find_by!(name: "MF Polygon Core").id
    hf_polygon_core_id = Material.find_by!(name: "HF Polygon Core").id
    ff_polygon_core_id = Material.find_by!(name: "FF Polygon Core").id
    abyssal_husk_id = Material.find_by!(name: "Abyssal Husk").id
    summer_flower_id = Material.find_by!(name: "Summer Flower").id

    assert_equal 1023282, result[shell_credit_id]
    assert_equal 46, result[abyssal_husk_id]
    assert_equal 60, result[summer_flower_id]
    assert_equal 4, result[lf_polygon_core_id]
    assert_equal 12, result[mf_polygon_core_id]
    assert_equal 12, result[hf_polygon_core_id]
    assert_equal 4, result[ff_polygon_core_id]
  end

  test "calculates correct skill costs for one skill one level" do
    result = call_planner({
      current_level: 1, target_level: 1,
      current_ascension_rank: 0, target_ascension_rank: 0,
      current_skill_levels: { basic_attack: 1, resonance_skill: 1, forte_circuit: 1, resonance_liberation: 1, intro_skill: 1 },
      target_skill_levels: { basic_attack: 2, resonance_skill: 1, forte_circuit: 1, resonance_liberation: 1, intro_skill: 1 }
    })

    shell_credit_id = Material.find_by!(name: "Shell Credit").id
    lf_polygon_core_id = Material.find_by!(name: "LF Polygon Core").id
    waveworn_residue_210_id = Material.find_by!(name: "Waveworn Residue 210").id

    assert_equal 1500, result[shell_credit_id]
    assert_equal 2, result[lf_polygon_core_id]
    assert_equal 2, result[waveworn_residue_210_id]
  end

  test "calculates correct skill costs for all skills 1 to 10" do
    result = call_planner({
      current_level: 1, target_level: 1,
      current_ascension_rank: 0, target_ascension_rank: 0,
      current_skill_levels: { basic_attack: 1, resonance_skill: 1, forte_circuit: 1, resonance_liberation: 1, intro_skill: 1 },
      target_skill_levels: { basic_attack: 10, resonance_skill: 10, forte_circuit: 10, resonance_liberation: 10, intro_skill: 10 }
    })

    shell_credit_id = Material.find_by!(name: "Shell Credit").id
    lf_polygon_core_id = Material.find_by!(name: "LF Polygon Core").id
    mf_polygon_core_id = Material.find_by!(name: "MF Polygon Core").id
    hf_polygon_core_id = Material.find_by!(name: "HF Polygon Core").id
    ff_polygon_core_id = Material.find_by!(name: "FF Polygon Core").id
    waveworn_residue_210_id = Material.find_by!(name: "Waveworn Residue 210").id
    waveworn_residue_226_id = Material.find_by!(name: "Waveworn Residue 226").id
    waveworn_residue_235_id = Material.find_by!(name: "Waveworn Residue 235").id
    waveworn_residue_239_id = Material.find_by!(name: "Waveworn Residue 239").id
    when_irises_bloom_id = Material.find_by!(name: "When Irises Bloom").id

    assert_equal 1400000, result[shell_credit_id]
    assert_equal 25, result[lf_polygon_core_id]
    assert_equal 25, result[mf_polygon_core_id]
    assert_equal 25, result[hf_polygon_core_id]
    assert_equal 45, result[ff_polygon_core_id]
    assert_equal 25, result[waveworn_residue_210_id]
    assert_equal 25, result[waveworn_residue_226_id]
    assert_equal 40, result[waveworn_residue_235_id]
    assert_equal 55, result[waveworn_residue_239_id]
    assert_equal 20, result[when_irises_bloom_id]
  end

  test "calculates correct forte node costs for a single node enabled" do
    result = call_planner({
      current_level: 1, target_level: 1,
      current_ascension_rank: 0, target_ascension_rank: 0,
      forte_node_upgrades: { basic_attack_node_1: 1 }
    })

    shell_credit_id = Material.find_by!(name: "Shell Credit").id
    hf_polygon_core_id = Material.find_by!(name: "HF Polygon Core").id
    waveworn_residue_235_id = Material.find_by!(name: "Waveworn Residue 235").id

    assert_equal 50000, result[shell_credit_id]
    assert_equal 3, result[hf_polygon_core_id]
    assert_equal 3, result[waveworn_residue_235_id]
  end

  test "calculates correct forte node costs when no nodes are enabled" do
    result = call_planner({
      current_level: 1, target_level: 20,
      current_ascension_rank: 0, target_ascension_rank: 0,
      forte_node_upgrades: {}
    })

    hf_polygon_core_id = Material.find_by!(name: "HF Polygon Core").id
    waveworn_residue_235_id = Material.find_by!(name: "Waveworn Residue 235").id

    assert_equal 0, result[hf_polygon_core_id]
    assert_equal 0, result[waveworn_residue_235_id]
  end

  test "calculates correct ascension materials for a Lahai Roi resonator" do
    aemeath = Resonator.find_by!(name: "Aemeath")
    result = ResonatorAscensionPlanner.new(
      resonator: aemeath,
      current_level: 20, target_level: 20,
      current_ascension_rank: 0, target_ascension_rank: 1,
      current_skill_levels: { basic_attack: 1 },
      target_skill_levels: { basic_attack: 2 },
      forte_node_upgrades: {}
    ).call

    shell_credit_id = Material.find_by!(name: "Shell Credit").id
    lf_exoswarm_core_id = Material.find_by!(name: "LF Exoswarm Core").id
    broken_wing_polarizer_id = Material.find_by!(name: "Broken Wing Polarizer").id

    assert_equal 6500, result[shell_credit_id]
    assert_equal 6, result[lf_exoswarm_core_id]
    assert_equal 2, result[broken_wing_polarizer_id]
  end

  test "calculates full material costs for Chisa 1 to 90 all skills and forte nodes" do
    result = call_planner({
      current_level: 1, target_level: 90,
      current_ascension_rank: 0, target_ascension_rank: 6,
      current_skill_levels: {
        basic_attack: 1, resonance_skill: 1,
        forte_circuit: 1, resonance_liberation: 1, intro_skill: 1
      },
      target_skill_levels: {
        basic_attack: 10, resonance_skill: 10,
        forte_circuit: 10, resonance_liberation: 10, intro_skill: 10
      },
      forte_node_upgrades: {
        basic_attack_node_1: 1, basic_attack_node_2: 1,
        resonance_skill_node_1: 1, resonance_skill_node_2: 1,
        forte_circuit_node_1: 1, forte_circuit_node_2: 1,
        resonance_liberation_node_1: 1, resonance_liberation_node_2: 1,
        intro_skill_node_1: 1, intro_skill_node_2: 1
      }
    })

    shell_credit_id = Material.find_by!(name: "Shell Credit").id
    basic_potion_id = Material.find_by!(name: "Basic Resonance Potion").id
    lf_polygon_core_id = Material.find_by!(name: "LF Polygon Core").id
    mf_polygon_core_id = Material.find_by!(name: "MF Polygon Core").id
    hf_polygon_core_id = Material.find_by!(name: "HF Polygon Core").id
    ff_polygon_core_id = Material.find_by!(name: "FF Polygon Core").id
    abyssal_husk_id = Material.find_by!(name: "Abyssal Husk").id
    summer_flower_id = Material.find_by!(name: "Summer Flower").id
    waveworn_residue_210_id = Material.find_by!(name: "Waveworn Residue 210").id
    waveworn_residue_226_id = Material.find_by!(name: "Waveworn Residue 226").id
    waveworn_residue_235_id = Material.find_by!(name: "Waveworn Residue 235").id
    waveworn_residue_239_id = Material.find_by!(name: "Waveworn Residue 239").id
    when_irises_bloom_id = Material.find_by!(name: "When Irises Bloom").id

    assert_equal 3053282, result[shell_credit_id]
    assert_equal 2438, result[basic_potion_id]
    assert_equal 46, result[abyssal_husk_id]
    assert_equal 60, result[summer_flower_id]
    assert_equal 29, result[lf_polygon_core_id]
    assert_equal 40, result[mf_polygon_core_id]
    assert_equal 52, result[hf_polygon_core_id]
    assert_equal 61, result[ff_polygon_core_id]
    assert_equal 25, result[waveworn_residue_210_id]
    assert_equal 28, result[waveworn_residue_226_id]
    assert_equal 55, result[waveworn_residue_235_id]
    assert_equal 67, result[waveworn_residue_239_id]
    assert_equal 26, result[when_irises_bloom_id]
  end

  private

  def call_planner(overrides = {})
    params = @base_params.merge(overrides)
    ResonatorAscensionPlanner.new(**params).call
  end

  def assert_validation_error(overrides, expected_message_fragment)
    error = assert_raises(ResonatorAscensionPlanner::ValidationError) do
      call_planner(overrides)
    end
    assert_match expected_message_fragment, error.message
  end
end
