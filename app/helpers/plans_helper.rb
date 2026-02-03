module PlansHelper
  def forte_configs
    [
      { label: "Basic Attack", key: "basic_attack" },
      { label: "Resonance Skill", key: "resonance_skill" },
      { label: "Forte Circuit", key: "forte_circuit", inherent: true },
      { label: "Resonance Liberation", key: "resonance_liberation" },
      { label: "Intro Skill", key: "intro_skill" }
    ]
  end

  def format_node_name(key)
    key.to_s.humanize.titleize
  end

  def sorted_plan_materials(output_hash)
    output_hash.sort_by { |mat_id, _|
      material = @materials_lookup[mat_id.to_i]
      material_sort_key(material)
    }
  end

  def material_sort_key(material)
    type_index = Material::MATERIAL_TYPE_ORDER.index(material.material_type) || 999
    [ type_index, material.id, material.rarity ]
  end
end
