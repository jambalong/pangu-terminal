# Moves a plan one place up (towards priority 1) or down within its owner's
# list. `plans` is the owner's list in priority order. Positions are rewritten
# as 1..n, which also gives plans created before priorities existed a place.
# Returns :moved, or :unchanged when the plan is already at that end.
class PlanReorderer < ApplicationService
  DIRECTIONS = %w[ up down ].freeze

  def initialize(plans:, plan:, direction:)
    @plans = plans
    @plan = plan
    @direction = direction.to_s
  end

  def call
    ordered = @plans.to_a
    index = ordered.index(@plan)
    return :unchanged unless index && DIRECTIONS.include?(@direction)

    target = @direction == "up" ? index - 1 : index + 1
    return :unchanged if target.negative? || target >= ordered.size

    ordered[index], ordered[target] = ordered[target], ordered[index]
    Plan.transaction do
      ordered.each_with_index do |plan, position|
        plan.update_columns(position: position + 1) unless plan.position == position + 1
      end
    end
    :moved
  end
end
