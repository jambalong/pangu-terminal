require "test_helper"

class InventoryExportsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "export@example.com", password: "password123")
    @shell = Material.find_by!(name: "Shell Credit")
    @user.inventory_item_for(@shell).update!(quantity: 321)
  end

  test "requires sign-in (a download gets a 401, not a redirect to a page)" do
    get inventory_export_path(format: :csv)
    assert_response :unauthorized

    get inventory_export_path(format: :json)
    assert_response :unauthorized
  end

  test "downloads a CSV with every material" do
    sign_in @user
    get inventory_export_path(format: :csv)

    assert_response :ok
    assert_match %r{text/csv}, response.media_type + response.headers["Content-Type"].to_s
    assert_match(/attachment; filename="pangu-inventory-\d{4}-\d{2}-\d{2}\.csv"/, response.headers["Content-Disposition"])
    lines = response.body.split("\r\n")
    assert_equal "key,name,quantity", lines.first
    assert_equal Material.count + 1, lines.size
    assert_includes lines, "shell_credit,Shell Credit,321"
  end

  test "downloads the same flat map the API returns as JSON" do
    sign_in @user
    get inventory_export_path(format: :json)

    assert_response :ok
    data = JSON.parse(response.body)
    assert_equal 321, data["shell_credit"]
    assert_equal Material.count, data.size
    assert_match(/\.json"/, response.headers["Content-Disposition"])
  end

  test "exports only the signed-in user's quantities" do
    other = User.create!(email: "export_other@example.com", password: "password123")
    other.inventory_item_for(@shell).update!(quantity: 999)
    sign_in other
    get inventory_export_path(format: :json)

    assert_equal 999, JSON.parse(response.body)["shell_credit"]
  end

  test "other formats are not served" do
    sign_in @user
    get inventory_export_path(format: :xml)

    assert_response :not_acceptable
  end
end
