class PlanForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :plan_type, :string
  attribute :subject_id, :integer
  attribute :current_level, :integer, default: 1
  attribute :target_level, :integer, default: 90
  attribute :current_ascension_rank, :integer, default: 0
  attribute :target_ascension_rank, :integer, default: 6

  %w[basic_attack resonance_skill forte_circuit resonance_liberation intro_skill].each do |skill|
    attribute "#{skill}_current".to_sym, :integer, default: 1
    attribute "#{skill}_target".to_sym, :integer, default: 10
    attribute "#{skill}_node_1".to_sym, :integer, default: 1
    attribute "#{skill}_node_2".to_sym, :integer, default: 1
  end

  def save(user, guest_token, existing_plan = nil)
    plan = existing_plan || Plan.new(user: user, guest_token: guest_token, plan_type: plan_type)
    subject = (plan_type == "Resonator" ? Resonator : Weapon).find(subject_id)

    plan.plan_data = {
      input: build_input_data(subject),
      output: run_planner_service(subject)
    }

    plan.save ? plan : (errors.merge!(plan.errors) and false)
  end

  # Transformation from JSONB -> Form Attributes
  def self.from_plan(plan)
    input = plan.plan_data["input"]

    attributes = {
      plan_type: plan.plan_type,
      subject_id: input["subject_id"],
      current_level: input["current_level"],
      target_level: input["target_level"],
      current_ascension_rank: input["current_ascension_rank"],
      target_ascension_rank: input["target_ascension_rank"]
    }

    if plan.plan_type == "Resonator"
      %w[current target].each do |state|
        input["#{state}_skill_levels"]&.each do |skill, value|
          attributes["#{skill}_#{state}"] = value
        end
      end

      input["forte_node_upgrades"]&.each do |node_name, value|
        attributes["#{node_name}"] = value
      end
    end

    new(attributes)
  end

  private

  def build_input_data(subject)
    # Merges levels, ranks, skills, and forte hashes into the JSONB input key
    {
      subject_name: subject_name,
      subject_id: subject_id,
      current_level: current_level,
      target_level: target_level,
      current_ascension_rank: current_ascension_rank,
      target_ascension_rank: target_ascension_rank
    }.tap do |h|
      h.merge!(resonator_input_data) if plan_type == "Resonator"
    end
  end

  def run_planner_service(subject)
    planner = if plan_type == "Resonator"
      ResonatorAscensionPlanner.new(
        resonator: subject,
        **base_planner_params,
        **resonator_input_data
      )
    else
      WeaponAscensionPlanner.new(
        weapon: subject,
        **base_planner_params
      )
    end

    planner.call
  end

  def base_planner_params
    {
      current_level: current_level,
      target_level: target_level,
      current_ascension_rank: current_ascension_rank,
      target_ascension_rank: target_ascension_rank
    }
  end

  def resonator_input_data
    {
      current_skill_levels: map_current_skill_levels,
      target_skill_levels: map_target_skill_levels,
      forte_node_upgrades: map_forte_nodes_upgrades
    }
  end

  def map_current_skill_levels
    {
      basic_attack: basic_attack_current,
      resonance_skill: resonance_skill_current,
      forte_circuit: forte_circuit_current,
      resonance_liberation: resonance_liberation_current,
      intro_skill: intro_skill_current
    }
  end

  def map_target_skill_levels
    {
      basic_attack: basic_attack_target,
      resonance_skill: resonance_skill_target,
      forte_circuit: forte_circuit_target,
      resonance_liberation: resonance_liberation_target,
      intro_skill: intro_skill_target
    }
  end

  def map_forte_nodes_upgrades
    {
      basic_attack_node_1: basic_attack_node_1.to_i,
      basic_attack_node_2: basic_attack_node_2.to_i,
      resonance_skill_node_1: resonance_skill_node_1.to_i,
      resonance_skill_node_2: resonance_skill_node_2.to_i,
      forte_circuit_node_1: forte_circuit_node_1.to_i,
      forte_circuit_node_2: forte_circuit_node_2.to_i,
      resonance_liberation_node_1: resonance_liberation_node_1.to_i,
      resonance_liberation_node_2: resonance_liberation_node_2.to_i,
      intro_skill_node_1: intro_skill_node_1.to_i,
      intro_skill_node_2: intro_skill_node_2.to_i
    }
  end
end
