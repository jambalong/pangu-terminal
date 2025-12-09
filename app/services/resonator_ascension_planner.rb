class ResonatorAscensionPlanner < ApplicationService
  SHELL_CREDIT_ID = Material.find_by(name: "Shell Credit").id

  def initialize(resonator:, current_level:, target_level:, current_ascension_rank:, target_ascension_rank:, current_skill_levels:, target_skill_levels:, current_forte_nodes:, target_forte_nodes:)
    @resonator = resonator
    @current_level = current_level.to_i
    @target_level = target_level.to_i
    @current_ascension_rank = current_ascension_rank.to_i
    @target_ascension_rank = target_ascension_rank.to_i
    @current_skill_levels = current_skill_levels.transform_values(&:to_i)
    @target_skill_levels = target_skill_levels.transform_values(&:to_i)
    @current_forte_nodes = current_forte_nodes.transform_values(&:to_i)
    @target_forte_nodes = target_forte_nodes.transform_values(&:to_i)

    @materials_totals = Hash.new(0)
  end

  def call
    validate_inputs!

    calculate_leveling_costs
  end

  private

  def validate_inputs!
    errors = []

    # this checks for a zero-change plan
    if @current_level == @target_level &&
       @current_ascension_rank == @target_ascension_rank &&
       @current_skill_levels == @target_skill_levels &&
       @current_forte_nodes == @target_forte_nodes
      errors << "Atleast one target value must be different from corresponding current value"
    end

    # this checks for impossible downgrades (level and ascension rank)
    if @target_level < @current_level &&
       @target_ascension_rank < @current_ascension_rank
      errors << "Target value must be greater than or equal to corresponding current value"
    end

    @current_skill_levels.each do |skill_name, current_level|
      target_level = @target_skill_levels[skill_name]

      if target_level && target_level < current_level
        errors << "Target value must be greater than or equal to corresponding current value"
      end
    end

    @current_forte_nodes.each do |node_name, current_upgrade|
      target_upgrade = @target_forte_nodes[node_name]

      if target_upgrade && target_upgrade < current_upgrade
        errors << "Target value must be greater than or equal to corresponding current value"
      end
    end

    raise "Input Validation Error: #{errors.join('; ')}" unless errors.empty?
  end

  def calculate_leveling_costs
    level_costs = ResonatorLevelCost.where(level: @current_level..@target_level)
    total_exp = 0

    level_costs.each do |cost|
      total_exp += cost.required_exp
      @materials_totals[:SHELL_CREDIT_ID]+= cost.credit_cost
    end

    @materials_totals[:SHELL_CREDIT_ID] += total_credit
    convert_exp_to_potions(total_exp)
  end

  def convert_exp_to_potions(total_exp)
    potion = Material.find_by(name: "Basic Resonance Potion")
    @materials_totals[potion.id] += total_exp / potion.exp_value
  end
end
