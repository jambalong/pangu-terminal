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
end
