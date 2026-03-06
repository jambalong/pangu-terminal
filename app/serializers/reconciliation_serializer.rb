class ReconciliationSerializer
  def initialize(reconciliation, materials_lookup)
    @reconciliation = reconciliation
    @materials_lookup = materials_lookup
  end

  def to_h
    @reconciliation.each_with_object({}) do |(material_id, data), result|
      material = @materials_lookup[material_id]
      next unless material

      result[material.snake_case_name] = {
        needed: data[:needed],
        owned: data[:owned],
        deficit: data[:deficit],
        satisfied: data[:satisfied],
        satisfied_by_higher_rarity: data[:used_higher_rarity]
      }

      result[material.snake_case_name][:can_synthesize] = data.dig(:synthesis_opportunity, :can_convert) || 0
    end
  end
end
