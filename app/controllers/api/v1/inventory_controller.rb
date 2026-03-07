# app/controllers/api/v1/inventory_controller.rb
module Api
  module V1
    class InventoryController < BaseController
      def index
        inventory_map = current_user.inventory_items.index_by(&:material_id)

        result = Material.all.each_with_object({}) do |material, hash|
          hash[material.snake_case_name] = inventory_map[material.id]&.quantity || 0
        end

        render json: result
      end
    end
  end
end
