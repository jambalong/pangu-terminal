class DashboardsController < ApplicationController
  before_action :authenticate_user!

  def show
    @plans = current_user.plans
    @active_plans_count = @plans.count

    # 1. Essential Lookups for the Partial Views
    all_material_ids = @plans.flat_map { |p| p.plan_data.dig("output")&.keys }.compact.uniq
    @materials_lookup = Material.where(id: all_material_ids).index_by(&:id)
    @materials_summary = Plan.fetch_materials_summary(@plans)

    # 2. Stats for your Dashboard widgets
    @materials_needed_count = @materials_summary.values.sum
    @farming_progress = 0 # Future logic
    @estimated_days = 0   # Future logic

    @onboarding = OnboardingChecklist.call(user: current_user)
    @onboarding = OnboardingChecklist.call(user: current_user)
    @recent_plans = @plans.order(created_at: :desc).limit(2)

    response.set_header("Turbo-Location", authenticated_root_path) if turbo_frame_request?
  end
end
