require "test_helper"

class Api::V1::PlansControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "test@example.com", password: "password123")
    @other_user = User.create!(email: "other@example.com", password: "password123")

    @api_key = @user.api_keys.create!(name: "Test Key")
    @other_api_key = @other_user.api_keys.create!(name: "Other Key")

    @weapon = Weapon.create!(
      name: "Kumokiri",
      weapon_type: "Weapon",
      rarity: 5
    )

    @plan = Plan.create!(
      user: @user,
      subject: @weapon,
      subject_type: "Weapon",
      plan_data: { "input" => {}, "output" => {} }
    )

    @other_plan = Plan.create!(
      user: @other_user,
      subject: @weapon,
      subject_type: "Weapon",
      plan_data: { "input" => {}, "output" => {} }
    )
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
    get api_v1_plans_path, headers: { "Authorization" => "Bearer #{SecureRandom.hex(16)}" }
    assert_response :unauthorized
  end

  test "returns 401 with bearer token missing value" do
    get api_v1_plans_path, headers: { "Authorization" => "Bearer " }
    assert_response :unauthorized
  end

  test "returns 401 when api key has been revoked" do
    @api_key.destroy
    get api_v1_plans_path, headers: auth_headers
    assert_response :unauthorized
  end

  test "returns json content type" do
    get api_v1_plans_path, headers: auth_headers
    assert_includes response.content_type, "application/json"
  end

  test "returns empty array when user has no plans" do
    @plan.destroy

    get api_v1_plans_path, headers: auth_headers

    assert_response :ok
    assert_equal [], JSON.parse(response.body)
  end

  test "returns only plans belonging to authenticated user" do
    get api_v1_plans_path, headers: auth_headers

    body = JSON.parse(response.body)
    returned_ids = body.map { |p| p["id"] }

    assert_equal 1, body.length
    assert_includes returned_ids, @plan.id
    assert_not_includes returned_ids, @other_plan.id
  end

  test "returns serialized plan attributes" do
    get api_v1_plans_path, headers: auth_headers

    plan_json = JSON.parse(response.body).first

    assert_equal @plan.id, plan_json["id"]
    assert_equal "Kumokiri", plan_json["subject_name"]
    assert_equal "Weapon", plan_json["subject_type"]
  end

  private

  def auth_headers
    { "Authorization" => "Bearer #{@api_key.token}" }
  end
end
