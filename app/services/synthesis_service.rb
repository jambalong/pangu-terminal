class SynthesisService
  def initialize(owned, required)
    @owned = owned
    @required = required
    @materials = Material.where(id: @owned.keys).index_by(&:id)
  end

  def reconcile
    result = {}

    @required.each do |material_id, needed|
      owned = @owned[material_id] || 0
      material = fetch_material(material_id)

      satisfied = exp_potion?(material) ? calculate_exp_satisfaction(material) : owned
      deficit = [ needed - satisfied, 0 ].max
      used_higher_rarity = satisfied > owned
      craftable_count = find_craftable_count(material, deficit)

      result[material_id] = {
        needed: needed,
        owned: owned,
        satisfied: satisfied,
        used_higher_rarity: used_higher_rarity,
        deficit: deficit,
        fulfilled: deficit == 0,
        craftable_count: craftable_count
      }
    end

    result
  end

  private

  def fetch_material(material_id)
    @materials[material_id]
  end

  def exp_potion?(material)
    material.material_type.in?(%w[resonator_exp weapon_exp])
  end

  def calculate_exp_satisfaction(material)
    # Plans always express EXP requirements in rarity-2 terms
    return 0 unless material.rarity == 2

    exp_group = @materials.values.select { |m| same_exp_type?(material, m) }
    satisfied_exp = exp_group.sum { |m| (@owned[m.id] || 0) * (m.exp_value || 0) }
    (satisfied_exp / material.exp_value).floor
  end

  def same_exp_type?(material, other)
    material.material_type == other.material_type
  end

  def find_craftable_count(material, deficit)
    return nil unless synthesizable?(material)
    return nil if deficit == 0

    lower_tier_material = find_lower_tier(material)
    return nil unless lower_tier_material

    owned = @owned[lower_tier_material.id] || 0
    needed = @required[lower_tier_material.id] || 0
    surplus = [ owned - needed, 0 ].max

    craftable_count = surplus / 3
    return nil if craftable_count == 0

    craftable_count
  end

  def synthesizable?(material)
    material.item_group_id.present?
  end

  def find_lower_tier(material)
    @materials.values.find do |m|
      m.item_group_id == material.item_group_id && m.rarity == material.rarity - 1
    end
  end
end
