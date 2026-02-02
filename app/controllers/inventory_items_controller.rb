class InventoryItemsController < ApplicationController
  include PlanLoading

  before_action :authenticate_user!
  before_action :load_inventory_and_plans, only: [ :index ]
  before_action :set_inventory_item, only: [ :update ]

  def index
    @selected_plan_id = params[:plan_id]
    @categories = Material.ordered_categories
    apply_filters
    compute_synthesis_data
  end

  def update
    if @inventory_item.update(inventory_item_params)
      load_inventory_and_plans

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_back fallback_location: inventory_items_path }
      end
    else
      head :unprocessable_entity
    end
  end

  private

  def load_inventory_and_plans
    @inventory_items = current_user.inventory_items.includes(:material)
    @plans = load_current_plans
    @material_lookup = Material.index_by_ids(@inventory_items.pluck(:material_id))
  end

  def apply_filters
    if params[:query].present?
      @inventory_items = @inventory_items.search_by_name(params[:query])
    end

    if params[:category].present?
      @inventory_items = @inventory_items.by_category(params[:category])
    end

    @inventory_items = @inventory_items.sort_by { |item| material_sort_key(item.material) }
  end

  def compute_synthesis_data
    inventory_hash = @inventory_items.index_by(&:material_id).transform_values(&:quantity)

    if @selected_plan_id.present?
      @selected_plan = @plans.find_by(id: @selected_plan_id)
      requirements_hash = (@selected_plan.plan_data.dig("output") || {}).transform_keys(&:to_i)
    else
      requirements_hash = Plan.fetch_materials_summary(@plans)
    end

    @synthesis_result = SynthesisService.new(inventory_hash, requirements_hash).reconcile_inventory
  end

  def set_inventory_item
    @inventory_item = current_user.inventory_items.find(params[:id])
  end

  def material_sort_key(material)
    type_index = Material::MATERIAL_TYPE_ORDER.index(material.material_type) || 999
    [ type_index, material.id, material.rarity ]
  end

  def inventory_item_params
    params.require(:inventory_item).permit(:quantity)
  end
end
