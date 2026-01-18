class InventoryItemsController < ApplicationController
  before_action :authenticate_user!

  def index
    @inventory_items = current_user.inventory_items
                                   .includes(:material)
                                   .order("materials.material_type ASC, materials.rarity ASC")
  end

  def update
    @inventory_item = current_user.inventory_items.find(params[:id])

    if @inventory_item.update(inventory_item_params)
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_back fallback_location: inventory_items_path }
      end
    end
  end

  private

  def inventory_item_params
    params.require(:inventory_item).permit(:quantity)
  end
end
