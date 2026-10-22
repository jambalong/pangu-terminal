require "test_helper"

class GuestPlanPrunerTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(email: "pruner@example.com", password: "password123")
    @weapons = Weapon.order(:id).limit(4).to_a
  end

  def plan_for(weapon, user: nil, guest_token: nil, updated_at: Time.current)
    plan = Plan.create!(user: user, guest_token: guest_token, subject: weapon, plan_data: { "input" => {}, "output" => {} })
    plan.update_columns(updated_at: updated_at)
    plan
  end

  test "dry run counts stale guest plans and deletes nothing" do
    plan_for(@weapons[0], guest_token: "old", updated_at: 120.days.ago)

    result = GuestPlanPruner.call

    assert_equal({ stale: 1, deleted: 0 }, result)
    assert_equal 1, Plan.where(guest_token: "old").count
  end

  test "apply deletes only stale guest plans" do
    stale = plan_for(@weapons[0], guest_token: "old", updated_at: 120.days.ago)
    fresh_guest = plan_for(@weapons[1], guest_token: "recent", updated_at: 5.days.ago)
    old_user_plan = plan_for(@weapons[2], user: @user, updated_at: 400.days.ago)

    result = GuestPlanPruner.call(apply: true)

    assert_equal({ stale: 1, deleted: 1 }, result)
    assert_not Plan.exists?(stale.id)
    assert Plan.exists?(fresh_guest.id)
    assert Plan.exists?(old_user_plan.id)
  end

  test "honours a custom age" do
    plan_for(@weapons[0], guest_token: "ten", updated_at: 10.days.ago)

    assert_equal 0, GuestPlanPruner.call(older_than: 30.days)[:stale]
    assert_equal 1, GuestPlanPruner.call(older_than: 7.days)[:stale]
  end

  test "reports nothing to do when there are no stale plans" do
    assert_equal({ stale: 0, deleted: 0 }, GuestPlanPruner.call(apply: true))
  end
end
