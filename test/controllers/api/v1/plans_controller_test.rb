require "test_helper"

class Api::V1::PlansControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "plans@example.com", password: "password123")
    @other_user = User.create!(email: "plans_other@example.com", password: "password123")

    @api_key = @user.api_keys.create!(name: "Test Key")
    @raw_token = @api_key.raw_token

    @shell_credit = Material.find_by!(name: "Shell Credit")
    @basic_energy_core = Material.find_by!(name: "Basic Energy Core")
    @lf_whisperin_core = Material.find_by!(name: "LF Whisperin Core")
    @mf_whisperin_core = Material.find_by!(name: "MF Whisperin Core")
    @weapon = Weapon.find_by!(name: "Kumokiri")

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
          @basic_energy_core.id => 38,
          @lf_whisperin_core.id => 6
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
    assert_equal 38,    plan_json["requirements"]["basic_energy_core"]
    assert_equal 6,     plan_json["requirements"]["lf_whisperin_core"]
  end

  private

  def auth_headers
    { "Authorization" => "Bearer #{@raw_token}" }
  end
end

class Api::V1::PlansControllerCreateTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "create@example.com", password: "password123")
    @api_key = @user.api_keys.create!(name: "Test Key")
    @raw_token = @api_key.raw_token

    @weapon = Weapon.find_by!(name: "Kumokiri")
    @resonator = Resonator.find_by!(name: "Chisa")
  end

  test "creates a plan with valid weapon params and returns 201" do
    post api_v1_plans_path, params: weapon_params, headers: auth_headers, as: :json
    assert_response :created
  end

  test "creates a plan with valid resonator params and returns 201" do
    post api_v1_plans_path, params: resonator_params, headers: auth_headers, as: :json
    assert_response :created
  end

  test "returns serialized plan with correct shape" do
    post api_v1_plans_path, params: weapon_params, headers: auth_headers, as: :json
    assert_response :created

    plan_json = JSON.parse(response.body)

    assert plan_json.key?("id")
    assert_equal "Kumokiri", plan_json["subject_name"]
    assert_equal "Weapon", plan_json["subject_type"]
    assert plan_json.key?("configuration")
    assert plan_json.key?("requirements")
  end

  test "returns 401 without auth token" do
    post api_v1_plans_path,
      params: weapon_params,
      headers: { "Content-Type" => "application/json" },
      as: :json

    assert_response :unauthorized
  end

  test "returns 404 when subject not found" do
    post api_v1_plans_path,
      params: weapon_params.merge(subject_id: 0),
      headers: auth_headers,
      as: :json

    assert_response :not_found
    body = JSON.parse(response.body)
    assert_equal "Subject not found", body["error"]
  end

  test "returns 422 on planner validation error for invalid params combo" do
    post api_v1_plans_path,
      params: weapon_params.merge(current_level: 90, target_level: 1),
      headers: auth_headers,
      as: :json

    assert_response :unprocessable_entity
    body = JSON.parse(response.body)
    assert body["errors"].is_a?(Array)
    assert body["errors"].any?
  end

  test "returns 422 on duplicate plan" do
    post api_v1_plans_path, params: weapon_params, headers: auth_headers, as: :json
    assert_response :created

    post api_v1_plans_path, params: weapon_params, headers: auth_headers, as: :json
    assert_response :unprocessable_entity

    body = JSON.parse(response.body)
    assert body["errors"].is_a?(Array)
    assert body["errors"].any?
  end

  private

  def auth_headers
    { "Authorization" => "Bearer #{@raw_token}" }
  end

  def weapon_params
    {
      subject_type: "Weapon",
      subject_id: @weapon.id,
      current_level: 1,
      target_level: 20,
      current_ascension_rank: 0,
      target_ascension_rank: 1
    }
  end

  def resonator_params
    {
      subject_type: "Resonator",
      subject_id: @resonator.id,
      current_level: 1,
      target_level: 20,
      current_ascension_rank: 0,
      target_ascension_rank: 1,
      basic_attack_current: 1, basic_attack_target: 2,
      resonance_skill_current: 1, resonance_skill_target: 2,
      forte_circuit_current: 1, forte_circuit_target: 2,
      resonance_liberation_current: 1, resonance_liberation_target: 2,
      intro_skill_current: 1, intro_skill_target: 2,
      basic_attack_node_1: 0, basic_attack_node_2: 0,
      resonance_skill_node_1: 0, resonance_skill_node_2: 0,
      forte_circuit_node_1: 0, forte_circuit_node_2: 0,
      resonance_liberation_node_1: 0, resonance_liberation_node_2: 0,
      intro_skill_node_1: 0, intro_skill_node_2: 0
    }
  end
end

class Api::V1::PlansControllerReconciliationTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "reconciliation@example.com", password: "password123")
    @other_user = User.create!(email: "reconciliation_other@example.com", password: "password123")

    @api_key = @user.api_keys.create!(name: "Test Key")
    @raw_token = @api_key.raw_token

    @shell_credit     = Material.find_by!(name: "Shell Credit")
    @basic_energy_core = Material.find_by!(name: "Basic Energy Core")
    @lf_whisperin_core = Material.find_by!(name: "LF Whisperin Core")
    @mf_whisperin_core = Material.find_by!(name: "MF Whisperin Core")
    @waveworn_residue_210 = Material.find_by!(name: "Waveworn Residue 210")
    @weapon = Weapon.find_by!(name: "Kumokiri")

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
          @shell_credit.id     => 25480,
          @basic_energy_core.id => 38,
          @lf_whisperin_core.id   => 6
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

  test "returns 401 with no token" do
    get reconciliation_api_v1_plan_path(@plan), headers: {}
    assert_response :unauthorized
  end

  test "returns 401 with invalid token" do
    get reconciliation_api_v1_plan_path(@plan),
      headers: { "Authorization" => "Bearer #{SecureRandom.hex(16)}" }

    assert_response :unauthorized
  end

  test "returns 404 for a plan belonging to another user" do
    get reconciliation_api_v1_plan_path(@other_plan), headers: auth_headers
    assert_response :not_found
  end

  test "returns 404 for a non-existent plan id" do
    get reconciliation_api_v1_plan_path(id: 0), headers: auth_headers
    assert_response :not_found
  end

  test "returns 200 for own plan" do
    get reconciliation_api_v1_plan_path(@plan), headers: auth_headers
    assert_response :ok
  end

  test "returns json content type" do
    get reconciliation_api_v1_plan_path(@plan), headers: auth_headers
    assert_includes response.content_type, "application/json"
  end

  test "response keys are material snake_case names" do
    get reconciliation_api_v1_plan_path(@plan), headers: auth_headers

    body = JSON.parse(response.body)
    assert_includes body.keys, "shell_credit"
    assert_includes body.keys, "basic_energy_core"
    assert_includes body.keys, "lf_whisperin_core"
  end

  test "each entry has the expected fields" do
    get reconciliation_api_v1_plan_path(@plan), headers: auth_headers

    entry = JSON.parse(response.body)["shell_credit"]
    assert_includes entry.keys, "needed"
    assert_includes entry.keys, "owned"
    assert_includes entry.keys, "deficit"
    assert_includes entry.keys, "satisfied"
    assert_includes entry.keys, "satisfied_by_higher_rarity"
    assert_includes entry.keys, "can_synthesize"
  end

  test "does not expose internal fields" do
    get reconciliation_api_v1_plan_path(@plan), headers: auth_headers

    entry = JSON.parse(response.body)["shell_credit"]

    assert_not_includes entry.keys, "satisfied_qty"
    assert_not_includes entry.keys, "used_higher_rarity"
  end

  test "needed reflects plan output quantities" do
    get reconciliation_api_v1_plan_path(@plan), headers: auth_headers

    body = JSON.parse(response.body)

    assert_equal 25480, body["shell_credit"]["needed"]
    assert_equal 38, body["basic_energy_core"]["needed"]
    assert_equal 6, body["lf_whisperin_core"]["needed"]
  end

  test "owned reflects user inventory" do
    set_quantity(@shell_credit, 1000)
    get reconciliation_api_v1_plan_path(@plan), headers: auth_headers

    assert_equal 1000, JSON.parse(response.body)["shell_credit"]["owned"]
  end

  test "owned is 0 when user has no quantity for material" do
    get reconciliation_api_v1_plan_path(@plan), headers: auth_headers
    assert_equal 0, JSON.parse(response.body)["shell_credit"]["owned"]
  end

  test "satisfied is true when inventory fully covers requirement" do
    set_quantity(@lf_whisperin_core, 10)
    get reconciliation_api_v1_plan_path(@plan), headers: auth_headers

    assert_equal true, JSON.parse(response.body)["lf_whisperin_core"]["satisfied"]
  end

  test "satisfied is false when inventory does not cover requirement" do
    get reconciliation_api_v1_plan_path(@plan), headers: auth_headers
    assert_equal false, JSON.parse(response.body)["lf_whisperin_core"]["satisfied"]
  end

  test "deficit is 0 when fully satisfied" do
    set_quantity(@lf_whisperin_core, 10)
    get reconciliation_api_v1_plan_path(@plan), headers: auth_headers

    assert_equal 0, JSON.parse(response.body)["lf_whisperin_core"]["deficit"]
  end

  test "deficit equals shortfall when not satisfied" do
    set_quantity(@lf_whisperin_core, 2)
    get reconciliation_api_v1_plan_path(@plan), headers: auth_headers

    assert_equal 4, JSON.parse(response.body)["lf_whisperin_core"]["deficit"]
  end

  test "can_synthesize is 0 when no synthesis opportunity exists" do
    get reconciliation_api_v1_plan_path(@plan), headers: auth_headers

    # Shell Credit is a currency therefore not synthesizable from anything
    assert_equal 0, JSON.parse(response.body)["shell_credit"]["can_synthesize"]
  end

  test "can_synthesize reflects surplus of lower tier material" do
    weapon_other = Weapon.find_by!(name: "Ages of Harvest")
    synthesis_plan = Plan.create!(
      user: @user,
      subject: weapon_other,
      subject_type: "Weapon",
      plan_data: {
        "input" => {},
        "output" => {
          @lf_whisperin_core.id => 3,
          @mf_whisperin_core.id  => 1
        }
      }
    )

    # 6 owned, 3 needed -> surplus of 3 -> can convert 1 MF Whisperin Core
    set_quantity(@lf_whisperin_core, 6)
    get reconciliation_api_v1_plan_path(synthesis_plan), headers: auth_headers

    assert_equal 1, JSON.parse(response.body)["mf_whisperin_core"]["can_synthesize"]
  end

  test "satisfied_by_higher_rarity is true when higher rarity exp item covers the requirement" do
    medium_energy_core = Material.find_by!(name: "Medium Energy Core")

    # 13 Medium Energy Core covers 38 Basic Energy Core requirement via EXP equivalence
    set_quantity(medium_energy_core, 13)
    get reconciliation_api_v1_plan_path(@plan), headers: auth_headers

    entry = JSON.parse(response.body)["basic_energy_core"]
    assert_equal 0, entry["owned"]
    assert_equal true, entry["satisfied"]
    assert_equal true, entry["satisfied_by_higher_rarity"]
  end

  private

  def auth_headers
    { "Authorization" => "Bearer #{@raw_token}" }
  end

  def set_quantity(material, quantity)
    @user.inventory_items.find_by!(material: material).update!(quantity: quantity)
  end
end
