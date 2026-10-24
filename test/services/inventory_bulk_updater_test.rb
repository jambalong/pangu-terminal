require "test_helper"

class InventoryBulkUpdaterTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(email: "bulk@example.com", password: "password123")
    @shell = Material.find_by!(name: "Shell Credit")
    @core = Material.find_by!(name: "Basic Energy Core")
  end

  def update(quantities) = InventoryBulkUpdater.call(user: @user, quantities: quantities)
  def quantity_of(material) = @user.inventory_items.find_by(material: material)&.quantity

  test "saves typed quantities, with separators and suffixes" do
    result = update(@shell.id.to_s => "1,200", @core.id.to_s => "25k")

    assert_equal [ 2, {} ], [ result[:updated], result[:errors] ]
    assert_equal [ 1200, 25_000 ], [ quantity_of(@shell), quantity_of(@core) ]
  end

  test "a blank entry means zero" do
    @user.inventory_item_for(@shell).update!(quantity: 9)

    update(@shell.id.to_s => "  ")

    assert_equal 0, quantity_of(@shell)
  end

  test "unchanged entries are not counted or written" do
    @user.inventory_item_for(@shell).update!(quantity: 10)

    result = update(@shell.id.to_s => "10", @core.id.to_s => "")

    assert_equal 0, result[:updated]
    assert_nil quantity_of(@core)
  end

  test "one bad entry means nothing is saved and every bad entry is named" do
    @user.inventory_item_for(@shell).update!(quantity: 5)

    result = update(@shell.id.to_s => "99", @core.id.to_s => "lots")

    assert_equal 0, result[:updated]
    assert_equal [ @core.id ], result[:errors].keys
    assert_match(/whole number/, result[:errors][@core.id])
    assert_equal 5, quantity_of(@shell), "the valid entry is not applied either"
  end

  test "values over the limit are errors" do
    result = update(@shell.id.to_s => "2000000001")

    assert_match(/more than 2,000,000,000/, result[:errors][@shell.id])
  end

  test "unknown material ids are ignored" do
    result = update("0" => "5", "999999999" => "5", @shell.id.to_s => "3")

    assert_equal 1, result[:updated]
    assert_equal({}, result[:errors])
  end

  test "only the given user's inventory changes" do
    other = User.create!(email: "bulk_other@example.com", password: "password123")
    other.inventory_item_for(@shell).update!(quantity: 4)

    update(@shell.id.to_s => "1")

    assert_equal 4, other.inventory_items.find_by(material: @shell).quantity
  end
end
