require "test_helper"

class Users::SessionsAndSignupTest < ActionDispatch::IntegrationTest
  include OauthTestHelper

  test "sign-in page hides provider buttons when no env vars are set" do
    get new_user_session_path

    assert_response :success
    assert_select ".oauth-button", count: 0
    assert_select "input[name='user[email]']"
  end

  test "sign-in page shows only configured providers and demotes the email form" do
    with_oauth_env(:discord) do
      get new_user_session_path
    end

    assert_select ".oauth-button", count: 1
    assert_select "form[action=?]", "/users/auth/discord"
    assert_select "summary", text: "Sign in with email"
    assert_select "a", text: "Sign Up", count: 0
  end

  test "sign-up form is the fallback while no provider is configured" do
    get new_user_registration_path
    assert_response :success

    assert_difference "User.count", 1 do
      post user_registration_path, params: { user: { email: "fallback@example.com", password: "password123", password_confirmation: "password123" } }
    end
  end

  test "sign-up is closed once a provider is configured" do
    with_oauth_env(:google_oauth2) do
      get new_user_registration_path
      assert_redirected_to new_user_session_path

      assert_no_difference "User.count" do
        post user_registration_path, params: { user: { email: "x@example.com", password: "password123", password_confirmation: "password123" } }
      end
      assert_redirected_to new_user_session_path
    end
  end

  test "legacy email and password sign-in still works" do
    User.create!(email: "legacy@example.com", password: "password123")

    with_oauth_env(:discord, :google_oauth2) do
      post user_session_path, params: { user: { email: "legacy@example.com", password: "password123" } }
    end

    assert_redirected_to authenticated_root_path
  end

  test "navbar shows display_name for OAuth users" do
    user = User.new(display_name: "waveplayer")
    user.identities.build(provider: "discord", uid: "n-1")
    user.save!
    sign_in user

    get authenticated_root_path

    assert_select ".user-badge", text: "waveplayer"
  end

  test "navbar falls back to the email local part for legacy users" do
    sign_in User.create!(email: "legacyname@example.com", password: "password123")

    get authenticated_root_path

    assert_select ".user-badge", text: "legacyname"
  end

  test "request to an unconfigured provider is not served" do
    post "/users/auth/nope"
    assert_response :not_found
  end
end
