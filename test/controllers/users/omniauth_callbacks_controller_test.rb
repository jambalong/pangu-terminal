require "test_helper"

class Users::OmniauthCallbacksControllerTest < ActionDispatch::IntegrationTest
  include OauthTestHelper

  test "creates a user and identity on first sign-in and signs them in" do
    mock_oauth(:discord, uid: "d-1", name: "WavePlayer")

    assert_difference [ "User.count", "Identity.count" ], 1 do
      sign_in_via_oauth(:discord)
    end

    assert_redirected_to authenticated_root_path
    user = Identity.find_by!(provider: "discord", uid: "d-1").user
    assert_equal "WavePlayer", user.display_name
    assert_nil user.email
    assert_predicate user.encrypted_password, :blank?
    follow_redirect!
    assert_response :success
  end

  test "creates users from google as well" do
    mock_oauth(:google_oauth2, uid: "g-1", name: "Google Person")

    assert_difference "User.count", 1 do
      sign_in_via_oauth(:google_oauth2)
    end

    assert_equal "Google Person", Identity.find_by!(provider: "google_oauth2", uid: "g-1").user.display_name
  end

  test "returning user signs in to the same account" do
    user = User.new(display_name: "Back Again")
    user.identities.build(provider: "discord", uid: "d-2")
    user.save!
    mock_oauth(:discord, uid: "d-2", name: "Renamed")

    assert_no_difference [ "User.count", "Identity.count" ] do
      sign_in_via_oauth(:discord)
    end

    assert_redirected_to authenticated_root_path
    assert_equal "Back Again", user.reload.display_name
  end

  test "claims guest plans for a new user" do
    guest_token = SecureRandom.uuid
    plan = Plan.create!(
      guest_token: guest_token,
      subject: Resonator.find_by!(name: "Aalto"),
      plan_data: { "input" => {}, "output" => {} }
    )
    cookies[:guest_token] = guest_token
    mock_oauth(:discord, uid: "d-3")

    sign_in_via_oauth(:discord)

    plan.reload
    assert_equal Identity.find_by!(provider: "discord", uid: "d-3").user_id, plan.user_id
    assert_nil plan.guest_token
  end

  test "failure redirects to sign-in with a flash" do
    OmniAuth.config.mock_auth[:discord] = :invalid_credentials

    assert_no_difference "User.count" do
      sign_in_via_oauth(:discord)
    end

    assert_redirected_to new_user_session_path
    assert_match(/did not complete/, flash[:alert])
  end

  test "does not link to an existing account with a matching email" do
    existing = User.create!(email: "same@example.com", password: "password123")
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2", uid: "g-9", info: { name: "Imposter", email: "same@example.com" }
    )

    assert_difference "User.count", 1 do
      sign_in_via_oauth(:google_oauth2)
    end

    assert_empty existing.identities
    assert_not_equal existing.id, Identity.find_by!(provider: "google_oauth2", uid: "g-9").user_id
  end

  test "links a provider to the signed-in user" do
    user = User.create!(email: "link@example.com", password: "password123")
    sign_in user
    mock_oauth(:discord, uid: "d-4")

    assert_difference "user.identities.count", 1 do
      sign_in_via_oauth(:discord)
    end

    assert_redirected_to edit_user_registration_path
  end

  test "refuses to link an identity that belongs to another account" do
    other = User.new(display_name: "Other")
    other.identities.build(provider: "discord", uid: "d-5")
    other.save!
    user = User.create!(email: "link2@example.com", password: "password123")
    sign_in user
    mock_oauth(:discord, uid: "d-5")

    assert_no_difference "Identity.count" do
      sign_in_via_oauth(:discord)
    end

    assert_redirected_to edit_user_registration_path
    assert_match(/already linked to another/, flash[:alert])
    assert_equal other.id, Identity.find_by!(provider: "discord", uid: "d-5").user_id
  end

  test "failure while signed in returns to settings" do
    sign_in User.create!(email: "fail@example.com", password: "password123")
    OmniAuth.config.mock_auth[:discord] = :access_denied

    sign_in_via_oauth(:discord)

    assert_redirected_to edit_user_registration_path
  end
end
