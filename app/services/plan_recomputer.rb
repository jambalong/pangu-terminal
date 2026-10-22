# Recomputes stored plans from their stored input.
#
# plans.plan_data["output"] is computed once when a plan is saved. Game data does
# not change, so plans only go stale when a calculation bug is fixed (or the
# planner's data is corrected). Run this after such a fix to bring existing plans
# in line. It is a dry run unless apply: true.
#
#   PlanRecomputer.call(scope: Plan.where(user_id: 1), apply: true)
#
# Returns { changed: [...], unchanged: n, failed: [...] }. Each changed entry has
# the plan id, subject name and a { material_id => [old_qty, new_qty] } diff.
class PlanRecomputer < ApplicationService
  def initialize(scope: Plan.all, apply: false)
    @scope = scope
    @apply = apply
  end

  def call
    result = { changed: [], unchanged: 0, failed: [] }

    @scope.includes(:subject).find_each do |plan|
      recompute(plan, result)
    end

    result
  end

  private

  def recompute(plan, result)
    fresh = normalize(PlanForm.from_plan(plan).plan_data)
    diff = diff_output(plan.plan_data["output"] || {}, fresh["output"])

    if diff.empty?
      result[:unchanged] += 1
      return
    end

    plan.update!(plan_data: fresh) if @apply
    result[:changed] << { plan_id: plan.id, subject: plan.subject&.name, diff: diff }
  rescue ResonatorAscensionPlanner::ValidationError, WeaponAscensionPlanner::ValidationError, ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound => e
    result[:failed] << { plan_id: plan.id, error: e.message }
  end

  # JSON round trip so keys and values match what comes back from the jsonb column.
  def normalize(plan_data)
    JSON.parse(plan_data.to_json)
  end

  def diff_output(old_output, new_output)
    (old_output.keys | new_output.keys).each_with_object({}) do |material_id, diff|
      old_qty = old_output[material_id]
      new_qty = new_output[material_id]
      diff[material_id.to_i] = [ old_qty, new_qty ] unless old_qty == new_qty
    end
  end
end
