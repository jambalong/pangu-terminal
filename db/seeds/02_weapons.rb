# Order:
# - Swords
# - Broadblades
# - Pistols
# - Gauntlets
# - Rectifiers
#   - 5-stars
#   - 4-stars

# ===============================================
# 02. WEAPONS
# ===============================================
puts "  --> Creating Weapons..."

WEAPON_DATA = {
  "Sword" => {
    5 => [
      "Blazing Brilliance",
      "Bloodpact's Pledge",
      "Defier's Thorn",
      "Emerald of Genesis",
      "Red Spring",
      "Unflickering Valor"
    ],
    4 => [
      "Commando of Conviction",
      "Endless Collapse",
      "Fables of Wisdom",
      "Feather Edge",
      "Lumingloss",
      "Lunar Cutter",
      "Overture",
      "Somnoire Anchor",
      "Sword#18"
    ]
  },

  "Broadblade" => {
    5 => [
      "Ages of Harvest",
      "Kumokiri",
      "Lustrous Razor",
      "Thunderflare Dominion",
      "Verdant Summit",
      "Wildfire Mark"
    ],
    4 => [
      "Aureate Zenith",
      "Autumntrace",
      "Broadblade#41",
      "Dauntless Evernight",
      "Discord",
      "Helios Cleaver",
      "Meditations on Mercy",
      "Waning Redshift"
    ]
  },

  "Pistols" => {
    5 => [
      "Lux & Umbra",
      "Static Mist",
      "The Last Dance",
      "Woodland Aria"
    ],
    4 => [
      "Cadenza",
      "Novaburst",
      "Pistols#26",
      "Relativistic Jet",
      "Romance in Farewell",
      "Solar Flame",
      "Thunderbolt",
      "Undying Flame"
    ]
  },

  "Gauntlets" => {
    5 => [
      "Abyss Surges",
      "Blazing Justice",
      "Moongazer's Sigil",
      "Tragicomedy",
      "Verity's Handle"
    ],
    4 => [
      "Aether Strike",
      "Amity Accord",
      "Celestial Spiral",
      "Gauntlets#21D",
      "Hollow Mirage",
      "Legend of Drunken Hero",
      "Marcato",
      "Stonard"
    ]
  },

  "Rectifier" => {
    5 => [
      "Cosmic Ripples",
      "Lethean Elegy",
      "Luminous Hymn",
      "Rime-Draped Sprouts",
      "Stellar Symphony",
      "Stringmaster",
      "Whispers of Sirens"
    ],
    4 => [
      "Augment",
      "Call of the Abyss",
      "Comet Flare",
      "Fusion Accretion",
      "Jinzhou Keeper",
      "Ocean's Gift",
      "Radiant Dawn",
      "Rectifier#25",
      "Variation",
      "Waltz in Masquerade"
    ]
  }
}.freeze

WEAPON_DATA.each do | weapon_type, rarities |
  rarities.each do | rarity, names |
    names.each do | name |
      weapon = Weapon.find_or_initialize_by(name: name)
      weapon.update!(
        weapon_type: weapon_type,
        rarity: rarity
      )

      # e.g. "Xiangli Yao" => xiangli_yao
      # e.g. "Rover-Aero" => rover_aero
      # e.g. "Lux & Umbra" => :lux_umbra
      # e.g. "Gauntlets#21D" => :gauntlets21d
      # e.g. "Loong's Pearl" => :loongs_pearl
      lookup_key = name.downcase.gsub(/['#&]/, '').strip.gsub('-', '_').gsub(/\s+/, '_').to_sym
      $SEED_DATA[lookup_key] = weapon
    end
  end
end

puts "  --> Weapons created succesfully."
