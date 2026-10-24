# For plans in priority order, how much more farming each one adds once the
# plans above it are done: Waveplates for that step, the running total, and how
# long the running total takes to regenerate. Only meaningful with two or more
# plans (a single plan is the whole optimizer result) and capped so a large
# account does not run the optimizer dozens of times.
class PlanPriorityBreakdown < ApplicationService
  MAX_PLANS = 12

  def initialize(user:, plans:, banked: 0)
    @user = user
    @plans = plans.to_a
    @banked = banked
  end

  def call
    return [] if @plans.size < 2 || @plans.size > MAX_PLANS

    previous = 0
    @plans.each_with_index.map do |plan, index|
      cumulative = OptimizerService.call(user: @user, plans: @plans.first(index + 1))[:totals][:total_wp]
      step = { plan: plan, rank: index + 1, waveplates: cumulative - previous, cumulative: cumulative,
               timeline: WaveplateTimeline.call(total: cumulative, banked: @banked) }
      previous = cumulative
      step
    end
  end
end
