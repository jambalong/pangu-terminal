require "test_helper"

class IdentitiesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "ident@example.com", password: "password123")
    @identity = @user.identities.create!(provider: "discord", uid: "i-1")
    sign_in @user
  end

  test "unlinks when the user still has email and password" do
    assert_difference "Identity.count", -1 do
      delete identity_path(@identity)
    end
    assert_redirected_to edit_user_registration_path
  end

  test "unlinks when another provider remains" do
    oauth_user = User.new
    oauth_user.identities.build(provider: "discord", uid: "i-2")
    oauth_user.identities.build(provider: "google_oauth2", uid: "i-3")
    oauth_user.save!
    sign_in oauth_user

    assert_difference "Identity.count", -1 do
      delete identity_path(oauth_user.identities.first)
    end
  end

  test "refuses to unlink the last way in" do
    oauth_user = User.new
    identity = oauth_user.identities.build(provider: "discord", uid: "i-4")
    oauth_user.save!
    sign_in oauth_user

    assert_no_difference "Identity.count" do
      delete identity_path(identity)
    end
    assert_match(/another sign-in method/, flash[:alert])
  end

  test "returns 404 for another user's identity" do
    other = User.new
    other_identity = other.identities.build(provider: "google_oauth2", uid: "i-5")
    other.save!

    assert_no_difference "Identity.count" do
      delete identity_path(other_identity)
    end
    assert_response :not_found
  end

  test "requires sign-in" do
    sign_out @user
    delete identity_path(@identity)
    assert_redirected_to new_user_session_path
  end
end
