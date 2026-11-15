require "test_helper"

class Users::SessionsAndSignupTest < ActionDispatch::IntegrationTest
  include OauthTestHelper

  test "sign-in page says so when no provider is configured" do
    get new_user_session_path

    assert_response :success
    assert_select ".oauth-button", count: 0
    assert_select ".status-msg", text: /no sign-in provider is configured/
  end

  test "sign-in page shows only configured providers and no email or password form" do
    with_oauth_env(:discord, :github) do
      get new_user_session_path
    end

    assert_select ".oauth-button", count: 2
    assert_select "form[action=?]", "/users/auth/discord"
    assert_select "form[action=?]", "/users/auth/github"
    assert_select "form[action=?]", "/users/auth/google_oauth2", count: 0
    assert_select "input[type=password]", count: 0
    assert_select "input[name='user[email]']", count: 0
  end

  test "there is no password sign-in, sign-up or password reset" do
    User.create!(email: "legacy@example.com", password: "password123")

    post "/sign-in", params: { user: { email: "legacy@example.com", password: "password123" } }
    assert_response :not_found

    get "/signup"
    assert_response :not_found

    post "/signup", params: { user: { email: "x@example.com", password: "password123", password_confirmation: "password123" } }
    assert_response :not_found

    get "/users/password/new"
    assert_response :not_found

    assert_no_difference "User.count" do
      post "/users", params: { user: { email: "y@example.com", password: "password123", password_confirmation: "password123" } }
    end
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
