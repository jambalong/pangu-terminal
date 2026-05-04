require "application_system_test_case"

class UserJourneyTest < ApplicationSystemTestCase
  setup do
    @user = User.create!(email: "system@example.com", password: "password123")
    @user.send(:initialize_inventory)
  end

  test "complete user journey: sign in, set SOL3 phase, create plan, update inventory, view optimizer results" do
    # Sign in
    visit new_user_session_path
    fill_in "Email", with: "system@example.com"
    fill_in "Password", with: "password123"
    click_button "Sign In"
    assert_text "Signed in successfully."
    assert_text "Dashboard"

    # Set SOL3 phase from Dashboard
    select "Phase 8", from: "user_sol3_phase"
    click_button "Save"
    assert_text "Your account has been updated successfully."

    # Create a plan
    visit plans_path
    assert_text "Planner"
    click_link "✚ New Plan"
    assert_text "Select Plan Type"
    click_link "Weapon"
    assert_text "Select Weapon"
    fill_in "Search by name...", with: "Kumokiri"
    click_link "Kumokiri", wait: 10
    assert_text "CONFIGURE WEAPON PLAN"
    click_button "Create Plan"
    assert_text "Plan created successfully."

    # Update inventory
    visit inventory_items_path
    assert_text "Inventory"
    click_link "Shell Credit"
    assert_text "Shell Credit"
    fill_in "inventory_item[quantity]", with: "50000"
    find("input[name='inventory_item[quantity]']").send_keys :tab
    assert_text "50k"

    # Optimizer
    visit optimizer_path
    assert_text "Waveplate Optimizer"
    click_link "> SELECT A PLAN"
    assert_text "Select a Plan"
    click_button "Kumokiri"
    click_button "> RUN OPTIMIZER"
    assert_selector ".optimizer-metrics"
  end
end
