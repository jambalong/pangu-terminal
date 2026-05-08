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
  5 => {
    "Aero" => [
      { name: "Cartethyia", weapon_type: "Sword", stat_a: "crit_rate", stat_b: "atk" },
      { name: "Ciaccona", weapon_type: "Pistols", stat_a: "crit_dmg", stat_b: "atk" },
      { name: "Iuno", weapon_type: "Gauntlets", stat_a: "crit_rate", stat_b: "atk" },
      { name: "Jianxin", weapon_type: "Gauntlets", stat_a: "crit_rate", stat_b: "atk" },
      { name: "Jiyan", weapon_type: "Broadblade", stat_a: "crit_rate", stat_b: "atk" },
      { name: "Qiuyuan", weapon_type: "Sword", stat_a: "crit_rate", stat_b: "atk" },
      { name: "Rover-Aero", weapon_type: "Sword", stat_a: "healing_bonus", stat_b: "atk" }
    ],
    "Electro" => [
      { name: "Augusta", weapon_type: "Broadblade", stat_a: "crit_rate", stat_b: "atk" },
      { name: "Calcharo", weapon_type: "Broadblade", stat_a: "crit_dmg", stat_b: "atk" },
      { name: "Xiangli Yao", weapon_type: "Gauntlets", stat_a: "crit_dmg", stat_b: "atk" },
      { name: "Yinlin", weapon_type: "Rectifier", stat_a: "crit_rate", stat_b: "atk" }
    ],
    "Fusion" => [
      { name: "Aemeath", weapon_type: "Sword", stat_a: "crit_rate", stat_b: "atk" },
      { name: "Brant", weapon_type: "Sword", stat_a: "crit_rate", stat_b: "atk" },
      { name: "Changli", weapon_type: "Sword", stat_a: "crit_rate", stat_b: "atk" },
      { name: "Encore", weapon_type: "Rectifier", stat_a: "fusion_dmg", stat_b: "atk" },
      { name: "Galbrena", weapon_type: "Pistols", stat_a: "crit_dmg", stat_b: "atk" },
      { name: "Lupa", weapon_type: "Broadblade", stat_a: "crit_rate", stat_b: "atk" },
      { name: "Mornye", weapon_type: "Broadblade", stat_a: "healing_bonus", stat_b: "def" }
    ],
    "Glacio" => [
      { name: "Carlotta", weapon_type: "Pistols", stat_a: "crit_rate", stat_b: "atk" },
      { name: "Lingyang", weapon_type: "Gauntlets", stat_a: "glacio_dmg", stat_b: "atk" },
      { name: "Zhezhi", weapon_type: "Rectifier", stat_a: "crit_rate", stat_b: "atk" }
    ],
    "Havoc" => [
      { name: "Camellya", weapon_type: "Sword", stat_a: "crit_dmg", stat_b: "atk" },
      { name: "Cantarella", weapon_type: "Rectifier", stat_a: "crit_rate", stat_b: "atk" },
      { name: "Chisa", weapon_type: "Broadblade", stat_a: "crit_rate", stat_b: "atk" },
      { name: "Phrolova", weapon_type: "Rectifier", stat_a: "crit_rate", stat_b: "atk" },
      { name: "Roccia", weapon_type: "Gauntlets", stat_a: "crit_dmg", stat_b: "atk" },
      { name: "Rover-Havoc", weapon_type: "Sword", stat_a: "havoc_dmg", stat_b: "atk" }
    ],
    "Spectro" => [
      { name: "Jinhsi", weapon_type: "Rectifier", stat_a: "crit_rate", stat_b: "atk" },
      { name: "Luuk Herssen", weapon_type: "Gauntlets", stat_a: "crit_rate", stat_b: "atk" },
      { name: "Lynae", weapon_type: "Pistols", stat_a: "crit_rate", stat_b: "atk" },
      { name: "Phoebe", weapon_type: "Rectifier", stat_a: "crit_dmg", stat_b: "atk" },
      { name: "Rover-Spectro", weapon_type: "Sword", stat_a: "spectro_dmg", stat_b: "atk" },
      { name: "Shorekeeper", weapon_type: "Rectifier", stat_a: "healing_bonus", stat_b: "hp" },
      { name: "Verina", weapon_type: "Rectifier", stat_a: "healing_bonus", stat_b: "atk" },
      { name: "Zani", weapon_type: "Gauntlets", stat_a: "crit_rate", stat_b: "atk" }
    ]
  },
  4 => {
    "Aero" => [
      { name: "Aalto", weapon_type: "Pistols", stat_a: "aero_dmg", stat_b: "atk" },
      { name: "Yangyang", weapon_type: "Sword", stat_a: "aero_dmg", stat_b: "atk" }
    ],
    "Electro" => [
      { name: "Buling", weapon_type: "Rectifier", stat_a: "healing_bonus", stat_b: "atk" },
      { name: "Lumi", weapon_type: "Broadblade", stat_a: "crit_rate", stat_b: "atk" },
      { name: "Yuanwu", weapon_type: "Gauntlets", stat_a: "electro_dmg", stat_b: "def" }
    ],
    "Fusion" => [
      { name: "Chixia", weapon_type: "Pistols", stat_a: "fusion_dmg", stat_b: "atk" },
      { name: "Mortefi", weapon_type: "Pistols", stat_a: "fusion_dmg", stat_b: "atk" }
    ],
    "Glacio" => [
      { name: "Baizhi", weapon_type: "Rectifier", stat_a: "healing_bonus", stat_b: "hp" },
      { name: "Sanhua", weapon_type: "Sword", stat_a: "glacio_dmg", stat_b: "atk" },
      { name: "Youhu", weapon_type: "Gauntlets", stat_a: "crit_rate", stat_b: "atk" }
    ],
    "Havoc" => [
      { name: "Danjin", weapon_type: "Sword", stat_a: "havoc_dmg", stat_b: "atk" },
      { name: "Taoqi", weapon_type: "Broadblade", stat_a: "havoc_dmg", stat_b: "def" }
    ]
  }
}.freeze

SKILL_LABELS = {
  "basic_attack" => "Basic-Attack",
  "resonance_skill" => "Resonance-Skill",
  "forte_circuit" => "Forte-Circuit",
  "resonance_liberation" => "Resonance-Liberation",
  "intro_skill" => "Intro-Skill",
  "inherent_skill_1" => "Inherent-Skill-1",
  "inherent_skill_2" => "Inherent-Skill-2"
}.freeze

# Per-resonator overrides where wutheringlab uses a different label
SKILL_LABEL_OVERRIDES = {
  "luuk-herssen" => { "basic_attack" => "Normal-Attack" },
  "cartethyia"   => { "basic_attack" => "Normal-Attack" },
  "ciaccona"     => { "basic_attack" => "Normal-Attack" },
  "lupa"         => { "basic_attack" => "Normal-Attack" },
  "zani"         => { "basic_attack" => "Normal-Attack" },
  "youhu"        => { "basic_attack" => "Normal-Attack" },
  "shorekeeper"  => { "resonance_skill" => "Resonance-Skill-" }
}.freeze

STAT_ICON_PATH = "/images/forte/stats"

RESONATOR_DATA.each do |rarity, elements|
  elements.each do |element, resonators|
    resonators.each do |data|
      filename = data[:name].downcase
                            .gsub(/['"#&]/, "")
                            .strip
                            .gsub(/\s+/, "-")

      skill_icons = SKILL_LABELS.each_with_object({}) do |(skill_key, skill_label), icons|
        label = SKILL_LABEL_OVERRIDES.dig(filename, skill_key) || skill_label
        icons[skill_key] = "/images/forte/skills/#{filename}/#{label.downcase}.webp"
      end

      forte_icons = {
        "skill_icons" => skill_icons,
        "stat_icons" => {
          "stat_a" => "#{STAT_ICON_PATH}/#{data[:stat_a]}.avif",
          "stat_b" => "#{STAT_ICON_PATH}/#{data[:stat_b]}.avif"
        }
      }

      resonator = Resonator.find_or_initialize_by(name: data[:name])
      resonator.update!(
        rarity: rarity,
        element: element,
        weapon_type: data[:weapon_type],
        image_url: "/images/resonators/#{filename}.png",
        forte_icons: forte_icons,
      )


      # e.g. "Xiangli Yao" => xiangli_yao
      # e.g. "Rover-Aero" => rover_aero
      # e.g. "Lux & Umbra" => :lux_umbra
      # e.g. "Gauntlets#21D" => :gauntlets21d
      # e.g. "Loong's Pearl" => :loongs_pearl
      lookup_key = filename.gsub("-", "_")
      $SEED_DATA[lookup_key.to_sym] = resonator
    end
  end
end

puts "  --> Resonators created succesfully."
