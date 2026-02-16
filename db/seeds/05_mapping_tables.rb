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
  aemeath:        $SEED_DATA[:aemeath],
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
  luuk_herssen:   $SEED_DATA[:luuk_herssen],
  lynae:          $SEED_DATA[:lynae],
  mornye:         $SEED_DATA[:mornye],
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
  buling:         $SEED_DATA[:buling],
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
  boson_astrolabe:        $SEED_DATA[:boson_astrolabe],
  cosmic_ripples:         $SEED_DATA[:cosmic_ripples],
  daybreakers_spine:      $SEED_DATA[:daybreakers_spine],
  defiers_thorn:          $SEED_DATA[:defiers_thorn],
  emerald_of_genesis:     $SEED_DATA[:emerald_of_genesis],
  emerald_sentence:       $SEED_DATA[:emerald_sentence],
  everbright_polestar:    $SEED_DATA[:everbright_polestar],
  kumokiri:               $SEED_DATA[:kumokiri],
  laser_shearer:          $SEED_DATA[:laser_shearer],
  lethean_elegy:          $SEED_DATA[:lethean_elegy],
  luminous_hymn:          $SEED_DATA[:luminous_hymn],
  lustrous_razor:         $SEED_DATA[:lustrous_razor],
  lux_umbra:              $SEED_DATA[:lux_umbra],
  moongazers_sigil:       $SEED_DATA[:moongazers_sigil],
  phasic_homogenizer:     $SEED_DATA[:phasic_homogenizer],
  pulsation_bracer:       $SEED_DATA[:pulsation_bracer],
  radiance_cleaver:       $SEED_DATA[:radiance_cleaver],
  red_spring:             $SEED_DATA[:red_spring],
  rime_draped_sprouts:    $SEED_DATA[:rime_draped_sprouts],
  spectrum_blaster:       $SEED_DATA[:spectrum_blaster],
  starfield_calibrator:   $SEED_DATA[:starfield_calibrator],
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
  abyssal_husk:                   $SEED_DATA[:abyssal_husk],
  blazing_bone:                   $SEED_DATA[:blazing_bone],
  blighted_crown_of_puppet_king:  $SEED_DATA[:blighted_crown_of_puppet_king],
  burning_judgment:               $SEED_DATA[:burning_judgment],
  cleansing_conch:                $SEED_DATA[:cleansing_conch],
  elegy_tacet_core:               $SEED_DATA[:elegy_tacet_core],
  gold_dissolving_feather:        $SEED_DATA[:gold_dissolving_feather],
  group_abomination_tacet_core:   $SEED_DATA[:group_abomination_tacet_core],
  hidden_thunder_tacet_core:      $SEED_DATA[:hidden_thunder_tacet_core],
  mysterious_code:                $SEED_DATA[:mysterious_code],
  our_choice:                     $SEED_DATA[:our_choice],
  platinum_core:                  $SEED_DATA[:platinum_core],
  rage_tacet_core:                $SEED_DATA[:rage_tacet_core],
  roaring_rock_fist:              $SEED_DATA[:roaring_rock_fist],
  sound_keeping_tacet_core:       $SEED_DATA[:sound_keeping_tacet_core],
  strife_tacet_core:              $SEED_DATA[:strife_tacet_core],
  suncoveters_reach:              $SEED_DATA[:suncoveters_reach],
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
  violet_coral:           $SEED_DATA[:violet_coral],
  wintry_bell:            $SEED_DATA[:wintry_bell],

  loongs_pearl:           $SEED_DATA[:loongs_pearl],
  pavo_plum:              $SEED_DATA[:pavo_plum],

  nova:                   $SEED_DATA[:nova],
  summer_flower:          $SEED_DATA[:summer_flower],

  afterlife:              $SEED_DATA[:afterlife],
  bamboo_iris:            $SEED_DATA[:bamboo_iris],
  bloodleaf_viburnum:     $SEED_DATA[:bloodleaf_viburnum],
  firecracker_jewelweed:  $SEED_DATA[:firecracker_jewelweed],
  golden_fleece:          $SEED_DATA[:golden_fleece],
  luminous_calendula:     $SEED_DATA[:luminous_calendula],
  seaside_cendrelis:      $SEED_DATA[:seaside_cendrelis],
  sliverglow_bloom:       $SEED_DATA[:sliverglow_bloom],
  stone_rose:             $SEED_DATA[:stone_rose],
  sword_acorus:           $SEED_DATA[:sword_acorus],

  arithmetic_shell:       $SEED_DATA[:arithmetic_shell],
  edelschnee:             $SEED_DATA[:edelschnee],
  gemini_spore:           $SEED_DATA[:gemini_spore],
  moss_amber:             $SEED_DATA[:moss_amber],
  rimewisp:               $SEED_DATA[:rimewisp],

  # Enemy Drops
  whisperin_core_set: [
    $SEED_DATA[:lf_whisperin_core],
    $SEED_DATA[:mf_whisperin_core],
    $SEED_DATA[:hf_whisperin_core],
    $SEED_DATA[:ff_whisperin_core]
  ],
  howler_core_set: [
    $SEED_DATA[:lf_howler_core],
    $SEED_DATA[:mf_howler_core],
    $SEED_DATA[:hf_howler_core],
    $SEED_DATA[:ff_howler_core]
  ],
  polygon_core_set: [
    $SEED_DATA[:lf_polygon_core],
    $SEED_DATA[:mf_polygon_core],
    $SEED_DATA[:hf_polygon_core],
    $SEED_DATA[:ff_polygon_core]
  ],
  tidal_residuum_core_set: [
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
  exoswarm_core_set: [
    $SEED_DATA[:lf_exoswarm_core],
    $SEED_DATA[:mf_exoswarm_core],
    $SEED_DATA[:hf_exoswarm_core],
    $SEED_DATA[:ff_exoswarm_core]
  ],
  mech_core_set: [
    $SEED_DATA[:lf_mech_core],
    $SEED_DATA[:mf_mech_core],
    $SEED_DATA[:hf_mech_core],
    $SEED_DATA[:ff_mech_core]
  ],
  exoswarm_pendant_set: [
    $SEED_DATA[:fractured_exoswarm_pendant],
    $SEED_DATA[:worn_exoswarm_pendant],
    $SEED_DATA[:chipped_exoswarm_pendant],
    $SEED_DATA[:intact_exoswarm_pendant]
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
  polarizer_set: [
    $SEED_DATA[:broken_wing_polarizer],
    $SEED_DATA[:monowing_polarizer],
    $SEED_DATA[:polywing_polarizer],
    $SEED_DATA[:layered_wing_polarizer]
  ],
  combustor_set: [
    $SEED_DATA[:incomplete_combustor],
    $SEED_DATA[:aftertune_combustor],
    $SEED_DATA[:remnant_combustor],
    $SEED_DATA[:reverb_combustor]
  ],
  string_set: [
    $SEED_DATA[:spliced_string],
    $SEED_DATA[:broken_string],
    $SEED_DATA[:solidified_string],
    $SEED_DATA[:melodic_string]
  ],
  carved_crystal_set: [
    $SEED_DATA[:lf_carved_crystal],
    $SEED_DATA[:mf_carved_crystal],
    $SEED_DATA[:hf_carved_crystal],
    $SEED_DATA[:ff_carved_crystal]
  ],
  waveworn_shard_set: [
    $SEED_DATA[:lf_waveworn_shard],
    $SEED_DATA[:mf_waveworn_shard],
    $SEED_DATA[:hf_waveworn_shard],
    $SEED_DATA[:ff_waveworn_shard]
  ],

  # Weekly Boss Drops
  curse_of_the_abyss:     $SEED_DATA[:curse_of_the_abyss],
  dreamless_feather:      $SEED_DATA[:dreamless_feather],
  gold_in_memory:         $SEED_DATA[:gold_in_memory],
  monument_bell:          $SEED_DATA[:monument_bell],
  sentinels_dagger:       $SEED_DATA[:sentinels_dagger],
  the_netherworlds_stare: $SEED_DATA[:the_netherworlds_stare],
  unending_destruction:   $SEED_DATA[:unending_destruction],
  wave_cutting_tooth:     $SEED_DATA[:wave_cutting_tooth],
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
  # 5-star Resonators
  [ RESONATORS[:aemeath],       MATERIALS[:our_choice],                    MATERIALS[:moss_amber],            MATERIALS[:exoswarm_core_set],        MATERIALS[:gold_in_memory] ],
  [ RESONATORS[:augusta],       MATERIALS[:blighted_crown_of_puppet_king], MATERIALS[:luminous_calendula],    MATERIALS[:tidal_residuum_core_set],  MATERIALS[:when_irises_bloom] ],
  [ RESONATORS[:brant],         MATERIALS[:blazing_bone],                  MATERIALS[:golden_fleece],         MATERIALS[:tidal_residuum_core_set],  MATERIALS[:the_netherworlds_stare] ],
  [ RESONATORS[:calcharo],      MATERIALS[:thundering_tacet_core],         MATERIALS[:iris],                  MATERIALS[:ring_set],                 MATERIALS[:monument_bell] ],
  [ RESONATORS[:camellya],      MATERIALS[:topological_confinement],       MATERIALS[:nova],                  MATERIALS[:whisperin_core_set],       MATERIALS[:dreamless_feather] ],
  [ RESONATORS[:cantarella],    MATERIALS[:cleansing_conch],               MATERIALS[:seaside_cendrelis],     MATERIALS[:polygon_core_set],         MATERIALS[:when_irises_bloom] ],
  [ RESONATORS[:carlotta],      MATERIALS[:platinum_core],                 MATERIALS[:sword_acorus],          MATERIALS[:polygon_core_set],         MATERIALS[:the_netherworlds_stare] ],
  [ RESONATORS[:cartethyia],    MATERIALS[:unfading_glory],                MATERIALS[:bamboo_iris],           MATERIALS[:tidal_residuum_core_set],  MATERIALS[:when_irises_bloom] ],
  [ RESONATORS[:changli],       MATERIALS[:rage_tacet_core],               MATERIALS[:pavo_plum],             MATERIALS[:ring_set],                 MATERIALS[:sentinels_dagger] ],
  [ RESONATORS[:chisa],         MATERIALS[:abyssal_husk],                  MATERIALS[:summer_flower],         MATERIALS[:polygon_core_set],         MATERIALS[:when_irises_bloom] ],
  [ RESONATORS[:ciaccona],      MATERIALS[:blazing_bone],                  MATERIALS[:golden_fleece],         MATERIALS[:tidal_residuum_core_set],  MATERIALS[:when_irises_bloom] ],
  [ RESONATORS[:encore],        MATERIALS[:rage_tacet_core],               MATERIALS[:pecok_flower],          MATERIALS[:whisperin_core_set],       MATERIALS[:unending_destruction] ],
  [ RESONATORS[:galbrena],      MATERIALS[:blighted_crown_of_puppet_king], MATERIALS[:stone_rose],            MATERIALS[:tidal_residuum_core_set],  MATERIALS[:curse_of_the_abyss] ],
  [ RESONATORS[:iuno],          MATERIALS[:abyssal_husk],                  MATERIALS[:sliverglow_bloom],      MATERIALS[:polygon_core_set],         MATERIALS[:the_netherworlds_stare] ],
  [ RESONATORS[:jianxin],       MATERIALS[:roaring_rock_fist],             MATERIALS[:lanternberry],          MATERIALS[:whisperin_core_set],       MATERIALS[:unending_destruction] ],
  [ RESONATORS[:jinhsi],        MATERIALS[:elegy_tacet_core],              MATERIALS[:loongs_pearl],          MATERIALS[:howler_core_set],          MATERIALS[:sentinels_dagger] ],
  [ RESONATORS[:jiyan],         MATERIALS[:roaring_rock_fist],             MATERIALS[:pecok_flower],          MATERIALS[:howler_core_set],          MATERIALS[:monument_bell] ],
  [ RESONATORS[:lingyang],      MATERIALS[:sound_keeping_tacet_core],      MATERIALS[:coriolus],              MATERIALS[:whisperin_core_set],       MATERIALS[:unending_destruction] ],
  [ RESONATORS[:lupa],          MATERIALS[:unfading_glory],                MATERIALS[:bloodleaf_viburnum],    MATERIALS[:howler_core_set],          MATERIALS[:the_netherworlds_stare] ],
  [ RESONATORS[:luuk_herssen],  MATERIALS[:suncoveters_reach],             MATERIALS[:edelschnee],            MATERIALS[:exoswarm_pendant_set],     MATERIALS[:gold_in_memory] ],
  [ RESONATORS[:lynae],         MATERIALS[:suncoveters_reach],             MATERIALS[:rimewisp],              MATERIALS[:exoswarm_core_set],        MATERIALS[:dreamless_feather] ],
  [ RESONATORS[:mornye],        MATERIALS[:burning_judgment],              MATERIALS[:gemini_spore],          MATERIALS[:mech_core_set],            MATERIALS[:the_netherworlds_stare] ],
  [ RESONATORS[:phoebe],        MATERIALS[:cleansing_conch],               MATERIALS[:firecracker_jewelweed], MATERIALS[:whisperin_core_set],       MATERIALS[:sentinels_dagger] ],
  [ RESONATORS[:phrolova],      MATERIALS[:truth_in_lies],                 MATERIALS[:afterlife],             MATERIALS[:polygon_core_set],         MATERIALS[:the_netherworlds_stare] ],
  [ RESONATORS[:qiuyuan],       MATERIALS[:truth_in_lies],                 MATERIALS[:wintry_bell],           MATERIALS[:whisperin_core_set],       MATERIALS[:curse_of_the_abyss] ],
  [ RESONATORS[:roccia],        MATERIALS[:cleansing_conch],               MATERIALS[:firecracker_jewelweed], MATERIALS[:tidal_residuum_core_set],  MATERIALS[:the_netherworlds_stare] ],
  [ RESONATORS[:rover_aero],    MATERIALS[:mysterious_code],               MATERIALS[:pecok_flower],          MATERIALS[:whisperin_core_set],       MATERIALS[:when_irises_bloom] ],
  [ RESONATORS[:rover_havoc],   MATERIALS[:mysterious_code],               MATERIALS[:pecok_flower],          MATERIALS[:whisperin_core_set],       MATERIALS[:dreamless_feather] ],
  [ RESONATORS[:rover_spectro], MATERIALS[:mysterious_code],               MATERIALS[:pecok_flower],          MATERIALS[:whisperin_core_set],       MATERIALS[:unending_destruction] ],
  [ RESONATORS[:shorekeeper],   MATERIALS[:topological_confinement],       MATERIALS[:nova],                  MATERIALS[:whisperin_core_set],       MATERIALS[:sentinels_dagger] ],
  [ RESONATORS[:verina],        MATERIALS[:elegy_tacet_core],              MATERIALS[:belle_poppy],           MATERIALS[:howler_core_set],          MATERIALS[:monument_bell] ],
  [ RESONATORS[:xiangli_yao],   MATERIALS[:hidden_thunder_tacet_core],     MATERIALS[:violet_coral],          MATERIALS[:whisperin_core_set],       MATERIALS[:unending_destruction] ],
  [ RESONATORS[:yinlin],        MATERIALS[:group_abomination_tacet_core],  MATERIALS[:coriolus],              MATERIALS[:whisperin_core_set],       MATERIALS[:dreamless_feather] ],
  [ RESONATORS[:zani],          MATERIALS[:platinum_core],                 MATERIALS[:sword_acorus],          MATERIALS[:polygon_core_set],         MATERIALS[:the_netherworlds_stare] ],
  [ RESONATORS[:zhezhi],        MATERIALS[:sound_keeping_tacet_core],      MATERIALS[:lanternberry],          MATERIALS[:howler_core_set],          MATERIALS[:monument_bell] ],

  # 4-star Resonators
  # [resonator, boss_mat, flower_mat, enemy_mat, weekly_boss_mat]
  [ RESONATORS[:aalto],         MATERIALS[:roaring_rock_fist],             MATERIALS[:wintry_bell],           MATERIALS[:howler_core_set],          MATERIALS[:monument_bell] ],
  [ RESONATORS[:baizhi],        MATERIALS[:sound_keeping_tacet_core],      MATERIALS[:lanternberry],          MATERIALS[:howler_core_set],          MATERIALS[:monument_bell] ],
  [ RESONATORS[:buling],        MATERIALS[:blighted_crown_of_puppet_king], MATERIALS[:pecok_flower],          MATERIALS[:whisperin_core_set],       MATERIALS[:curse_of_the_abyss] ],
  [ RESONATORS[:chixia],        MATERIALS[:rage_tacet_core],               MATERIALS[:belle_poppy],           MATERIALS[:whisperin_core_set],       MATERIALS[:monument_bell] ],
  [ RESONATORS[:danjin],        MATERIALS[:strife_tacet_core],             MATERIALS[:belle_poppy],           MATERIALS[:ring_set],                 MATERIALS[:dreamless_feather] ],
  [ RESONATORS[:lumi],          MATERIALS[:thundering_tacet_core],         MATERIALS[:terraspawn_fungus],     MATERIALS[:howler_core_set],          MATERIALS[:sentinels_dagger] ],
  [ RESONATORS[:mortefi],       MATERIALS[:rage_tacet_core],               MATERIALS[:coriolus],              MATERIALS[:whisperin_core_set],       MATERIALS[:monument_bell] ],
  [ RESONATORS[:sanhua],        MATERIALS[:sound_keeping_tacet_core],      MATERIALS[:wintry_bell],           MATERIALS[:whisperin_core_set],       MATERIALS[:unending_destruction] ],
  [ RESONATORS[:taoqi],         MATERIALS[:gold_dissolving_feather],       MATERIALS[:iris],                  MATERIALS[:howler_core_set],          MATERIALS[:dreamless_feather] ],
  [ RESONATORS[:yangyang],      MATERIALS[:roaring_rock_fist],             MATERIALS[:wintry_bell],           MATERIALS[:ring_set],                 MATERIALS[:unending_destruction] ],
  [ RESONATORS[:youhu],         MATERIALS[:topological_confinement],       MATERIALS[:violet_coral],          MATERIALS[:ring_set],                 MATERIALS[:monument_bell] ],
  [ RESONATORS[:yuanwu],        MATERIALS[:hidden_thunder_tacet_core],     MATERIALS[:terraspawn_fungus],     MATERIALS[:ring_set],                 MATERIALS[:unending_destruction] ]
].freeze

puts "  --> Mapping Resonator Materials..."
RESONATOR_MAPPING_DATA.each do |mapping|
  map_resonator_materials(*mapping)
end

puts "  --> Resonator Material Maps created."

# --- 3. Map weapons to their unique material requirements ---
# This method handles all Weapons and Enemy Drop requirements
# It creates records in the WeaponMaterialMap table.
def map_weapon_materials(material_set, weapon_array)
  material_set.each_with_index do |material, idx|
    rarity = idx + 2

    weapon_array.each do |weapon|
      WeaponMaterialMap.find_or_initialize_by(
        weapon: weapon,
        material_type: "EnemyDrop",
        rarity: rarity
      ).update!(material: material)
    end
  end
end

# Each material set contains an array of weapons that requires the material set
WEAPON_MAPPING_DATA = {
  MATERIALS[:whisperin_core_set] => [
    # 5-Star
    WEAPONS[:ages_of_harvest],
    WEAPONS[:kumokiri],
    WEAPONS[:lustrous_razor],
    WEAPONS[:thunderflare_dominion],
    WEAPONS[:verdant_summit],
    WEAPONS[:wildfire_mark],
    # 4-Star
    WEAPONS[:aureate_zenith],
    WEAPONS[:autumntrace],
    WEAPONS[:broadblade41],
    WEAPONS[:dauntless_evernight],
    WEAPONS[:discord],
    WEAPONS[:helios_cleaver],
    WEAPONS[:meditations_on_mercy],
    WEAPONS[:waning_redshift]
  ].freeze,

  MATERIALS[:howler_core_set] => [
    # 5-Star
    WEAPONS[:abyss_surges],
    WEAPONS[:blazing_brilliance],
    WEAPONS[:blazing_justice],
    WEAPONS[:bloodpacts_pledge],
    WEAPONS[:defiers_thorn],
    WEAPONS[:emerald_of_genesis],
    WEAPONS[:emerald_sentence],
    WEAPONS[:moongazers_sigil],
    WEAPONS[:red_spring],
    WEAPONS[:tragicomedy],
    WEAPONS[:unflickering_valor],
    WEAPONS[:veritys_handle],
    # 4-Star
    WEAPONS[:aether_strike],
    WEAPONS[:amity_accord],
    WEAPONS[:celestial_spiral],
    WEAPONS[:commando_of_conviction],
    WEAPONS[:endless_collapse],
    WEAPONS[:fables_of_wisdom],
    WEAPONS[:feather_edge],
    WEAPONS[:gauntlets21d],
    WEAPONS[:hollow_mirage],
    WEAPONS[:legend_of_drunken_hero],
    WEAPONS[:lumingloss],
    WEAPONS[:lunar_cutter],
    WEAPONS[:marcato],
    WEAPONS[:overture],
    WEAPONS[:somnoire_anchor],
    WEAPONS[:stonard],
    WEAPONS[:sword18]
  ].freeze,

  MATERIALS[:ring_set] => [
    # 5-Star
    WEAPONS[:cosmic_ripples],
    WEAPONS[:lethean_elegy],
    WEAPONS[:luminous_hymn],
    WEAPONS[:lux_umbra],
    WEAPONS[:rime_draped_sprouts],
    WEAPONS[:static_mist],
    WEAPONS[:stellar_symphony],
    WEAPONS[:stringmaster],
    WEAPONS[:the_last_dance],
    WEAPONS[:whispers_of_sirens],
    WEAPONS[:woodland_aria],
    # 4-Star
    WEAPONS[:augment],
    WEAPONS[:cadenza],
    WEAPONS[:call_of_the_abyss],
    WEAPONS[:comet_flare],
    WEAPONS[:jinzhou_keeper],
    WEAPONS[:novaburst],
    WEAPONS[:oceans_gift],
    WEAPONS[:pistols26],
    WEAPONS[:radiant_dawn],
    WEAPONS[:rectifier25],
    WEAPONS[:relativistic_jet],
    WEAPONS[:romance_in_farewell],
    WEAPONS[:solar_flame],
    WEAPONS[:thunderbolt],
    WEAPONS[:undying_flame],
    WEAPONS[:variation],
    WEAPONS[:waltz_in_masquerade]
  ].freeze,

  MATERIALS[:exoswarm_core_set] => [
    # 5-star
    WEAPONS[:boson_astrolabe]
  ].freeze,

  MATERIALS[:mech_core_set] => [
    # 5-Star
    WEAPONS[:daybreakers_spine],
    WEAPONS[:everbright_polestar],
    WEAPONS[:laser_shearer],
    WEAPONS[:pulsation_bracer]
  ].freeze,

  MATERIALS[:exoswarm_pendant_set] => [
    # 5-Star
    WEAPONS[:phasic_homogenizer],
    WEAPONS[:radiance_cleaver],
    WEAPONS[:starfield_calibrator],
    WEAPONS[:spectrum_blaster]
  ].freeze
}.freeze

puts "  --> Mapping Weapon Materials..."
WEAPON_MAPPING_DATA.each do |material_set, weapon_array|
  map_weapon_materials(material_set, weapon_array)
end

puts "  --> Weapon Material Maps created."

# --- 4. Map weapon type to their unique material requirements ---
# This method handles all Weapon Types and Forgery Drops requirements
# It creates records in the WeaponTypeMaterial table.
def map_weapon_type_materials(weapon_type, material_set, region)
  material_set.each_with_index do |material, idx|
    rarity = idx + 2

    WeaponTypeMaterial.find_or_initialize_by(
      weapon_type: weapon_type,
      material_type: "ForgeryDrop",
      rarity: rarity,
      region: region
    ).update!(material: material)
  end
end

BASE_WEAPON_TYPE_MAPPING_DATA = {
  "Sword" => MATERIALS[:metallic_drip_set],
  "Broadblade" => MATERIALS[:waveworn_residue_set],
  "Pistols" => MATERIALS[:phlogiston_set],
  "Gauntlets" => MATERIALS[:cadence_set],
  "Rectifier" => MATERIALS[:helix_set]
}.freeze

LAHAI_ROI_WEAPON_TYPE_MAPPING_DATA = {
  "Sword" => MATERIALS[:polarizer_set],
  "Broadblade" => MATERIALS[:carved_crystal_set],
  "Pistols" => MATERIALS[:combustor_set],
  "Gauntlets" => MATERIALS[:waveworn_shard_set],
  "Rectifier" => MATERIALS[:string_set]
}.freeze

puts "  --> Mapping Weapon Type Materials..."
[
  [ "base", BASE_WEAPON_TYPE_MAPPING_DATA ],
  [ "lahai_roi", LAHAI_ROI_WEAPON_TYPE_MAPPING_DATA ]
].each do |region, mapping_data|
  mapping_data.each do |weapon_type, material_set|
    map_weapon_type_materials(weapon_type, material_set, region)
  end
end

puts "  --> Weapon Type Material Maps created."
