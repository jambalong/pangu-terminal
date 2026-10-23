require "application_system_test_case"

class InventoryFilterTest < ApplicationSystemTestCase
  setup do
    @user = User.create!(email: "filter@example.com", password: "password123")
    @user.send(:initialize_inventory)
  end

  test "typing in the search box filters the grid without a submit click" do
    visit new_user_session_path
    fill_in "Email", with: "filter@example.com"
    fill_in "Password", with: "password123"
    click_button "Sign In"
    assert_text "Dashboard"

    visit inventory_items_path
    assert_text "Shell Credit"
    assert_text "Resonator EXP", wait: 5

    fill_in "Search materials...", with: "Shell Credit"

    assert_text "Shell Credit"
    assert_no_text "Basic Resonance Potion", wait: 5
  end
end
