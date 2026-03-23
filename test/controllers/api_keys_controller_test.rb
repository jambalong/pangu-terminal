require "test_helper"

class ApiKeysControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "api_keys@example.com", password: "password123")
  end

  test "unauthenticated user is redirected to sign in" do
    post api_keys_path, params: { name: "My Key" }
    assert_redirected_to new_user_session_path
  end

  test "creates api key and redirects" do
    sign_in @user

    assert_difference "ApiKey.count", 1 do
      post api_keys_path, params: { name: "My Key" }
    end

    assert_redirected_to "#{edit_user_registration_path}#api-keys"
  end

  test "sets flash with generated token on create" do
    sign_in @user
    post api_keys_path, params: { name: "My Key" }

    assert flash[:api_token].present?
    assert_equal 'API Key "My Key" generated successfully.', flash[:notice]
  end

  test "does not create api key without name" do
    sign_in @user

    assert_no_difference "ApiKey.count" do
      post api_keys_path, params: { name: "" }
    end

    assert flash[:alert].present?
  end

  test "destroys api key and redirects" do
    sign_in @user
    api_key = @user.api_keys.create!(name: "My Key")

    assert_difference "ApiKey.count", -1 do
      delete api_key_path(api_key)
    end

    assert_redirected_to "#{edit_user_registration_path}#api-keys"
  end

  test "sets flash notice on destroy" do
    sign_in @user
    api_key = @user.api_keys.create!(name: "My Key")

    delete api_key_path(api_key)

    assert_equal 'API Key "My Key" revoked successfully.', flash[:notice]
  end

  test "cannot destroy another user's api key" do
    other_user = User.create!(email: "api_keys_other@example.com", password: "password123")
    other_key = other_user.api_keys.create!(name: "Other Key")

    sign_in @user

    assert_no_difference "ApiKey.count" do
      delete api_key_path(other_key)
    end

    assert_response :not_found
  end
end
