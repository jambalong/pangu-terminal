require "test_helper"

class Api::V1::ProfileControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "profile@example.com", password: "password123")
    @api_key = @user.api_keys.create!(name: "Test Key")
    @raw_token = @api_key.raw_token
  end

  test "returns 200 and updates sol3_phase with valid value" do
    patch api_v1_profile_path, params: { sol3_phase: 5 }, headers: auth_headers, as: :json

    assert_response :ok
    assert_equal 5, JSON.parse(response.body)["sol3_phase"]
  end

  test "returns 422 when sol3_phase is below range" do
    patch api_v1_profile_path, params: { sol3_phase: 0 }, headers: auth_headers, as: :json

    assert_response :unprocessable_entity
    assert_equal "sol3_phase must be an integer between 1 and 8", JSON.parse(response.body)["error"]
  end

  test "returns 422 when sol3_phase is above range" do
    patch api_v1_profile_path, params: { sol3_phase: 9 }, headers: auth_headers, as: :json

    assert_response :unprocessable_entity
    assert_equal "sol3_phase must be an integer between 1 and 8", JSON.parse(response.body)["error"]
  end

  test "returns 422 when sol3_phase is missing" do
    patch api_v1_profile_path, params: {}, headers: auth_headers, as: :json

    assert_response :unprocessable_entity
    assert_equal "sol3_phase must be an integer between 1 and 8", JSON.parse(response.body)["error"]
  end

  test "returns 401 when unauthenticated" do
    patch api_v1_profile_path, params: { sol3_phase: 5 }, as: :json

    assert_response :unauthorized
  end

  private

    def auth_headers
      { "Authorization" => "Bearer #{@raw_token}" }
    end
end
