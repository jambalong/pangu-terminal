# Game Data & Domain Guide

How *Wuthering Waves* concepts map onto this codebase, and how to update game data when a new patch lands. All game data is seeded from `db/seeds/`.

## Domain glossary

| Term | Meaning in the app |
| --- | --- |
| **Resonator** | Playable character (`resonators`): `element`, `weapon_type`, `rarity` (4 or 5). Rover variants are named `Rover-<Element>` and use `RoverAscensionCost` instead of `ResonatorAscensionCost`. |
| **Weapon** | `weapons`: `weapon_type` (Sword, Broadblade, Pistols, Gauntlets, Rectifier), `rarity`. |
| **Ascension rank** | 0..6. Caps level: rank 0 -> 20, 1 -> 40, 2 -> 50, 3 -> 60, 4 -> 70, 5 -> 80, 6 -> 90 (`ASCENSION_LEVEL_CAPS` in `ResonatorAscensionPlanner`). |
| **Skills** | basic_attack, resonance_skill, forte_circuit, resonance_liberation, intro_skill (levels 1..10). |
| **Forte nodes** | Two stat-bonus / inherent-skill nodes per skill (`<skill>_node_1/2`), costs in `forte_node_costs` keyed by `node_identifier`. |
| **Material type** | Abstract kind (`credit`, `resonator_exp`, `weapon_exp`, `boss_drop`, `flower`, `enemy_drop`, `forgery_drop`, `weekly_boss_drop`). Cost tables speak in `(material_type, rarity)`; map tables resolve to a concrete material per Resonator/weapon. |
| **Rarity tier** | Materials rarity 1..5. Lower tiers synthesize 3:1 into the next tier within the same `item_group_id` (not for EXP potions or credits). |
| **EXP potions/cores** | Plans express EXP needs in rarity-2 terms; higher-rarity EXP items count via `exp_value` (`SynthesisService#calculate_exp_satisfaction`). |
| **Waveplate** | Stamina resource. `sources.waveplate_cost` is per run. |
| **SOL3 phase** | 1..8 progression phase of the game's Sol-III world level, set per user (`users.sol3_phase`); selects which `drop_rates` rows apply. |
| **Lahai-Roi (LF) forgery sets** | Newer Resonators and weapons use a different set of weapon-type (forgery) materials (`WeaponTypeMaterial.region = "lahai_roi"` vs `"base"`): Broken Wing Polarizer (Sword), LF Carved Crystal (Broadblade), Incomplete Combustor (Pistols), LF Waveworn Shard (Gauntlets), Spliced String (Rectifier). Membership is **hard-coded** by name in `LAHAI_ROI_RESONATORS` (`app/services/resonator_ascension_planner.rb`) and `LAHAI_ROI_WEAPONS` (`app/services/weapon_ascension_planner.rb`). Despite the name, it now covers every post-3.0 Resonator that uses these sets, including the Mengzhou ones. |

## Seed pipeline

`db/seeds.rb` wraps everything in one transaction and loads `db/seeds/*.rb` in filename order. Files share objects through the global `$SEED_DATA`.

| File | Creates |
| --- | --- |
| `01_resonators.rb` | Resonators (by rarity/element) with forte stat icons (`stat_a`, `stat_b`) |
| `02_weapons.rb` | Weapons |
| `03_materials.rb` | Materials by type/category; sets `image_url` from the name (`/images/materials/<slug>.png`), `exp_value`, `item_group_id` (rarity-2 name's parameterized form starts a group when `grouped: true`) |
| `04_cost_templates.rb` | Level, ascension, skill, forte node and weapon cost tables |
| `05_mapping_tables.rb` | `ResonatorMaterialMap`, `WeaponMaterialMap`, `WeaponTypeMaterial` (reads `$SEED_DATA`) |
| `06_sources.rb` | Waveplate-costing `Source` rows |
| `07_material_sources.rb` | Material <-> Source links |
| `08_drop_rates.rb` | `DropRate` rows (header notes the data date; community-spreadsheet derived) |

Seeds must be **idempotent** (`find_or_initialize_by` + `update!`). Production runs `db:seed` on every boot via `bin/docker-entrypoint`. Because it never deletes, removing a row from a seed file does not remove it from production.

## Adding a new Resonator (patch checklist)

1. `01_resonators.rb`: add the entry under the right rarity/element (`name`, `weapon_type`, `stat_a`, `stat_b`).
2. Art: add `public/images/resonators/<slug>.png` (slug = lowercased name, `'"#&:` stripped, spaces -> `-`; same rule for materials/weapons); forte icons via `bin/rails forte:download_stat_icons forte:download_skill_icons` (needs network and ImageMagick `magick`/`convert`; per-Resonator label overrides are in `lib/tasks/forte_icons.rake`).
3. `05_mapping_tables.rb`: add the Resonator to `RESONATORS` and its `ResonatorMaterialMap` rows (boss drop, flower, enemy drops, forgery drop, weekly boss).
4. If the Resonator's skill materials use the newer (LF) forgery sets, add it to `LAHAI_ROI_RESONATORS` (and new weapons to `LAHAI_ROI_WEAPONS`); ensure matching `WeaponTypeMaterial` rows exist for that region.
5. If it has a new boss/weekly/forgery material: add it in `03_materials.rb` (+ image in `public/images/materials/`), `07_material_sources.rb`, and `08_drop_rates.rb`.
6. Run `bin/rails db:seed` twice to confirm idempotency, then `bin/rails images:missing` to list the image files still to add (fill `config/image_sources.yml` with URL templates or per-record URLs and run `bin/rails images:download` locally to fetch and convert them to 256x256 PNG; ImageMagick required), and `bin/rails test` (`test/models/seed_data_integrity_test.rb` fails if a mapping or source is missing).

## Adding a new weapon

Add to `02_weapons.rb`; add `WeaponMaterialMap` rows in `05_mapping_tables.rb`; add art under `public/images/weapons/`. New weapon rarities require `WeaponLevelCost`/`WeaponAscensionCost` rows for that `weapon_rarity`.

## Adding a new SOL3 phase or updating drop rates

`DropRate.sol3_phase` is validated to `1..8` (`app/models/drop_rate.rb`), the dashboard dropdown is `(1..8)` (`app/views/dashboards/show.html.erb`), and the API validates `1..8` (`Api::V1::ProfileController`). To add phase 9+, change all three and add seed rows in `08_drop_rates.rb`. `DropRateService` falls back to the highest available phase when the user's phase has no row.

## New or changed sources

Add to `06_sources.rb` (unique `name`; `source_type` one of `forgery_challenge`, `simulation_challenge`, `boss_challenge`, `weekly_challenge`; `waveplate_cost` > 0), link in `07_material_sources.rb`, and add drop rates. `FarmingPriorityService::SOURCE_TYPE_LABELS` supplies display labels; an unknown source type falls back to `humanize`, so add a label there for a new type.
