require "test_helper"

class PlanTest < ActiveSupport::TestCase
  setup do
    @resonator = Resonator.find_by!(name: "Aalto")
    @user = User.create!(email: "test@example.com", password: "password")
    @plan = Plan.new(
      guest_token: "abc123",
      subject: @resonator,
      plan_data: { "input" => {}, "output" => {} }
    )
  end

  test "valid plan with guest_token" do
    assert @plan.valid?
  end

  test "invalid without subject_type" do
    @plan.subject_type = nil
    assert @plan.invalid?
    assert_includes @plan.errors[:subject_type], "can't be blank"
  end

  test "invalid with unrecognized subject_type" do
    @plan.subject_type = "Character"
    assert @plan.invalid?
    assert @plan.errors[:subject_type].any?
  end

  test "invalid without subject_id" do
    @plan.subject_id = nil
    assert @plan.invalid?
    assert @plan.errors[:subject_id].any?
  end

  test "invalid without plan_data" do
    @plan.plan_data = nil
    assert @plan.invalid?
    assert @plan.errors[:plan_data].any?
  end

  test "invalid when both user_id and guest_token are nil" do
    @plan.guest_token = nil
    @plan.user_id = nil
    assert @plan.invalid?
    assert @plan.errors[:base].any?
  end

  test "invalid when same user already has a plan for the same subject" do
    Plan.create!(
      user: @user,
      subject: @resonator,
      plan_data: { "input" => {}, "output" => {} }
    )
    duplicate = Plan.new(
      user: @user,
      subject: @resonator,
      plan_data: { "input" => {}, "output" => {} }
    )
    assert duplicate.invalid?
    assert duplicate.errors[:subject_id].any?
  end

  test "valid when same user has plans for different subjects of the same type" do
    other_resonator = Resonator.where.not(id: @resonator.id).first!
    Plan.create!(
      user: @user,
      subject: @resonator,
      plan_data: { "input" => {}, "output" => {} }
    )
    second_plan = Plan.new(
      user: @user,
      subject: other_resonator,
      plan_data: { "input" => {}, "output" => {} }
    )
    assert second_plan.valid?
  end

  test "valid when same user has plans for same subject_id but different subject_type" do
    @weapon = Weapon.find_by!(name: "Commando of Conviction")
    Plan.create!(
      user: @user,
      subject: @resonator,
      plan_data: { "input" => {}, "output" => {} }
    )
    cross_type_plan = Plan.new(
      user: @user,
      subject: @weapon,
      plan_data: { "input" => {}, "output" => {} }
    )
    assert cross_type_plan.valid?
  end

  test "valid when different user creates a plan for the same subject" do
    Plan.create!(
      user: @user,
      subject: @resonator,
      plan_data: { "input" => {}, "output" => {} }
    )
    other_user = User.create!(email: "other@example.com", password: "password")
    other_plan = Plan.new(
      user: other_user,
      subject: @resonator,
      plan_data: { "input" => {}, "output" => {} }
    )
    assert other_plan.valid?
  end
end
