require "test_helper"

class OnboardingChecklistTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(email: "onboarding@example.com", password: "password123")
  end

  def done
    OnboardingChecklist.call(user: @user)[:steps].to_h { |step| [ step[:key], step[:done] ] }
  end

  test "a new account has nothing done" do
    result = OnboardingChecklist.call(user: @user)

    assert_equal %i[ sol3_phase plan inventory ], result[:steps].map { |step| step[:key] }
    assert_equal({ sol3_phase: false, plan: false, inventory: false }, done)
    assert_not result[:complete]
  end

  test "each step completes from the user's own data" do
    @user.update!(sol3_phase: 4)
    assert_equal({ sol3_phase: true, plan: false, inventory: false }, done)

    Plan.create!(user: @user, subject: Weapon.find_by!(name: "Kumokiri"), plan_data: { "input" => {}, "output" => {} })
    assert_equal({ sol3_phase: true, plan: true, inventory: false }, done)

    @user.inventory_item_for(Material.find_by!(name: "Shell Credit")).update!(quantity: 5)
    assert_equal({ sol3_phase: true, plan: true, inventory: true }, done)
    assert OnboardingChecklist.call(user: @user)[:complete]
  end

  test "inventory rows at zero do not count as owning something" do
    @user.inventory_item_for(Material.find_by!(name: "Shell Credit"))

    assert_not done[:inventory]
  end

  test "another user's data does not count" do
    other = User.create!(email: "onboarding_other@example.com", password: "password123", sol3_phase: 3)
    Plan.create!(user: other, subject: Weapon.find_by!(name: "Kumokiri"), plan_data: { "input" => {}, "output" => {} })

    assert_equal({ sol3_phase: false, plan: false, inventory: false }, done)
  end
end
