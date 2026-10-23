class OptimizersController < ApplicationController
  include PlanLoading

  before_action :authenticate_user!
  before_action :load_plans

  def index
    @inventory_empty = !current_user.inventory_items.where("quantity > 0").exists?
    @selected_plan = if params[:plan_id].present?
      session[:optimizer_plan_id] = params[:plan_id]
      @plans.find_by(id: params[:plan_id])
    elsif session[:optimizer_plan_id].present?
      @plans.find_by(id: session[:optimizer_plan_id])
    end

    if @selected_plan && params[:run] && sol3_phase_set?
      @results, @chain_coverage, @totals = compute_optimizer_results
      @farming_priority = FarmingPriorityService.call(@results)
    end
  end

  def plans_modal
    render layout: false
  end

  def select_plan
    @inventory_empty = !current_user.inventory_items.where("quantity > 0").exists?
    session[:optimizer_plan_id] = params[:plan_id]
    @selected_plan = @plans.find_by(id: params[:plan_id])
  end

  def advise
    @selected_plan = @plans.find_by(id: session[:optimizer_plan_id])
    return head :no_content unless @selected_plan && sol3_phase_set?

    status, advice = FarmingAdviceRequest.new(user: current_user, plan: @selected_plan).fetch

    render partial: "farming_advice", locals: { pending: status == :pending, advice: advice }
  end

  private

  # The view shows a "set your SOL3 phase" gate while it is nil; the optimizer
  # cannot estimate runs without it (DropRateService requires an integer).
  def sol3_phase_set?
    current_user.sol3_phase.present?
  end

  def load_plans
    @plans = load_current_plans
  end

  def compute_optimizer_results
    optimizer = OptimizerService.call(user: current_user, plan: @selected_plan)
    [ optimizer[:results], optimizer[:chain_coverage], optimizer[:totals] ]
  end
end
