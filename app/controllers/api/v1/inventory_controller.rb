# app/controllers/api/v1/inventory_controller.rb
module Api
  module V1
    class InventoryController < BaseController
      def index
        items = @current_user.inventory_items.includes(:material).order("materials.name ASC")

        render json: items.each_with_object({}) { |item, hash| hash[item.material.snake_case_name] = item.quantity }
      end
    end
  end
end
