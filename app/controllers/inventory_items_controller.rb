class InventoryItemsController < ApplicationController
  include PlanLoading

  before_action :authenticate_user!
  before_action :load_inventory_and_plans, only: [ :index ]
  before_action :set_inventory_item, only: [ :edit, :update ]

  def index
    @selected_plan = @plans.find_by(id: params[:plan_id]) if params[:plan_id].present?
    @categories = Material.ordered_categories
    apply_filters
    apply_plan_filter
    compute_synthesis_data
  end

  def edit
    render layout: false
  end

  def update
    if @inventory_item.update(inventory_item_params)
      load_inventory_and_plans

      @selected_plan = @plans.find_by(id: params[:plan_id]) if params[:plan_id].present?
      compute_synthesis_data

      @related_items = current_user.inventory_items.joins(:material)
        .where(materials: { item_group_id: @inventory_item.material.item_group_id })

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to inventory_items_path }
      end
    else
      render :edit, status: :unprocessable_entity
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

  def apply_plan_filter
    return unless @selected_plan.present?

    expected_exp_type = Plan::EXP_POTION_TYPE_MAP[@selected_plan.subject_type]
    requirements_hash = (@selected_plan.plan_data.dig("output") || {}).transform_keys(&:to_i)
    @inventory_items = @inventory_items.select do |i|
      # Keep if in plan requirements, OR if it's an relevant exp potion (any tier)
      requirements_hash[i.material_id].present? || i.material.material_type == expected_exp_type
    end
  end

  def compute_synthesis_data
    inventory_hash = @inventory_items.index_by(&:material_id).transform_values(&:quantity)

    if @selected_plan.present?
      requirements_hash = (@selected_plan.plan_data.dig("output") || {}).transform_keys(&:to_i)
    else
      requirements_hash = Plan.fetch_materials_summary(@plans)
    end

    @synthesis_result = SynthesisService.new(inventory_hash, requirements_hash).reconcile_inventory
  end

  def exp_potion?(material)
    return false unless material
    material.material_type.in?(%w[ResonatorEXP WeaponEXP])
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
