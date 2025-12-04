# Order:
# - Credit
# - ResonatorEXP
# - WeaponEXP
# - BossDrop
# - Flower
# - EnemyDrop
# - ForgeryDrop
# - WeeklyBossDrop

# ===============================================
# 03. MATERIALS
# ===============================================
puts "  --> Creating Materials..."

def seed_material_set(data_array, type, category, default_exp=0)
  data_array.each do |data|
    material = Material.find_or_initialize_by(name: data[:name])
    material.update!(
      rarity: data[:rarity],
      material_type: type,
      category: category,
      exp_value: data[:exp] || default_exp
    )

    # e.g. "Xiangli Yao" => xiangli_yao
    # e.g. "Rover-Aero" => rover_aero
    # e.g. "Lux & Umbra" => :lux_umbra
    # e.g. "Gauntlets#21D" => :gauntlets21d
    # e.g. "Loong's Pearl" => :loongs_pearl
    lookup_key = data[:name].downcase.gsub(/['#&]/, '').strip.gsub('-', '_').gsub(/\s+/, '_').to_sym
    $SEED_DATA[lookup_key] = material
  end
end

# --- Universal Currency ---
shell_credit = Material.find_or_initialize_by(name: "Shell Credit")
shell_credit.update!(
  rarity: 3,
  material_type: "Credit",
  category: "Universal Currency"
)

$SEED_DATA[:shell_credit] = shell_credit

# --- Resonator & Weapon EXP Materials ---
RESONATOR_EXP_DATA = [
  { name: "Basic Resonance Potion", rarity: 2, exp: 1000 },
  { name: "Medium Resonance Potion", rarity: 3, exp: 3000 },
  { name: "Advanced Resonance Potion", rarity: 4, exp: 8000 },
  { name: "Premium Resonance Potion", rarity: 5, exp: 20000 }
].freeze

WEAPON_EXP_DATA = [
  { name: "Basic Energy Core", rarity: 2, exp: 1000 },
  { name: "Medium Energy Core", rarity: 3, exp: 3000 },
  { name: "Advanced Energy Core", rarity: 4, exp: 8000 },
  { name: "Premium Energy Core", rarity: 5, exp: 20000 }
].freeze

seed_material_set(RESONATOR_EXP_DATA, "ResonatorEXP", "Resonator EXP Material")
seed_material_set(WEAPON_EXP_DATA, "WeaponEXP", "Weapon EXP Material")

# --- Resonator Ascension Materials ---
BOSS_DROP_DATA = [
  { name: "Mysterious Code", rarity: 5 },
  { name: "Abyssal Husk", rarity: 4 },
  { name: "Blazing Bone", rarity: 4 },
  { name: "Blighted Crown of Puppet King", rarity: 4 },
  { name: "Cleansing Conch", rarity: 4 },
  { name: "Elegy Tacet Core", rarity: 4 },
  { name: "Gold-Dissolving Feather", rarity: 4 },
  { name: "Group Abomination Tacet Core", rarity: 4 },
  { name: "Hidden Thunder Tacet Core", rarity: 4 },
  { name: "Platinum Core", rarity: 4 },
  { name: "Rage Tacet Core", rarity: 4 },
  { name: "Roaring Rock Fist", rarity: 4 },
  { name: "Sound-Keeping Tacet Core", rarity: 4 },
  { name: "Strife Tacet Core", rarity: 4 },
  { name: "Thundering Tacet Core", rarity: 4 },
  { name: "Topological Confinement", rarity: 4 },
  { name: "Truth in Lies", rarity: 4 },
  { name: "Unfading Glory", rarity: 4 }
].freeze

seed_material_set(BOSS_DROP_DATA, "BossDrop", "Resonator Ascension Material")

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
  { name: "Afterlife", rarity: 1 },
  { name: "Bamboo Iris", rarity: 1 },
  { name: "Bloodleaf Viburnum", rarity: 1 },
  { name: "Firecracker Jewelweed", rarity: 1 },
  { name: "Golden Fleece", rarity: 1 },
  { name: "Luminous Calendula", rarity: 1 },
  { name: "Seaside Cendrelis", rarity: 1 },
  { name: "Sliverglow Bloom", rarity: 1 },
  { name: "Stone Rose", rarity: 1 },
  { name: "Sword Acorus", rarity: 1 }
].freeze

seed_material_set(FLOWER_DATA, "Flower", "Ascension Material")

# --- Weapon and Skill Material (EnemyDrop) ---
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

  # Tidal Residuum Set
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
  { name: "Mask of Insanity", rarity: 5 }
].freeze

seed_material_set(ENEMY_DROP_DATA, "EnemyDrop", "Weapon and Skill Material")

# --- Weapon and Skill Material (ForgeryDrop) ---
FORGERY_DROP_DATA = [
  # Metallic Drip Set
  { name: "Inert Metallic Drip", rarity: 2 },
  { name: "Reactive Metallic Drip", rarity: 3 },
  { name: "Polarized Metallic Drip", rarity: 4 },
  { name: "Heterized Metallic Drip", rarity: 5 },

  # Phlogiston Set
  { name: "Impure Phlogiston", rarity: 2 },
  { name: "Extracted Phlogiston", rarity: 3 },
  { name: "Refined Phlogiston", rarity: 4 },
  { name: "Flawless Phlogiston", rarity: 5 },

  # Helix Set
  { name: "Lento Helix", rarity: 2 },
  { name: "Adagio Helix", rarity: 3 },
  { name: "Andante Helix", rarity: 4 },
  { name: "Presto Helix", rarity: 5 },

  # Waveworn Residue Set
  { name: "Waveworn Residue 210", rarity: 2 },
  { name: "Waveworn Residue 226", rarity: 3 },
  { name: "Waveworn Residue 235", rarity: 4 },
  { name: "Waveworn Residue 239", rarity: 5 },

  # Cadence Set
  { name: "Cadence Seed", rarity: 2 },
  { name: "Cadence Bud", rarity: 3 },
  { name: "Cadence Leaf", rarity: 4 },
  { name: "Cadence Blossom", rarity: 5 }
].freeze

seed_material_set(FORGERY_DROP_DATA, "ForgeryDrop", "Weapon and Skill Material")

# --- Skill Upgrade Materials ---
WEEKLY_BOSS_DROP_DATA = [
  { name: "Curse of the Abyss", rarity: 4 }
  { name: "Dreamless Feather", rarity: 4 },
  { name: "Monument Bell", rarity: 4 },
  { name: "Sentinel's Dagger", rarity: 4 },
  { name: "The Netherworld's Stare", rarity: 4 },
  { name: "Unending Destruction", rarity: 4 },
  { name: "When Irises Bloom", rarity: 4 },
].freeze

seed_material_set(WEEKLY_BOSS_DROP_DATA, "WeeklyBossDrop", "Skill Upgrade Material")

puts "  --> Materials created succesfully."
