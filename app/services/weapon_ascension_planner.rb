class WeaponAscensionPlanner < ApplicationService
  SHELL_CREDIT_ID = Material.find_by(name: "Shell Credit").id

  def initialize(
    weapon:, current_level:, target_level:,
    current_ascension_rank:, target_ascension_rank:
  )
    @weapon: weapon
    @current_level: current_level.to_i
    @target_level: current_level.to_i
    @current_ascension_rank: current_ascension_rank.to_i
    @target_ascension_rank: target_ascension_rank.to_i

    @materials_totals = Hash.new(0)
  end

  def call
    validate_inputs!

    calculate_leveling_costs
    calculate_ascension_costs

    @materials_totals
  rescue => e
    Rails.logger.error("ResonatorAscensionPlanner Error: #{e.message}")
    raise
  end

  private

  def validate_inputs!
    errors = []

    # this checks for a zero-change plan
    if @current_level == @target_level &&
       @current_ascension_rank == @target_ascension_rank
      errors << "At least one target value must be different from the corresponding current value to generate a plan."
    end

    # this checks for impossible downgrades (level and ascension rank)
    if @target_level < @current_level
      errors << "Target Level (#{@target_level}) cannot be less than Current Level (#{@current_level})."
    end

    if @target_ascension_rank < @current_ascension_rank
      errors << "Target ascension rank value must be greater than or equal to current ascension rank value."
    end

    raise "Input Validation Error: #{errors.join('; ')}" unless errors.empty?
  end

  def calculate_leveling_costs
    required_levels = (@current_level + 1)..@target_level
    level_costs = WeaponLevelCost.find_by(level: required_levels)
    total_exp_required = 0

    level_costs.each do |level_cost|
      total_exp_required += level_cost.exp_required
      @materials_totals[SHELL_CREDIT_ID] += level_cost.credit_cost
    end

    convert_exp_to_potions(total_exp_required)
  end

  def convert_exp_to_potions(total_exp_required)
    basic_potion = Material.find_by(name: "Basic Energy Core")
    @materials_totals[basic_potion.id] += total_exp_required / basic_potion.exp_value
  end

  def calculate_ascension_costs
    required_ascension_ranks = (@current_ascension_rank + 1)..@target_ascension_rank
    ascension_costs = WeaponAscensionCost.where(ascension_rank: required_ascension_ranks)
    materials_by_weapon = WeaponMaterialMap.where(weapon_id: @weapon.id).to_a

    ascension_costs.each do |ascension_cost|
      if ascension_cost.material_type == "Credit"
        @materials_totals[SHELL_CREDIT_ID] += ascension_cost.quantity
        next
      end

      found_map = materials_by_weapon.find do |map_record|
        map_record.material_type == ascension_cost.material_type &&
        map_record.rarity == ascension_cost.rarity
      end

      if found_map
        @materials_totals[found_map.material_id] += ascension_cost.quantity
      end
    end
  end
end
