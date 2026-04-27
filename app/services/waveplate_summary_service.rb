class WaveplateSummaryService < ApplicationService
  def initialize(plan, sol3_phase)
    @plan = plan
    @sol3_phase = sol3_phase
  end

  def call
    needed = (@plan.plan_data.dig("output") || {}).transform_keys(&:to_i)
    owned = @plan.user.inventory_items.index_by(&:material_id).transform_values(&:quantity)
    reconciled = SynthesisService.new(owned, needed).reconcile
    deficits = reconciled.select { |material_id, data| data[:deficit] > 0 }

    return {} if deficits.empty?

    materials = Material.where(id: deficits.keys).index_by(&:id)
    results = {}

    materials.each do |material_id, material|
      deficit = deficits[material_id][:deficit]
      sources = DropRateService.call(material, deficit, @sol3_phase)

      next if sources.empty?

      first_source = sources.values.first

      results[material.snake_case_name] = {
        deficit: deficit,
        source_type: first_source[:source_type],
        sources: sources.keys,
        estimated_runs: first_source[:estimated_runs],
        waveplate_cost: first_source[:waveplate_cost]
      }
    end

    results
  end
end
