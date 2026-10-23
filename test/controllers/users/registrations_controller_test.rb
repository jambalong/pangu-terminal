require "test_helper"

class Users::RegistrationsControllerTest < ActionDispatch::IntegrationTest
  include OauthTestHelper

  setup do
    @user = User.create!(email: "registrations@example.com", password: "password123")
    sign_in @user
  end

  # after_update_path_for
  test "redirects to root after profile update when sol3_phase is present and password is blank" do
    patch update_user_registration_path, params: {
      user: {
        email: @user.email,
        sol3_phase: 4,
        password: "",
        password_confirmation: "",
        current_password: "password123"
      }
    }

    assert_redirected_to authenticated_root_path
  end

  test "redirects to edit after profile update when sol3_phase is absent" do
    patch update_user_registration_path, params: {
      user: {
        email: @user.email,
        password: "",
        password_confirmation: "",
        current_password: "password123"
      }
    }

    assert_redirected_to edit_user_registration_path
  end

  # update_resource
  test "updates user without current_password when password fields are blank" do
    new_email = "updated@example.com"

    patch update_user_registration_path, params: {
      user: {
        email: new_email,
        password: "",
        password_confirmation: "",
        current_password: "password123"
      }
    }

    assert_equal new_email, @user.reload.email
  end

  test "updates password when password fields are present" do
    patch update_user_registration_path, params: {
      user: {
        email: @user.email,
        password: "newpassword123",
        password_confirmation: "newpassword123",
        current_password: "password123"
      }
    }

    assert @user.reload.valid_password?("newpassword123")
  end

  # OAuth-only accounts
  test "OAuth user updates settings without a current password" do
    oauth_user = User.new(display_name: "player")
    oauth_user.identities.build(provider: "discord", uid: "r-1")
    oauth_user.save!
    sign_in oauth_user

    patch update_user_registration_path, params: {
      user: { email: "", password: "", password_confirmation: "" }
    }

    assert_redirected_to edit_user_registration_path
    assert_equal 0, oauth_user.reload.errors.count
  end

  test "OAuth user can add an email and password without a current password" do
    oauth_user = User.new
    oauth_user.identities.build(provider: "discord", uid: "r-2")
    oauth_user.save!
    sign_in oauth_user

    patch update_user_registration_path, params: {
      user: { email: "added@example.com", password: "password123", password_confirmation: "password123" }
    }

    assert_equal "added@example.com", oauth_user.reload.email
    assert oauth_user.valid_password?("password123")
  end

  test "OAuth user can set SOL3 phase" do
    oauth_user = User.new
    oauth_user.identities.build(provider: "discord", uid: "r-3")
    oauth_user.save!
    sign_in oauth_user

    patch update_user_registration_path, params: { user: { sol3_phase: 5 } }

    assert_equal 5, oauth_user.reload.sol3_phase
  end

  test "OAuth user can delete their account without a password" do
    oauth_user = User.new
    oauth_user.identities.build(provider: "discord", uid: "r-4")
    oauth_user.save!
    sign_in oauth_user

    assert_difference [ "User.count", "Identity.count" ], -1 do
      delete user_registration_path
    end
  end

  test "password users still must confirm their current password" do
    patch update_user_registration_path, params: {
      user: { email: "other@example.com", password: "", password_confirmation: "", current_password: "wrong" }
    }

    assert_equal "registrations@example.com", @user.reload.email
  end

  test "settings page hides the current password field for OAuth users" do
    oauth_user = User.new
    oauth_user.identities.build(provider: "discord", uid: "r-5")
    oauth_user.save!
    sign_in oauth_user

    get edit_user_registration_path

    assert_response :success
    assert_select "#user_current_password", count: 0
  end

  test "settings page shows linked providers and link buttons for configured ones" do
    @user.identities.create!(provider: "discord", uid: "r-6")

    with_oauth_env(:google_oauth2) do
      get edit_user_registration_path
    end

    assert_select "form[action=?]", identity_path(@user.identities.first)
    assert_select "form[action=?]", "/users/auth/google_oauth2"
    assert_select "form[action=?]", "/users/auth/discord", count: 0
  end

  test "username can be changed without a password and is lowercased" do
    patch update_user_registration_path, params: { user: { display_name: "New-Tag" } }

    assert_redirected_to edit_user_registration_path
    assert_equal "new-tag", @user.reload.display_name
  end

  test "username works for OAuth users without a password" do
    oauth_user = User.new(display_name: "rover-1111")
    oauth_user.identities.build(provider: "discord", uid: "r-7")
    oauth_user.save!
    sign_in oauth_user

    patch update_user_registration_path, params: { user: { display_name: "starfall" } }

    assert_equal "starfall", oauth_user.reload.display_name
  end

  test "an invalid username is rejected and not saved" do
    @user.update!(display_name: "keepme")

    patch update_user_registration_path, params: { user: { display_name: "this name is far too long" } }

    assert_equal "keepme", @user.reload.display_name
    assert_response :unprocessable_content
  end

  test "settings page has a username field" do
    get edit_user_registration_path
    assert_select "input[name='user[display_name]'][maxlength='16']"
  end
end
