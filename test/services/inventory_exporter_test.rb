require "test_helper"

class InventoryExporterTest < ActiveSupport::TestCase
  test "lists every material with its quantity, zero when nothing is recorded" do
    user = User.create!(email: "exporter@example.com", password: "password123")
    shell = Material.find_by!(name: "Shell Credit")
    user.inventory_item_for(shell).update!(quantity: 42)

    entries = InventoryExporter.call(user: user)

    assert_equal Material.count, entries.size
    assert_equal({ key: "shell_credit", name: "Shell Credit", quantity: 42 }, entries.find { |e| e[:key] == "shell_credit" })
    assert_equal 0, entries.find { |e| e[:key] == "basic_energy_core" }[:quantity]
  end

  test "keys match the API's inventory keys" do
    user = User.create!(email: "exporter_keys@example.com", password: "password123")

    assert_equal Material.all.map(&:snake_case_name).sort, InventoryExporter.call(user: user).map { |e| e[:key] }.sort
  end

  test "an export imports back to the same inventory" do
    user = User.create!(email: "exporter_roundtrip@example.com", password: "password123")
    user.inventory_item_for(Material.find_by!(name: "Shell Credit")).update!(quantity: 1234)
    csv = InventoryTable.to_csv(InventoryExporter.call(user: user))
    other = User.create!(email: "exporter_roundtrip2@example.com", password: "password123")

    result = InventoryImporter.call(user: other, content: csv)

    assert_equal [], result[:skipped]
    assert_equal 1234, other.inventory_items.find_by!(material: Material.find_by!(name: "Shell Credit")).quantity
  end
end
