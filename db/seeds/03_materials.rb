# Order:
# - credit
# - resonator_exp
# - weapon_exp
# - boss_drop
# - flower
# - enemy_drop
# - forgery_drop
# - weekly_boss_drop

# ===============================================
# 03. MATERIALS
# ===============================================
puts "  --> Creating Materials..."

def seed_material_set(data_array, type, category, default_exp: 0, grouped: false, default_description: nil)
  current_group_id = nil

  data_array.each do |data|
    if grouped && data[:rarity] == 2
      current_group_id = data[:name].parameterize
    end

    filename = data[:name].downcase
                        .gsub(/['"#&]/, '')
                        .strip
                        .gsub(/\s+/, '-')

    material = Material.find_or_initialize_by(name: data[:name])
    material.update!(
      rarity: data[:rarity],
      material_type: type,
      category: category,
      image_url: "/images/materials/#{filename}.png",
      exp_value: data[:exp] || default_exp,
      item_group_id: grouped ? current_group_id : nil,
      description: data[:description] || default_description
    )

    # e.g. "Xiangli Yao" => xiangli_yao
    # e.g. "Rover-Aero" => rover_aero
    # e.g. "Lux & Umbra" => :lux_umbra
    # e.g. "Gauntlets#21D" => :gauntlets21d
    # e.g. "Loong's Pearl" => :loongs_pearl
    lookup_key = filename.gsub('-', '_')
    $SEED_DATA[lookup_key.to_sym] = material
  end
end

# --- Universal Currency ---
shell_credit = Material.find_or_initialize_by(name: "Shell Credit")
shell_credit.update!(
  rarity: 3,
  material_type: "credit",
  category: "Universal Currency",
  image_url: "/images/materials/shell-credit.png",
  description: "The universal currency issued by Huanglong, officially recognized across many regions."
)

$SEED_DATA[:shell_credit] = shell_credit

# --- Resonator & Weapon EXP Materials ---
RESONATOR_EXP_DATA = [
  { name: "Basic Resonance Potion", rarity: 2, exp: 1000, description: "Provides 1,000 Resonator EXP." },
  { name: "Medium Resonance Potion", rarity: 3, exp: 3000, description: "Provides 3,000 Resonator EXP." },
  { name: "Advanced Resonance Potion", rarity: 4, exp: 8000, description: "Provides 8,000 Resonator EXP." },
  { name: "Premium Resonance Potion", rarity: 5, exp: 20000, description: "Provides 20,000 Resonator EXP." }
].freeze

WEAPON_EXP_DATA = [
  { name: "Basic Energy Core", rarity: 2, exp: 1000, description: "Provides 1,000 Weapon EXP." },
  { name: "Medium Energy Core", rarity: 3, exp: 3000, description: "Provides 3,000 Weapon EXP." },
  { name: "Advanced Energy Core", rarity: 4, exp: 8000, description: "Provides 8,000 Weapon EXP." },
  { name: "Premium Energy Core", rarity: 5, exp: 20000, description: "Provides 20,000 Weapon EXP." }
].freeze

seed_material_set(RESONATOR_EXP_DATA, "resonator_exp", "Resonator EXP Material")
seed_material_set(WEAPON_EXP_DATA, "weapon_exp", "Weapon EXP Material")

# --- Resonator Ascension Materials ---
BOSS_DROP_DATA = [
  { name: "Abyssal Husk", rarity: 4, description: "Embers of Glory's drop, used for Resonator Ascension." },
  { name: "Blazing Bone", rarity: 4, description: "Dragon of Dirge's drop, used for Resonator Ascension." },
  { name: "Blighted Crown of Puppet King", rarity: 4, description: "The False Sovereign's drop, used for Resonator Ascension." },
  { name: "Burning Judgment", rarity: 4, description: "Reactor Husk's drop, used for Resonator Ascension." },
  { name: "Cleansing Conch", rarity: 4, description: "The Queen of the Night's drop, used for Resonator Ascension." },
  { name: "Elegy Tacet Core", rarity: 4, description: "Mourning Aix's drop, used for Resonator Ascension." },
  { name: "Gold-Dissolving Feather", rarity: 4, description: "The Impermanence Heron's drop, a Resonator's Ascension item." },
  { name: "Group Abomination Tacet Core", rarity: 4, description: "Mech Abomination's drop, used for Resonator Ascension." },
  { name: "Hidden Thunder Tacet Core", rarity: 4, description: "Tempest Mephis's drop, Resonator ascension item." },
  { name: "Mysterious Code", rarity: 5, description: "Used for Rover's Ascension." },
  { name: "Our Choice", rarity: 4, description: "Nameless Explorer's drop, used for Resonator Ascension." },
  { name: "Platinum Core", rarity: 4, description: "Sentry Construct's drop, used for Resonator Ascension." },
  { name: "Rage Tacet Core", rarity: 4, description: "Inferno Rider's drop, used for Resonator Ascension." },
  { name: "Roaring Rock Fist", rarity: 4, description: "Feilian Beringal's drop, used for Resonator Ascension." },
  { name: "Sound-Keeping Tacet Core", rarity: 4, description: "Lampylumen Myriad's drop, used for Resonator Ascension." },
  { name: "Strife Tacet Core", rarity: 4, description: "Crownless's drop, a Resonator's Ascension item." },
  { name: "Suncoveter's Reach", rarity: 4, description: "Hyvatia's drop, used for Resonator Ascension." },
  { name: "Thundering Tacet Core", rarity: 4, description: "Thundering Mephis's drop, used for Resonator Ascension." },
  { name: "Topological Confinement", rarity: 4, description: "Fallacy of No Return's drop, used for Resonator Ascension." },
  { name: "Truth in Lies", rarity: 4, description: "Fenrico's drop, used for Resonator Ascension." },
  { name: "Unfading Glory", rarity: 4, description: "Lioness of Glory's drop, used for Resonator Ascension." }
].freeze

seed_material_set(BOSS_DROP_DATA, "boss_drop", "Resonator Ascension Material")

# --- Ascension Materials ---
FLOWER_DATA = [
  # Jinzhou
  { name: "Belle Poppy", rarity: 1 },
  { name: "Coriolus", rarity: 1 },
  { name: "Iris", rarity: 1 },
  { name: "Lanternberry", rarity: 1 },
  { name: "Pecok Flower", rarity: 1 },
  { name: "Terraspawn Fungus", rarity: 1 },
  { name: "Violet Coral", rarity: 1 },
  { name: "Wintry Bell", rarity: 1 },

  # Mt. Firmament
  { name: "Loong's Pearl", rarity: 1 },
  { name: "Pavo Plum", rarity: 1 },

  # The Black Shores
  { name: "Nova", rarity: 1 },
  { name: "Summer Flower", rarity: 1 },

  # Rinascita
  { name: '"Afterlife"', rarity: 1 },
  { name: "Bamboo Iris", rarity: 1 },
  { name: "Bloodleaf Viburnum", rarity: 1 },
  { name: "Firecracker Jewelweed", rarity: 1 },
  { name: "Golden Fleece", rarity: 1 },
  { name: "Luminous Calendula", rarity: 1 },
  { name: "Seaside Cendrelis", rarity: 1 },
  { name: "Sliverglow Bloom", rarity: 1 },
  { name: "Stone Rose", rarity: 1 },
  { name: "Sword Acorus", rarity: 1 },

  # Lahai-Roi
  { name: "Arithmetic Shell", rarity: 1 },
  { name: "Edelschnee", rarity: 1 },
  { name: "Gemini Spore", rarity: 1 },
  { name: "Moss Amber", rarity: 1 },
  { name: "Rimewisp", rarity: 1 }
].freeze

seed_material_set(FLOWER_DATA, "flower", "Ascension Material", default_description: "A material used for Resonator Ascension.")

# --- Weapon and Skill Material (enemy_drop) ---
ENEMY_DROP_DATA = [
  # Whisperin Core Set
  { name: "LF Whisperin Core", rarity: 2 },
  { name: "MF Whisperin Core", rarity: 3 },
  { name: "HF Whisperin Core", rarity: 4 },
  { name: "FF Whisperin Core", rarity: 5 },

  # Howler Core Set
  { name: "LF Howler Core", rarity: 2 },
  { name: "MF Howler Core", rarity: 3 },
  { name: "HF Howler Core", rarity: 4 },
  { name: "FF Howler Core", rarity: 5 },

  # Polygon Core Set
  { name: "LF Polygon Core", rarity: 2 },
  { name: "MF Polygon Core", rarity: 3 },
  { name: "HF Polygon Core", rarity: 4 },
  { name: "FF Polygon Core", rarity: 5 },

  # Tidal Residuum Core Set
  { name: "LF Tidal Residuum Core", rarity: 2 },
  { name: "MF Tidal Residuum Core", rarity: 3 },
  { name: "HF Tidal Residuum Core", rarity: 4 },
  { name: "FF Tidal Residuum Core", rarity: 5 },

  # Ring Set
  { name: "Crude Ring", rarity: 2 },
  { name: "Basic Ring", rarity: 3 },
  { name: "Improved Ring", rarity: 4 },
  { name: "Tailored Ring", rarity: 5 },

  # Mask Set
  { name: "Mask of Constraint", rarity: 2 },
  { name: "Mask of Erosion", rarity: 3 },
  { name: "Mask of Distortion", rarity: 4 },
  { name: "Mask of Insanity", rarity: 5 },

  # Exoswarm Core Set
  { name: "LF Exoswarm Core", rarity: 2 },
  { name: "MF Exoswarm Core", rarity: 3 },
  { name: "HF Exoswarm Core", rarity: 4 },
  { name: "FF Exoswarm Core", rarity: 5 },

  # Mech Core Set
  { name: "LF Mech Core", rarity: 2 },
  { name: "MF Mech Core", rarity: 3 },
  { name: "HF Mech Core", rarity: 4 },
  { name: "FF Mech Core", rarity: 5 },

  # Exoswarm Pendant Set
  { name: "Fractured Exoswarm Pendant", rarity: 2 },
  { name: "Worn Exoswarm Pendant", rarity: 3 },
  { name: "Chipped Exoswarm Pendant", rarity: 4 },
  { name: "Intact Exoswarm Pendant", rarity: 5 }
].freeze

seed_material_set(ENEMY_DROP_DATA, "enemy_drop", "Weapon and Skill Material", grouped: true, default_description: "A material used for Weapon & Resonator Ascension and Skill Upgrade.")

# --- Weapon and Skill Material (forgery_drop) ---
FORGERY_DROP_DATA = [
  # Metallic Drip Set — Sword
  { name: "Inert Metallic Drip", rarity: 2, description: "A basic material used for Weapon Ascension and Skill Upgrade for Sword Resonators." },
  { name: "Reactive Metallic Drip", rarity: 3, description: "A medium material used for Weapon Ascension and Skill Upgrade for Sword Resonators." },
  { name: "Polarized Metallic Drip", rarity: 4, description: "An advanced material used for Weapon Ascension and Skill Upgrade for Sword Resonators." },
  { name: "Heterized Metallic Drip", rarity: 5, description: "A premium material used for Weapon Ascension and Skill Upgrade for Sword Resonators." },

  # Phlogiston Set — Pistols
  { name: "Impure Phlogiston", rarity: 2, description: "A basic material used for Weapon Ascension and Skill Upgrade for Pistols Resonators." },
  { name: "Extracted Phlogiston", rarity: 3, description: "A medium material used for Weapon Ascension and Skill Upgrade for Pistols Resonators." },
  { name: "Refined Phlogiston", rarity: 4, description: "An advanced material used for Weapon Ascension and Skill Upgrade for Pistols Resonators." },
  { name: "Flawless Phlogiston", rarity: 5, description: "A premium material used for Weapon Ascension and Skill Upgrade for Pistols Resonators." },

  # Helix Set — Rectifier
  { name: "Lento Helix", rarity: 2, description: "A basic material used for Weapon Ascension and Skill Upgrade for Rectifier Resonators." },
  { name: "Adagio Helix", rarity: 3, description: "A medium material used for Weapon Ascension and Skill Upgrade for Rectifier Resonators." },
  { name: "Andante Helix", rarity: 4, description: "An advanced material used for Weapon Ascension and Skill Upgrade for Rectifier Resonators." },
  { name: "Presto Helix", rarity: 5, description: "A premium material used for Weapon Ascension and Skill Upgrade for Rectifier Resonators." },

  # Waveworn Residue Set — Broadblade
  { name: "Waveworn Residue 210", rarity: 2, description: "A basic material used for Weapon Ascension and Skill Upgrade for Broadblade Resonators." },
  { name: "Waveworn Residue 226", rarity: 3, description: "A medium material used for Weapon Ascension and Skill Upgrade for Broadblade Resonators." },
  { name: "Waveworn Residue 235", rarity: 4, description: "An advanced material used for Weapon Ascension and Skill Upgrade for Broadblade Resonators." },
  { name: "Waveworn Residue 239", rarity: 5, description: "A premium material used for Weapon Ascension and Skill Upgrade for Broadblade Resonators." },

  # Cadence Set — Gauntlets
  { name: "Cadence Seed", rarity: 2, description: "A basic material used for Weapon Ascension and Skill Upgrade for Gauntlets Resonators." },
  { name: "Cadence Bud", rarity: 3, description: "A medium material used for Weapon Ascension and Skill Upgrade for Gauntlets Resonators." },
  { name: "Cadence Leaf", rarity: 4, description: "An advanced material used for Weapon Ascension and Skill Upgrade for Gauntlets Resonators." },
  { name: "Cadence Blossom", rarity: 5, description: "A premium material used for Weapon Ascension and Skill Upgrade for Gauntlets Resonators." },

  # Polarizer Set — Broadblade (Roya Frostlands)
  { name: "Broken Wing Polarizer", rarity: 2, description: "A basic material used for Weapon Ascension and Skill Upgrade for Broadblade Resonators." },
  { name: "Monowing Polarizer", rarity: 3, description: "A medium material used for Weapon Ascension and Skill Upgrade for Broadblade Resonators." },
  { name: "Polywing Polarizer", rarity: 4, description: "An advanced material used for Weapon Ascension and Skill Upgrade for Broadblade Resonators." },
  { name: "Layered Wing Polarizer", rarity: 5, description: "A premium material used for Weapon Ascension and Skill Upgrade for Broadblade Resonators." },

  # Combustor Set — Pistols (Roya Frostlands)
  { name: "Incomplete Combustor", rarity: 2, description: "A basic material used for Weapon Ascension and Skill Upgrade for Pistols Resonators." },
  { name: "Aftertune Combustor", rarity: 3, description: "A medium material used for Weapon Ascension and Skill Upgrade for Pistols Resonators." },
  { name: "Remnant Combustor", rarity: 4, description: "An advanced material used for Weapon Ascension and Skill Upgrade for Pistols Resonators." },
  { name: "Reverb Combustor", rarity: 5, description: "A premium material used for Weapon Ascension and Skill Upgrade for Pistols Resonators." },

  # String Set — Rectifier (Roya Frostlands)
  { name: "Spliced String", rarity: 2, description: "A basic material used for Weapon Ascension and Skill Upgrade for Rectifier Resonators." },
  { name: "Broken String", rarity: 3, description: "A medium material used for Weapon Ascension and Skill Upgrade for Rectifier Resonators." },
  { name: "Solidified String", rarity: 4, description: "An advanced material used for Weapon Ascension and Skill Upgrade for Rectifier Resonators." },
  { name: "Melodic String", rarity: 5, description: "A premium material used for Weapon Ascension and Skill Upgrade for Rectifier Resonators." },

  # Carved Crystal Set — Sword (Rinascita)
  { name: "LF Carved Crystal", rarity: 2, description: "A basic material used for Weapon Ascension and Skill Upgrade for Sword Resonators." },
  { name: "MF Carved Crystal", rarity: 3, description: "A medium material used for Weapon Ascension and Skill Upgrade for Sword Resonators." },
  { name: "HF Carved Crystal", rarity: 4, description: "An advanced material used for Weapon Ascension and Skill Upgrade for Sword Resonators." },
  { name: "FF Carved Crystal", rarity: 5, description: "A premium material used for Weapon Ascension and Skill Upgrade for Sword Resonators." },

  # Waveworn Shard Set — Gauntlets (Roya Frostlands)
  { name: "LF Waveworn Shard", rarity: 2, description: "A basic material used for Weapon Ascension and Skill Upgrade for Gauntlets Resonators." },
  { name: "MF Waveworn Shard", rarity: 3, description: "A medium material used for Weapon Ascension and Skill Upgrade for Gauntlets Resonators." },
  { name: "HF Waveworn Shard", rarity: 4, description: "An advanced material used for Weapon Ascension and Skill Upgrade for Gauntlets Resonators." },
  { name: "FF Waveworn Shard", rarity: 5, description: "A premium material used for Weapon Ascension and Skill Upgrade for Gauntlets Resonators." }
].freeze

seed_material_set(FORGERY_DROP_DATA, "forgery_drop", "Weapon and Skill Material", grouped: true)

# --- Skill Upgrade Materials ---
WEEKLY_BOSS_DROP_DATA = [
  { name: "Curse of the Abyss", rarity: 4, description: "Threnodian Leviathan's drop, used for Skill Upgrade." },
  { name: "Dreamless Feather", rarity: 4, description: "Dreamless's drop, used for Skill Upgrade." },
  { name: "Gold in Memory", rarity: 4, description: "Sigillum's drop, used for Skill Upgrade." },
  { name: "Monument Bell", rarity: 4, description: "Bell-Borne Geochelone's drop, used for Skill Upgrade." },
  { name: "Sentinel's Dagger", rarity: 4, description: "Sentinel Jué's drop, used for Skill Upgrade." },
  { name: "The Netherworld's Stare", rarity: 4, description: "Hecate's drop, used for Resonator Ascension." },
  { name: "Unending Destruction", rarity: 4, description: "Scar's drop, used for Skill Upgrade." },
  { name: "When Irises Bloom", rarity: 4, description: "Fleurdelys' drop, used for Skill Upgrade." }
].freeze

seed_material_set(WEEKLY_BOSS_DROP_DATA, "weekly_boss_drop", "Skill Upgrade Material")

puts "  --> Materials created succesfully."
