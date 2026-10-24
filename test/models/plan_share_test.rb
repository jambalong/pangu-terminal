require "test_helper"

class PlanShareTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(email: "share_model@example.com", password: "password123")
    @plan = Plan.create!(user: @user, subject: Weapon.first, plan_data: { "input" => {}, "output" => {} })
  end

  test "a new plan is not shared" do
    assert_nil @plan.share_token
    assert_not @plan.shared?
  end

  test "share! makes a long random url-safe token" do
    token = @plan.share!

    assert @plan.reload.shared?
    assert_equal token, @plan.share_token
    assert_match(/\A[A-Za-z0-9_-]{22}\z/, token)
  end

  test "share! keeps the same token when already shared" do
    first = @plan.share!

    assert_equal first, @plan.share!
  end

  test "each plan gets its own token" do
    other = Plan.create!(user: @user, subject: Weapon.second, plan_data: { "input" => {}, "output" => {} })

    assert_not_equal @plan.share!, other.share!
  end

  test "unshare! removes the token and a new share makes a different one" do
    first = @plan.share!
    @plan.unshare!

    assert_not @plan.reload.shared?
    assert_not_equal first, @plan.share!
  end

  test "tokens are unique in the database" do
    other = Plan.create!(user: @user, subject: Weapon.second, plan_data: { "input" => {}, "output" => {} })
    @plan.share!

    assert_raises(ActiveRecord::RecordNotUnique) { other.update_columns(share_token: @plan.share_token) }
  end

  test "sharing works for legacy plans that would fail validation" do
    @plan.update_columns(subject_id: 0)
    assert_not @plan.reload.valid?

    assert @plan.share!.present?
  end

  test "sharing does not change the plan's priority or contents" do
    data = { "input" => { "a" => 1 }, "output" => { "5" => 3 } }
    @plan.update!(plan_data: data)
    position = @plan.position

    @plan.share!

    assert_equal [ position, data ], [ @plan.reload.position, @plan.plan_data ]
  end
end
