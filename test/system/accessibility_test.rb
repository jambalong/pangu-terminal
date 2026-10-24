require "application_system_test_case"

# Runs axe-core on the main pages, including WCAG AA color contrast. Rules
# listed in SKIPPED would be known gaps with a follow-up; the list is empty.
class AccessibilityTest < ApplicationSystemTestCase
  SKIPPED = %w[].freeze

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

  test "an error message outlives the old 2.5 second timeout and can be dismissed" do
    visit new_user_session_path
    fill_in "Email", with: "a11y@example.com"
    fill_in "Password", with: "wrong-password"
    click_button "Sign In"

    assert_selector ".flash-message.alert"
    sleep 3.2
    assert_selector ".flash-message.alert"

    click_button "Dismiss message"
    assert_no_selector ".flash-message.alert", wait: 3
  end

  test "the optimizer plan picker can be opened again after choosing a plan" do
    sign_in_through_form
    Plan.create!(user: @user, subject: Weapon.find_by!(name: "Kumokiri"), plan_data: { "input" => {}, "output" => {} })
    visit optimizer_path

    click_link "> SELECT A PLAN"
    assert_selector "[role=dialog]"
    click_button "Kumokiri"
    assert_no_selector "[role=dialog]"

    find("a.optimizer-plan-card").click
    assert_selector "[role=dialog]"
    assert_equal 1, page.evaluate_script("document.querySelectorAll('turbo-frame#modal').length")
  end

  test "navigating with the nav links keeps a single main_content frame" do
    sign_in_through_form

    click_link "Inventory", match: :first
    assert_selector "h1", text: "Inventory"
    click_link "Planner", match: :first
    assert_selector "h1", text: "Planner"

    assert_equal 1, page.evaluate_script("document.querySelectorAll('turbo-frame#main_content').length")
    assert_equal 1, page.evaluate_script("document.querySelectorAll('turbo-frame#modal').length")
  end
end
