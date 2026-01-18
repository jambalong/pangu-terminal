class InventoryItemsController < ApplicationController
  before_action :authenticate_user!

  def index
    @inventory_items = current_user.inventory_items
                                   .includes(:material)
                                   .order("materials.id ASC, materials.rarity ASC")

    if params[:query].present?
      @inventory_items = @inventory_items.search_by_name(params[:query])
    end

    if params[:category].present?
      @inventory_items = @inventory_items.by_category(params[:category])
    end
  end

  def update
    @inventory_item = current_user.inventory_items.find(params[:id])

    if @inventory_item.update(inventory_item_params)
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_back fallback_location: inventory_items_path }
      end
    else
      head :unprocessable_entity
    end
  end

  private

  def inventory_item_params
    params.require(:inventory_item).permit(:quantity)
  end
end
