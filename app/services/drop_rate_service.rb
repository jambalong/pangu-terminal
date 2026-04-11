class DropRateService < ApplicationService
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
      drop_rate = DropRate.find_by(
        source: source,
        sol3_phase: @sol3_phase,
        rarity: @material.rarity,
        material_type: @material.material_type
      )

      next if drop_rate.nil?

      estimated_runs = (@deficit / drop_rate.avg_quantity).ceil.to_i
      waveplate_cost = estimated_runs * source.waveplate_cost

      results[source.name] = {
        estimated_runs: estimated_runs,
        waveplate_cost: waveplate_cost
      }
    end

    results
  end
end
