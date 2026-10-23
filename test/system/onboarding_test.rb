require "application_system_test_case"

class OnboardingTest < ApplicationSystemTestCase
  setup do
    @user = User.create!(email: "onboard@example.com", password: "password123")
    @user.send(:initialize_inventory)
    visit new_user_session_path
    fill_in "Email", with: "onboard@example.com"
    fill_in "Password", with: "password123"
    click_button "Sign In"
    assert_text "Dashboard"
  end

  test "the checklist can be hidden and stays hidden after a reload" do
    assert_text "Get started"
    assert_text "Create your first plan"

    click_button "Hide"
    assert_no_text "Get started", wait: 5

    visit authenticated_root_path
    assert_text "Dashboard"
    assert_no_text "Get started"
  end

  test "the planner explains itself when empty and the hint disappears with the first plan" do
    visit plans_path
    assert_text "No plans yet"

    click_link "✚ New Plan"
    click_link "Weapon"
    fill_in "Search by name...", with: "Kumokiri"
    click_link "Kumokiri", wait: 10
    click_button "Create Plan"
    assert_text "Plan created successfully."

    assert_no_text "No plans yet", wait: 5
  end
end
