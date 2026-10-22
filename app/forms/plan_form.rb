class PlanForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :id, :integer
  attribute :subject_type, :string
  attribute :subject_id, :integer
  attribute :subject_name, :string
  attribute :current_level, :integer, default: 1
  attribute :target_level, :integer, default: 90
  attribute :current_ascension_rank, :integer, default: 0
  attribute :target_ascension_rank, :integer, default: 6

  SKILLS = %w[basic_attack resonance_skill forte_circuit resonance_liberation intro_skill].freeze

  SKILLS.each do |skill|
    attribute "#{skill}_current".to_sym, :integer, default: 1
    attribute "#{skill}_target".to_sym, :integer, default: 10
    attribute "#{skill}_node_1".to_sym, :integer, default: 1
    attribute "#{skill}_node_2".to_sym, :integer, default: 1
  end

  CORE_ATTRIBUTES = %i[
    id subject_type subject_id current_level target_level current_ascension_rank target_ascension_rank
  ].freeze

  # Every attribute the planner form may submit; PlansController permits exactly these.
  def self.permitted_params
    CORE_ATTRIBUTES + SKILLS.flat_map do |skill|
      [ :"#{skill}_current", :"#{skill}_target", :"#{skill}_node_1", :"#{skill}_node_2" ]
    end
  end

  attr_reader :plan

  def persisted?
    id.present?
  end

  # Runs the planner for the current attributes. Single source of truth for the
  # shape stored in plans.plan_data; used by #save and by PlanRecomputer.
  def plan_data
    apply_defaults_to_blanks

    subject = subject_type.constantize.find(subject_id)

    {
      input: build_input_data(subject),
      output: run_planner_service(subject)
    }
  end

  def save(user, guest_token, existing_plan = nil)
    plan = existing_plan || Plan.new(user: user, guest_token: guest_token)
    plan.subject_type = subject_type
    plan.subject_id = subject_id
    plan.plan_data = plan_data

    if plan.save
      plan
    else
      errors.merge!(plan.errors)
      false
    end
  end

  def self.model_name
    ActiveModel::Name.new(self, nil, "Plan")
  end

  # Transformation from JSONB -> Form Attributes
  def self.from_plan(plan)
    input = plan.plan_data&.dig("input") || {}

    attributes = {
      id: plan.id,
      subject_type: plan.subject_type,
      subject_id: plan.subject_id,
      current_level: input["current_level"],
      target_level: input["target_level"],
      current_ascension_rank: input["current_ascension_rank"],
      target_ascension_rank: input["target_ascension_rank"]
    }

    if plan.subject_type == "Resonator"
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

  def apply_defaults_to_blanks
    self.attributes.each do |attr_name, value|
      if value.blank?
        default_value = self.class._default_attributes[attr_name]&.value
        public_send("#{attr_name}=", default_value) unless default_value.nil?
      end
    end
  end

  def build_input_data(subject)
    # Merges levels, ranks, skills, and forte hashes into the JSONB input key
    {
      subject_name: subject.name,
      current_level: current_level,
      target_level: target_level,
      current_ascension_rank: current_ascension_rank,
      target_ascension_rank: target_ascension_rank
    }.tap do |h|
      h.merge!(resonator_input_data) if subject_type == "Resonator"
    end
  end

  def run_planner_service(subject)
    planner = if subject_type == "Resonator"
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
    SKILLS.to_h { |skill| [ skill.to_sym, public_send("#{skill}_current") ] }
  end

  def map_target_skill_levels
    SKILLS.to_h { |skill| [ skill.to_sym, public_send("#{skill}_target") ] }
  end

  def map_forte_nodes_upgrades
    SKILLS.flat_map { |skill| %w[node_1 node_2].map { |node| "#{skill}_#{node}" } }
          .to_h { |name| [ name.to_sym, public_send(name).to_i ] }
  end
end
