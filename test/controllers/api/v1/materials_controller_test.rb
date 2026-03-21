require "test_helper"

class Api::V1::MaterialsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "materials@example.com", password: "password123")
    @api_key = @user.api_keys.create!(name: "Test Key")
    @raw_token = @api_key.raw_token

    @cadence_seed = Material.find_by!(name: "Cadence Seed")
    @shell_credit = Material.find_by!(name: "Shell Credit")
  end

  test "returns 200 with valid token" do
    get api_v1_materials_path, headers: auth_headers
    assert_response :ok
  end

  test "returns 401 with no token" do
    get api_v1_materials_path, headers: {}
    assert_response :unauthorized
  end

  test "returns 401 with invalid token" do
    get api_v1_materials_path, headers: { "Authorization" => "Bearer #{SecureRandom.hex(16)}" }
    assert_response :unauthorized
  end

  test "returns 401 with bearer token missing value" do
    get api_v1_materials_path, headers: { "Authorization" => "Bearer " }
    assert_response :unauthorized
  end

  test "returns 401 when api key has been revoked" do
    @api_key.destroy
    get api_v1_materials_path, headers: auth_headers
    assert_response :unauthorized
  end

  test "returns json content type" do
    get api_v1_materials_path, headers: auth_headers
    assert_includes response.content_type, "application/json"
  end

  test "returns an array" do
    get api_v1_materials_path, headers: auth_headers
    assert JSON.parse(response.body).is_a?(Array)
  end

  test "each entry has the expected fields" do
    get api_v1_materials_path, headers: auth_headers

    entry = JSON.parse(response.body).first
    assert_includes entry.keys, "material_key"
    assert_includes entry.keys, "display_name"
    assert_includes entry.keys, "rarity"
    assert_includes entry.keys, "material_type"
    assert_includes entry.keys, "sources"
  end

  test "material_key is snake_case name" do
    get api_v1_materials_path, headers: auth_headers

    body = JSON.parse(response.body)
    cadence_seed = body.find { |m| m["display_name"] == "Cadence Seed" }
    assert_equal "cadence_seed", cadence_seed["material_key"]
  end

  test "returns correct rarity and material_type" do
    get api_v1_materials_path, headers: auth_headers

    body = JSON.parse(response.body)
    cadence_seed = body.find { |m| m["display_name"] == "Cadence Seed" }
    assert_equal @cadence_seed.rarity, cadence_seed["rarity"]
    assert_equal @cadence_seed.material_type, cadence_seed["material_type"]
  end

  test "sources is an empty array for materials with no source" do
    get api_v1_materials_path, headers: auth_headers

    body = JSON.parse(response.body)

    # flowers are overworld gatherables (so seed doesn't have source for this yet)
    iris = body.find { |m| m["display_name"] == "Iris" }
    assert_equal [], iris["sources"]
  end

  test "sources contain expected fields when present" do
    get api_v1_materials_path, headers: auth_headers

    body = JSON.parse(response.body)
    material_with_sources = body.find { |m| m["sources"].any? }
    source = material_with_sources["sources"].first

    assert_includes source.keys, "name"
    assert_includes source.keys, "source_type"
    assert_includes source.keys, "waveplate_cost"
    assert_includes source.keys, "location"
    assert_includes source.keys, "region"
  end

  private

  def auth_headers
    { "Authorization" => "Bearer #{@raw_token}" }
  end
end
