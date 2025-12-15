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
end
