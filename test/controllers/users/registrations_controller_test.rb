require "test_helper"

class Users::RegistrationsControllerTest < ActionDispatch::IntegrationTest
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
end
