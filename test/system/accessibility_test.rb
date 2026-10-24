require "application_system_test_case"

# Runs axe-core on the main pages. Rules listed in SKIPPED are known gaps that
# a later change will fix and remove from this list.
class AccessibilityTest < ApplicationSystemTestCase
  SKIPPED = %w[ color-contrast ].freeze

  setup do
    @user = User.create!(email: "a11y@example.com", password: "password123", sol3_phase: 3)
    @user.send(:initialize_inventory)
  end

  def sign_in_through_form
    visit new_user_session_path
    fill_in "Email", with: "a11y@example.com"
    fill_in "Password", with: "password123"
    click_button "Sign In"
    assert_text "Dashboard"
  end

  test "public pages have no axe violations" do
    [ root_path, new_user_session_path, privacy_path, user_manual_path, plans_path ].each do |path|
      visit path
      assert_selector "body"
      assert_no_axe_violations(skip: SKIPPED)
    end
  end

  test "signed-in pages have no axe violations" do
    sign_in_through_form
    assert_no_axe_violations(skip: SKIPPED)

    [ plans_path, inventory_items_path, optimizer_path, edit_user_registration_path ].each do |path|
      visit path
      assert_selector "body"
      assert_no_axe_violations(skip: SKIPPED)
    end
  end

  test "the skip link is the first thing keyboard users reach and it moves focus to the content" do
    visit root_path
    page.driver.browser.keyboard.type(:Tab)

    assert_selector ".skip-link:focus", visible: :all
    page.driver.browser.keyboard.type(:Enter)
    assert_selector "#main-content:focus"
  end

  test "the material summary accordion is a button that reports its state" do
    sign_in_through_form
    Plan.create!(user: @user, subject: Weapon.find_by!(name: "Kumokiri"), plan_data: { "input" => {}, "output" => {} })
    visit plans_path

    toggle = find("button.accordion-header")
    assert_equal "false", toggle["aria-expanded"]
    toggle.click
    assert_equal "true", find("button.accordion-header")["aria-expanded"]
    toggle.click
    assert_equal "false", find("button.accordion-header")["aria-expanded"]
  end

  test "the current page is marked in the navigation" do
    sign_in_through_form
    visit plans_path

    assert_selector "a.nav-plan[aria-current=page]"
    assert_no_selector "a.nav-inventory[aria-current]"
  end
end
