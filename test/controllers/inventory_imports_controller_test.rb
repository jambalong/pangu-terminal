require "test_helper"

class InventoryImportsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "import@example.com", password: "password123")
    @shell = Material.find_by!(name: "Shell Credit")
    sign_in @user
  end

  def upload(content, name: "inventory.csv", type: "text/csv")
    Rack::Test::UploadedFile.new(StringIO.new(content), type, original_filename: name)
  end

  def shell_quantity = @user.inventory_items.find_by(material: @shell)&.quantity

  test "requires sign-in" do
    sign_out @user
    get new_inventory_import_path
    assert_redirected_to new_user_session_path

    post inventory_import_path, params: { data: "key,quantity\nshell_credit,1" }
    assert_redirected_to new_user_session_path
  end

  test "shows the form with labelled fields" do
    get new_inventory_import_path

    assert_response :ok
    assert_select "h1", text: "Import inventory"
    assert_select "label[for=file]"
    assert_select "label[for=data]"
    assert_select "form[enctype='multipart/form-data']"
  end

  test "imports an uploaded CSV and reports the result" do
    post inventory_import_path, params: { file: upload("key,quantity\nshell_credit,500\nbogus,2\n") }

    assert_response :ok
    assert_equal 500, shell_quantity
    assert_select "#import-result-title", text: "Import finished"
    assert_select ".import-skipped li", text: /unknown material/
    assert_select "[role=status]"
  end

  test "imports pasted JSON" do
    post inventory_import_path, params: { data: '{"shell_credit": 77}' }

    assert_response :ok
    assert_equal 77, shell_quantity
  end

  test "an upload wins over pasted text" do
    post inventory_import_path, params: { file: upload("key,quantity\nshell_credit,1\n"), data: "key,quantity\nshell_credit,2\n" }

    assert_equal 1, shell_quantity
  end

  test "an unreadable file is an error and changes nothing" do
    @user.inventory_item_for(@shell).update!(quantity: 5)

    post inventory_import_path, params: { data: "{not json" }

    assert_response :unprocessable_content
    assert_select "[role=alert]", text: /Nothing was imported/
    assert_equal 5, shell_quantity
  end

  test "nothing chosen is an error" do
    post inventory_import_path, params: {}

    assert_response :unprocessable_content
    assert_select "[role=alert]", text: /Choose a file or paste/
  end

  test "files over 1 MB are refused" do
    post inventory_import_path, params: { file: upload("a" * (1.megabyte + 1)) }

    assert_response :unprocessable_content
    assert_select "[role=alert]", text: /too large/
  end

  test "pasted text over 1 MB is refused" do
    post inventory_import_path, params: { data: "a" * (1.megabyte + 1) }

    assert_response :unprocessable_content
  end

  test "a file field that is not a file is treated as missing, not a crash" do
    post inventory_import_path, params: { file: "oops", data: "" }

    assert_response :unprocessable_content
  end

  test "only the signed-in user's inventory changes" do
    other = User.create!(email: "import_other@example.com", password: "password123")
    other.inventory_item_for(@shell).update!(quantity: 7)

    post inventory_import_path, params: { data: "key,quantity\nshell_credit,1\n" }

    assert_equal 7, other.inventory_items.find_by(material: @shell).quantity
  end

  test "the inventory page links to export and import" do
    get inventory_items_path

    assert_select "nav[aria-label='Inventory data'] a", count: 3
    assert_select "a[href$='/inventory/export.csv']"
    assert_select "a[href$='/inventory/export.json']"
    assert_select "a[href$='/inventory/import']"
  end
end
