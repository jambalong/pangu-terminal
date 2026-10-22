require "test_helper"

class PlanRecomputerTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(email: "recompute@example.com", password: "password123")
    @weapon = Weapon.find_by!(name: "Kumokiri")
    @resonator = Resonator.find_by!(name: "Chisa")
    @shell_credit = Material.find_by!(name: "Shell Credit")

    @weapon_plan = PlanForm.new(
      subject_type: "Weapon", subject_id: @weapon.id,
      current_level: 1, target_level: 20, current_ascension_rank: 0, target_ascension_rank: 1
    ).save(@user, nil)
    @resonator_plan = PlanForm.new(
      subject_type: "Resonator", subject_id: @resonator.id,
      current_level: 1, target_level: 40, current_ascension_rank: 0, target_ascension_rank: 2
    ).save(@user, nil)
  end

  # Simulates a plan saved while the planner had a bug.
  def make_stale(plan, material_id, wrong_quantity)
    data = plan.reload.plan_data.deep_dup
    @correct = data["output"][material_id.to_s]
    data["output"][material_id.to_s] = wrong_quantity
    plan.update_columns(plan_data: data)
  end

  test "plans computed by the current planner are unchanged" do
    result = PlanRecomputer.call(scope: Plan.where(user: @user), apply: true)

    assert_empty result[:changed]
    assert_empty result[:failed]
    assert_equal 2, result[:unchanged]
  end

  test "dry run reports stale plans without writing" do
    make_stale(@weapon_plan, @shell_credit.id, 1)

    result = PlanRecomputer.call(scope: Plan.where(user: @user))

    assert_equal 1, result[:changed].size
    change = result[:changed].first
    assert_equal @weapon_plan.id, change[:plan_id]
    assert_equal @weapon.name, change[:subject]
    assert_equal [ 1, @correct ], change[:diff][@shell_credit.id]
    assert_equal 1, @weapon_plan.reload.plan_data["output"][@shell_credit.id.to_s]
  end

  test "apply rewrites stale plans and leaves the others alone" do
    make_stale(@weapon_plan, @shell_credit.id, 1)
    untouched_updated_at = @resonator_plan.reload.updated_at

    PlanRecomputer.call(scope: Plan.where(user: @user), apply: true)

    assert_equal @correct, @weapon_plan.reload.plan_data["output"][@shell_credit.id.to_s]
    assert_equal untouched_updated_at, @resonator_plan.reload.updated_at
    assert_empty PlanRecomputer.call(scope: Plan.where(user: @user))[:changed]
  end

  test "recomputes resonator plans from stored skill and forte input" do
    make_stale(@resonator_plan, @shell_credit.id, 5)

    result = PlanRecomputer.call(scope: Plan.where(id: @resonator_plan.id), apply: true)

    assert_equal [ @resonator_plan.id ], result[:changed].map { |c| c[:plan_id] }
    assert_equal @correct, @resonator_plan.reload.plan_data["output"][@shell_credit.id.to_s]
  end

  test "keeps the stored input when it rewrites a plan" do
    input_before = @weapon_plan.plan_data["input"]
    make_stale(@weapon_plan, @shell_credit.id, 1)

    PlanRecomputer.call(scope: Plan.where(id: @weapon_plan.id), apply: true)

    assert_equal input_before, @weapon_plan.reload.plan_data["input"]
  end

  test "recomputes guest plans too" do
    guest_plan = PlanForm.new(
      subject_type: "Weapon", subject_id: @weapon.id,
      current_level: 1, target_level: 20, current_ascension_rank: 0, target_ascension_rank: 1
    ).save(nil, "guest-token")
    make_stale(guest_plan, @shell_credit.id, 1)

    result = PlanRecomputer.call(scope: Plan.where(guest_token: "guest-token"), apply: true)

    assert_equal [ guest_plan.id ], result[:changed].map { |c| c[:plan_id] }
    assert_nil guest_plan.reload.user_id
  end

  test "reports plans whose stored input no longer validates instead of raising" do
    data = @weapon_plan.plan_data.deep_dup
    data["input"]["target_level"] = 1000
    @weapon_plan.update_columns(plan_data: data)

    result = PlanRecomputer.call(scope: Plan.where(id: @weapon_plan.id), apply: true)

    assert_equal [ @weapon_plan.id ], result[:failed].map { |f| f[:plan_id] }
    assert_empty result[:changed]
    assert_equal 1000, @weapon_plan.reload.plan_data["input"]["target_level"]
  end
end
