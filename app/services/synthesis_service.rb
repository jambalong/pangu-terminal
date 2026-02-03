class SynthesisService
  def initialize(inventory_hash, requirements_hash)
    @inventory = inventory_hash
    @requirements = requirements_hash
    @materials_cache = {}
  end

  def reconcile_inventory
    reconciliation = {}

    @requirements.each do |material_id, needed_qty|
      owned_qty = @inventory[material_id] || 0
      material = get_material(material_id)

      satisfied_qty = calculate_satisfied_qty(material, owned_qty, needed_qty)
      deficit = [ needed_qty - satisfied_qty, 0 ].max

      synthesis_opportunity = find_synthesis_opportunity(material, owned_qty, needed_qty)

      reconciliation[material_id] = {
        needed: needed_qty,
        owned: owned_qty,
        deficit: deficit,
        satisfied: deficit == 0,
        synthesis_opportunity: synthesis_opportunity
      }
    end

    reconciliation
  end

  private

  def get_material(material_id)
    @materials_cache[material_id] ||= Material.find_by(id: material_id)
  end

  def calculate_satisfied_qty(material, owned_qty, needed_qty)
    exp_potion?(material) ? calculate_exp_potion_satisfaction(material, needed_qty) : owned_qty
  end

  def calculate_exp_potion_satisfaction(material, needed_qty)
    return 0 unless material

    current_rarity = material.rarity || 2
    satisfied_exp = 0

    @inventory.each do |inv_material_id, owned_qty|
      inv_material = get_material(inv_material_id)

      next unless same_exp_potion_type?(material, inv_material)
      next unless inv_material&.rarity.to_i >= current_rarity.to_i

      total_exp_from_this = owned_qty * (inv_material.exp_value || 0)
      satisfied_exp +=  total_exp_from_this
    end

    material_exp_value = material.exp_value
    (satisfied_exp / material_exp_value).floor
  end

  def same_exp_potion_type?(material1, material2)
    return false unless material1 && material2

    exp_potion?(material1) &&
      exp_potion?(material2) &&
      material1.material_type == material2.material_type
  end

  def exp_potion?(material)
    return false unless material
    material.material_type.in?(%w[ResonatorEXP WeaponEXP])
  end

  def find_synthesis_opportunity(material, owned_qty, needed_qty)
    return nil unless synthesizable?(material)

    deficit = [ needed_qty - owned_qty, 0 ].max
    return nil if deficit == 0

    lower_tier = find_lower_tier(material)
    return nil unless lower_tier

    lower_tier_owned = @inventory[lower_tier.id] || 0
    lower_tier_needed = @requirements[lower_tier.id] || 0
    lower_tier_surplus = [ lower_tier_owned - lower_tier_needed, 0 ].max

    can_convert = (lower_tier_surplus / 3).floor
    return nil if can_convert == 0

    {
      can_supplement: true,
      source_material_id: lower_tier.id,
      source_name: lower_tier.name,
      surplus_available: lower_tier_surplus,
      can_convert: can_convert
    }
  end

  def synthesizable?(material)
    return false unless material

    material.category.in?("Weapon and Skill Material") &&
      material.material_type.in?(%w[EnemyDrop ForgeryDrop])
  end

  def find_lower_tier(material)
    return nil unless material
    return nil if material.rarity <= 2

    Material.find_by(
      item_group_id: material.item_group_id,
      rarity: material.rarity - 1
    )
  end
end
