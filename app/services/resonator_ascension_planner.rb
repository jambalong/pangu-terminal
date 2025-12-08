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
end
