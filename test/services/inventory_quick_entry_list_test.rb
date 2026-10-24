require "test_helper"

class InventoryQuickEntryListTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(email: "quick_list@example.com", password: "password123")
    @shell = Material.find_by!(name: "Shell Credit")
    @core = Material.find_by!(name: "Basic Energy Core")
  end

  def list(show_all: false) = InventoryQuickEntryList.call(user: @user, show_all: show_all)
  def items(result) = result[:groups].flat_map { |group| group[:items] }

  test "without plans every material is listed" do
    result = list

    assert result[:showing_all]
    assert_not result[:has_plans]
    assert_equal Material.count, items(result).size
  end

  test "with plans only the materials they need are listed, with the needed total" do
    Plan.create!(user: @user, subject: Weapon.find_by!(name: "Kumokiri"),
                 plan_data: { "input" => {}, "output" => { @shell.id.to_s => 100, @core.id.to_s => 0 } })
    Plan.create!(user: @user, subject: Weapon.where.not(name: "Kumokiri").first,
                 plan_data: { "input" => {}, "output" => { @shell.id.to_s => 50 } })

    result = list

    assert_not result[:showing_all]
    assert_equal [ @shell ], items(result).map { |item| item[:material] }
    assert_equal 150, items(result).first[:needed]
  end

  test "show_all lists everything even with plans" do
    Plan.create!(user: @user, subject: Weapon.find_by!(name: "Kumokiri"),
                 plan_data: { "input" => {}, "output" => { @shell.id.to_s => 100 } })

    assert_equal Material.count, items(list(show_all: true)).size
    assert list(show_all: true)[:has_plans]
  end

  test "carries what the user owns and groups by category in game order" do
    @user.inventory_item_for(@shell).update!(quantity: 33)

    result = list

    assert_equal 33, items(result).find { |item| item[:material] == @shell }[:owned]
    assert_equal "Universal Currency", result[:groups].first[:category]
    order = result[:groups].map { |group| Material::CATEGORY_ORDER.index(group[:category]) || 99 }
    assert_equal order.sort, order
  end

  test "another user's plans and inventory are not mixed in" do
    other = User.create!(email: "quick_list_other@example.com", password: "password123")
    Plan.create!(user: other, subject: Weapon.find_by!(name: "Kumokiri"),
                 plan_data: { "input" => {}, "output" => { @shell.id.to_s => 100 } })
    other.inventory_item_for(@shell).update!(quantity: 77)

    result = list

    assert_not result[:has_plans]
    assert_equal 0, items(result).find { |item| item[:material] == @shell }[:owned]
  end
end
