require "application_system_test_case"

class OauthSignInTest < ApplicationSystemTestCase
  include OauthTestHelper

  test "sign in with a provider creates an account and lands on the dashboard" do
    mock_oauth(:discord, uid: "sys-1")

    with_oauth_env(:discord, :google_oauth2, :github) do
      visit new_user_session_path
      assert_button "Continue with Google"
      assert_button "Continue with GitHub"
      assert_no_field "Password"
      assert_no_field "Email"

      click_button "Continue with Discord"
      assert_text "Dashboard"
      assert_text Identity.find_by!(uid: "sys-1").user.display_name
    end
  end

  test "sign in with GitHub creates an account" do
    mock_oauth(:github, uid: "sys-gh-1")

    with_oauth_env(:github) do
      visit new_user_session_path
      click_button "Continue with GitHub"
      assert_text "Dashboard"
      assert_equal "github", Identity.find_by!(uid: "sys-gh-1").provider
    end
  end

  test "without providers the page says sign-in is unavailable" do
    visit new_user_session_path
    assert_no_button "Continue with Discord"
    assert_no_field "Password"
    assert_text "no sign-in provider is configured"
  end
end
