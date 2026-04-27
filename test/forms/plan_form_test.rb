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
