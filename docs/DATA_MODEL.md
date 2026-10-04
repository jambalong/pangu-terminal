# Data Model

Source of truth: `db/schema.rb` and `app/models/`. PostgreSQL 17.

## Overview

```
User ─┬─< Plan >── subject (polymorphic: Resonator | Weapon)
      ├─< InventoryItem >── Material ─┬─< MaterialSource >── Source ─< DropRate
      └─< ApiKey                      ├─< ResonatorMaterialMap >── Resonator
                                      ├─< WeaponMaterialMap >── Weapon
                                      └─< WeaponTypeMaterial
Cost tables (no FKs, keyed by level/rank/material_type):
  ResonatorLevelCost, ResonatorAscensionCost, RoverAscensionCost, SkillCost,
  ForteNodeCost, WeaponLevelCost, WeaponAscensionCost
```

## User-owned tables

| Table | Key columns | Notes |
| --- | --- | --- |
| `users` | `email`, `encrypted_password`, `sol3_phase` (1..8, nullable), Devise reset/remember columns | `after_create :initialize_inventory` inserts a zero-quantity `inventory_items` row per `Material`. |
| `plans` | `user_id` (nullable), `guest_token` (nullable), `subject_type`, `subject_id`, `plan_data` jsonb | Validations: subject type in `Resonator`/`Weapon`, subject must exist, one plan per `(user, subject_type, subject_id)` (unique index), must have `user_id` or `guest_token`. |
| `inventory_items` | `user_id`, `material_id`, `quantity` >= 0 | Unique `(user_id, material_id)`. |
| `api_keys` | `user_id`, `name`, `token` (SHA-256 digest), `last_used_at` | Max 3 per user. Raw token is never stored. |

### `plans.plan_data`

```json
{
  "input": {
    "subject_name": "Aemeath",
    "current_level": 1, "target_level": 90,
    "current_ascension_rank": 0, "target_ascension_rank": 6,
    "current_skill_levels": { "basic_attack": 1, "resonance_skill": 1, "forte_circuit": 1, "resonance_liberation": 1, "intro_skill": 1 },
    "target_skill_levels":  { "basic_attack": 10, "...": 10 },
    "forte_node_upgrades":  { "basic_attack_node_1": 1, "basic_attack_node_2": 1, "...": 1 }
  },
  "output": { "<material_id>": 2500000, "<material_id>": 46 }
}
```

`output` keys are material ids as strings (JSON). `input` is built by `PlanForm#build_input_data` and read back by `PlanForm.from_plan`. Weapon plans only store `subject_name` plus level/ascension keys. Forte node values are `0/1` integers (the API serializer exposes them as booleans, see `PlanSerializer`). Aggregate across plans with `Plan.fetch_materials_summary(plans)`.

## Game data tables (seeded; see [GAME_DATA.md](GAME_DATA.md))

| Table | Purpose |
| --- | --- |
| `resonators` | `name` (unique), `element`, `weapon_type`, `rarity`, `image_url`, `forte_icons` jsonb (stat/skill icon paths for the forte UI) |
| `weapons` | `name` (unique), `weapon_type`, `rarity`, `image_url` |
| `materials` | `name` (unique by validation), `category`, `material_type`, `rarity` 1..5, `exp_value`, `item_group_id` (synthesis family), `image_url`, `description` |
| `resonator_material_maps` / `weapon_material_maps` | Resolve an abstract `material_type` + `rarity` for a specific Resonator/weapon to a concrete `material_id` (unique per material/type/subject) |
| `weapon_type_materials` | Same resolution for materials shared by weapon type (+ optional `region`) |
| `resonator_level_costs`, `weapon_level_costs` | EXP and credit cost per level (weapons also by `weapon_rarity`) |
| `resonator_ascension_costs`, `rover_ascension_costs`, `weapon_ascension_costs` | Material type/rarity/quantity per ascension rank |
| `skill_costs`, `forte_node_costs` | Per skill level / per forte node (`node_identifier`) material costs |
| `sources` | Waveplate-costing farm sources: `name` (unique), `source_type` (`forgery_challenge`, `simulation_challenge`, `boss_challenge`, `weekly_challenge`), `waveplate_cost`, `location`, `region` |
| `material_sources` | Which sources drop which materials (unique pair) |
| `drop_rates` | `avg_quantity` per `(source, sol3_phase 1..8, rarity, material_type)` (unique) |

Enemy drops, quests, exploration and synthesis are intentionally not modeled as sources; such materials have no Waveplate source.

## Infrastructure tables

`solid_queue_*`, `solid_cache_entries`, `solid_cable_messages` come from the Solid* gems (migrations `20251102*`). In production they share the primary database.

## Migrations

`db/migrate/` is chronological from 2025-11-02. `db/schema.rb` is not dumped after migrations in production (`dump_schema_after_migration = false`); regenerate it locally with `bin/rails db:migrate`.
