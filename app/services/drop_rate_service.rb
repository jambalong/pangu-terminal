class DropRateService < ApplicationService
  EXP_MATERIAL_TYPES = %w[resonator_exp weapon_exp].freeze

  def initialize(material, deficit, sol3_phase)
    raise ArgumentError, "material must be a Material" unless material.is_a?(Material)
    raise ArgumentError, "deficit must be an integer" unless deficit.is_a?(Integer)
    raise ArgumentError, "sol3_phase must be an integer" unless sol3_phase.is_a?(Integer)

    @material = material
    @deficit = deficit
    @sol3_phase = sol3_phase
  end

  def call
    return {} if @deficit == 0

    results = {}

    @material.sources.each do |source|
      avg_quantity = if exp_material?
        calculate_exp_avg_quantity(source)
      else
        find_drop_rate(source)&.avg_quantity
      end

      next if avg_quantity.nil? || avg_quantity == 0

      estimated_runs = (@deficit / avg_quantity).ceil.to_i
      waveplate_cost = estimated_runs * source.waveplate_cost

      results[source.name] = {
        estimated_runs: estimated_runs,
        waveplate_cost: waveplate_cost
      }
    end

    results
  end

  private

  def exp_material?
    EXP_MATERIAL_TYPES.include?(@material.material_type)
  end

  def calculate_exp_avg_quantity(source)
    rarity_2_exp_value = @material.exp_value
    return nil if rarity_2_exp_value.nil? || rarity_2_exp_value == 0

    drop_rates = DropRate.where(
      source: source,
      sol3_phase: @sol3_phase,
      material_type: @material.material_type
    )

    return nil if drop_rates.empty?

    exp_materials = Material.where(material_type: @material.material_type).index_by(&:rarity)

    total_rarity_2_equivalent = drop_rates.sum do |drop_rate|
      exp_material = exp_materials[drop_rate.rarity]
      next 0 unless exp_material

      drop_rate.avg_quantity * (exp_material.exp_value / rarity_2_exp_value.to_f)
    end

    total_rarity_2_equivalent
  end

  def find_drop_rate(source)
    DropRate.where(
      source: source,
      rarity: @material.rarity,
      material_type: @material.material_type
    ).where("sol3_phase <= ?", @sol3_phase).order(sol3_phase: :desc).first
  end
end
