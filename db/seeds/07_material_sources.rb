# ===============================================
# 07. MATERIAL SOURCES
# ===============================================
puts "  --> Creating Material Sources..."

def seed_material_source(material_name, source_name)
  material = Material.find_by!(name: material_name)
  source = Source.find_by!(name: source_name)
  MaterialSource.find_or_create_by!(material: material, source: source)
end

# --- Simulation Challenges ---
# All three simulation challenges drop all EXP tiers and Shell Credit

SIMULATION_SOURCES = [
  "Simulation Training",
  "Gladiator's Portrait",
  "B.1.N.G.O."
].freeze

RESONATOR_EXP_MATERIALS = [
  "Basic Resonance Potion",
  "Medium Resonance Potion",
  "Advanced Resonance Potion",
  "Premium Resonance Potion"
].freeze

WEAPON_EXP_MATERIALS = [
  "Basic Energy Core",
  "Medium Energy Core",
  "Advanced Energy Core",
  "Premium Energy Core"
].freeze

SIMULATION_SOURCES.each do |source|
  RESONATOR_EXP_MATERIALS.each { |m| seed_material_source(m, source) }
  WEAPON_EXP_MATERIALS.each { |m| seed_material_source(m, source) }
  seed_material_source("Shell Credit", source)
end

# --- Forgery Challenges ---
# Each set has 4 tiers, all map to the same source(s)

FORGERY_MATERIAL_SOURCES = {
  # Waveworn Residue Set — Huanglong + Rinascita
  "Waveworn Residue 210" => [ "Eroded Ruins", "Garden of Adoration" ],
  "Waveworn Residue 226" => [ "Eroded Ruins", "Garden of Adoration" ],
  "Waveworn Residue 235" => [ "Eroded Ruins", "Garden of Adoration" ],
  "Waveworn Residue 239" => [ "Eroded Ruins", "Garden of Adoration" ],

  # Metallic Drip Set — Huanglong + Rinascita
  "Inert Metallic Drip"     => [ "Flaming Remnants", "Garden of Salvation" ],
  "Reactive Metallic Drip"  => [ "Flaming Remnants", "Garden of Salvation" ],
  "Polarized Metallic Drip" => [ "Flaming Remnants", "Garden of Salvation" ],
  "Heterized Metallic Drip" => [ "Flaming Remnants", "Garden of Salvation" ],

  # Phlogiston Set — Huanglong + Rinascita
  "Impure Phlogiston"   => [ "Marigold Woods", "Abyss of Confession" ],
  "Extracted Phlogiston" => [ "Marigold Woods", "Abyss of Confession" ],
  "Refined Phlogiston"  => [ "Marigold Woods", "Abyss of Confession" ],
  "Flawless Phlogiston" => [ "Marigold Woods", "Abyss of Confession" ],

  # Helix Set — Huanglong + Rinascita
  "Lento Helix"   => [ "Misty Forest", "Abyss of Initiation" ],
  "Adagio Helix"  => [ "Misty Forest", "Abyss of Initiation" ],
  "Andante Helix" => [ "Misty Forest", "Abyss of Initiation" ],
  "Presto Helix"  => [ "Misty Forest", "Abyss of Initiation" ],

  # Cadence Set — Huanglong + Rinascita
  "Cadence Seed"    => [ "Moonlit Groves", "Abyss of Sacrifice" ],
  "Cadence Bud"     => [ "Moonlit Groves", "Abyss of Sacrifice" ],
  "Cadence Leaf"    => [ "Moonlit Groves", "Abyss of Sacrifice" ],
  "Cadence Blossom" => [ "Moonlit Groves", "Abyss of Sacrifice" ],

  # Polarizer Set — Roya Frostlands only
  "Broken Wing Polarizer" => [ "Fallen Sanctum" ],
  "Monowing Polarizer"    => [ "Fallen Sanctum" ],
  "Polywing Polarizer"    => [ "Fallen Sanctum" ],
  "Layered Wing Polarizer" => [ "Fallen Sanctum" ],

  # String Set — Roya Frostlands only
  "Spliced String"   => [ "Lesson in Sunset" ],
  "Broken String"    => [ "Lesson in Sunset" ],
  "Solidified String" => [ "Lesson in Sunset" ],
  "Melodic String"   => [ "Lesson in Sunset" ],

  # Carved Crystal Set — Roya Frostlands only
  "LF Carved Crystal" => [ "Stricken Sanctum" ],
  "MF Carved Crystal" => [ "Stricken Sanctum" ],
  "HF Carved Crystal" => [ "Stricken Sanctum" ],
  "FF Carved Crystal" => [ "Stricken Sanctum" ],

  # Waveworn Shard Set — Roya Frostlands only
  "LF Waveworn Shard" => [ "Lesson in Void" ],
  "MF Waveworn Shard" => [ "Lesson in Void" ],
  "HF Waveworn Shard" => [ "Lesson in Void" ],
  "FF Waveworn Shard" => [ "Lesson in Void" ],

  # Combustor Set — Roya Frostlands only
  "Incomplete Combustor" => [ "Lesson in Embers" ],
  "Aftertune Combustor"  => [ "Lesson in Embers" ],
  "Remnant Combustor"    => [ "Lesson in Embers" ],
  "Reverb Combustor"     => [ "Lesson in Embers" ]
}.freeze

FORGERY_MATERIAL_SOURCES.each do |material_name, sources|
  sources.each { |source_name| seed_material_source(material_name, source_name) }
end

# --- Boss Challenges ---
# Each boss material maps to exactly one source

BOSS_MATERIAL_SOURCES = {
  "Our Choice"                      => "Nameless Explorer",
  "Burning Judgment"                => "Reactor Husk",
  "Suncoveter's Reach"              => "Hyvatia",
  "Blighted Crown of Puppet King"   => "The False Sovereign",
  "Abyssal Husk"                    => "Lady of the Sea",
  "Truth in Lies"                   => "Fenrico",
  "Unfading Glory"                  => "Lioness of Glory",
  "Platinum Core"                   => "Sentry Construct",
  "Blazing Bone"                    => "Dragon of Dirge",
  "Cleansing Conch"                 => "Lorelei",
  "Group Abomination Tacet Core"    => "Mech Abomination",
  "Elegy Tacet Core"                => "Mourning Aix",
  "Gold-Dissolving Feather"         => "Impermanence Heron",
  "Thundering Tacet Core"           => "Thundering Mephis",
  "Topological Confinement"         => "Fallacy of No Return",
  "Rage Tacet Core"                 => "Inferno Rider",
  "Roaring Rock Fist"               => "Feilian Beringal",
  "Sound-Keeping Tacet Core"        => "Lampylumen Myriad",
  "Hidden Thunder Tacet Core"       => "Tempest Mephis",
  "Strife Tacet Core"               => "Crownless"
}.freeze

BOSS_MATERIAL_SOURCES.each do |material_name, source_name|
  seed_material_source(material_name, source_name)
end

# --- Weekly Challenges ---
# Each weekly material maps to exactly one source

WEEKLY_MATERIAL_SOURCES = {
  "Gold in Memory"          => "Gate of the Lost Star",
  "Curse of the Abyss"      => "Cindernite Apocalypse",
  "When Irises Bloom"       => "The Wheel of Broken Fate",
  "The Netherworld's Stare" => "Beyond the Crimson Curtain",
  "Sentinel's Dagger"       => "The Fated Confrontation",
  "Monument Bell"           => "Bell-Borne Geochelone",
  "Dreamless Feather"       => "Statue of the Crownless",
  "Unending Destruction"    => "Chaotic Juncture"
}.freeze

WEEKLY_MATERIAL_SOURCES.each do |material_name, source_name|
  seed_material_source(material_name, source_name)
end

# --- No source rows ---
# Mysterious Code - drops from Casket Delivery and Quests, no Waveplate cost
# Wave-Cutting Tooth - culled, no in-game source confirmed

puts "  --> Material Sources created successfully."
