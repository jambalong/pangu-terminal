require "test_helper"

class Api::V1::PlansControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "test@example.com", password: "password123")
    @api_key = @user.api_keys.create!(name: "Test Key")
  end

  test "returns 200 with valid token" do
    get api_v1_plans_path, headers: auth_headers
    assert_response :ok
  end

  test "returns 401 with no token" do
    get api_v1_plans_path, headers: {}
    assert_response :unauthorized
  end

  test "returns 401 with invalid token" do
    get api_v1_plans_path, headers: { "Authorization" => "Bearer <invalid_token>" }
    assert_response :unauthorized
  end

  test "returns [] with valid token but no plans" do
    get api_v1_plans_path, headers: auth_headers
    assert_equal [], JSON.parse(response.body)
  end

  test "returns json content type" do
    get api_v1_plans_path, headers: auth_headers
    assert_includes response.content_type, "application/json"
  end

  private

  def auth_headers
    { "Authorization" => "Bearer #{@api_key.token}" }
  end
end
