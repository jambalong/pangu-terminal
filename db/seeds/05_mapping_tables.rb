# Order:
# - Resonator Material Maps
# - Weapon Material Maps
# - Weapon Type Materials

# ===============================================
# 05. MAPPING TABLES
# ===============================================
puts "  --> Creating Mapping Tables..."

# --- 1. Fetch all resonators, weapons, and materials ---
# NOTE: This relies on 01_resonators.rb, 02_weapons.rb, and 03_materials.rb 
# creating these items and saving them to $SEED_DATA

RESONATORS = {
  # 5-Star Resonators
  augusta:        $SEED_DATA[:augusta],
  brant:          $SEED_DATA[:brant],
  calcharo:       $SEED_DATA[:calcharo],
  camellya:       $SEED_DATA[:camellya],
  cantarella:     $SEED_DATA[:cantarella],
  carlotta:       $SEED_DATA[:carlotta],
  cartethyia:     $SEED_DATA[:cartethyia],
  changli:        $SEED_DATA[:changli],
  chisa:          $SEED_DATA[:chisa],
  ciaccona:       $SEED_DATA[:ciaccona],
  encore:         $SEED_DATA[:encore],
  galbrena:       $SEED_DATA[:galbrena],
  iuno:           $SEED_DATA[:iuno],
  jianxin:        $SEED_DATA[:jianxin],
  jinhsi:         $SEED_DATA[:jinhsi],
  jiyan:          $SEED_DATA[:jiyan],
  lingyang:       $SEED_DATA[:lingyang],
  lupa:           $SEED_DATA[:lupa],
  phoebe:         $SEED_DATA[:phoebe],
  phrolova:       $SEED_DATA[:phrolova],
  qiuyuan:        $SEED_DATA[:qiuyuan],
  roccia:         $SEED_DATA[:roccia],
  rover_aero:     $SEED_DATA[:rover_aero],
  rover_havoc:    $SEED_DATA[:rover_havoc],
  rover_spectro:  $SEED_DATA[:rover_spectro],
  shorekeeper:    $SEED_DATA[:shorekeeper],
  verina:         $SEED_DATA[:verina],
  xiangli_yao:    $SEED_DATA[:xiangli_yao],
  yinlin:         $SEED_DATA[:yinlin],
  zani:           $SEED_DATA[:zani],
  zhezhi:         $SEED_DATA[:zhezhi],

  # 4-Star Resonators
  aalto:          $SEED_DATA[:aalto],
  baizhi:         $SEED_DATA[:baizhi],
  chixia:         $SEED_DATA[:chixia],
  danjin:         $SEED_DATA[:danjin],
  lumi:           $SEED_DATA[:lumi],
  mortefi:        $SEED_DATA[:mortefi],
  sanhua:         $SEED_DATA[:sanhua],
  taoqi:          $SEED_DATA[:taoqi],
  yangyang:       $SEED_DATA[:yangyang],
  youhu:          $SEED_DATA[:youhu],
  yuanwu:         $SEED_DATA[:yuanwu]
}.freeze

WEAPONS = {
  # 5-Star Weapons
  abyss_surges:           $SEED_DATA[:abyss_surges],
  ages_of_harvest:        $SEED_DATA[:ages_of_harvest],
  blazing_brilliance:     $SEED_DATA[:blazing_brilliance],
  blazing_justice:        $SEED_DATA[:blazing_justice],
  bloodpacts_pledge:      $SEED_DATA[:bloodpacts_pledge],
  cosmic_ripples:         $SEED_DATA[:cosmic_ripples],
  defiers_thorn:          $SEED_DATA[:defiers_thorn],
  emerald_of_genesis:     $SEED_DATA[:emerald_of_genesis],
  emerald_sentence:       $SEED_DATA[:emerald_sentence],
  kumokiri:               $SEED_DATA[:kumokiri],
  lethean_elegy:          $SEED_DATA[:lethean_elegy],
  luminous_hymn:          $SEED_DATA[:luminous_hymn],
  lustrous_razor:         $SEED_DATA[:lustrous_razor],
  lux_umbra:              $SEED_DATA[:lux_umbra],
  moongazers_sigil:       $SEED_DATA[:moongazers_sigil],
  red_spring:             $SEED_DATA[:red_spring],
  rime_draped_sprouts:    $SEED_DATA[:rime_draped_sprouts],
  static_mist:            $SEED_DATA[:static_mist],
  stellar_symphony:       $SEED_DATA[:stellar_symphony],
  stringmaster:           $SEED_DATA[:stringmaster],
  the_last_dance:         $SEED_DATA[:the_last_dance],
  thunderflare_dominion:  $SEED_DATA[:thunderflare_dominion],
  tragicomedy:            $SEED_DATA[:tragicomedy],
  unflickering_valor:     $SEED_DATA[:unflickering_valor],
  verdant_summit:         $SEED_DATA[:verdant_summit],
  veritys_handle:         $SEED_DATA[:veritys_handle],
  whispers_of_sirens:     $SEED_DATA[:whispers_of_sirens],
  wildfire_mark:          $SEED_DATA[:wildfire_mark],
  woodland_aria:          $SEED_DATA[:woodland_aria],

  # 4-Star Weapons
  aether_strike:          $SEED_DATA[:aether_strike],
  amity_accord:           $SEED_DATA[:amity_accord],
  augment:                $SEED_DATA[:augment],
  aureate_zenith:         $SEED_DATA[:aureate_zenith],
  autumntrace:            $SEED_DATA[:autumntrace],
  broadblade41:           $SEED_DATA[:broadblade41],
  cadenza:                $SEED_DATA[:cadenza],
  call_of_the_abyss:      $SEED_DATA[:call_of_the_abyss],
  celestial_spiral:       $SEED_DATA[:celestial_spiral],
  comet_flare:            $SEED_DATA[:comet_flare],
  commando_of_conviction: $SEED_DATA[:commando_of_conviction],
  dauntless_evernight:    $SEED_DATA[:dauntless_evernight],
  discord:                $SEED_DATA[:discord],
  endless_collapse:       $SEED_DATA[:endless_collapse],
  fables_of_wisdom:       $SEED_DATA[:fables_of_wisdom],
  feather_edge:           $SEED_DATA[:feather_edge],
  fusion_accretion:       $SEED_DATA[:fusion_accretion],
  gauntlets21d:           $SEED_DATA[:gauntlets21d],
  helios_cleaver:         $SEED_DATA[:helios_cleaver],
  hollow_mirage:          $SEED_DATA[:hollow_mirage],
  jinzhou_keeper:         $SEED_DATA[:jinzhou_keeper],
  legend_of_drunken_hero: $SEED_DATA[:legend_of_drunken_hero],
  lumingloss:             $SEED_DATA[:lumingloss],
  lunar_cutter:           $SEED_DATA[:lunar_cutter],
  marcato:                $SEED_DATA[:marcato],
  meditations_on_mercy:   $SEED_DATA[:meditations_on_mercy],
  novaburst:              $SEED_DATA[:novaburst],
  oceans_gift:            $SEED_DATA[:oceans_gift],
  overture:               $SEED_DATA[:overture],
  pistols26:              $SEED_DATA[:pistols26],
  radiant_dawn:           $SEED_DATA[:radiant_dawn],
  rectifier25:            $SEED_DATA[:rectifier25],
  relativistic_jet:       $SEED_DATA[:relativistic_jet],
  romance_in_farewell:    $SEED_DATA[:romance_in_farewell],
  solar_flame:            $SEED_DATA[:solar_flame],
  somnoire_anchor:        $SEED_DATA[:somnoire_anchor],
  stonard:                $SEED_DATA[:stonard],
  sword18:                $SEED_DATA[:sword18],
  thunderbolt:            $SEED_DATA[:thunderbolt],
  undying_flame:          $SEED_DATA[:undying_flame],
  variation:              $SEED_DATA[:variation],
  waltz_in_masquerade:    $SEED_DATA[:waltz_in_masquerade],
  waning_redshift:        $SEED_DATA[:waning_redshift]
}.freeze

MATERIALS = {
  # Currency & EXP
  shell_credit:               $SEED_DATA[:shell_credit],

  basic_resonance_potion:     $SEED_DATA[:basic_resonance_potion],
  medium_resonance_potion:    $SEED_DATA[:medium_resonance_potion],
  advanced_resonance_potion:  $SEED_DATA[:advanced_resonance_potion],
  premium_resonance_potion:   $SEED_DATA[:premium_resonance_potion],

  basic_energy_core:          $SEED_DATA[:basic_energy_core],
  medium_energy_core:         $SEED_DATA[:medium_energy_core],
  advanced_energy_core:       $SEED_DATA[:advanced_energy_core],
  premium_energy_core:        $SEED_DATA[:premium_energy_core],

  # Boss Drops
  mysterious_code:                $SEED_DATA[:mysterious_code],

  abyssal_husk:                   $SEED_DATA[:abyssal_husk],
  blazing_bone:                   $SEED_DATA[:blazing_bone],
  blighted_crown_of_puppet_king:  $SEED_DATA[:blighted_crown_of_puppet_king],
  cleansing_conch:                $SEED_DATA[:cleansing_conch],
  elegy_tacet_core:               $SEED_DATA[:elegy_tacet_core],
  gold_dissolving_feather:        $SEED_DATA[:gold_dissolving_feather],
  group_abomination_tacet_core:   $SEED_DATA[:group_abomination_tacet_core],
  hidden_thunder_tacet_core:      $SEED_DATA[:hidden_thunder_tacet_core],
  platinum_core:                  $SEED_DATA[:platinum_core],
  rage_tacet_core:                $SEED_DATA[:rage_tacet_core],
  roaring_rock_fist:              $SEED_DATA[:roaring_rock_fist],
  sound_keeping_tacet_core:       $SEED_DATA[:sound_keeping_tacet_core],
  strife_tacet_core:              $SEED_DATA[:strife_tacet_core],
  thundering_tacet_core:          $SEED_DATA[:thundering_tacet_core],
  topological_confinement:        $SEED_DATA[:topological_confinement],
  truth_in_lies:                  $SEED_DATA[:truth_in_lies],
  unfading_glory:                 $SEED_DATA[:unfading_glory],

  # Flowers
  belle_poppy:            $SEED_DATA[:belle_poppy],
  coriolus:               $SEED_DATA[:coriolus],
  iris:                   $SEED_DATA[:iris],
  lanternberry:           $SEED_DATA[:lanternberry],
  pecok_flower:           $SEED_DATA[:pecok_flower],
  terraspawn_fungus:      $SEED_DATA[:terraspawn_fungus],
  wintry_bell:            $SEED_DATA[:wintry_bell],
  violet_coral:           $SEED_DATA[:violet_coral],

  pavo_plum:              $SEED_DATA[:pavo_plum],
  loongs_pearl:           $SEED_DATA[:loongs_pearl],

  nova:                   $SEED_DATA[:nova],
  summer_flower:          $SEED_DATA[:summer_flower],

  afterlife:              $SEED_DATA[:afterlife],
  bamboo_iris:            $SEED_DATA[:bamboo_iris],
  firecracker_jewelweed:  $SEED_DATA[:firecracker_jewelweed],
  golden_fleece:          $SEED_DATA[:golden_fleece],
  seaside_cendrelis:      $SEED_DATA[:seaside_cendrelis],
  sword_acorus:           $SEED_DATA[:sword_acorus],

  bloodleaf_viburnum:     $SEED_DATA[:bloodleaf_viburnum],
  luminous_calendula:     $SEED_DATA[:luminous_calendula],
  sliverglow_bloom:       $SEED_DATA[:sliverglow_bloom],
  stone_rose:             $SEED_DATA[:stone_rose],

  # Enemy Drops
  whisperin_set: [
    $SEED_DATA[:lf_whisperin_core],
    $SEED_DATA[:mf_whisperin_core],
    $SEED_DATA[:hf_whisperin_core],
    $SEED_DATA[:ff_whisperin_core]
  ],
  howler_set: [
    $SEED_DATA[:lf_howler_core],
    $SEED_DATA[:mf_howler_core],
    $SEED_DATA[:hf_howler_core],
    $SEED_DATA[:ff_howler_core]
  ],
  polygon_set: [
    $SEED_DATA[:lf_polygon_core],
    $SEED_DATA[:mf_polygon_core],
    $SEED_DATA[:hf_polygon_core],
    $SEED_DATA[:ff_polygon_core]
  ],
  tidal_residuum_set: [
    $SEED_DATA[:lf_tidal_residuum_core],
    $SEED_DATA[:mf_tidal_residuum_core],
    $SEED_DATA[:hf_tidal_residuum_core],
    $SEED_DATA[:ff_tidal_residuum_core]
  ],
  ring_set: [
    $SEED_DATA[:crude_ring],
    $SEED_DATA[:basic_ring],
    $SEED_DATA[:improved_ring],
    $SEED_DATA[:tailored_ring]
  ],
  mask_set: [
    $SEED_DATA[:mask_of_constraint],
    $SEED_DATA[:mask_of_erosion],
    $SEED_DATA[:mask_of_distortion],
    $SEED_DATA[:mask_of_insanity]
  ],

  # Forgery Drops
  metallic_drip_set: [
    $SEED_DATA[:inert_metallic_drip],
    $SEED_DATA[:reactive_metallic_drip],
    $SEED_DATA[:polarized_metallic_drip],
    $SEED_DATA[:heterized_metallic_drip]
  ],
  phlogiston_set: [
    $SEED_DATA[:impure_phlogiston],
    $SEED_DATA[:extracted_phlogiston],
    $SEED_DATA[:refined_phlogiston],
    $SEED_DATA[:flawless_phlogiston]
  ],
  helix_set: [
    $SEED_DATA[:lento_helix],
    $SEED_DATA[:adagio_helix],
    $SEED_DATA[:andante_helix],
    $SEED_DATA[:presto_helix]
  ],
  waveworn_residue_set: [
    $SEED_DATA[:waveworn_residue_210],
    $SEED_DATA[:waveworn_residue_226],
    $SEED_DATA[:waveworn_residue_235],
    $SEED_DATA[:waveworn_residue_239]
  ],
  cadence_set: [
    $SEED_DATA[:cadence_seed],
    $SEED_DATA[:cadence_bud],
    $SEED_DATA[:cadence_leaf],
    $SEED_DATA[:cadence_blossom]
  ],

  # Weekly Boss Drops
  curse_of_the_abyss:     $SEED_DATA[:curse_of_the_abyss],
  dreamless_feather:      $SEED_DATA[:dreamless_feather],
  monument_bell:          $SEED_DATA[:monument_bell],
  sentinels_dagger:       $SEED_DATA[:sentinels_dagger],
  the_netherworlds_stare: $SEED_DATA[:the_netherworlds_stare],
  unending_destruction:   $SEED_DATA[:unending_destruction],
  when_irises_bloom:      $SEED_DATA[:when_irises_bloom]
}.freeze

# --- 2. Map resonators to their unique material requirements ---
# This method handles all Boss Drops, Flowers, Enemy Drops, and Weekly Boss Drops
# It creates records in the ResonatorMaterialMap table.
def map_resonator_materials(resonator, boss_mat, flower_mat, enemy_mat, weekly_boss_mat)
  # Boss Drops
  ResonatorMaterialMap.find_or_initialize_by(
    resonator: resonator,
    material_type: "BossDrop",
    rarity: 4
  ).update!(material: boss_mat)

  # Flowers
  ResonatorMaterialMap.find_or_initialize_by(
    resonator: resonator,
    material_type: "Flower",
    rarity: 1
  ).update!(material: flower_mat)

  # Enemy Drops (Rarity 2, 3, 4, 5)
  enemy_mat.each_with_index do |material, idx|
    rarity = idx + 2

    ResonatorMaterialMap.find_or_initialize_by(
      resonator: resonator,
      material_type: "EnemyDrop",
      rarity: rarity
    ).update!(material: material)
  end

  # Weekly Boss Drops
  ResonatorMaterialMap.find_or_initialize_by(
    resonator: resonator,
    material_type: "WeeklyBossDrop",
    rarity: 4
  ).update!(material: weekly_boss_mat)
end

# The order of elements MUST match the arguments of map_resonator_materials:
# [resonator, boss_mat, flower_mat, enemy_mat, weekly_boss_mat]
RESONATOR_MAPPING_DATA = [
  [ RESONATORS[:augusta],       MATERIALS[:blighted_crown_of_puppet_king], MATERIALS[:luminous_calendula],    MATERIALS[:tidal_residuum_set], MATERIALS[:when_irises_bloom] ],
  [ RESONATORS[:brant],         MATERIALS[:blazing_bone],                  MATERIALS[:golden_fleece],         MATERIALS[:tidal_residuum_set], MATERIALS[:the_netherworlds_stare] ],
  [ RESONATORS[:calcharo],      MATERIALS[:thundering_tacet_core],         MATERIALS[:iris],                  MATERIALS[:ring_set],           MATERIALS[:monument_bell] ],
  [ RESONATORS[:camellya],      MATERIALS[:topological_confinement],       MATERIALS[:nova],                  MATERIALS[:whisperin_set],      MATERIALS[:dreamless_feather] ],
  [ RESONATORS[:cantarella],    MATERIALS[:cleansing_conch],               MATERIALS[:seaside_cendrelis],     MATERIALS[:polygon_set],        MATERIALS[:when_irises_bloom] ],
  [ RESONATORS[:carlotta],      MATERIALS[:platinum_core],                 MATERIALS[:sword_acorus],          MATERIALS[:polygon_set],        MATERIALS[:the_netherworlds_stare] ],
  [ RESONATORS[:cartethyia],    MATERIALS[:unfading_glory],                MATERIALS[:bamboo_iris],           MATERIALS[:tidal_residuum_set], MATERIALS[:when_irises_bloom] ],
  [ RESONATORS[:changli],       MATERIALS[:rage_tacet_core],               MATERIALS[:pavo_plum],             MATERIALS[:ring_set],           MATERIALS[:sentinels_dagger] ],
  [ RESONATORS[:chisa],         MATERIALS[:abyssal_husk],                  MATERIALS[:summer_flower],         MATERIALS[:polygon_set],        MATERIALS[:when_irises_bloom] ],
  [ RESONATORS[:ciaccona],      MATERIALS[:blazing_bone],                  MATERIALS[:golden_fleece],         MATERIALS[:tidal_residuum_set], MATERIALS[:when_irises_bloom] ],
  [ RESONATORS[:encore],        MATERIALS[:rage_tacet_core],               MATERIALS[:pecok_flower],          MATERIALS[:whisperin_set],      MATERIALS[:unending_destruction] ],
  [ RESONATORS[:galbrena],      MATERIALS[:blighted_crown_of_puppet_king], MATERIALS[:stone_rose],            MATERIALS[:tidal_residuum_set], MATERIALS[:curse_of_the_abyss] ],
  [ RESONATORS[:iuno],          MATERIALS[:abyssal_husk],                  MATERIALS[:sliverglow_bloom],      MATERIALS[:polygon_set],        MATERIALS[:the_netherworlds_stare] ],
  [ RESONATORS[:jianxin],       MATERIALS[:roaring_rock_fist],             MATERIALS[:lanternberry],          MATERIALS[:whisperin_set],      MATERIALS[:unending_destruction] ],
  [ RESONATORS[:jinhsi],        MATERIALS[:elegy_tacet_core],              MATERIALS[:loongs_pearl],          MATERIALS[:howler_set],         MATERIALS[:sentinels_dagger] ],
  [ RESONATORS[:jiyan],         MATERIALS[:roaring_rock_fist],             MATERIALS[:pecok_flower],          MATERIALS[:howler_set],         MATERIALS[:monument_bell] ],
  [ RESONATORS[:lingyang],      MATERIALS[:sound_keeping_tacet_core],      MATERIALS[:coriolus],              MATERIALS[:whisperin_set],      MATERIALS[:unending_destruction] ],
  [ RESONATORS[:lupa],          MATERIALS[:unfading_glory],                MATERIALS[:bloodleaf_viburnum],    MATERIALS[:howler_set],         MATERIALS[:the_netherworlds_stare] ],
  [ RESONATORS[:phoebe],        MATERIALS[:cleansing_conch],               MATERIALS[:firecracker_jewelweed], MATERIALS[:whisperin_set],      MATERIALS[:sentinels_dagger] ],
  [ RESONATORS[:phrolova],      MATERIALS[:truth_in_lies],                 MATERIALS[:afterlife],             MATERIALS[:polygon_set],        MATERIALS[:the_netherworlds_stare] ],
  [ RESONATORS[:qiuyuan],       MATERIALS[:truth_in_lies],                 MATERIALS[:wintry_bell],           MATERIALS[:whisperin_set],      MATERIALS[:curse_of_the_abyss] ],
  [ RESONATORS[:roccia],        MATERIALS[:cleansing_conch],               MATERIALS[:firecracker_jewelweed], MATERIALS[:tidal_residuum_set], MATERIALS[:the_netherworlds_stare] ],
  [ RESONATORS[:rover_aero],    MATERIALS[:mysterious_code],               MATERIALS[:pecok_flower],          MATERIALS[:whisperin_set],      MATERIALS[:when_irises_bloom] ],
  [ RESONATORS[:rover_havoc],   MATERIALS[:mysterious_code],               MATERIALS[:pecok_flower],          MATERIALS[:whisperin_set],      MATERIALS[:dreamless_feather] ],
  [ RESONATORS[:rover_spectro], MATERIALS[:mysterious_code],               MATERIALS[:pecok_flower],          MATERIALS[:whisperin_set],      MATERIALS[:unending_destruction] ],
  [ RESONATORS[:shorekeeper],   MATERIALS[:topological_confinement],       MATERIALS[:nova],                  MATERIALS[:whisperin_set],      MATERIALS[:sentinels_dagger] ],
  [ RESONATORS[:verina],        MATERIALS[:elegy_tacet_core],              MATERIALS[:belle_poppy],           MATERIALS[:howler_set],         MATERIALS[:monument_bell] ],
  [ RESONATORS[:xiangli_yao],   MATERIALS[:hidden_thunder_tacet_core],     MATERIALS[:violet_coral],          MATERIALS[:whisperin_set],      MATERIALS[:unending_destruction] ],
  [ RESONATORS[:yinlin],        MATERIALS[:group_abomination_tacet_core],  MATERIALS[:coriolus],              MATERIALS[:whisperin_set],      MATERIALS[:dreamless_feather] ],
  [ RESONATORS[:zani],          MATERIALS[:platinum_core],                 MATERIALS[:sword_acorus],          MATERIALS[:polygon_set],        MATERIALS[:the_netherworlds_stare] ],
  [ RESONATORS[:zhezhi],        MATERIALS[:sound_keeping_tacet_core],      MATERIALS[:lanternberry],          MATERIALS[:howler_set],         MATERIALS[:monument_bell] ]
].freeze

puts "  --> Mapping Resonator Materials..."
RESONATOR_MAPPING_DATA.each do |mapping|
  map_resonator_materials(*mapping)
end

puts "  --> Resonator Material Maps created."
# TODO: Weapon Material Maps and Weapon Type Materials Map

