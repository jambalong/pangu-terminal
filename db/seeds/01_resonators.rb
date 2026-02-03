# Order:
# - 5-stars
# - 4-stars
#   - Aero
#   - Electro
#   - Fusion
#   - Glacio
#   - Havoc
#   - Spectro

# ===============================================
# 01. RESONATORS
# ===============================================
puts "  --> Creating Resonators..."

RESONATOR_DATA = {
  5 => { # 5-STAR RESONATORS
    "Aero" => [
      { name: "Cartethyia", weapon_type: "Sword" },
      { name: "Ciaccona", weapon_type: "Pistols" },
      { name: "Iuno", weapon_type: "Gauntlets" },
      { name: "Jianxin", weapon_type: "Gauntlets" },
      { name: "Jiyan", weapon_type: "Broadblade" },
      { name: "Qiuyuan", weapon_type: "Sword" },
      { name: "Rover-Aero", weapon_type: "Sword" }
    ],
    "Electro" => [
      { name: "Augusta", weapon_type: "Broadblade" },
      { name: "Calcharo", weapon_type: "Broadblade" },
      { name: "Xiangli Yao", weapon_type: "Gauntlets" },
      { name: "Yinlin", weapon_type: "Rectifier" }
    ],
    "Fusion" => [
      { name: "Brant", weapon_type: "Sword" },
      { name: "Changli", weapon_type: "Sword" },
      { name: "Encore", weapon_type: "Rectifier" },
      { name: "Galbrena", weapon_type: "Pistols" },
      { name: "Lupa", weapon_type: "Broadblade" }
    ],
    "Glacio" => [
      { name: "Carlotta", weapon_type: "Pistols" },
      { name: "Lingyang", weapon_type: "Gauntlets" },
      { name: "Zhezhi", weapon_type: "Rectifier" }
    ],
    "Havoc" => [
      { name: "Camellya", weapon_type: "Sword" },
      { name: "Cantarella", weapon_type: "Rectifier" },
      { name: "Chisa", weapon_type: "Broadblade" },
      { name: "Phrolova", weapon_type: "Rectifier" },
      { name: "Roccia", weapon_type: "Gauntlets" },
      { name: "Rover-Havoc", weapon_type: "Sword" }
    ],
    "Spectro" => [
      { name: "Jinhsi", weapon_type: "Rectifier" },
      { name: "Phoebe", weapon_type: "Rectifier" },
      { name: "Rover-Spectro", weapon_type: "Sword" },
      { name: "Shorekeeper", weapon_type: "Rectifier" },
      { name: "Verina", weapon_type: "Rectifier" },
      { name: "Zani", weapon_type: "Gauntlets" }
    ]
  },

  4 => { # 4-STAR RESONATORS
    "Aero" => [
      { name: "Aalto", weapon_type: "Pistols" },
      { name: "Yangyang", weapon_type: "Sword" }
    ],
    "Electro" => [
      { name: "Lumi", weapon_type: "Broadblade" },
      { name: "Yuanwu", weapon_type: "Gauntlets" }
    ],
    "Fusion" => [
      { name: "Chixia", weapon_type: "Pistols" },
      { name: "Mortefi", weapon_type: "Pistols" }
    ],
    "Glacio" => [
      { name: "Baizhi", weapon_type: "Rectifier" },
      { name: "Sanhua", weapon_type: "Sword" },
      { name: "Youhu", weapon_type: "Gauntlets" }
    ],
    "Havoc" => [
      { name: "Danjin", weapon_type: "Sword" },
      { name: "Taoqi", weapon_type: "Broadblade" }
    ]
  }
}.freeze

RESONATOR_DATA.each do |rarity, elements|
  elements.each do |element, resonators|
    resonators.each do |data|
      resonator = Resonator.find_or_initialize_by(name: data[:name])
      resonator.update!(
        rarity: rarity,
        element: element,
        weapon_type: data[:weapon_type]
      )

      # e.g. "Xiangli Yao" => xiangli_yao
      # e.g. "Rover-Aero" => rover_aero
      # e.g. "Lux & Umbra" => :lux_umbra
      # e.g. "Gauntlets#21D" => :gauntlets21d
      # e.g. "Loong's Pearl" => :loongs_pearl
      lookup_key = data[:name].downcase
                        .gsub(/['#&]/, '')
                        .strip
                        .gsub('-', '_')
                        .gsub(/\s+/, '_')
                        .to_sym
      $SEED_DATA[lookup_key] = resonator
    end
  end
end

puts "  --> Resonators created succesfully."
