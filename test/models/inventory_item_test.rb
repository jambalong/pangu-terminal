require "test_helper"

class InventoryItemTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(email: "test@example.com", password: "password123")
    @material = Material.create!(
      name: "Test Material",
      material_type: "ForgeryDrop",
      category: "Weapon and Skill Material",
      rarity: 2
    )
  end

  test "valid inventory item" do
    item = InventoryItem.new(user: @user, material: @material, quantity: 50)
    assert item.valid?
  end

  test "requires quantity" do
    item = InventoryItem.new(user: @user, material: @material, quantity: nil)
    assert_not item.valid?
    assert item.errors[:quantity].present?
  end

  test "quantity must be >= 0" do
    item = InventoryItem.new(user: @user, material: @material, quantity: -1)
    assert_not item.valid?
  end

  test "unique user + material combo" do
    InventoryItem.create!(user: @user, material: @material, quantity: 50)
    duplicate = InventoryItem.new(user: @user, material: @material, quantity: 100)
    assert_not duplicate.valid?
  end
end
