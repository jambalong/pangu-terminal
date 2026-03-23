require "test_helper"

class InventoryItemsControllerIndexTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "inventory_index@example.com", password: "password123")
  end

  test "unauthenticated user is redirected to sign in" do
    get inventory_items_path
    assert_redirected_to new_user_session_path
  end

  test "authenticated user can access index" do
    sign_in @user
    get inventory_items_path
    assert_response :ok
  end

  test "filters inventory by plan when plan_id param is present" do
    weapon = Weapon.find_by!(name: "Kumokiri")
    plan = Plan.create!(
      user: @user,
      subject: weapon,
      plan_data: { "input" => {}, "output" => {} }
    )

    sign_in @user
    get inventory_items_path(plan_id: plan.id)
    assert_response :ok
  end
end

class InventoryItemsControllerEditTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "inventory_edit@example.com", password: "password123")
    @other_user = User.create!(email: "inventory_edit_other@example.com", password: "password123")
    @material = Material.find_by!(name: "Cadence Seed")
    @inventory_item = @user.inventory_item_for(@material)
  end

  test "owner can access edit" do
    sign_in @user
    get edit_inventory_item_path(@inventory_item)
    assert_response :ok
  end

  test "non-owner gets 404" do
    sign_in @other_user
    get edit_inventory_item_path(@inventory_item)
    assert_response :not_found
  end
end

class InventoryItemsControllerUpdateTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "inventory_update@example.com", password: "password123")
    @other_user = User.create!(email: "inventory_update_other@example.com", password: "password123")
    @material = Material.find_by!(name: "Cadence Seed")

    sign_in @user
    @inventory_item = @user.inventory_item_for(@material)
  end

  test "updates inventory item quantity" do
    sign_in @user
    patch inventory_item_path(@inventory_item),
      params: { inventory_item: { quantity: 47 } },
      headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_equal 47, @inventory_item.reload.quantity
  end

  test "updates inventory item and redirects on HTML success" do
    sign_in @user
    patch inventory_item_path(@inventory_item),
      params: { inventory_item: { quantity: 67 } }

    assert_redirected_to inventory_items_path
  end

  test "does not update with invalid quantity" do
    sign_in @user
    original_quantity = @inventory_item.quantity

    patch inventory_item_path(@inventory_item),
      params: { inventory_item: { quantity: -1 } },
      headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_equal original_quantity, @inventory_item.reload.quantity
  end

  test "non-owner gets 404" do
    sign_in @other_user
    patch inventory_item_path(@inventory_item),
      params: { inventory_item: { quantity: 99 } }

    assert_response :not_found
  end
end
