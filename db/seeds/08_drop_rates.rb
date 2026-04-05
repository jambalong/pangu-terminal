# Order:
# - Forgery Challenge
# - Simulation Challenge
# - Boss Challenge
# - Weekly Challenge

# ===============================================
# 08. DROP RATES - updated as of 2026.04.04
# ===============================================
puts "  --> Creating Drop Rates..."

def seed_drop_rate(source_name, sol3_phase, rarity, material_type, avg_quantity)
  source = Source.find_by!(name: source_name)
  drop_rate = DropRate.find_or_initialize_by(
    source: source,
    sol3_phase: sol3_phase,
    rarity: rarity,
    material_type: material_type
  )
  drop_rate.update!(avg_quantity: avg_quantity)
end

# --- Forgery Challenges ---
# All forgery sources share identical drop rates for a given rarity and SOL3 phase.
# avg_quantity is averaged across Domain Levels within the same SOL3 phase.
# Data starts at SOL3 phase 3, forgery challenges are not available before phase 3.

FORGERY_MATERIAL_TYPE = "forgery_drop"
FORGERY_SOURCES = [
  "Fallen Sanctum",
  "Lesson in Sunset",
  "Stricken Sanctum",
  "Lesson in Void",
  "Lesson in Embers",
  "Garden of Adoration",
  "Garden of Salvation",
  "Abyss of Confession",
  "Abyss of Initiation",
  "Abyss of Sacrifice",
  "Eroded Ruins",
  "Flaming Remnants",
  "Marigold Woods",
  "Misty Forest",
  "Moonlit Groves"
].freeze

# sol3_phase, rarity, avg_quantity
# Phase 3 has two domain levels (40 and 50) - averaged.
FORGERY_DROP_RATE_DATA = [
  [ 3, 2, 6.765 ],  # (7.00 + 6.53) / 2
  [ 3, 3, 1.955 ],  # (1.00 + 2.91) / 2
  [ 4, 2, 6.38 ],
  [ 4, 3, 3.22 ],
  [ 4, 4, 0.42 ],
  [ 5, 2, 6.38 ],
  [ 5, 3, 4.00 ],
  [ 5, 4, 0.64 ],
  [ 5, 5, 0.096 ],
  [ 6, 2, 6.36 ],
  [ 6, 3, 5.41 ],
  [ 6, 4, 1.083 ],
  [ 6, 5, 0.095 ],
  [ 7, 2, 6.40 ],
  [ 7, 3, 8.00 ],
  [ 7, 4, 1.682 ],
  [ 7, 5, 0.202 ]
].freeze

FORGERY_SOURCES.each do |source_name|
  FORGERY_DROP_RATE_DATA.each do |sol3_phase, rarity, avg_quantity|
    seed_drop_rate(source_name, sol3_phase, rarity, FORGERY_MATERIAL_TYPE, avg_quantity)
  end
end

# --- Simulation Challenges ---
# Drops Shell Credit and EXP potions.
# Three simulation sources share identical rates.
# Resonator EXP and Weapon EXP use the same rarity tiers.
# avg_quantity for EXP is expressed as 2* potion equivalent quantity.

# Shell Credit - rarity 3 (no rarity tiers, single drop type)
SIMULATION_SHELL_CREDIT_DATA = [
  [ 1, 3, 24000 ],
  [ 2, 3, 40000 ],
  [ 3, 3, 56000 ],
  [ 4, 3, 72000 ],
  [ 5, 3, 76000 ],
  [ 6, 3, 80000 ],
  [ 7, 3, 82000 ],
  [ 8, 3, 84000 ]
].freeze

# Resonator EXP - rarity 2, 3, 4, 5 potions per run
SIMULATION_RESONATOR_EXP_DATA = [
  [ 1, 2, 4.79 ],
  [ 1, 3, 6.00 ],
  [ 2, 2, 2.00 ],
  [ 2, 3, 6.69 ],
  [ 2, 4, 2.00 ],
  [ 3, 3, 5.55 ],
  [ 3, 4, 4.14 ],
  [ 3, 5, 0.21 ],
  [ 4, 3, 2.35 ],
  [ 4, 4, 5.04 ],
  [ 4, 5, 1.10 ],
  [ 5, 4, 3.77 ],
  [ 5, 5, 2.03 ],
  [ 6, 4, 4.00 ],
  [ 6, 5, 2.16 ],
  [ 7, 4, 4.08 ],
  [ 7, 5, 2.31 ],
  [ 8, 4, 4.18 ],
  [ 8, 5, 2.250 ]
].freeze

# Weapon EXP - rarity 2, 3, 4 cores per run
SIMULATION_WEAPON_EXP_DATA = [
  [ 1, 2, 4.71 ],
  [ 1, 3, 6.00 ],
  [ 2, 2, 2.00 ],
  [ 2, 3, 6.56 ],
  [ 2, 4, 2.00 ],
  [ 3, 3, 5.53 ],
  [ 3, 4, 4.25 ],
  [ 3, 5, 0.14 ],
  [ 4, 3, 2.38 ],
  [ 4, 4, 5.03 ],
  [ 4, 5, 1.05 ],
  [ 5, 4, 3.90 ],
  [ 5, 5, 2.10 ],
  [ 6, 4, 4.00 ],
  [ 6, 5, 2.26 ],
  [ 7, 4, 4.47 ],
  [ 7, 5, 2.47 ],
  [ 8, 4, 4.15 ],
  [ 8, 5, 2.294 ]
].freeze

CREDIT_MATERIAL_TYPE = "credit"
RESONATOR_EXP_MATERIAL_TYPE = "resonator_exp"
WEAPON_EXP_MATERIAL_TYPE = "weapon_exp"

# Defined in 07_material_sources.rb
SIMULATION_SOURCES.each do |source_name|
  SIMULATION_SHELL_CREDIT_DATA.each do |sol3_phase, rarity, avg_quantity|
    seed_drop_rate(source_name, sol3_phase, rarity, CREDIT_MATERIAL_TYPE, avg_quantity)
  end
  SIMULATION_RESONATOR_EXP_DATA.each do |sol3_phase, rarity, avg_quantity|
    seed_drop_rate(source_name, sol3_phase, rarity, RESONATOR_EXP_MATERIAL_TYPE, avg_quantity)
  end
  SIMULATION_WEAPON_EXP_DATA.each do |sol3_phase, rarity, avg_quantity|
    seed_drop_rate(source_name, sol3_phase, rarity, WEAPON_EXP_MATERIAL_TYPE, avg_quantity)
  end
end

# --- Boss Challenges ---
# Each boss drops one primary material - a Tacet Core or unique boss material.
# All boss materials are rarity 4.
# avg_quantity per run from World Bosses spreadsheet, Material column.

BOSS_PHASE_DROP_RATES = {
  1 => 1.00,
  2 => 1.00,
  3 => 1.45,
  4 => 2.00,
  5 => 2.80,
  6 => 3.13,
  7 => 4.28,
  8 => 4.50
}.freeze

BOSS_SOURCES = Source.where(source_type: "boss_challenge").pluck(:name)
BOSS_MATERIAL_TYPE = "boss_drop"
BOSS_MATERIAL_RARITY = 4

BOSS_SOURCES.each do |source_name|
  BOSS_PHASE_DROP_RATES.each do |sol3_phase, avg_quantity|
    seed_drop_rate(source_name, sol3_phase, BOSS_MATERIAL_RARITY, BOSS_MATERIAL_TYPE, avg_quantity)
  end
end

# --- Weekly Challenges ---
# Each weekly drops one primary material - a unique weekly boss material.
# All weekly materials are rarity 4.
# avg_quantity per run from Weekly Boss spreadsheet, Material column.

WEEKLY_PHASE_DROP_RATES = {
  1 => 1.50,
  2 => 1.56,
  3 => 1.59,
  4 => 1.80,
  5 => 2.00,
  6 => 2.38,
  7 => 3.00,
  8 => 3.00
}.freeze

WEEKLY_SOURCES = Source.where(source_type: "weekly_challenge").pluck(:name)
WEEKLY_MATERIAL_TYPE = "weekly_boss_drop"
WEEKLY_MATERIAL_RARITY = 4

WEEKLY_SOURCES.each do |source_name|
  WEEKLY_PHASE_DROP_RATES.each do |sol3_phase, avg_quantity|
    seed_drop_rate(source_name, sol3_phase, WEEKLY_MATERIAL_RARITY, WEEKLY_MATERIAL_TYPE, avg_quantity)
  end
end

puts "  --> Drop Rates created successfully."
