require "test_helper"

class InventoryQuickEntriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "quick@example.com", password: "password123")
    @shell = Material.find_by!(name: "Shell Credit")
    @core = Material.find_by!(name: "Basic Energy Core")
    sign_in @user
  end

  def quantity_of(material) = @user.inventory_items.find_by(material: material)&.quantity

  test "requires sign-in" do
    sign_out @user
    get inventory_quick_entry_path
    assert_redirected_to new_user_session_path

    patch inventory_quick_entry_path, params: { quantities: { @shell.id => "5" } }
    assert_redirected_to new_user_session_path
  end

  test "lists every material with labelled inputs when there are no plans" do
    get inventory_quick_entry_path

    assert_response :ok
    assert_select "h1", text: "Quick entry"
    assert_select "input.quick-input", count: Material.count
    assert_select "label[for='quantity_#{@shell.id}']", text: /Shell Credit/
    assert_select "section[aria-labelledby] h2", minimum: 1
  end

  test "with plans it lists only the needed materials and says how to see them all" do
    Plan.create!(user: @user, subject: Weapon.find_by!(name: "Kumokiri"),
                 plan_data: { "input" => {}, "output" => { @shell.id.to_s => 25480 } })

    get inventory_quick_entry_path

    assert_select "input.quick-input", count: 1
    assert_select ".quick-needed", text: "plans need 25,480"
    assert_select "a", text: "Show every material"

    get inventory_quick_entry_path(all: 1)
    assert_select "input.quick-input", count: Material.count
    assert_select "a", text: "Show only what my plans need"
  end

  test "shows what is already owned and leaves zero blank" do
    @user.inventory_item_for(@shell).update!(quantity: 321)

    get inventory_quick_entry_path

    assert_select "input#quantity_#{@shell.id}[value='321']"
    assert_select "input#quantity_#{@core.id}[value]", count: 0
  end

  test "saving updates the inventory and redirects with a message" do
    patch inventory_quick_entry_path, params: { quantities: { @shell.id => "1,500", @core.id => "2k" } }

    assert_redirected_to inventory_quick_entry_path
    assert_equal "Saved 2 materials.", flash[:notice]
    assert_equal [ 1500, 2000 ], [ quantity_of(@shell), quantity_of(@core) ]
  end

  test "saving with nothing changed says so, and keeps the all-materials view" do
    patch inventory_quick_entry_path, params: { all: 1, quantities: { @shell.id => "" } }

    assert_redirected_to inventory_quick_entry_path(all: 1)
    assert_equal "Nothing changed.", flash[:notice]
  end

  test "a bad entry saves nothing, names the field and keeps what was typed" do
    patch inventory_quick_entry_path, params: { quantities: { @shell.id => "100", @core.id => "plenty" } }

    assert_response :unprocessable_content
    assert_select ".quick-errors[role=alert]", text: /Nothing was saved/
    assert_select ".quick-errors a[href='#quantity_#{@core.id}']", text: "Basic Energy Core"
    assert_select "input#quantity_#{@core.id}[aria-invalid=true][value='plenty'][aria-describedby='error_#{@core.id}']"
    assert_select "input#quantity_#{@shell.id}[value='100']"
    assert_nil quantity_of(@shell)
  end

  test "unknown keys and other junk are ignored, not an error" do
    patch inventory_quick_entry_path, params: { quantities: { "0" => "5", "abc" => "5", @shell.id => "9" }, junk: "x" }

    assert_redirected_to inventory_quick_entry_path
    assert_equal 9, quantity_of(@shell)
  end

  test "a malformed quantities param does not crash" do
    patch inventory_quick_entry_path, params: { quantities: "nope" }

    assert_response :redirect
  end

  test "only the signed-in user's inventory changes" do
    other = User.create!(email: "quick_other@example.com", password: "password123")
    other.inventory_item_for(@shell).update!(quantity: 4)

    patch inventory_quick_entry_path, params: { quantities: { @shell.id => "1" } }

    assert_equal 4, other.inventory_items.find_by(material: @shell).quantity
  end

  test "the inventory page and the onboarding card link to quick entry" do
    get inventory_items_path
    assert_select "nav[aria-label='Inventory data'] a[href$='/inventory/quick']", text: "Quick entry"

    @user.update!(sol3_phase: 3)
    Plan.create!(user: @user, subject: Weapon.find_by!(name: "Kumokiri"), plan_data: { "input" => {}, "output" => {} })
    get authenticated_root_path
    assert_select ".onboarding-card a[href$='/inventory/quick']", text: "Enter inventory"
  end
end
