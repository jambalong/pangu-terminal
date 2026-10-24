# The user's whole inventory as plain data, one entry per material (zero when
# nothing is recorded), in material order. Same keys as the API's inventory.
class InventoryExporter < ApplicationService
  def initialize(user:)
    @user = user
  end

  def call
    quantities = @user.inventory_items.pluck(:material_id, :quantity).to_h

    Material.order(:id).map do |material|
      { key: material.snake_case_name, name: material.name, quantity: quantities.fetch(material.id, 0) }
    end
  end
end
