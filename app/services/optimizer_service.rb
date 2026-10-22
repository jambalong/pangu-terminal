# Compares a plan's requirements to a user's inventory and estimates the farming
# needed to close each deficit. Returns the data the optimizer views render.
class OptimizerService < ApplicationService
  def initialize(user:, plan:)
    @user = user
    @plan = plan
  end

  def call
    needed = (@plan.plan_data.dig("output") || {}).transform_keys(&:to_i)
    owned = @user.inventory_items.index_by(&:material_id).transform_values(&:quantity)
    synthesis = SynthesisService.new(owned, needed)
    deficits = synthesis.reconcile.select { |_material_id, data| data[:deficit] > 0 }
    materials = Material.includes(:sources).where(id: deficits.keys).index_by(&:id)

    results = materials.each_with_object({}) do |(material_id, material), memo|
      deficit = deficits[material_id][:deficit]
      memo[material_id] = {
        material: material,
        deficit: deficit,
        sources: DropRateService.call(material, deficit, @user.sol3_phase)
      }
    end

    { results: results, chain_coverage: synthesis.chain_coverage, totals: source_totals(results) }
  end

  private

  def source_totals(results)
    by_source = Hash.new { |hash, source_name| hash[source_name] = { estimated_runs: 0, waveplate_cost_per_run: 0 } }

    results.each_value do |data|
      data[:sources].each do |source_name, source_data|
        if source_data[:estimated_runs] > by_source[source_name][:estimated_runs]
          by_source[source_name] = {
            estimated_runs: source_data[:estimated_runs],
            waveplate_cost_per_run: source_data[:waveplate_cost_per_run]
          }
        end
      end
    end

    total_runs = by_source.values.sum { |source| source[:estimated_runs] }
    total_wp = by_source.values.sum { |source| source[:estimated_runs] * source[:waveplate_cost_per_run] }

    { total_runs: total_runs, total_wp: total_wp }
  end
end
