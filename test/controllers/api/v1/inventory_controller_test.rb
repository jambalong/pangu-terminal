require "test_helper"

class Api::V1::InventoryControllerTest < ActionDispatch::IntegrationTest
  setup do
    @cadence_seed = Material.find_by!(name: "Cadence Seed")
    @cadence_bud = Material.find_by!(name: "Cadence Bud")

    @user = User.create!(email: "test@example.com", password: "password123")
    @other_user = User.create!(email: "other@example.com", password: "password123")

    @api_key = @user.api_keys.create!(name: "Test Key")
    @raw_token = @api_key.raw_token

    @user.inventory_items.find_by(material: @cadence_seed).update!(quantity: 47)
  end

  test "returns 200 with valid token" do
    get api_v1_inventory_index_path, headers: auth_headers
    assert_response :ok
  end

  test "returns 401 with no token" do
    get api_v1_inventory_index_path, headers: {}
    assert_response :unauthorized
  end

  test "returns 401 with invalid token" do
    get api_v1_inventory_index_path, headers: { "Authorization" => "Bearer #{SecureRandom.hex(16)}" }
    assert_response :unauthorized
  end

  test "returns 401 with bearer token missing value" do
    get api_v1_inventory_index_path, headers: { "Authorization" => "Bearer " }
    assert_response :unauthorized
  end

  test "returns 401 when api key has been revoked" do
    @api_key.destroy
    get api_v1_inventory_index_path, headers: auth_headers
    assert_response :unauthorized
  end

  test "returns json content type" do
    get api_v1_inventory_index_path, headers: auth_headers
    assert_includes response.content_type, "application/json"
  end

  test "returns zero quantity for materials qty not yet updated" do
    get api_v1_inventory_index_path, headers: auth_headers

    body = JSON.parse(response.body)
    assert_equal 0, body["cadence_bud"]
  end

  test "returns only inventory belonging to authenticated user" do
    @other_user.inventory_items.find_by(material: @cadence_seed).update!(quantity: 999)

    get api_v1_inventory_index_path, headers: auth_headers

    body = JSON.parse(response.body)
    assert_equal 47, body["cadence_seed"]
    assert_not_equal 999, body["cadence_seed"]
  end

  test "returns correct quantity for inventory item" do
    get api_v1_inventory_index_path, headers: auth_headers

    body = JSON.parse(response.body)

    assert_equal 47, body["cadence_seed"]
  end

  test "returns snake_case material names as keys" do
    get api_v1_inventory_index_path, headers: auth_headers

    body = JSON.parse(response.body)
    body.keys.each do |key|
      assert_match(/\A[a-z0-9_]+\z/, key)
    end
  end

  private

  def auth_headers
    { "Authorization" => "Bearer #{@raw_token}" }
  end
end
