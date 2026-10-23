require "application_system_test_case"

class OauthSignInTest < ApplicationSystemTestCase
  include OauthTestHelper

  test "sign in with a provider creates an account and lands on the dashboard" do
    mock_oauth(:discord, uid: "sys-1")

    with_oauth_env(:discord, :google_oauth2) do
      visit new_user_session_path
      assert_button "Continue with Google"
      assert_text "Sign in with email"
      assert_no_field "Password"

      click_button "Continue with Discord"
      assert_text "Dashboard"
      assert_text Identity.find_by!(uid: "sys-1").user.display_name
    end
  end

  test "without providers the email form is shown directly" do
    visit new_user_session_path
    assert_no_button "Continue with Discord"
    assert_field "Password"
  end
end
