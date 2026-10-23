require "application_system_test_case"

# Loads real pages in Chrome and fails on any content security policy violation
# (blocked script, style, font, image or request).
class ContentSecurityPolicyTest < ApplicationSystemTestCase
  setup do
    @user = User.create!(email: "csp@example.com", password: "password123", sol3_phase: 3)
    @user.send(:initialize_inventory)
    page.driver.browser.evaluate_on_new_document(<<~JS)
      window.__cspViolations = [];
      document.addEventListener("securitypolicyviolation", (event) => {
        window.__cspViolations.push(event.violatedDirective + " blocked " + event.blockedURI);
      });
    JS
  end

  def assert_no_csp_violations
    sleep 0.3 # let late-loading fonts and images report
    assert_equal [], page.evaluate_script("window.__cspViolations"), "CSP violations on #{current_path}"
  end

  test "public pages load without violations" do
    [ root_path, user_manual_path, privacy_path, new_user_session_path ].each do |path|
      visit path
      assert_selector "body"
      assert_no_csp_violations
    end
  end

  test "signed-in pages and the plan modal load without violations" do
    visit new_user_session_path
    fill_in "Email", with: "csp@example.com"
    fill_in "Password", with: "password123"
    click_button "Sign In"
    assert_text "Dashboard"
    assert_no_csp_violations

    [ plans_path, inventory_items_path, optimizer_path, edit_user_registration_path ].each do |path|
      visit path
      assert_selector "body"
      assert_no_csp_violations
    end

    visit plans_path
    click_link "✚ New Plan"
    assert_text "Select Plan Type"
    assert_no_csp_violations
  end
end
