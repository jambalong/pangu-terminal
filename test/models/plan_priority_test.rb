require "test_helper"

class PlanPriorityTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(email: "priority_model@example.com", password: "password123")
    @weapons = Weapon.limit(4).to_a
  end

  def plan_for(weapon, owner: @user)
    Plan.create!(user: owner, subject: weapon, plan_data: { "input" => {}, "output" => {} })
  end

  test "new plans go to the end of their owner's list" do
    first, second, third = @weapons.first(3).map { |weapon| plan_for(weapon) }

    assert_equal [ 1, 2, 3 ], [ first, second, third ].map(&:position)
    assert_equal [ first, second, third ], @user.plans.by_priority.to_a
  end

  test "each user and each guest has their own numbering" do
    other = User.create!(email: "priority_other@example.com", password: "password123")
    plan_for(@weapons[0])
    plan_for(@weapons[1])

    assert_equal 1, plan_for(@weapons[0], owner: other).position

    token = SecureRandom.uuid
    guest = Plan.create!(guest_token: token, subject: @weapons[0], plan_data: { "input" => {}, "output" => {} })
    guest_two = Plan.create!(guest_token: token, subject: @weapons[1], plan_data: { "input" => {}, "output" => {} })
    assert_equal [ 1, 2 ], [ guest.position, guest_two.position ]
  end

  test "plans from before priorities existed sort first, in creation order" do
    old_a = plan_for(@weapons[0])
    old_b = plan_for(@weapons[1])
    [ old_a, old_b ].each { |plan| plan.update_columns(position: nil) }
    old_a.update_columns(created_at: 2.days.ago)
    old_b.update_columns(created_at: 1.day.ago)

    newer = plan_for(@weapons[2])

    assert_equal [ old_a, old_b, newer ], @user.plans.by_priority.to_a
  end

  test "a position given explicitly is kept" do
    plan = Plan.create!(user: @user, subject: @weapons[0], position: 7, plan_data: { "input" => {}, "output" => {} })

    assert_equal 7, plan.position
  end

  test "editing a plan does not change its priority" do
    first = plan_for(@weapons[0])
    plan_for(@weapons[1])

    first.update!(plan_data: { "input" => { "x" => 1 }, "output" => {} })

    assert_equal 1, first.reload.position
  end
end
