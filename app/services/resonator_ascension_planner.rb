class ResonatorAscensionPlanner < ApplicationService
  class ValidationError < StandardError; end

  ASCENSION_LEVEL_CAPS = {
    0 => 20, 1 => 40, 2 => 50, 3 => 60, 4 => 70, 5 => 80, 6 => 90
  }

  FORTE_NODES_MAP = {
    basic_attack_node_1:          "Stat Bonus Tier 1",
    basic_attack_node_2:          "Stat Bonus Tier 2",
    resonance_skill_node_1:       "Stat Bonus Tier 1",
    resonance_skill_node_2:       "Stat Bonus Tier 2",

    forte_circuit_node_1:         "Inherent Skill Tier 1",
    forte_circuit_node_2:         "Inherent Skill Tier 2",

    resonance_liberation_node_1:  "Stat Bonus Tier 1",
    resonance_liberation_node_2:  "Stat Bonus Tier 2",
    intro_skill_node_1:           "Stat Bonus Tier 1",
    intro_skill_node_2:           "Stat Bonus Tier 2"
  }

  LAHAI_ROI_RESONATORS = [
    "Aemeath",
    "Luuk Herssen",
    "Lynae",
    "Mornye"
  ].freeze

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

    region = LAHAI_ROI_RESONATORS.include?(@resonator.name) ? "lahai_roi" : "base"
    @materials_by_weapon_type = WeaponTypeMaterial.where(
      weapon_type: @resonator.weapon_type,
      region: region
    ).to_a

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

  private

  def validate_inputs!
    errors = []

    validate_no_changes!(errors)
    validate_level_ranges!(errors)
    validate_skill_ranges!(errors)
    validate_no_downgrades!(errors)
    validate_ascension_caps!(errors)
    validate_skill_downgrades!(errors)
    validate_forte_nodes!(errors)

    raise ValidationError, errors.join("|") unless errors.empty?
  end

  def validate_no_changes!(errors)
    return unless @current_level == @target_level &&
                  @current_ascension_rank == @target_ascension_rank &&
                  @current_skill_levels == @target_skill_levels

    errors << "Nothing changed. Update at least one target."
  end

  def validate_level_ranges!(errors)
    unless @current_level.between?(1, 90)
      errors << "Current level invalid: #{@current_level}. Must be 1-90."
    end
    unless @target_level.between?(1, 90)
      errors << "Target level invalid: #{@target_level}. Must be 1-90."
    end
  end

  def validate_skill_ranges!(errors)
    validate_skill_hash_range!("Current", @current_skill_levels, errors)
    validate_skill_hash_range!("Target", @target_skill_levels, errors)
  end

  def validate_skill_hash_range!(label, skill_levels, errors)
    skill_levels.each do |skill_name, level|
      unless level.between?(1, 10)
        errors << "#{label} #{skill_name.to_s.titleize}: #{level} invalid. Must be 1-10."
      end
    end
  end

  def validate_no_downgrades!(errors)
    if @target_level < @current_level
      errors << "Target level (#{@target_level}) can't be less than current (#{@current_level})."
    end
    if @target_ascension_rank < @current_ascension_rank
      errors << "Target rank (#{@target_ascension_rank}) can't be less than current (#{@current_ascension_rank})."
    end
  end

  def validate_ascension_caps!(errors)
    validate_level_within_cap!("Current", @current_level, @current_ascension_rank, errors)
    validate_level_within_cap!("Target", @target_level, @target_ascension_rank, errors)
  end

  def validate_level_within_cap!(label, level, rank, errors)
    max = ASCENSION_LEVEL_CAPS[rank]
    if max.nil?
      errors << "#{label} level #{level} exceeds max for rank #{rank} (#{max})."
      return
    end

    if level > max
      errors << "#{label} level #{level} exceeds max for rank #{rank} (#{max})."
    end

    if rank > 0
      min = ASCENSION_LEVEL_CAPS[rank - 1]
      if level < min
        errors << "Rank #{rank} needs at least level #{min}, got #{level}."
      end
    end
  end

  def validate_skill_downgrades!(errors)
    @current_skill_levels.each do |skill_name, current_level|
      target_level = @target_skill_levels[skill_name]
      next unless target_level && target_level < current_level

      errors << "#{skill_name.to_s.titleize}: target (#{target_level}) < current (#{current_level})."
    end
  end

  def validate_forte_nodes!(errors)
    @forte_node_upgrades.each do |node_key, state|
      unless FORTE_NODES_MAP.include?(node_key)
        errors << "Invalid forte node: #{node_key}."
      end
      unless [ 0, 1 ].include?(state)
        errors << "#{node_key}: state must be 0 or 1, got #{state}."
      end
    end
  end

  def shell_credit_id
    @shell_credit_id ||= Material.find_by!(name: "Shell Credit").id
  end

  def basic_potion
    @basic_potion ||= Material.find_by!(name: "Basic Resonance Potion")
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
    ascension_model = @resonator.name.start_with?("Rover") ? RoverAscensionCost : ResonatorAscensionCost
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

      cost_identifier = FORTE_NODES_MAP[node_key]
      next unless cost_identifier.present?

      forte_node_costs = ForteNodeCost.where(node_identifier: cost_identifier)
      add_materials(forte_node_costs)
    end
  end
end
