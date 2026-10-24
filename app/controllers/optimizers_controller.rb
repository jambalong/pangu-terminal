class OptimizersController < ApplicationController
  include PlanLoading

  before_action :authenticate_user!
  before_action :load_plans
  before_action :apply_selection_params, only: [ :index, :select_plan ]
  before_action :load_selection

  def index
    @inventory_empty = inventory_empty?

    if @selected_plans.any? && params[:run] && sol3_phase_set?
      @results, @chain_coverage, @totals = compute_optimizer_results
      @farming_priority = FarmingPriorityService.call(@results)
    end
  end

  def plans_modal
    render layout: false
  end

  def select_plan
    @inventory_empty = inventory_empty?
  end

  def advise
    return head :no_content unless @selected_plans.any? && sol3_phase_set?

    status, advice = FarmingAdviceRequest.new(user: current_user, plans: @selected_plans).fetch

    render partial: "farming_advice", locals: { pending: status == :pending, advice: advice }
  end

  private

  # The view shows a "set your SOL3 phase" gate while it is nil; the optimizer
  # cannot estimate runs without it (DropRateService requires an integer).
  def sol3_phase_set?
    current_user.sol3_phase.present?
  end

  def inventory_empty?
    !current_user.inventory_items.where("quantity > 0").exists?
  end

  def load_plans
    @plans = load_current_plans
  end

  # The selection lives in the session: every plan (so plans created later are
  # included), or a chosen set of plan ids. A single `plan_id` is still accepted.
  def apply_selection_params
    permitted = params.permit(:plan_id, :all, plan_ids: [])

    if permitted[:all].present?
      session[:optimizer_all] = true
      session.delete(:optimizer_plan_ids)
    elsif permitted[:plan_ids].present? || permitted[:plan_id].present?
      session[:optimizer_all] = false
      session[:optimizer_plan_ids] = Array(permitted[:plan_ids].presence || permitted[:plan_id]).map(&:to_s)
    end
  end

  # Only the user's own plans can be selected; foreign or deleted ids are ignored.
  def load_selection
    @all_plans_selected = session[:optimizer_all].present? && @plans.any?
    ids = session[:optimizer_plan_ids].presence || Array(session[:optimizer_plan_id].presence)

    @selected_plans =
      if @all_plans_selected
        @plans.to_a
      elsif ids.present?
        @plans.where(id: ids).to_a
      else
        []
      end
  end

  def compute_optimizer_results
    optimizer = OptimizerService.call(user: current_user, plans: @selected_plans)
    [ optimizer[:results], optimizer[:chain_coverage], optimizer[:totals] ]
  end
end
