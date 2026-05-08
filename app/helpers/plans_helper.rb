module PlansHelper
  def forte_configs(resonator = nil)
    forte_icons = resonator&.forte_icons || {}
    skill_icons = forte_icons["skill_icons"] || {}
    stat_icons  = forte_icons["stat_icons"]  || {}

    [
      { label: "Basic Attack", key: "basic_attack", skill_icon: skill_icons["basic_attack"], stat_icon: stat_icons["stat_a"] },
      { label: "Resonance Skill", key: "resonance_skill", skill_icon: skill_icons["resonance_skill"], stat_icon: stat_icons["stat_b"] },
      { label: "Forte Circuit", key: "forte_circuit", skill_icon: skill_icons["forte_circuit"], inherent: true,  inherent_1_icon: skill_icons["inherent_skill_1"], inherent_2_icon: skill_icons["inherent_skill_2"] },
      { label: "Resonance Liberation", key: "resonance_liberation", skill_icon: skill_icons["resonance_liberation"], stat_icon: stat_icons["stat_b"] },
      { label: "Intro Skill", key: "intro_skill", skill_icon: skill_icons["intro_skill"], stat_icon: stat_icons["stat_a"] }
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
