class ResonatorAscensionPlanner < ApplicationService
  class ValidationError < StandardError; end

  ASCENSION_LEVEL_CAPS = {
    0 => 20, 1 => 40, 2 => 50, 3 => 60, 4 => 70, 5 => 80, 6 => 90
  }

  FORTE_NODES_MAP = {
    "basic_attack_node_1"         => "Stat Bonus Tier 1",
    "basic_attack_node_2"         => "Stat Bonus Tier 2",
    "resonance_skill_node_1"      => "Stat Bonus Tier 1",
    "resonance_skill_node_2"      => "Stat Bonus Tier 2",

    "forte_circuit_node_1"        => "Inherent Skill Tier 1",
    "forte_circuit_node_2"        => "Inherent Skill Tier 2",

    "resonance_liberation_node_1" => "Stat Bonus Tier 1",
    "resonance_liberation_node_2" => "Stat Bonus Tier 2",
    "intro_skill_node_1"          => "Stat Bonus Tier 1",
    "intro_skill_node_2"          => "Stat Bonus Tier 2"
  }

  def initialize(
    resonator:, current_level:, target_level:,
    current_ascension_rank:, target_ascension_rank:,
    current_skill_levels:, target_skill_levels:,
    forte_node_upgrades:
  )
    @resonator = resonator
    @current_level = current_level.to_i
    @target_level = target_level.to_i
    @current_ascension_rank = current_ascension_rank.to_i
    @target_ascension_rank = target_ascension_rank.to_i
    @current_skill_levels = current_skill_levels.symbolize_keys.transform_values(&:to_i)
    @target_skill_levels = target_skill_levels.symbolize_keys.transform_values(&:to_i)
    @forte_node_upgrades = forte_node_upgrades.symbolize_keys.transform_values(&:to_i)

    @materials_totals = Hash.new(0)
  end

  def call
    validate_inputs!

    @materials_by_resonator = ResonatorMaterialMap.where(resonator_id: @resonator.id).to_a
    @materials_by_weapon_type = WeaponTypeMaterial.where(weapon_type: @resonator.weapon_type).to_a

    calculate_leveling_costs
    calculate_ascension_costs
    calculate_skill_leveling_costs
    calculate_forte_node_costs

    @materials_totals
  rescue ValidationError => e
    raise e
  rescue => e
    Rails.logger.error("ResonatorAscensionPlanner Error: #{e.message}")
    raise
  end

  def self.shell_credit_id
    @shell_credit_id ||= Material.find_by!(name: "Shell Credit").id
  end

  def self.basic_potion
    @basic_potion ||= Material.find_by!(name: "Basic Resonance Potion")
  end

  private

  def validate_inputs!
    errors = []

    # this checks for a zero-change plan
    if @current_level == @target_level &&
       @current_ascension_rank == @target_ascension_rank &&
       @current_skill_levels == @target_skill_levels
      errors << "At least one target value must be different from the corresponding current value to generate a plan."
    end

    # this checks for proper level range
    unless @current_level.between?(1, 90)
      errors << "Current level (#{@current_level}) must be between (1) and (90)."
    end

    unless @target_level.between?(1, 90)
      errors << "Target level (#{@target_level}) must be between (1) and (90)."
    end

    # this checks for proper skill level range
    @current_skill_levels.each do |skill_name, level|
      unless level.between?(1, 10)
        errors << "Current '#{skill_name.to_s.titleize}' level must be between (1) and (10)."
      end
    end

    @target_skill_levels.each do |skill_name, level|
      unless level.between?(1, 10)
        errors << "Target '#{skill_name.to_s.titleize}' level must be between (1) and (10)."
      end
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
      errors << "Current level (#{@current_level}) exceeds max level (#{current_max_level}) for ascension rank (#{@current_ascension_rank})."
    end

    if @current_ascension_rank > 0
      min_level_required = ASCENSION_LEVEL_CAPS[@current_ascension_rank - 1]

      if @current_level < min_level_required
        errors << "Current ascension rank (#{@current_ascension_rank}) requires a minimum level of (#{min_level_required})."
      end
    end

    target_max_level = ASCENSION_LEVEL_CAPS[@target_ascension_rank]
    if target_max_level.nil? || @target_level > target_max_level
      errors << "Target level (#{@target_level}) exceeds max level (#{target_max_level}) for Ascension Rank (#{@target_ascension_rank})."
    end

    if @target_ascension_rank > 0
      min_level_required = ASCENSION_LEVEL_CAPS[@target_ascension_rank - 1]

      if @target_level < min_level_required
        errors << "Target ascension rank (#{@target_ascension_rank}) requires a minimum level of (#{min_level_required})."
      end
    end

    # this checks for impossible downgrades (skill and forte nodes)
    @current_skill_levels.each do |skill_name, current_level|
      target_level = @target_skill_levels[skill_name]

      if target_level && target_level < current_level
        errors << "Current level (#{current_level}) for [#{skill_name.to_s.titleize}] exceeds target level (#{target_level})."
      end
    end

    raise ValidationError, errors.join("|") unless errors.empty?
  end

  def shell_credit_id
    self.class.shell_credit_id
  end

  def basic_potion
    self.class.basic_potion
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
        material_id = @materials_by_resonator.find do |map|
          map.material_type == cost.material_type &&
          map.rarity == cost.rarity
        end&.material_id

        @materials_totals[material_id] += cost.quantity if material_id
      end
    end
  end

  def calculate_leveling_costs
    required_levels = (@current_level + 1)..@target_level
    level_costs = ResonatorLevelCost.where(level: required_levels)
    total_exp_required = 0

    level_costs.each do |level_cost|
      total_exp_required += level_cost.exp_required
      @materials_totals[shell_credit_id] += level_cost.credit_cost
    end

    convert_exp_to_potions(total_exp_required)
  end

  def convert_exp_to_potions(total_exp_required)
    potion = basic_potion

    return if total_exp_required <= 0

    quantity = (total_exp_required / potion.exp_value)
    @materials_totals[potion.id] += quantity
  end

  def calculate_ascension_costs
    ascension_model = @resonator.name.start_with?("Rover") ? RoerAscensionCost : ResonatorAscensionCost
    required_ascension_ranks = (@current_ascension_rank + 1)..@target_ascension_rank
    ascension_costs = ascension_model.where(ascension_rank: required_ascension_ranks)
    add_materials(ascension_costs)
  end

  def calculate_skill_leveling_costs
    @current_skill_levels.each do |skill_name, current_level|
      target_level = @target_skill_levels[skill_name]
      next unless target_level && target_level > current_level

      required_level_range = (current_level + 1)..target_level
      skill_costs = SkillCost.where(level: required_level_range)
      add_materials(skill_costs)
    end
  end

  def calculate_forte_node_costs
    @forte_node_upgrades.each do |node_key, state|
      next unless state == 1

      cost_identifier = FORTE_NODES_MAP[node_key.to_s]
      next unless cost_identifier.present?

      forte_node_costs = ForteNodeCost.where(node_identifier: cost_identifier)
      add_materials(forte_node_costs)
    end
  end
end
