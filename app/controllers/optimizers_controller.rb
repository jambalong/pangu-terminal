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

    if @selected_plan && params[:run]
      @results, @chain_coverage, @totals = compute_optimizer_results
      @farming_priority = FarmingPriorityService.call(@results)
    end
  end

  def plans_modal
    render layout: false
  end

  def select_plan
    session[:optimizer_plan_id] = params[:plan_id]
    @selected_plan = @plans.find_by(id: params[:plan_id])
  end

  def advise
    @selected_plan = @plans.find_by(id: session[:optimizer_plan_id])
    return head :no_content unless @selected_plan

    @results, @chain_coverage, @totals = compute_optimizer_results
    @farming_priority = FarmingPriorityService.call(@results)
    @farming_advice = FarmingAdvisorService.call(
      results: @results,
      farming_priority: @farming_priority,
      chain_coverage: @chain_coverage
    )

    render partial: "farming_advice"
  end

  private

  def load_plans
    @plans = load_current_plans
  end

  def compute_optimizer_results
    optimizer = OptimizerService.call(user: current_user, plan: @selected_plan)
    [ optimizer[:results], optimizer[:chain_coverage], optimizer[:totals] ]
  end
end
