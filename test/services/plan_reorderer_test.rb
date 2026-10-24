require "test_helper"

class PlanReordererTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(email: "reorder@example.com", password: "password123")
    @a, @b, @c = Weapon.limit(3).map do |weapon|
      Plan.create!(user: @user, subject: weapon, plan_data: { "input" => {}, "output" => {} })
    end
  end

  def move(plan, direction) = PlanReorderer.call(plans: @user.plans.by_priority, plan: plan, direction: direction)
  def order = @user.plans.by_priority.to_a

  test "moves a plan up" do
    assert_equal :moved, move(@b, "up")
    assert_equal [ @b, @a, @c ], order
  end

  test "moves a plan down" do
    assert_equal :moved, move(@b, "down")
    assert_equal [ @a, @c, @b ], order
  end

  test "the first plan cannot go up and the last cannot go down" do
    assert_equal :unchanged, move(@a, "up")
    assert_equal :unchanged, move(@c, "down")
    assert_equal [ @a, @b, @c ], order
  end

  test "an unknown direction changes nothing" do
    assert_equal :unchanged, move(@b, "sideways")
    assert_equal :unchanged, move(@b, nil)
    assert_equal [ @a, @b, @c ], order
  end

  test "positions are rewritten as 1 to n, including plans that had none" do
    [ @a, @b, @c ].each { |plan| plan.update_columns(position: nil) }
    @a.update_columns(created_at: 3.days.ago)
    @b.update_columns(created_at: 2.days.ago)
    @c.update_columns(created_at: 1.day.ago)

    move(@c, "up")

    assert_equal [ @a, @c, @b ], order
    assert_equal [ 1, 2, 3 ], order.map(&:position)
  end

  test "a plan that is not in the list is left alone" do
    stranger = User.create!(email: "reorder_stranger@example.com", password: "password123")
    foreign = Plan.create!(user: stranger, subject: @a.subject, plan_data: { "input" => {}, "output" => {} })

    assert_equal :unchanged, move(foreign, "up")
    assert_equal [ @a, @b, @c ], order
  end

  test "another owner's priorities are untouched" do
    stranger = User.create!(email: "reorder_stranger2@example.com", password: "password123")
    theirs = Weapon.limit(2).map { |weapon| Plan.create!(user: stranger, subject: weapon, plan_data: { "input" => {}, "output" => {} }) }

    move(@b, "up")

    assert_equal [ 1, 2 ], theirs.map { |plan| plan.reload.position }
  end
end
