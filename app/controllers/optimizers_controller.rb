class OptimizersController < ApplicationController
  include PlanLoading

  before_action :authenticate_user!
  before_action :load_plans

  def index
    @selected_plan = if params[:plan_id].present?
      session[:optimizer_plan_id] = params[:plan_id]
      @plans.find_by(id: params[:plan_id])
    elsif session[:optimizer_plan_id].present?
      @plans.find_by(id: session[:optimizer_plan_id])
    end

    if @selected_plan
      @results, @chain_coverage = compute_optimizer_results
      @farming_priority = FarmingPriorityService.call(@results)

      @farming_advice = FarmingAdvisorService.call(
        results: @results,
        farming_priority: @farming_priority,
        sol3_phase: current_user.sol3_phase,
        chain_coverage: @chain_coverage
      )
    end
  end

  def plans_modal
    render layout: false
  end

  def select_plan
    session[:optimizer_plan_id] = params[:plan_id]
    @selected_plan = @plans.find_by(id: params[:plan_id])

    if @selected_plan
      @results, @chain_coverage = compute_optimizer_results
      @farming_priority = FarmingPriorityService.call(@results)

      @farming_advice = FarmingAdvisorService.call(
        results: @results,
        farming_priority: @farming_priority,
        sol3_phase: current_user.sol3_phase,
        chain_coverage: @chain_coverage
      )
    end
  end

  private

  def load_plans
    @plans = load_current_plans
  end

  def compute_optimizer_results
    needed = (@selected_plan.plan_data.dig("output") || {}).transform_keys(&:to_i)
    inventory_items = current_user.inventory_items
    owned = inventory_items.index_by(&:material_id).transform_values(&:quantity)
    synthesis = SynthesisService.new(owned, needed)
    reconciled = synthesis.reconcile
    deficits = reconciled.select { |material_id, data| data[:deficit] > 0 }
    materials = Material.includes(:sources).where(id: deficits.keys).index_by(&:id)

    results = materials.each_with_object({}) do |(material_id, material), results|
      deficit = deficits[material_id][:deficit]
      results[material_id] = {
        material: material,
        deficit: deficit,
        sources: DropRateService.call(material, deficit, current_user.sol3_phase)
      }
    end

    [ results, synthesis.chain_coverage ]
  end
end
