# Echo Farming Support: Design & Plan

Status: **proposal, nothing implemented.** Written 2026-10-05 from a read of the codebase and the community Tacet Fields drop-rate screenshot (the same spreadsheet family as `db/seeds/08_drop_rates.rb`). Items marked **[verify]** are assumptions that need an in-game or wiki check before they go into seeds.

## 1. Goal

Today the app plans Resonator and weapon costs and estimates Waveplate runs for them. Echo leveling is a large Waveplate sink that none of that covers, so the optimizer under-reports what a build really costs. Goal: model **Tacet Fields** as a farmable source and let a plan include **Echo EXP** needs, so the optimizer, Waveplate summary, API and advisor all account for them.

Non-goals for the first release: per-echo catalog, Sonata sets, substat/tuner RNG, choosing which echo a field drops.

## 2. What the data says

Columns of the screenshot, one row per SOL3 phase (Union Level 19 to 70):

| Column group | Meaning | Maps to |
| --- | --- | --- |
| Runs | Sample size behind the row (33, 17, 79, 115, 102, 214, 269, 1697). Not a game parameter. | Provenance comment only. Phases 1 to 3 are thin samples (17 to 79 runs). |
| Union Level / SOL3 Phase | Same 1..8 phases the app already uses. | `DropRate.sol3_phase` |
| Shell | Shell Credit per run (2500 to 5250). | `DropRate`, `material_type: "credit"` |
| Echo drops 5*/4*/3*/2* | Average number of echoes of each rarity per run. | `DropRate`, new `material_type: "echo"` |
| Total Echoes | Sum of the four columns (checked, within rounding). | Derived, not stored. |
| Polyhedra 5*/4*/3* (values like 20, 10/10, 15) | **Unknown**, see open question Q1. Values per phase sum to about 20 and shift toward higher rarity as phase rises, so it looks like a rarity mix of a fixed 20 rather than a per-run average. | Not modeled until answered. |
| Cylinders 5*/4*/3*/2* | Echo EXP tubes per run. | `DropRate`, new `material_type: "echo_exp"` |
| Echo EXP (Total) | EXP per run from the tubes. | Cross-check only. |

**Cross-check I ran.** With tube values 5* = 5000, 4* = 2000, 3* = 1000 EXP, tubes per run times EXP reproduces the sheet's "Echo EXP (Total)" within 0.2% for all eight phases (for example phase 8: 3.231 x 5000 + 4.00 x 2000 = 24155, exactly the sheet value). So the total excludes the value of the echoes themselves and the tube EXP values are confirmed for 3* to 5*. The 2* tube never drops in the sheet, so its value (500 assumed) is **[verify]**.

Other notes:
- Phases 1 to 8 are all present, unlike forgery data which starts at phase 3, so no fallback is needed.
- Waveplate cost per Tacet Field run is 60 **[verify]**.

## 3. How the existing code fits

Reusable as-is:
- `DropRate(source, sol3_phase, rarity, material_type, avg_quantity)` can hold all three new kinds of row with no schema change.
- `DropRateService` already converts EXP tiers into rarity-2 equivalents (`calculate_exp_avg_quantity`), exactly how Echo EXP tubes would work.
- `FarmingPriorityService` and the optimizer view are source-type driven; a new type only needs a label.

Hard-coded EXP assumptions that must be generalized (otherwise tubes silently behave like ordinary materials):

| Location | Hard-coded |
| --- | --- |
| `app/services/drop_rate_service.rb` | `EXP_MATERIAL_TYPES = %w[resonator_exp weapon_exp]` |
| `app/services/synthesis_service.rb` | `exp_potion?` list |
| `app/controllers/inventory_items_controller.rb` | `exp_potion?` list and plan filter via `Plan::EXP_POTION_TYPE_MAP` |
| `app/models/material.rb` | `CATEGORY_ORDER`, `MATERIAL_TYPE_ORDER` |

Fix: one `Material::EXP_TYPES` constant used by all of them, then add `echo_exp`.

### Two pre-existing issues this feature would make worse

1. **Inventory rows are only created for new users.** `User#initialize_inventory` runs `after_create`; nothing backfills when new materials are seeded (no migration or seed step touches `InventoryItem`). Existing users therefore have no inventory row for materials added after they signed up, including, probably, the 3.2 to 3.7 additions. New Echo EXP tubes would be invisible to them. Needs an idempotent backfill (`insert_all` with `unique_by: [user_id, material_id]`) run from seeds (production seeds on every boot) and a regression test. **[verify on production data]**
2. **`OptimizersController#compute_source_totals` appears to over-count.** It sums `estimated_runs` across *every* source returned for *every* material, not the best source per material. Shell Credit has three identical Simulation sources, so by my reading they are counted three times in "Total runs" and "Estimated cost". Not yet confirmed at runtime. If Tacet Field were linked as a Shell Credit source (2,500 to 5,250 Shell for 60 Waveplate versus 24,000 to 84,000 for 40 Waveplate in Simulation), it would add a large phantom cost. So: **do not link Shell Credit to Tacet Field in v1**, and fix totals first (pick the cheapest source per material, then take the max runs per source because one run drops everything).

## 4. Proposed design

### 4.1 Data (seeds only, no migrations)

- `03_materials.rb`: category `Echo EXP Material`, type `echo_exp`, four tubes: Basic (2*, 500), Medium (3*, 1000), Advanced (4*, 2000), Premium (5*, 5000). Not grouped (like potions, not synthesizable). Names and art **[verify]**: the sheet only shows icons.
- `06_sources.rb`: one source `Tacet Field`, `source_type: "tacet_field_challenge"`, 60 Waveplate, region "Any". The sheet gives one rate per phase, so per-field rows add nothing until echo-specific drops are modeled.
- `07_material_sources.rb`: link the four tubes to `Tacet Field` (not Shell Credit, see above).
- `08_drop_rates.rb`: eight phases x four tube rarities (zeros omitted, as `avg_quantity > 0` is validated). Keep the "Runs" sample sizes in a comment.
- `FarmingPriorityService::SOURCE_TYPE_LABELS`: add `"tacet_field_challenge" => "Tacet Field"`.
- `docs/GAME_DATA.md` and `docs/DATA_MODEL.md`: new type, source and checklist.

Echo drops themselves (`material_type: "echo"`) are stored only if Q1/Q2 call for an echo-supply feature (section 6, phase 3).

### 4.2 Planning: how echo needs enter a plan

Three options, with a recommendation:

| Option | Description | Pros | Cons |
| --- | --- | --- | --- |
| **A (recommended)** | Add an optional "Echoes" section to the Resonator plan form: number of echoes (default 5, the in-game loadout), their rarity and target level. The planner adds `echo_exp` (in Basic Tube units) and Shell to `plan_data.output`. | No new plan type; fits per-Resonator build thinking; inventory, reconciliation, API and optimizer work unchanged once `echo_exp` is an EXP type. | Needs an echo level-cost table. Resonator plan form grows. |
| B | New plan subject (e.g. "Echo build"). | Clean separation. | `Plan.subject` is polymorphic and unique per `[user, subject_type, subject_id]`; needs a new subject table, form flow, serializers. Much bigger. |
| C | Standalone calculator on the optimizer page ("I need N Echo EXP"). | Smallest. | Not saved, not reconciled against inventory, invisible to API and advisor. |

Recommendation: **A**, shipped after the data and refactor steps. C is an acceptable stop-gap if A's data collection stalls.

Needed data for A: Echo EXP and Shell cost per level for each echo rarity (max levels 25/20/15/10/5 for 5* to 1* **[verify]**), as a new `EchoLevelCost(rarity, level, exp_required, credit_cost)` table mirroring `ResonatorLevelCost`. Collect from the wiki and cross-check against a few known totals before seeding.

`PlanForm` additions: `echo_count`, `echo_rarity`, `echo_target_level` (inputs stored under `plan_data.input`, defaulting to "not planning echoes" so existing plans are unaffected). `ResonatorAscensionPlanner` gets an `calculate_echo_costs` step, converting EXP to Basic Tubes the same way `convert_exp_to_potions` does.

Note: that conversion uses integer division (`total_exp / potion.exp_value`), which rounds down. For Echo EXP use `ceil` so a plan is never short; the existing potion code probably deserves the same change **[verify]**.

### 4.3 Optimizer, summary, API, advisor

- Optimizer and `WaveplateSummaryService`: no code change beyond the EXP constant. Tubes resolve to the `Tacet Field` source through `DropRateService` and appear in `FARMING_PRIORITY` with the new label. (Totals fix from section 3 is a prerequisite.)
- API: `materials` and `plans` responses gain the four tube keys (`basic_sealed_tube`, ...; key = `Material#snake_case_name`) and the new source. Update `docs/API.md` examples.
- Advisor (`FarmingAdvisorService`): add a line to the prompt that Echo EXP tubes come only from Tacet Fields, so it does not mix them up with potions. Tests stub `LlmClient`, so this is prompt-only.
- Inventory: new category group and tube images in `public/images/materials/` (`bin/rails images:missing`; extend `config/image_sources.yml` if wiki names differ).

### 4.4 Tests

- `drop_rate_service_test`: tube EXP equivalence at a phase, deficit to runs.
- `synthesis_service_test`: owned higher tubes satisfy a Basic-tube requirement (mirrors the potion tests).
- `seed_data_integrity_test`: every `echo_exp` material has `Tacet Field` as a source with drop rates for phases 1 to 8.
- `resonator_ascension_planner_test`: echo section off leaves output unchanged; on adds `echo_exp` and Shell.
- Optimizer controller test covering totals with Shell and tube deficits together (guards the over-count fix).
- Inventory backfill test.
- System test: create a plan with echoes, enter inventory, run the optimizer.

## 5. Risks

| Risk | Mitigation |
| --- | --- |
| Sheet data is community-sourced; phases 1 to 3 have small samples | Record sample sizes in seed comments; note it in docs. |
| Echo level-cost data is not in the repo and I have not verified numbers | Collect and cross-check before coding the planner; ship data-only steps first. |
| Existing users lack inventory rows for new materials | Backfill step (section 3). |
| Optimizer totals over-count | Fix and test before adding a new source. |
| Production seeds on every boot and never delete | Keep seed changes additive; renames need a one-off cleanup. |

## 6. Phased plan

1. **Foundations (no user-visible echo yet).** `Material::EXP_TYPES` refactor; inventory backfill; optimizer totals fix. Each is independently valuable and testable.
2. **Tacet Field data.** Materials, source, drop rates, label, images, integrity tests, docs. Optimizer can already show a tube deficit if one is entered manually.
3. **Echo planning (Option A).** `EchoLevelCost` data, `PlanForm` and planner changes, plan UI section, API/doc updates, advisor prompt, tests, system test.
4. **Optional, only if wanted (Q1/Q2):** echo-supply goals ("I need N 5* echoes") from the per-rarity echo drop rates, and any use of the unexplained polyhedra columns.

Each phase gets its own `CHANGELOG.md` entry; phases 1 and 2 are patch/minor, phase 3 is a minor release.

## 7. Open questions

- **Q1.** What are the three polyhedra columns (5*/4*/3*, values such as 20, 10/10, 15)? My guess is a rarity mix of a fixed pool of 20 tied to the data bank level, but I could not derive it from the other columns.
- **Q2.** Is "how many Waveplates to farm tubes for my echo build" the whole goal, or do you also want "how many runs to get N echoes of rarity R"? The latter is possible with the per-rarity echo columns but not per specific echo or Sonata set.
- **Q3.** Option A (echoes inside Resonator plans) versus C (standalone calculator)?
- **Q4.** Confirm in game: Tacet Field cost (60 Waveplate), tube names and the 2* tube value, echo max levels, and whether leveling echoes also costs Shell.
