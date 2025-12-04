# Order:
# - ResonatorLevelCosts
# - RoverAscensionCosts
# - ResonatorAscensionCosts
# - SkillCosts
# - ForteNodeCosts
# - WeaponLevelCosts
# - WeaponAscensionCosts

# ===============================================
# 04. COST TEMPLATES
# ===============================================
puts "  --> Creating Cost Templates..."

# --- Resonator Level Costs (2 -> 90)
RESONATOR_LEVEL_COSTS = [
  # Resonator Level 2 -> 20
  { level: 2, exp: 400 },
  { level: 3, exp: 400 },
  { level: 4, exp: 500 },
  { level: 5, exp: 600 },
  { level: 6, exp: 700 },
  { level: 7, exp: 900 },
  { level: 8, exp: 1000 },
  { level: 9, exp: 1200 },
  { level: 10, exp: 1300 },
  { level: 11, exp: 1500 },
  { level: 12, exp: 1700 },
  { level: 13, exp: 2000 },
  { level: 14, exp: 2200 },
  { level: 15, exp: 2400 },
  { level: 16, exp: 2700 },
  { level: 17, exp: 3000 },
  { level: 18, exp: 3300 },
  { level: 19, exp: 3600 },
  { level: 20, exp: 3900 },

  # Resonator Level 21 -> 40
  { level: 21, exp: 4300 },
  { level: 22, exp: 4600 },
  { level: 23, exp: 5000 },
  { level: 24, exp: 5400 },
  { level: 25, exp: 5800 },
  { level: 26, exp: 6300 },
  { level: 27, exp: 6700 },
  { level: 28, exp: 7200 },
  { level: 29, exp: 7700 },
  { level: 30, exp: 8200 },
  { level: 31, exp: 8700 },
  { level: 32, exp: 9300 },
  { level: 33, exp: 9800 },
  { level: 34, exp: 10400 },
  { level: 35, exp: 11000 },
  { level: 36, exp: 11700 },
  { level: 37, exp: 12300 },
  { level: 38, exp: 13000 },
  { level: 39, exp: 13700 },
  { level: 40, exp: 14400 },

  # Resonator Level 41 -> 50
  { level: 41, exp: 15100 },
  { level: 42, exp: 15900 },
  { level: 43, exp: 16700 },
  { level: 44, exp: 17500 },
  { level: 45, exp: 18300 },
  { level: 46, exp: 19200 },
  { level: 47, exp: 20000 },
  { level: 48, exp: 20900 },
  { level: 49, exp: 21900 },
  { level: 50, exp: 22800 },

  # Resonator Level 51 -> 60
  { level: 51, exp: 23800 },
  { level: 52, exp: 24800 },
  { level: 53, exp: 25800 },
  { level: 54, exp: 26900 },
  { level: 55, exp: 28000 },
  { level: 56, exp: 29100 },
  { level: 57, exp: 30300 },
  { level: 58, exp: 31400 },
  { level: 59, exp: 32600 },
  { level: 60, exp: 33900 },

  # Resonator Level 61 -> 70
  { level: 61, exp: 35100 },
  { level: 62, exp: 36400 },
  { level: 63, exp: 37700 },
  { level: 64, exp: 39100 },
  { level: 65, exp: 40500 },
  { level: 66, exp: 41900 },
  { level: 67, exp: 43300 },
  { level: 68, exp: 44800 },
  { level: 69, exp: 46300 },
  { level: 70, exp: 47900 },

  # Resonator Level 71 -> 80
  { level: 71, exp: 49500 },
  { level: 72, exp: 51100 },
  { level: 73, exp: 52800 },
  { level: 74, exp: 54500 },
  { level: 75, exp: 56200 },
  { level: 76, exp: 58000 },
  { level: 77, exp: 59800 },
  { level: 78, exp: 61600 },
  { level: 79, exp: 63500 },
  { level: 80, exp: 65400 },

  # Resonator Level 81 -> 90
  { level: 81, exp: 67400 },
  { level: 82, exp: 69400 },
  { level: 83, exp: 71400 },
  { level: 84, exp: 73500 },
  { level: 85, exp: 75600 },
  { level: 86, exp: 77800 },
  { level: 87, exp: 80000 },
  { level: 88, exp: 82300 },
  { level: 89, exp: 84600 },
  { level: 90, exp: 86900 }
].freeze

# EXP cost required for destination level
# Credit cost is calculated using `EXP * 0.35`
def create_resonator_level_cost(level, exp)
  credit = (exp * 0.35).to_i

  ResonatorLevelCost.find_or_initialize_by(level: level).update!(
    exp_required: exp,
    credit_cost: credit
  )
end

RESONATOR_LEVEL_COSTS.each do |cost|
  create_resonator_level_cost(cost[:level], cost[:exp])
end

# --- Rover Ascension Costs ---
ROVER_ASCENSION_COSTS = [
  # Ascension Rank 1 (Unlocks Level 20)
  { rank: 1, type: "Credit", rarity: 3, quantity: 5000 },
  { rank: 1, type: "EnemyDrop", rarity: 2, quantity: 4 },

  # Ascension Rank 2 (Unlocks Level 40)
  { rank: 2, type: "Credit", rarity: 3, quantity: 10000 },
  { rank: 2, type: "EnemyDrop", rarity: 3, quantity: 4 },
  { rank: 2, type: "BossDrop", rarity: 5, quantity: 1 },
  { rank: 2, type: "Flower", rarity: 1, quantity: 4 },

  # Ascension Rank 3 (Unlocks Level 50)
  { rank: 3, type: "Credit", rarity: 3, quantity: 15000 },
  { rank: 3, type: "EnemyDrop", rarity: 3, quantity: 8 },
  { rank: 3, type: "BossDrop", rarity: 5, quantity: 1 },
  { rank: 3, type: "Flower", rarity: 1, quantity: 8 },

  # Ascension Rank 4 (Unlocks Level 60)
  { rank: 4, type: "Credit", rarity: 3, quantity: 20000 },
  { rank: 4, type: "EnemyDrop", rarity: 4, quantity: 4 },
  { rank: 4, type: "BossDrop", rarity: 5, quantity: 1 },
  { rank: 4, type: "Flower", rarity: 1, quantity: 12 },

  # Ascension Rank 5 (Unlocks Level 70)
  { rank: 5, type: "Credit", rarity: 3, quantity: 40000 },
  { rank: 5, type: "EnemyDrop", rarity: 4, quantity: 8 },
  { rank: 5, type: "BossDrop", rarity: 5, quantity: 1 },
  { rank: 5, type: "Flower", rarity: 1, quantity: 16 },

  # Ascension Rank 6 (Unlocks Level 80)
  { rank: 6, type: "Credit", rarity: 3, quantity: 80000 },
  { rank: 6, type: "EnemyDrop", rarity: 5, quantity: 4 },
  { rank: 6, type: "BossDrop", rarity: 5, quantity: 1 },
  { rank: 6, type: "Flower", rarity: 1, quantity: 20 }
].freeze

def create_rover_ascension_cost(rank, type, rarity, quantity)
  RoverAscensionCost.find_or_initialize_by(
    ascension_rank: rank,
    material_type: type,
    rarity: rarity
  ).update!(quantity: quantity)
end

ROVER_ASCENSION_COSTS.each do |cost|
  create_rover_ascension_cost(cost[:rank], cost[:type], cost[:rarity], cost[:quantity])
end

# --- Resonator Ascension Costs ---
RESONATOR_ASCENSION_COSTS = [
  # Ascension Rank 1 (Unlocks Level 20)
  { rank: 1, type: "Credit", rarity: 3, quantity: 5000 },
  { rank: 1, type: "EnemyDrop", rarity: 2, quantity: 4 },

  # Ascension Rank 2 (Unlocks Level 40)
  { rank: 2, type: "Credit", rarity: 3, quantity: 10000 },
  { rank: 2, type: "EnemyDrop", rarity: 3, quantity: 4 },
  { rank: 2, type: "BossDrop", rarity: 4, quantity: 3 },
  { rank: 2, type: "Flower", rarity: 1, quantity: 4 },

  # Ascension Rank 3 (Unlocks Level 50)
  { rank: 3, type: "Credit", rarity: 3, quantity: 15000 },
  { rank: 3, type: "EnemyDrop", rarity: 3, quantity: 8 },
  { rank: 3, type: "BossDrop", rarity: 4, quantity: 6 },
  { rank: 3, type: "Flower", rarity: 1, quantity: 8 },

  # Ascension Rank 4 (Unlocks Level 60)
  { rank: 4, type: "Credit", rarity: 3, quantity: 20000 },
  { rank: 4, type: "EnemyDrop", rarity: 4, quantity: 4 },
  { rank: 4, type: "BossDrop", rarity: 4, quantity: 9 },
  { rank: 4, type: "Flower", rarity: 1, quantity: 12 },

  # Ascension Rank 5 (Unlocks Level 70)
  { rank: 5, type: "Credit", rarity: 3, quantity: 40000 },
  { rank: 5, type: "EnemyDrop", rarity: 4, quantity: 8 },
  { rank: 5, type: "BossDrop", rarity: 4, quantity: 12 },
  { rank: 5, type: "Flower", rarity: 1, quantity: 16 },

  # Ascension Rank 6 (Unlocks Level 80)
  { rank: 6, type: "Credit", rarity: 3, quantity: 80000 },
  { rank: 6, type: "EnemyDrop", rarity: 5, quantity: 4 },
  { rank: 6, type: "BossDrop", rarity: 4, quantity: 16 },
  { rank: 6, type: "Flower", rarity: 1, quantity: 20 }
].freeze

def create_resonator_ascension_cost(rank, type, rarity, quantity)
  ResonatorAscensionCost.find_or_initialize_by(
    ascension_rank: rank,
    material_type: type,
    rarity: rarity
  ).update!(quantity: quantity)
end

RESONATOR_ASCENSION_COSTS.each do |cost|
  create_resonator_ascension_cost(cost[:rank], cost[:type], cost[:rarity], cost[:quantity])
end

# --- Skill Costs ---
SKILL_COSTS = [
  # Skill Level 1 -> 2
  { level: 2, type: "Credit", rarity: 3, quantity: 1500 },
  { level: 2, type: "EnemyDrop", rarity: 2, quantity: 2 },
  { level: 2, type: "ForgeryDrop", rarity: 2, quantity: 2 },

  # Skill Level 2 -> 3
  { level: 3, type: "Credit", rarity: 3, quantity: 2000 },
  { level: 3, type: "EnemyDrop", rarity: 2, quantity: 3 },
  { level: 3, type: "ForgeryDrop", rarity: 2, quantity: 3 },

  # Skill Level 3 -> 4
  # Note: Material rarity increases here
  { level: 4, type: "Credit", rarity: 3, quantity: 4500 },
  { level: 4, type: "EnemyDrop", rarity: 3, quantity: 2 },
  { level: 4, type: "ForgeryDrop", rarity: 3, quantity: 2 },

  # Skill Level 4 -> 5
  { level: 5, type: "Credit", rarity: 3, quantity: 6000 },
  { level: 5, type: "EnemyDrop", rarity: 3, quantity: 3 },
  { level: 5, type: "ForgeryDrop", rarity: 3, quantity: 3 },

  # Skill Level 5 -> 6
  # Note: Material rarity increases here
  { level: 6, type: "Credit", rarity: 3, quantity: 16000 },
  { level: 6, type: "EnemyDrop", rarity: 4, quantity: 2 },
  { level: 6, type: "ForgeryDrop", rarity: 4, quantity: 3 },

  # Skill Level 6 -> 7
  # Note: Added `WeeklyBossDrop` material requirement
  { level: 6, type: "Credit", rarity: 3, quantity: 30000 },
  { level: 6, type: "EnemyDrop", rarity: 4, quantity: 3 },
  { level: 6, type: "WeeklyBossDrop", rarity: 4, quantity: 1 },
  { level: 6, type: "ForgeryDrop", rarity: 4, quantity: 5 },

  # Skill Level 7 -> 8
  # Note: Material rarity increases here
  { level: 6, type: "Credit", rarity: 3, quantity: 50000 },
  { level: 6, type: "EnemyDrop", rarity: 5, quantity: 2 },
  { level: 6, type: "WeeklyBossDrop", rarity: 4, quantity: 1 },
  { level: 6, type: "ForgeryDrop", rarity: 5, quantity: 2 },

  # Skill Level 8 -> 9
  { level: 6, type: "Credit", rarity: 3, quantity: 70000 },
  { level: 6, type: "EnemyDrop", rarity: 5, quantity: 3 },
  { level: 6, type: "WeeklyBossDrop", rarity: 4, quantity: 1 },
  { level: 6, type: "ForgeryDrop", rarity: 5, quantity: 3 },

  # Skill Level 9 -> 10
  { level: 6, type: "Credit", rarity: 3, quantity: 100000 },
  { level: 6, type: "EnemyDrop", rarity: 5, quantity: 4 },
  { level: 6, type: "WeeklyBossDrop", rarity: 4, quantity: 1 },
  { level: 6, type: "ForgeryDrop", rarity: 5, quantity: 6 }
].freeze

def create_skill_cost(level, type, rarity, quantity)
  SkillCost.find_or_initialize_by(
    level: level,
    material_type: type,
    rarity: rarity
  ).update!(quantity: quantity)
end

SKILL_COSTS.each do |cost|
  create_skill_cost(cost[:level], cost[:type], cost[:rarity], cost[:quantity])
end

# --- Forte Node Costs ---
FORTE_NODE_COSTS = [
  # Inherent Skill tier 1
  { node: "Inherent Skill", tier: 1, type: "Credit", rarity: 3, quantity: 10000 },
  { node: "Inherent Skill", tier: 1, type: "EnemyDrop", rarity: 3, quantity: 3 },
  { node: "Inherent Skill", tier: 1, type: "WeeklyBossDrop", rarity: 4, quantity: 1 },
  { node: "Inherent Skill", tier: 1, type: "ForgeryDrop", rarity: 3, quantity: 3 },

  # Inherent Skill tier 2
  # Note: Material rarity increases here
  { node: "Inherent Skill", tier: 2, type: "Credit", rarity: 3, quantity: 20000 },
  { node: "Inherent Skill", tier: 2, type: "EnemyDrop", rarity: 4, quantity: 3 },
  { node: "Inherent Skill", tier: 2, type: "WeeklyBossDrop", rarity: 4, quantity: 1 },
  { node: "Inherent Skill", tier: 2, type: "ForgeryDrop", rarity: 4, quantity: 3 },

  # Stat Bonus tier 1
  { node: "Stat Bonus", tier: 1, type: "Credit", rarity: 3, quantity: 50000 },
  { node: "Stat Bonus", tier: 1, type: "EnemyDrop", rarity: 4, quantity: 3 },
  { node: "Stat Bonus", tier: 1, type: "ForgeryDrop", rarity: 4, quantity: 3 },

  # Stat Bonus tier 2
  { node: "Stat Bonus", tier: 2, type: "Credit", rarity: 3, quantity: 100000 },
  { node: "Stat Bonus", tier: 2, type: "EnemyDrop", rarity: 5, quantity: 3 },
  { node: "Stat Bonus", tier: 2, type: "WeeklyBossDrop", rarity: 4, quantity: 1 },
  { node: "Stat Bonus", tier: 2, type: "ForgeryDrop", rarity: 5, quantity: 3 }
].freeze

def create_forte_node_cost(node, tier, type, rarity, quantity)
  ForteNodeCost.find_or_initialize_by(
    node_type: node,
    node_tier: tier,
    material_type: type,
    rarity: rarity
  ).update!(quantity: quantity)
end

FORTE_NODE_COSTS.each do |cost|
  create_forte_node_cost(cost[:node], cost[:tier], cost[:type], cost[:rarity], cost[:quantity])
end

# --- Weapon Level Costs (2 -> 90)
WEAPON_LEVEL_COSTS_R5 = [
  # Weapon R5 Level 2 -> 20
  { level: 2, exp: 600 },
  { level: 3, exp: 700 },
  { level: 4, exp: 800 },
  { level: 5, exp: 900 },
  { level: 6, exp: 1000 },
  { level: 7, exp: 1100 },
  { level: 8, exp: 1300 },
  { level: 9, exp: 1400 },
  { level: 10, exp: 1600 },
  { level: 11, exp: 1800 },
  { level: 12, exp: 2000 },
  { level: 13, exp: 2200 },
  { level: 14, exp: 2500 },
  { level: 15, exp: 2700 },
  { level: 16, exp: 3000 },
  { level: 17, exp: 3300 },
  { level: 18, exp: 3600 },
  { level: 19, exp: 3900 },
  { level: 20, exp: 4300 },

  # Weapon R5 Level 21 -> 40
  { level: 21, exp: 4600 },
  { level: 22, exp: 5000 },
  { level: 23, exp: 5400 },
  { level: 24, exp: 5800 },
  { level: 25, exp: 6300 },
  { level: 26, exp: 6700 },
  { level: 27, exp: 7200 },
  { level: 28, exp: 7700 },
  { level: 29, exp: 8200 },
  { level: 30, exp: 8700 },
  { level: 31, exp: 9300 },
  { level: 32, exp: 9900 },
  { level: 33, exp: 10500 },
  { level: 34, exp: 11100 },
  { level: 35, exp: 11800 },
  { level: 36, exp: 12400 },
  { level: 37, exp: 13100 },
  { level: 38, exp: 13800 },
  { level: 39, exp: 14600 },
  { level: 40, exp: 15300 },

  # Weapon R5 Level 41 -> 50
  { level: 41, exp: 16100 },
  { level: 42, exp: 16900 },
  { level: 43, exp: 17700 },
  { level: 44, exp: 18600 },
  { level: 45, exp: 19400 },
  { level: 46, exp: 20300 },
  { level: 47, exp: 21300 },
  { level: 48, exp: 22200 },
  { level: 49, exp: 23200 },
  { level: 50, exp: 24200 },

  # Weapon R5 Level 51 -> 60
  { level: 51, exp: 25200 },
  { level: 52, exp: 26300 },
  { level: 53, exp: 27300 },
  { level: 54, exp: 28400 },
  { level: 55, exp: 29600 },
  { level: 56, exp: 30700 },
  { level: 57, exp: 31900 },
  { level: 58, exp: 33100 },
  { level: 59, exp: 34300 },
  { level: 60, exp: 35600 },

  # Weapon R5 Level 61 -> 70
  { level: 61, exp: 36900 },
  { level: 62, exp: 38200 },
  { level: 63, exp: 39600 },
  { level: 64, exp: 41000 },
  { level: 65, exp: 42400 },
  { level: 66, exp: 43800 },
  { level: 67, exp: 45300 },
  { level: 68, exp: 46800 },
  { level: 69, exp: 48300 },
  { level: 70, exp: 49800 },

  # Weapon R5 Level 71 -> 80
  { level: 71, exp: 51400 },
  { level: 72, exp: 53000 },
  { level: 73, exp: 54700 },
  { level: 74, exp: 56400 },
  { level: 75, exp: 58100 },
  { level: 76, exp: 59800 },
  { level: 77, exp: 61600 },
  { level: 78, exp: 63400 },
  { level: 79, exp: 65200 },
  { level: 80, exp: 67100 },

  # Weapon R5 Level 81 -> 90
  { level: 81, exp: 71600 },
  { level: 82, exp: 73900 },
  { level: 83, exp: 76900 },
  { level: 84, exp: 80600 },
  { level: 85, exp: 85300 },
  { level: 86, exp: 91400 },
  { level: 87, exp: 99000 },
  { level: 88, exp: 108400 },
  { level: 89, exp: 120000 },
  { level: 90, exp: 134100 }
].freeze

WEAPON_LEVEL_COSTS_R4 = [
  # Weapon R4 Level 2 -> 20
  { level: 2, exp: 400 },
  { level: 3, exp: 500 },
  { level: 4, exp: 700 },
  { level: 5, exp: 800 },
  { level: 6, exp: 1000 },
  { level: 7, exp: 1100 },
  { level: 8, exp: 1300 },
  { level: 9, exp: 1500 },
  { level: 10, exp: 1600 },
  { level: 11, exp: 1800 },
  { level: 12, exp: 2000 },
  { level: 13, exp: 2200 },
  { level: 14, exp: 2400 },
  { level: 15, exp: 2700 },
  { level: 16, exp: 2900 },
  { level: 17, exp: 3100 },
  { level: 18, exp: 3400 },
  { level: 19, exp: 3600 },
  { level: 20, exp: 3900 },

  # Weapon R4 Level 21 -> 40
  { level: 21, exp: 4200 },
  { level: 22, exp: 4400 },
  { level: 23, exp: 4700 },
  { level: 24, exp: 5000 },
  { level: 25, exp: 5400 },
  { level: 26, exp: 5700 },
  { level: 27, exp: 6000 },
  { level: 28, exp: 6400 },
  { level: 29, exp: 6700 },
  { level: 30, exp: 7100 },
  { level: 31, exp: 7500 },
  { level: 32, exp: 7900 },
  { level: 33, exp: 8300 },
  { level: 34, exp: 8800 },
  { level: 35, exp: 9200 },
  { level: 36, exp: 9700 },
  { level: 37, exp: 10200 },
  { level: 38, exp: 10700 },
  { level: 39, exp: 11200 },
  { level: 40, exp: 11700 },

  # Weapon R4 Level 41 -> 50
  { level: 41, exp: 12300 },
  { level: 42, exp: 12800 },
  { level: 43, exp: 13400 },
  { level: 44, exp: 14000 },
  { level: 45, exp: 14700 },
  { level: 46, exp: 15300 },
  { level: 47, exp: 16000 },
  { level: 48, exp: 16700 },
  { level: 49, exp: 17400 },
  { level: 50, exp: 18200 },

  # Weapon R4 Level 51 -> 60
  { level: 51, exp: 18900 },
  { level: 52, exp: 19700 },
  { level: 53, exp: 20500 },
  { level: 54, exp: 21400 },
  { level: 55, exp: 22200 },
  { level: 56, exp: 23100 },
  { level: 57, exp: 24100 },
  { level: 58, exp: 2500 },
  { level: 59, exp: 2600 },
  { level: 60, exp: 2700 },

  # Weapon R4 Level 61 -> 70
  { level: 61, exp: 28100 },
  { level: 62, exp: 29200 },
  { level: 63, exp: 30300 },
  { level: 64, exp: 31400 },
  { level: 65, exp: 32600 },
  { level: 66, exp: 33800 },
  { level: 67, exp: 35100 },
  { level: 68, exp: 36400 },
  { level: 69, exp: 37700 },
  { level: 70, exp: 39000 },

  # Weapon R4 Level 71 -> 80
  { level: 71, exp: 40500 },
  { level: 72, exp: 41900 },
  { level: 73, exp: 43400 },
  { level: 74, exp: 44900 },
  { level: 75, exp: 46500 },
  { level: 76, exp: 48100 },
  { level: 77, exp: 49800 },
  { level: 78, exp: 51500 },
  { level: 79, exp: 53200 },
  { level: 80, exp: 55000 },

  # Weapon R4 Level 81 -> 90
  { level: 81, exp: 60500 },
  { level: 82, exp: 63200 },
  { level: 83, exp: 67000 },
  { level: 84, exp: 72100 },
  { level: 85, exp: 78700 },
  { level: 86, exp: 87200 },
  { level: 87, exp: 97900 },
  { level: 88, exp: 111400 },
  { level: 89, exp: 128000 },
  { level: 90, exp: 148400 }
].freeze

# EXP cost required for destination level
# Credit cost is calculated using `EXP * 0.4`
def create_weapon_level_cost_r5(level, exp)
  credit = (exp * 0.4).to_i

  ResonatorLevelCost.find_or_initialize_by(
    weapon_rarity: 5,
    level: level
  ).update!(
    exp_required: exp,
    credit_cost: credit
  )
end

def create_weapon_level_cost_r4(level, exp)
  credit = (exp * 0.4).to_i

  ResonatorLevelCost.find_or_initialize_by(
    weapon_rarity: 4,
    level: level
  ).update!(
    exp_required: exp,
    credit_cost: credit
  )
end

WEAPON_LEVEL_COSTS_R5.each do |cost|
  create_weapon_level_cost_r5(cost[:level], cost[:exp])
end

WEAPON_LEVEL_COSTS_R4.each do |cost|
  create_weapon_level_cost_r4(cost[:level], cost[:exp])
end

# --- Weapon Ascension Costs ---
WEAPON_ASCENSION_COSTS = [
  # 5-stars Ascension Rank 1
  { stars: 5, rank: 1, type: "Credit", rarity: 3, quantity: 10000 },
  { stars: 5, rank: 1, type: "EnemyDrop", rarity: 2, quantity: 6 },

  # 5-stars Ascension Rank 2
  # Note: Material rarity increases here
  # Note: Add `ForgeryDrop` material requirement
  { stars: 5, rank: 2, type: "Credit", rarity: 3, quantity: 20000 },
  { stars: 5, rank: 2, type: "EnemyDrop", rarity: 3, quantity: 6 },
  { stars: 5, rank: 2, type: "ForgeryDrop", rarity: 2, quantity: 6 },

  # 5-stars Ascension Rank 3
  # Note: Material rarity increases here
  { stars: 5, rank: 3, type: "Credit", rarity: 3, quantity: 40000 },
  { stars: 5, rank: 3, type: "EnemyDrop", rarity: 4, quantity: 4 },
  { stars: 5, rank: 3, type: "ForgeryDrop", rarity: 3, quantity: 8 },

  # 5-stars Ascension Rank 4
  # Note: Material rarity increases here
  { stars: 5, rank: 4, type: "Credit", rarity: 3, quantity: 60000 },
  { stars: 5, rank: 4, type: "EnemyDrop", rarity: 4, quantity: 6 },
  { stars: 5, rank: 4, type: "ForgeryDrop", rarity: 4, quantity: 6 },

  # 5-stars Ascension Rank 5
  # Note: Material rarity increases here
  { stars: 5, rank: 5, type: "Credit", rarity: 3, quantity: 80000 },
  { stars: 5, rank: 5, type: "EnemyDrop", rarity: 5, quantity: 4 },
  { stars: 5, rank: 5, type: "ForgeryDrop", rarity: 5, quantity: 8 },

  # 5-stars Ascension Rank 6
  { stars: 5, rank: 6, type: "Credit", rarity: 3, quantity: 120000 },
  { stars: 5, rank: 6, type: "EnemyDrop", rarity: 5, quantity: 8 },
  { stars: 5, rank: 6, type: "ForgeryDrop", rarity: 5, quantity: 12 },

  # 4-stars Ascension Rank 1
  { stars: 4, rank: 1, type: "Credit", rarity: 3, quantity: 8000 },
  { stars: 4, rank: 1, type: "EnemyDrop", rarity: 2, quantity: 5 },

  # 4-stars Ascension Rank 2
  # Note: Material rarity increases here
  # Note: Add `ForgeryDrop` material requirement
  { stars: 4, rank: 2, type: "Credit", rarity: 3, quantity: 16000 },
  { stars: 4, rank: 2, type: "EnemyDrop", rarity: 3, quantity: 5 },
  { stars: 4, rank: 2, type: "ForgeryDrop", rarity: 2, quantity: 5 },

  # 4-stars Ascension Rank 3
  # Note: Material rarity increases here
  { stars: 4, rank: 3, type: "Credit", rarity: 3, quantity: 32000 },
  { stars: 4, rank: 3, type: "EnemyDrop", rarity: 4, quantity: 4 },
  { stars: 4, rank: 3, type: "ForgeryDrop", rarity: 3, quantity: 7 },

  # 4-stars Ascension Rank 4
  # Note: Material rarity increases here
  { stars: 4, rank: 4, type: "Credit", rarity: 3, quantity: 48000 },
  { stars: 4, rank: 4, type: "EnemyDrop", rarity: 4, quantity: 5 },
  { stars: 4, rank: 4, type: "ForgeryDrop", rarity: 4, quantity: 5 },

  # 4-stars Ascension Rank 5
  # Note: Material rarity increases here
  { stars: 4, rank: 5, type: "Credit", rarity: 3, quantity: 64000 },
  { stars: 4, rank: 5, type: "EnemyDrop", rarity: 5, quantity: 4 },
  { stars: 4, rank: 5, type: "ForgeryDrop", rarity: 5, quantity: 7 },

  # 4-stars Ascension Rank 6
  { stars: 4, rank: 6, type: "Credit", rarity: 3, quantity: 96000 },
  { stars: 4, rank: 6, type: "EnemyDrop", rarity: 5, quantity: 7 },
  { stars: 4, rank: 6, type: "ForgeryDrop", rarity: 5, quantity: 10 }
].freeze

def create_weapon_ascension_cost(stars, rank, type, rarity, quantity)
  WeaponAscensionCost.find_or_initialize_by(
    weapon_rarity: stars,
    ascension_rank: rank,
    material_type: type,
    rarity: rarity
  ).update!(quantity: quantity)
end

WEAPON_ASCENSION_COSTS.each do |cost|
  create_weapon_ascension_cost(cost[:stars], cost[:rank], cost[:type], cost[:rarity], cost[:quantity])
end

puts "  --> Cost Templates created succesfully."
