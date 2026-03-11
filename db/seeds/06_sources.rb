# Order:
# - Forgery Challenge
# - Simulation Training
# - Boss Challenge
# - Weekly Challenge

# ===============================================
# 06. SOURCES
# ===============================================

puts "  --> Creating Sources..."

# SOURCE_DATA contains all Waveplate-costing farming sources.
# Only sources with meaningful drop rates are modeled here.
# Enemy drops, quests, exploration rewards, and synthesis are excluded.
# source_types: forgery_challenge, simulation_challenge, boss_challenge, weekly_challenge

SOURCE_DATA = [
  # --- Forgery Challenge ---
  # Roya Frostlands
  {
    name: "Fallen Sanctum",
    source_type: "forgery_challenge",
    waveplate_cost: 40,
    location: "Etching Plains, Roya Frostlands",
    region: "Roya Frostlands"
  },
  {
    name: "Lesson in Sunset",
    source_type: "forgery_challenge",
    waveplate_cost: 40,
    location: "Etching Plains, Roya Frostlands",
    region: "Roya Frostlands"
  },
  {
    name: "Stricken Sanctum",
    source_type: "forgery_challenge",
    waveplate_cost: 40,
    location: "Fangspire Chasm, Roya Frostlands",
    region: "Roya Frostlands"
  },
  {
    name: "Lesson in Void",
    source_type: "forgery_challenge",
    waveplate_cost: 40,
    location: "Giant's Gaze, Roya Frostlands",
    region: "Roya Frostlands"
  },
  {
    name: "Lesson in Embers",
    source_type: "forgery_challenge",
    waveplate_cost: 40,
    location: "Stagnant Run, Roya Frostlands",
    region: "Roya Frostlands"
  },

  # Rinascita
  {
    name: "Garden of Adoration",
    source_type: "forgery_challenge",
    waveplate_cost: 40,
    location: "Fagaceae Peninsula, Rinascita",
    region: "Rinascita"
  },
  {
    name: "Garden of Salvation",
    source_type: "forgery_challenge",
    waveplate_cost: 40,
    location: "Requiem Ravine, Hallowed Reach, Rinascita",
    region: "Rinascita"
  },
  {
    name: "Abyss of Confession",
    source_type: "forgery_challenge",
    waveplate_cost: 40,
    location: "Nimbus Sanctum, Rinascita",
    region: "Rinascita"
  },
  {
    name: "Abyss of Initiation",
    source_type: "forgery_challenge",
    waveplate_cost: 40,
    location: "Whisperwind Haven, Rinascita",
    region: "Rinascita"
  },
  {
    name: "Abyss of Sacrifice",
    source_type: "forgery_challenge",
    waveplate_cost: 40,
    location: "Thorncrown Rises, Thessaleo Fells, Rinascita",
    region: "Rinascita"
  },

  # Huanglong
  {
    name: "Eroded Ruins",
    source_type: "forgery_challenge",
    waveplate_cost: 40,
    location: "Wuming Bay, Huanglong",
    region: "Huanglong"
  },
  {
    name: "Flaming Remnants",
    source_type: "forgery_challenge",
    waveplate_cost: 40,
    location: "Sea of Flames, Port City of Guixu, Huanglong",
    region: "Huanglong"
  },
  {
    name: "Marigold Woods",
    source_type: "forgery_challenge",
    waveplate_cost: 40,
    location: "Central Plains, Huanglong",
    region: "Huanglong"
  },
  {
    name: "Misty Forest",
    source_type: "forgery_challenge",
    waveplate_cost: 40,
    location: "Forbidden Forest, Dim Forest, Huanglong",
    region: "Huanglong"
  },
  {
    name: "Moonlit Groves",
    source_type: "forgery_challenge",
    waveplate_cost: 40,
    location: "Wuming Bay, Huanglong",
    region: "Huanglong"
  },

  # --- Simulation Training ---
  {
    name: "B.1.N.G.O.",
    source_type: "simulation_challenge",
    waveplate_cost: 40,
    location: "Square, Startorch Academy, Roya Frostlands",
    region: "Roya Frostlands"
  },
  {
    name: "Gladiator's Portrait",
    source_type: "simulation_challenge",
    waveplate_cost: 40,
    location: "Montelli Quarter, Ragunna City, Rinascita",
    region: "Rinascita"
  },
  {
    name: "Simulation Training",
    source_type: "simulation_challenge",
    waveplate_cost: 40,
    location: "Jinzhou, Huanglong",
    region: "Huanglong"
  },

  # --- Boss Challenge ---
  {
    name: "Nameless Explorer",
    source_type: "boss_challenge",
    waveplate_cost: 60,
    location: "Blocked Sector, SkyArk Space Station, Roya Frostlands",
    region: "Roya Frostlands"
  },
  {
    name: "Hyvatia",
    source_type: "boss_challenge",
    waveplate_cost: 60,
    location: "Starward Riseway, Roya Frostlands",
    region: "Roya Frostlands"
  },
  {
    name: "Reactor Husk",
    source_type: "boss_challenge",
    waveplate_cost: 60,
    location: "Exospine Barrows, Fangspire Chasm, Roya Frostlands",
    region: "Roya Frostlands"
  },
  {
    name: "Lady of the Sea",
    source_type: "boss_challenge",
    waveplate_cost: 60,
    location: "Capitoline Hilltop, Capitoline Hill, Rinascita",
    region: "Rinascita"
  },
  {
    name: "The False Sovereign",
    source_type: "boss_challenge",
    waveplate_cost: 60,
    location: "Earthrend Wedge, Sanguis Plateaus, Rinascita",
    region: "Rinascita"
  },
  {
    name: "Fenrico",
    source_type: "boss_challenge",
    waveplate_cost: 60,
    location: "Lumen Tower, Fabricatorium of the Deep, Rinascita",
    region: "Rinascita"
  },
  {
    name: "Lioness of Glory",
    source_type: "boss_challenge",
    waveplate_cost: 60,
    location: "Titanbone Expanse, Septimont, Rinascita",
    region: "Rinascita"
  },
  {
    name: "Dragon of Dirge",
    source_type: "boss_challenge",
    waveplate_cost: 60,
    location: "Figurehead's Shrine, Penitent's End, Rinascita",
    region: "Rinascita"
  },
  {
    name: "Lorelei",
    source_type: "boss_challenge",
    waveplate_cost: 60,
    location: "Atrium of Reflections, Nimbus Sanctum, Rinascita",
    region: "Rinascita"
  },
  {
    name: "Sentry Construct",
    source_type: "boss_challenge",
    waveplate_cost: 60,
    location: "Averardo Vault, Rinascita",
    region: "Rinascita"
  },
  {
    name: "Crownless",
    source_type: "boss_challenge",
    waveplate_cost: 60,
    location: "Stone Pile Plain, Central Plains, Huanglong",
    region: "Huanglong"
  },
  {
    name: "Tempest Mephis",
    source_type: "boss_challenge",
    waveplate_cost: 60,
    location: "Central Plains, Huanglong",
    region: "Huanglong"
  },
  {
    name: "Thundering Mephis",
    source_type: "boss_challenge",
    waveplate_cost: 60,
    location: "Withering Frontline, Desorock Highland, Huanglong",
    region: "Huanglong"
  },
  {
    name: "Inferno Rider",
    source_type: "boss_challenge",
    waveplate_cost: 60,
    location: "Sea of Flames, Port City of Guixu, Huanglong",
    region: "Huanglong"
  },
  {
    name: "Feilian Beringal",
    source_type: "boss_challenge",
    waveplate_cost: 60,
    location: "Giant Banyan, Dim Forest, Huanglong",
    region: "Huanglong"
  },
  {
    name: "Mourning Aix",
    source_type: "boss_challenge",
    waveplate_cost: 60,
    location: "Heron Wetland, Whining Aix's Mire, Huanglong",
    region: "Huanglong"
  },
  {
    name: "Impermanence Heron",
    source_type: "boss_challenge",
    waveplate_cost: 60,
    location: "Camp Overwatch, Desorock Highland, Huanglong",
    region: "Huanglong"
  },
  {
    name: "Lampylumen Myriad",
    source_type: "boss_challenge",
    waveplate_cost: 60,
    location: "Dust-Sealed Track, Tiger's Maw, Huanglong",
    region: "Huanglong"
  },
  {
    name: "Mech Abomination",
    source_type: "boss_challenge",
    waveplate_cost: 60,
    location: "Court of Savantae Ruins, Whining Aix's Mire, Huanglong",
    region: "Huanglong"
  },
  {
    name: "Fallacy of No Return",
    source_type: "boss_challenge",
    waveplate_cost: 60,
    location: "Data Torrent, Tethy's Deep, The Black Shores",
    region: "The Black Shores"
  },

  # --- Weekly Challenge ---
  {
    name: "Gate of the Lost Star",
    source_type: "weekly_challenge",
    waveplate_cost: 60,
    location: "Tidelost Forest, Roya Frostlands",
    region: "Roya Frostlands"
  },
  {
    name: "Cindernite Apocalypse",
    source_type: "weekly_challenge",
    waveplate_cost: 60,
    location: "Three Heroes' Crest, Sanguis Plateaus, Rinascita",
    region: "Rinascita"
  },
  {
    name: "The Wheel of Broken Fate",
    source_type: "weekly_challenge",
    waveplate_cost: 60,
    location: "Holy Spire of Confluence, Avinoleum, Rinascita",
    region: "Rinascita"
  },
  {
    name: "Beyond the Crimson Curtain",
    source_type: "weekly_challenge",
    waveplate_cost: 60,
    location: "Ragunna City, Rinascita",
    region: "Rinascita"
  },
  {
    name: "The Fated Confrontation",
    source_type: "weekly_challenge",
    waveplate_cost: 60,
    location: "Loong's Crest, Mt. Firmament, Huanglong",
    region: "Huanglong"
  },
  {
    name: "Statue of the Crownless",
    source_type: "weekly_challenge",
    waveplate_cost: 60,
    location: "Suspended Ruins, Norfall Barrens, Huanglong",
    region: "Huanglong"
  },
  {
    name: "Chaotic Juncture",
    source_type: "weekly_challenge",
    waveplate_cost: 60,
    location: "Qichi Village, Central Plains, Huanglong",
    region: "Huanglong"
  },
  {
    name: "Bell-Borne Geochelone",
    source_type: "weekly_challenge",
    waveplate_cost: 60,
    location: "Bell-Borne Ravine, Gorges of Spirits, Huanglong",
    region: "Huanglong"
  }
].freeze

def seed_source(name, source_type, waveplate_cost, location, region)
  source = Source.find_or_initialize_by(name: name)
  source.update!(
    source_type: source_type,
    waveplate_cost: waveplate_cost,
    location: location,
    region: region
  )
end

SOURCE_DATA.each do |data|
  seed_source(
    data[:name],
    data[:source_type],
    data[:waveplate_cost],
    data[:location],
    data[:region]
  )
end

puts "  --> Sources created successfully."
