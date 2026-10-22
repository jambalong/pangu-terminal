require "test_helper"

class PlanFormTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(email: "planform@example.com", password: "password123")
    @resonator = Resonator.find_by!(name: "Chisa")
    @weapon = Weapon.find_by!(name: "Kumokiri")
  end

  test "from_plan builds form from a weapon plan" do
    plan = Plan.create!(
      user: @user,
      subject: @weapon,
      subject_type: "Weapon",
      plan_data: {
        "input" => {
          "current_level" => 1,
          "target_level" => 20,
          "current_ascension_rank" => 0,
          "target_ascension_rank" => 1
        },
        "output" => {}
      }
    )

    form = PlanForm.from_plan(plan)

    assert_equal "Weapon", form.subject_type
    assert_equal 1, form.current_level
    assert_equal 20, form.target_level
  end

  test "from_plan builds form from a resonator plan with skill levels and forte nodes" do
    plan = Plan.create!(
      user: @user,
      subject: @resonator,
      subject_type: "Resonator",
      plan_data: {
        "input" => {
          "current_level" => 1,
          "target_level" => 20,
          "current_ascension_rank" => 0,
          "target_ascension_rank" => 1,
          "current_skill_levels" => { "basic_attack" => 1 },
          "target_skill_levels" => { "basic_attack" => 5 },
          "forte_node_upgrades" => { "basic_attack_node_1" => true }
        },
        "output" => {}
      }
    )

    form = PlanForm.from_plan(plan)

    assert_equal "Resonator", form.subject_type
    assert_equal 1, form.current_level
    assert_equal 20, form.target_level
  end

  test "from_plan handles plan with no input data" do
    plan = Plan.create!(
      user: @user,
      subject: @weapon,
      subject_type: "Weapon",
      plan_data: { "input" => nil, "output" => {} }
    )

    form = PlanForm.from_plan(plan)
    assert_equal "Weapon", form.subject_type
  end

  test "from_plan handles resonator plan with missing skill and node data" do
    plan = Plan.create!(
      user: @user,
      subject: @resonator,
      subject_type: "Resonator",
      plan_data: {
        "input" => {
          "current_level" => 1,
          "target_level" => 20,
          "current_ascension_rank" => 0,
          "target_ascension_rank" => 1
        },
        "output" => {}
      }
    )

    form = PlanForm.from_plan(plan)
    assert_equal "Resonator", form.subject_type
  end
end

class PlanFormSkillMappingTest < ActiveSupport::TestCase
  SKILLS = %i[basic_attack resonance_skill forte_circuit resonance_liberation intro_skill].freeze

  setup do
    attrs = { subject_type: "Resonator", subject_id: Resonator.find_by!(name: "Chisa").id }
    SKILLS.each_with_index do |skill, i|
      attrs["#{skill}_current"] = i + 1
      attrs["#{skill}_target"] = i + 6
      attrs["#{skill}_node_1"] = 1
      attrs["#{skill}_node_2"] = i.even? ? 1 : 0
    end
    @form = PlanForm.new(attrs)
  end

  test "current and target skill level hashes are keyed by skill symbol in a fixed order" do
    current = @form.send(:map_current_skill_levels)
    target = @form.send(:map_target_skill_levels)

    assert_equal SKILLS, current.keys
    assert_equal SKILLS, target.keys
    assert_equal [ 1, 2, 3, 4, 5 ], current.values
    assert_equal [ 6, 7, 8, 9, 10 ], target.values
  end

  test "forte node hash has both nodes per skill as integers in a fixed order" do
    nodes = @form.send(:map_forte_nodes_upgrades)

    expected_keys = SKILLS.flat_map { |s| [ :"#{s}_node_1", :"#{s}_node_2" ] }
    assert_equal expected_keys, nodes.keys
    assert_equal [ 1, 1, 1, 0, 1, 1, 1, 0, 1, 1 ], nodes.values
  end

  test "resonator input data combines the three hashes" do
    data = @form.send(:resonator_input_data)

    assert_equal %i[current_skill_levels target_skill_levels forte_node_upgrades], data.keys
  end

  test "permitted_params is exactly the core fields plus four fields per skill" do
    expected = %i[
      id subject_type subject_id current_level target_level current_ascension_rank target_ascension_rank
      basic_attack_current basic_attack_target resonance_skill_current resonance_skill_target
      forte_circuit_current forte_circuit_target resonance_liberation_current resonance_liberation_target
      intro_skill_current intro_skill_target
      basic_attack_node_1 basic_attack_node_2 resonance_skill_node_1 resonance_skill_node_2
      forte_circuit_node_1 forte_circuit_node_2 resonance_liberation_node_1 resonance_liberation_node_2
      intro_skill_node_1 intro_skill_node_2
    ]

    assert_equal expected.sort, PlanForm.permitted_params.sort
  end
end
