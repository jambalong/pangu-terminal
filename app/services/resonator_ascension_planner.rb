class ResonatorAscensionPlanner < ApplicationService
  SHELL_CREDIT_ID = Material.find_by(name: "Shell Credit").id

  FORTE_NODES_MAP = {
    "Basic Attack Node 1" => "Stat Bonus Tier 1",
    "Basic Attack Node 2" => "Stat Bonus Tier 2",
    "Resonance Skill Node 1" => "Stat Bonus Tier 1",
    "Resonance Skill Node 2" => "Stat Bonus Tier 2",

    "Forte Circuit Node 1" => "Inherent Skill Tier 1",
    "Forte Circuit Node 2" => "Inherent Skill Tier 2",

    "Resonance Liberation Node 1" => "Stat Bonus Tier 1",
    "Resonance Liberation Node 2" => "Stat Bonus Tier 2",
    "Intro Skill Node 1" => "Stat Bonus Tier 1",
    "Intro Skill Node 2" => "Stat Bonus Tier 2"
  }

  def initialize(
    resonator:, current_level:, target_level:,
    current_ascension_rank:, target_ascension_rank:,
    current_skill_levels:, target_skill_levels:,
    current_forte_nodes:, target_forte_nodes:
  )
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
    calculate_ascension_costs
    calculate_skill_leveling_costs
    calculate_forte_node_costs

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
       @current_ascension_rank == @target_ascension_rank &&
       @current_skill_levels == @target_skill_levels &&
       @current_forte_nodes == @target_forte_nodes
      errors << "Atleast one target value must be different from corresponding current value"
    end

    # this checks for impossible downgrades (level and ascension rank)
    if @target_level < @current_level &&
       @target_ascension_rank < @current_ascension_rank
      errors << "Target level value must be greater than or equal to current level value"
    end

    @current_skill_levels.each do |skill_name, current_level|
      target_level = @target_skill_levels[skill_name]

      if target_level && target_level < current_level
        errors << "Target skill level value must be greater than or equal to current skill level value"
      end
    end

    @current_forte_nodes.each do |node_name, current_upgrade|
      target_upgrade = @target_forte_nodes[node_name]

      if target_upgrade && target_upgrade < current_upgrade
        errors << "Target forte nodes value must be greater than or equal to current forte nodes value"
      end
    end

    raise "Input Validation Error: #{errors.join('; ')}" unless errors.empty?
  end

  def calculate_leveling_costs
    level_costs = ResonatorLevelCost.where(level: @current_level..@target_level)
    total_exp_required = 0

    level_costs.each do |level_cost|
      total_exp_required += level_cost.exp_required
      @materials_totals[SHELL_CREDIT_ID] += level_cost.credit_cost
    end

    convert_exp_to_potions(total_exp_required)
  end

  def convert_exp_to_potions(total_exp_required)
    basic_potion = Material.find_by(name: "Basic Resonance Potion")
    @materials_totals[basic_potion.id] += total_exp_required / basic_potion.exp_value
  end

  def calculate_ascension_costs
    rover_resonators = [ "Rover-Aero", "Rover-Havoc", "Rover-Spectro" ]
    ascension_cost_model = rover_resonators.include?(@resonator.name) ? RoverAscensionCost : ResonatorAscensionCost

    required_ascension_rank = (@current_ascension_rank + 1..@target_ascension_rank)
    ascension_costs = ascension_cost_model.where(ascension_rank: required_ascension_rank)
    materials_by_resonator = ResonatorMaterialMap.where(resonator_id: @resonator.id).to_a

    ascension_costs.each do |ascension_cost|
      if ascension_cost.material_type == "Credit"
        @materials_totals[SHELL_CREDIT_ID] += ascension_cost.quantity
        next
      end

      found_map = materials_by_resonator.find do |map_record|
        map_record.material_type == ascension_cost.material_type &&
        map_record.rarity == ascension_cost.rarity
      end

      if found_map
        @materials_totals[found_map.material_id] += ascension_cost.quantity
      end
    end
  end

  def calculate_skill_leveling_costs
    materials_to_resonator = ResonatorMaterialMap.where(resonator_id: @resonator.id).to_a
    materials_to_weapon_type = WeaponTypeMaterial.where(weapon_type: @resonator.weapon_type).to_a

    @current_skill_levels.each do |skill_name, current_level|
      target_level = @target_skill_levels[skill_name]
      next unless target_level && target_level > current_level

      required_level_range = (current_level + 1..target_level)
      skill_costs = SkillCost.where(level: required_level_range)

      skill_costs.each do |skill_cost|
        if skill_cost.material_type == "Credit"
          @materials_totals[SHELL_CREDIT_ID] += skill_cost.quantity
          next
        end

        if skill_cost.material_type == "ForgeryDrop"
          found_map = materials_to_weapon_type.find do |map_record|
            map_record.rarity == skill_cost.rarity
          end

          if found_map
            @materials_totals[found_map.material_id] += skill_cost.quantity
          end
          next
        end

        found_map = materials_to_resonator.find do |map_record|
          map_record.material_type == skill_cost.material_type &&
          map_record.rarity == skill_cost.rarity
        end

        if found_map
          @materials_totals[found_map.material_id] += skill_cost.quantity
        end
      end
    end
  end
end
