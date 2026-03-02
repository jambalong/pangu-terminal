class PlanSerializer
  def initialize(plan, materials_lookup)
    @plan = plan
    @materials_lookup = materials_lookup
  end

  def to_h
    {
      id: @plan.id,
      subject_name: @plan.subject.name,
      subject_type: @plan.subject_type,
      configuration: configuration,
      requirements: requirements,
      created_at: @plan.created_at,
      updated_at: @plan.updated_at
    }
  end

  private

  def configuration
    input = @plan.plan_data.dig("input")

    base = {
      current_level: input["current_level"],
      target_level: input["target_level"],
      current_ascension_rank: input["current_ascension_rank"],
      target_ascension_rank: input["target_ascension_rank"]
    }

    if @plan.subject_type == "Resonator"
      base.merge(resonator_configuration(input))
    else
      base
    end
  end

  def resonator_configuration(input)
    current_skills = input["current_skill_levels"]
    target_skills = input["target_skill_levels"]
    forte_nodes = input["forte_node_upgrades"]

    {
      current_skill_levels: {
        basic_attack: current_skills["basic_attack"],
        resonance_skill: current_skills["resonance_skill"],
        forte_circuit: current_skills["forte_circuit"],
        resonance_liberation: current_skills["resonance_liberation"],
        intro_skill: current_skills["intro_skill"]
      },
      target_skill_levels: {
        basic_attack: target_skills["basic_attack"],
        resonance_skill: target_skills["resonance_skill"],
        forte_circuit: target_skills["forte_circuit"],
        resonance_liberation: target_skills["resonance_liberation"],
        intro_skill: target_skills["intro_skill"]
      },
      forte_node_upgrades: {
        basic_attack: {
          stat_bonus_tier_1: forte_nodes["basic_attack_node_1"] == 1,
          stat_bonus_tier_2: forte_nodes["basic_attack_node_2"] == 1
        },
        resonance_skill: {
          stat_bonus_tier_1: forte_nodes["resonance_skill_node_1"] == 1,
          stat_bonus_tier_2: forte_nodes["resonance_skill_node_2"] == 1
        },
        forte_circuit: {
          inherent_skill_tier_1: forte_nodes["forte_circuit_node_1"] == 1,
          inherent_skill_tier_2: forte_nodes["forte_circuit_node_2"] == 1
        },
        resonance_liberation: {
          stat_bonus_tier_1: forte_nodes["resonance_liberation_node_1"] == 1,
          stat_bonus_tier_2: forte_nodes["resonance_liberation_node_2"] == 1
        },
        intro_skill: {
          stat_bonus_tier_1: forte_nodes["intro_skill_node_1"] == 1,
          stat_bonus_tier_2: forte_nodes["intro_skill_node_2"] == 1
        }
      }
    }
  end

  def requirements
    output = @plan.plan_data.dig("output")

    output.each_with_object({}) do |(material_id, quantity), result|
      material = @materials_lookup[material_id.to_i]
      next unless material

      result[material.snake_case_name] = quantity
    end
  end
end
