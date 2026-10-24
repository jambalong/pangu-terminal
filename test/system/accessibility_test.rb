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

  def focus_inside_dialog?
    page.evaluate_script("document.querySelector('[role=dialog]').contains(document.activeElement)")
  end

  test "the new plan dialog is named, takes focus, traps Tab and gives focus back on Escape" do
    visit plans_path
    find("a.new-plan-btn", text: "NEW PLAN", match: :first).click

    assert_selector "[role=dialog][aria-modal=true]"
    title = page.evaluate_script(
      "document.getElementById(document.querySelector('[role=dialog]').getAttribute('aria-labelledby')).textContent.trim()"
    )
    assert_equal "Select Plan Type", title
    assert_selector "[role=dialog] :focus"
    assert_no_axe_violations(skip: SKIPPED)

    12.times do
      page.driver.browser.keyboard.type(:Tab)
      assert focus_inside_dialog?, "Tab escaped the dialog"
    end
    12.times do
      page.driver.browser.keyboard.type([ :shift, :Tab ])
      assert focus_inside_dialog?, "Shift+Tab escaped the dialog"
    end

    page.driver.browser.keyboard.type(:Escape)
    assert_no_selector "[role=dialog]"
    assert_selector ".new-plan-btn:focus"
  end

  test "the dialog has a close button" do
    visit plans_path
    find("a.new-plan-btn", text: "NEW PLAN", match: :first).click
    assert_selector "[role=dialog]"

    click_button "Close dialog"

    assert_no_selector "[role=dialog]"
  end

  test "the delete confirmation closes with Escape" do
    sign_in_through_form
    plan = Plan.create!(user: @user, subject: Weapon.find_by!(name: "Kumokiri"), plan_data: { "input" => {}, "output" => {} })
    visit confirm_delete_plan_path(plan)
    visit plans_path
    click_link "Delete", match: :first
    assert_selector "[role=dialog]"

    page.driver.browser.keyboard.type(:Escape)

    assert_no_selector "[role=dialog]"
    assert Plan.exists?(plan.id)
  end
end
