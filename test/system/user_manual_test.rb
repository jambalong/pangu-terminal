require "application_system_test_case"

class UserManualTest < ApplicationSystemTestCase
  test "the sidebar highlights the section being read, including the last one at the bottom" do
    visit user_manual_path

    assert_selector ".manual-nav a.active", text: "Introduction", count: 1

    page.execute_script("window.scrollTo(0, document.documentElement.scrollHeight)")

    assert_selector ".manual-nav a.active", text: "FAQ / Troubleshooting", count: 1
    assert_selector ".manual-nav a.active", count: 1
  end
end
