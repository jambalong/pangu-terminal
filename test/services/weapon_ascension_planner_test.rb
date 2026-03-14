require "test_helper"

class WeaponAscensionPlannerTest < ActiveSupport::TestCase
  setup do
    @kumokiri = Weapon.find_by!(name: "Kumokiri")
    @base_params = {
      weapon: @kumokiri,
      current_level: 1, target_level: 1,
      current_ascension_rank: 0, target_ascension_rank: 0
    }
  end

  test "raises ValidationError when nothing has changed" do
    assert_validation_error({}, "At least one target value")
  end

  test "raises ValidationError when target level is below current level" do
    assert_validation_error(
      { current_level: 40, target_level: 39, current_ascension_rank: 1, target_ascension_rank: 1 },
      "cannot be less than current level"
    )
  end

  test "raises ValidationError when target ascension rank is below current rank" do
    assert_validation_error(
      { current_level: 20, target_level: 20, current_ascension_rank: 1, target_ascension_rank: 0 },
      "greater than or equal to"
    )
  end

  test "raises ValidationError when current level is below 1" do
    assert_validation_error(
      { current_level: 0, target_level: 20 },
      "must be between (1) and (90)"
    )
  end

  test "raises ValidationError when target level exceeds 90" do
    assert_validation_error(
      { current_level: 1, target_level: 91, target_ascension_rank: 6 },
      "must be between (1) and (90)"
    )
  end

  test "raises ValidationError when current level exceeds ascension cap" do
    assert_validation_error(
      { current_level: 21, target_level: 21, current_ascension_rank: 0, target_ascension_rank: 1 },
      "exceeds max level"
    )
  end

  test "raises ValidationError when level is below ascension minimum" do
    assert_validation_error(
      { current_level: 1, target_level: 20, current_ascension_rank: 1, target_ascension_rank: 1 },
      "requires a minimum level"
    )
  end

  test "calculates correct credit and energy core cost for leveling 1 to 20" do
    result = call_planner({ target_level: 20 })

    shell_credit_id = Material.find_by!(name: "Shell Credit").id
    basic_core_id = Material.find_by!(name: "Basic Energy Core").id

    assert_equal 15480, result[shell_credit_id]
    assert_equal 38, result[basic_core_id]
  end

  test "returns no energy core when level does not change" do
    result = call_planner({ current_level: 20, target_level: 20, target_ascension_rank: 1 })

    shell_credit_id = Material.find_by!(name: "Shell Credit").id
    basic_core_id = Material.find_by!(name: "Basic Energy Core").id

    assert_equal 10000, result[shell_credit_id]
    assert_equal 0, result[basic_core_id]
  end

  test "calculates correct ascension materials for rank 0 to 1" do
    result = call_planner({
      current_level: 20, target_level: 20,
      current_ascension_rank: 0, target_ascension_rank: 1
    })

    shell_credit_id = Material.find_by!(name: "Shell Credit").id
    lf_whisperin_core_id = Material.find_by!(name: "LF Whisperin Core").id

    assert_equal 10000, result[shell_credit_id]
    assert_equal 6, result[lf_whisperin_core_id]
  end

  test "calculates correct ascension materials for a Lahai Roi weapon" do
    everbright = Weapon.find_by!(name: "Everbright Polestar")
    result = WeaponAscensionPlanner.new(
      weapon: everbright,
      current_level: 40, target_level: 40,
      current_ascension_rank: 1, target_ascension_rank: 2
    ).call

    shell_credit_id = Material.find_by!(name: "Shell Credit").id
    mf_mech_core_id = Material.find_by!(name: "MF Mech Core").id
    broken_wing_polarizer_id = Material.find_by!(name: "Broken Wing Polarizer").id

    assert_equal 20000, result[shell_credit_id]
    assert_equal 6, result[mf_mech_core_id]
    assert_equal 6, result[broken_wing_polarizer_id]
  end

  test "calculates full material costs for Kumokiri 1 to 90" do
    result = call_planner({
      current_level: 1, target_level: 90,
      current_ascension_rank: 0, target_ascension_rank: 6
    })

    shell_credit_id = Material.find_by!(name: "Shell Credit").id
    basic_core_id = Material.find_by!(name: "Basic Energy Core").id
    lf_whisperin_core_id = Material.find_by!(name: "LF Whisperin Core").id
    mf_whisperin_core_id = Material.find_by!(name: "MF Whisperin Core").id
    hf_whisperin_core_id = Material.find_by!(name: "HF Whisperin Core").id
    ff_whisperin_core_id = Material.find_by!(name: "FF Whisperin Core").id
    waveworn_residue_210_id = Material.find_by!(name: "Waveworn Residue 210").id
    waveworn_residue_226_id = Material.find_by!(name: "Waveworn Residue 226").id
    waveworn_residue_235_id = Material.find_by!(name: "Waveworn Residue 235").id
    waveworn_residue_239_id = Material.find_by!(name: "Waveworn Residue 239").id

    assert_equal 1406960, result[shell_credit_id]
    assert_equal 2692, result[basic_core_id]
    assert_equal 6, result[lf_whisperin_core_id]
    assert_equal 6, result[mf_whisperin_core_id]
    assert_equal 10, result[hf_whisperin_core_id]
    assert_equal 12, result[ff_whisperin_core_id]
    assert_equal 6, result[waveworn_residue_210_id]
    assert_equal 8, result[waveworn_residue_226_id]
    assert_equal 6, result[waveworn_residue_235_id]
    assert_equal 20, result[waveworn_residue_239_id]
  end

  private

  def call_planner(overrides = {})
    params = @base_params.merge(overrides)
    WeaponAscensionPlanner.new(**params).call
  end

  def assert_validation_error(overrides, expected_message_fragment)
    error = assert_raises(WeaponAscensionPlanner::ValidationError) do
      call_planner(overrides)
    end
    assert_match expected_message_fragment, error.message
  end
end
