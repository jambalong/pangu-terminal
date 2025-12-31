class WeaponAscensionPlanner < ApplicationService
  class ValidationError < StandardError; end

  ASCENSION_LEVEL_CAPS = {
    0 => 20, 1 => 40, 2 => 50, 3 => 60, 4 => 70, 5 => 80, 6 => 90
  }

  def initialize(
    weapon:, current_level:, target_level:,
    current_ascension_rank:, target_ascension_rank:
  )
    @weapon = weapon
    @current_level = current_level.to_i
    @target_level = target_level.to_i
    @current_ascension_rank = current_ascension_rank.to_i
    @target_ascension_rank = target_ascension_rank.to_i

    @materials_totals = Hash.new(0)
  end

  def call
    validate_inputs!

    @materials_by_weapon = WeaponMaterialMap.where(weapon_id: @weapon.id).to_a
    @materials_by_weapon_type = WeaponTypeMaterial.where(weapon_type: @weapon.weapon_type).to_a

    calculate_leveling_costs
    calculate_ascension_costs

    @materials_totals
  rescue ValidationError => e
    raise e
  rescue => e
    Rails.logger.error("WeaponAscensionPlanner Error: #{e.message}")
    raise
  end

  def self.shell_credit_id
    @shell_credit_id ||= Material.find_by(name: "Shell Credit").id
  end

  def self.basic_core
    @basic_core ||= Material.find_by(name: "Basic Energy Core")
  end

  private

  def validate_inputs!
    errors = []

    # this checks for a zero-change plan
    if @current_level == @target_level &&
       @current_ascension_rank == @target_ascension_rank
      errors << "At least one target value must be different from the corresponding current value to generate a plan."
    end

    # this checks for proper level range
    unless @current_level.between?(1, 90)
      errors << "Current Level (#{@current_level}) must be between 1 and 90."
    end

    unless @target_level.between?(1, 90)
      errors << "Target Level (#{@target_level}) must be between 1 and 90."
    end

    # this checks for impossible downgrades (level and ascension rank)
    if @target_level < @current_level
      errors << "Target level (#{@target_level}) cannot be less than current level (#{@current_level})."
    end

    if @target_ascension_rank < @current_ascension_rank
      errors << "Target ascension rank value must be greater than or equal to current ascension rank value."
    end

    # this keeps level range within ascension rank
    current_max_level = ASCENSION_LEVEL_CAPS[@current_ascension_rank]
    if current_max_level.nil? || @current_level > current_max_level
      errors << "Current level (#{@current_level}) is impossible with current ascension rank (#{@current_ascension_rank}). Max level is #{current_max_level || 'N/A'}."
    end

    if @current_ascension_rank > 0
      min_level_required = ASCENSION_LEVEL_CAPS[@current_ascension_rank - 1]

      if @current_level < min_level_required
        errors << "Current ascension rank #{@current_ascension_rank} requires a minimum level of #{min_level_required}."
      end
    end

    target_max_level = ASCENSION_LEVEL_CAPS[@target_ascension_rank]
    if target_max_level.nil? || @target_level > target_max_level
      errors << "Target level (#{@target_level}) is impossible with target ascension rank (#{@target_ascension_rank}). Max level is #{target_max_level || 'N/A'}."
    end

    if @target_ascension_rank > 0
      min_level_required = ASCENSION_LEVEL_CAPS[@target_ascension_rank - 1]

      if @target_level < min_level_required
        errors << "Target ascension rank #{@target_ascension_rank} requires a minimum level of #{min_level_required}."
      end
    end

    raise ValidationError, errors.join("|") unless errors.empty?
  end

  def shell_credit_id
    self.class.shell_credit_id
  end

  def basic_core
    self.class.basic_core
  end

  def add_materials(cost_records)
    cost_records.each do |cost|
      case cost.material_type
      when "Credit"
        @materials_totals[shell_credit_id] += cost.quantity
      when "ForgeryDrop"
        material_id = @materials_by_weapon_type.find { |map| map.rarity == cost.rarity }&.material_id
        @materials_totals[material_id] += cost.quantity if material_id
      else
        material_id = @materials_by_weapon.find do |map|
          map.material_type == cost.material_type &&
          map.rarity == cost.rarity
        end&.material_id

        @materials_totals[material_id] += cost.quantity if material_id
      end
    end
  end

  def calculate_leveling_costs
    required_levels = (@current_level + 1)..@target_level
    level_costs = WeaponLevelCost.where(level: required_levels, weapon_rarity: @weapon.rarity)
    total_exp_required = 0

    level_costs.each do |level_cost|
      total_exp_required += level_cost.exp_required
      @materials_totals[shell_credit_id] += level_cost.credit_cost
    end

    convert_exp_to_potions(total_exp_required)
  end

  def convert_exp_to_potions(total_exp_required)
    core = basic_core

    return if total_exp_required <= 0

    quantity = (total_exp_required / core.exp_value)
    @materials_totals[core.id] += quantity
  end

  def calculate_ascension_costs
    required_ascension_ranks = (@current_ascension_rank + 1)..@target_ascension_rank
    ascension_costs = WeaponAscensionCost.where(ascension_rank: required_ascension_ranks, weapon_rarity: @weapon.rarity)
    add_materials(ascension_costs)
  end
end
