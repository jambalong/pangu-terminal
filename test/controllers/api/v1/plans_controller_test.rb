require "test_helper"

class Api::V1::PlansControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "test@example.com", password: "password123")
    @other_user = User.create!(email: "other@example.com", password: "password123")

    @api_key = @user.api_keys.create!(name: "Test Key")
    @raw_token = @api_key.raw_token

    @shell_credit = Material.create!(
      name: "Shell Credit",
      rarity: 3,
      material_type: "Credit",
      category: "Universal Currency"
    )

    @basic_exp_potion = Material.create!(
      name: "Basic Resonance Potion",
      rarity: 2,
      material_type: "ResonatorEXP",
      category: "Resonator EXP Material",
      exp_value: 1000
    )

    @lf_howler_core = Material.create!(
      name: "LF Howler Core",
      rarity: 2,
      material_type: "EnemyDrop",
      category: "Weapon and Skill Material"
    )

    @weapon = Weapon.create!(
      name: "Kumokiri",
      weapon_type: "Weapon",
      rarity: 5
    )

    @plan = Plan.create!(
      user: @user,
      subject: @weapon,
      subject_type: "Weapon",
      plan_data: {
        "input" => {
          "current_level" => 1,
          "target_level" => 20,
          "current_ascension_rank" => 0,
          "target_ascension_rank" => 1
        },
        "output" => {
          @shell_credit.id => 25480,
          @basic_exp_potion.id => 38,
          @lf_howler_core.id => 6
        }
      }
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
    empty_user = User.create!(email: "empty@example.com", password: "password123")
    empty_key = empty_user.api_keys.create!(name: "Empty Key")

    get api_v1_plans_path, headers: { "Authorization" => "Bearer #{empty_key.raw_token}" }

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

    assert_equal 1,  plan_json["configuration"]["current_level"]
    assert_equal 20, plan_json["configuration"]["target_level"]
    assert_equal 0,  plan_json["configuration"]["current_ascension_rank"]
    assert_equal 1,  plan_json["configuration"]["target_ascension_rank"]

    assert_equal 25480, plan_json["requirements"]["shell_credit"]
    assert_equal 38,    plan_json["requirements"]["basic_resonance_potion"]
    assert_equal 6,     plan_json["requirements"]["lf_howler_core"]
  end

  private

  def auth_headers
    { "Authorization" => "Bearer #{@raw_token}" }
  end
end
