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
    click_button "Use all plans (1)"
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

  test "choosing several plans works from the keyboard and is announced as a group" do
    sign_in_through_form
    %w[ Kumokiri ].each { |name| Plan.create!(user: @user, subject: Weapon.find_by!(name: name), plan_data: { "input" => {}, "output" => {} }) }
    Plan.create!(user: @user, subject: Weapon.where.not(name: "Kumokiri").first, plan_data: { "input" => {}, "output" => {} })
    visit optimizer_path

    click_link "> SELECT A PLAN"
    assert_selector "[role=dialog] fieldset legend", text: "Or pick the ones you want"
    assert_no_axe_violations(skip: SKIPPED)

    page.driver.browser.keyboard.type(:Tab) until page.evaluate_script("document.activeElement.type") == "checkbox"
    page.driver.browser.keyboard.type(:Space)
    page.driver.browser.keyboard.type(:Tab)
    page.driver.browser.keyboard.type(:Space)
    assert_selector ".optimizer-plan-select-card:has(input:checked)", count: 2

    click_button "Use selected plans"
    assert_no_selector "[role=dialog]"
    assert_selector ".optimizer-plan-name", text: "2 plans"
  end

  test "all plans can be chosen in one click and the card names the scope" do
    sign_in_through_form
    2.times do |i|
      Plan.create!(user: @user, subject: Weapon.order(:id).offset(i).first, plan_data: { "input" => {}, "output" => {} })
    end
    visit optimizer_path

    click_link "> SELECT A PLAN"
    click_button "Use all plans (2)"

    assert_selector ".optimizer-plan-name", text: "All plans (2)"
    assert_no_axe_violations(skip: SKIPPED)
  end

  test "optimizer results with the Waveplate timeline are accessible" do
    sign_in_through_form
    shell_credit = Material.find_by!(name: "Shell Credit")
    Plan.create!(user: @user, subject: Weapon.find_by!(name: "Kumokiri"),
                 plan_data: { "input" => {}, "output" => { shell_credit.id.to_s => 25480 } })
    visit optimizer_path
    click_link "> SELECT A PLAN"
    click_button "Use all plans (1)"

    fill_in "Waveplates you have now (optional)", with: "100"
    click_button "> RUN OPTIMIZER"

    assert_selector ".optimizer-metrics", wait: 10
    assert_selector ".optimizer-metric-label", text: /time to regenerate/i
    assert_text "Counting the 100 you have now"
    assert_no_axe_violations(skip: SKIPPED)
  end

  test "the inventory import page and a finished import are accessible" do
    sign_in_through_form
    visit inventory_items_path
    click_link "Import"
    assert_selector "h1", text: "Import inventory"
    assert_no_axe_violations(skip: SKIPPED)

    fill_in "Or paste it here", with: "key,quantity\nshell_credit,500\nnot_a_material,3"
    click_button "Import"

    assert_text "Import finished"
    assert_text "unknown material"
    assert_no_axe_violations(skip: SKIPPED)
    assert_equal 500, @user.inventory_items.find_by!(material: Material.find_by!(name: "Shell Credit")).quantity
  end

  test "quick entry is keyboard driven, saves, and reports a bad entry accessibly" do
    sign_in_through_form
    shell = Material.find_by!(name: "Shell Credit")
    core = Material.find_by!(name: "Basic Energy Core")
    visit inventory_quick_entry_path
    assert_selector "h1", text: "Quick entry"
    assert_no_axe_violations(skip: SKIPPED)

    assert_selector "#quantity_#{shell.id}:focus"
    page.driver.browser.keyboard.type("25k")
    page.driver.browser.keyboard.type(:Enter)
    assert_selector "#quantity_#{Material.order(:id).second.id}:focus"
    page.driver.browser.keyboard.type([ :shift, :Enter ])
    assert_selector "#quantity_#{shell.id}:focus"

    find("#quantity_#{core.id}").fill_in with: "plenty"
    click_button "Save changes"

    assert_selector ".quick-errors[role=alert]"
    assert_selector "#quantity_#{core.id}[aria-invalid=true]"
    assert_selector "#quantity_#{core.id}:focus"
    assert_no_axe_violations(skip: SKIPPED)
    assert_equal 0, @user.inventory_items.find_by!(material: shell).quantity, "nothing is saved when an entry is bad"

    find("#quantity_#{core.id}").fill_in with: "40"
    click_button "Save changes"

    assert_text "Saved 2 materials."
    assert_equal [ 25_000, 40 ], [ @user.inventory_items.find_by!(material: shell).quantity, @user.inventory_items.find_by!(material: core).quantity ]
  end

  test "plans can be reordered, focus stays on a move button, and the optimizer follows the order" do
    sign_in_through_form
    shell = Material.find_by!(name: "Shell Credit")
    first, second = Weapon.limit(2).map do |weapon|
      Plan.create!(user: @user, subject: weapon, plan_data: { "input" => {}, "output" => { shell.id.to_s => 5000 } })
    end
    visit plans_path
    assert_selector ".plan-rank", text: "#1"
    assert_no_axe_violations(skip: SKIPPED)

    down = "button[aria-label='Move #{first.subject.name} down, priority 1 of 2']"
    # A click, not a key press: the test driver sends a key as separate key and character
    # events, and the trailing one lands on whichever button takes focus next. The buttons
    # are native <button>s, so keyboards work the same way.
    find(down).click

    assert_text "Moved #{first.subject.name} down."
    assert_selector "button[aria-label='Move #{first.subject.name} up, priority 2 of 2']:focus"
    assert_selector ".plan-card:first-of-type .plan-card-title", text: second.subject.name
    assert_selector "button[aria-label='Move #{first.subject.name} up, priority 2 of 2']:not([disabled])"
    assert_equal [ second, first ], @user.plans.by_priority.to_a

    visit optimizer_path
    click_link "> SELECT A PLAN"
    click_button "Use all plans (2)"
    click_button "> RUN OPTIMIZER"

    assert_selector ".optimizer-order-name", text: second.subject.name, wait: 10
    assert_equal [ second.subject.name, first.subject.name ], all(".optimizer-order-name").map(&:text)
    assert_no_axe_violations(skip: SKIPPED)
  end

  test "sharing a plan: create the link, copy it, a stranger sees it, then stop sharing" do
    sign_in_through_form
    shell = Material.find_by!(name: "Shell Credit")
    plan = Plan.create!(user: @user, subject: Weapon.find_by!(name: "Kumokiri"),
                        plan_data: { "input" => {}, "output" => { shell.id.to_s => 25480 } })
    visit plans_path

    click_link "Share", match: :first
    assert_selector "[role=dialog] h2", text: "Share Kumokiri"
    assert_no_axe_violations(skip: SKIPPED)
    click_button "Create link"

    assert_selector "input#share-url[readonly]"
    assert_no_axe_violations(skip: SKIPPED)
    path = URI(find("input#share-url").value).path
    assert_equal "/p/#{plan.reload.share_token}", path

    click_button "Copy link"
    assert_selector "[role=status]", text: /copied|Ctrl\+C/i

    using_session("stranger") do
      visit path
      assert_selector "h1", text: "Kumokiri"
      assert_text "Shell Credit"
      assert_text "25,480"
      assert_no_text @user.email
      assert_no_axe_violations(skip: SKIPPED)
    end

    # Back from the second session: reload, as the first one was in the background.
    visit plans_path
    assert_selector ".shared-badge", text: "Shared"
    click_link "Share", match: :first
    click_button "Stop sharing"
    assert_selector "button", text: "Create link"
    assert_not plan.reload.shared?

    using_session("stranger") do
      visit path
      assert_no_selector "h1", text: "Kumokiri"
    end
  end
end
