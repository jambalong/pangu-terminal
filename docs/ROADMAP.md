# Roadmap & Known Issues

Working backlog for bringing the project "up to current". Last reviewed 2026-10-05 (game version 3.7 released 2026-09-30; all docs audited against the repo). Check items off (and add a `CHANGELOG.md` entry) as they land.

## Done (v1.1.0)

- [x] Documentation foundation (`docs/`, `AGENTS.md`, `CLAUDE.md`).
- [x] Drop rates re-verified against the community spreadsheet screenshot for 3.7. Weekly boss, world boss, forgery and simulation (Shell / Resonator EXP / Weapon EXP) values for all SOL3 phases match `db/seeds/08_drop_rates.rb`; no changes were needed.
- [x] Kamal deployment removed (kept only in git history; see [DEPLOYMENT.md](DEPLOYMENT.md#history)).
- [x] Dependencies: patch/minor bumps plus `ruby_llm` 2.0.0 (required: 1.16.0 had a high-severity ReDoS advisory, CVE-2026-67991, that failed `bin/bundler-audit`) and Gemini model moved off the deprecated preview id.

## Done (v1.2.x)

- [x] Game data 3.2 to 3.7 phase 1 (v1.2.0): 12 Resonators, 11 weapons, new materials, sources and mappings; Fusion Accretion mapped to the Ring set; seed data integrity tests.
- [x] Image tooling (v1.2.1 to v1.2.3): `images:missing` / `images:download` with Fandom URL derivation, `Normal-Attack` skill icon labels, per-icon URL override for Hiyuki's Inherent Skill 1.
- [x] Image assets for the new content (portraits, weapon and material icons, forte skill icons).

## Done (v1.3.0)

- [x] Guest plan uniqueness is scoped by `guest_token` (one guest no longer blocks every other guest from planning the same subject).
- [x] API 500s log the exception class and a backtrace excerpt; `Api::V1::InventoryController` uses `@current_user`.
- [x] `LlmClient` fallback message is a single constant with `fallback?`, covered by tests.
- [x] Optimizer computation extracted into `OptimizerService`; farming advice cached for one day per prompt digest.
- [x] `libvips` removed from the Dockerfile; agent guidance (`AGENTS.md`, `CLAUDE.md`, `.claude/settings.json`) rewritten with workflow, boundaries and a definition of done.

## 1. Game data: remaining

- [ ] **Deferred until the 2026-10-22 release is confirmed:** Suoming (Electro Sword; flower Miasmic Branch; boss Forged Empyrean's Sigh; enemy set Howler Core; skill boss Remnant of the Wheel; stats unknown) and her weapon Unspoken Rue (Sword on the Polarizer set per wiki "likely"; enemy-drop set unknown).
- [ ] Consider moving region/forgery-set membership into data (e.g. `resonators.region`, `weapons.region`) instead of the name lists `LAHAI_ROI_RESONATORS` / `LAHAI_ROI_WEAPONS`.
- [ ] Check cost tables (`04_cost_templates.rb`) and the SOL3 phase cap (hard-coded `1..8` in `DropRate`, the dashboard dropdown and `Api::V1::ProfileController`) against 3.7.
- [ ] Optional feature: the drop-rate spreadsheet also covers **Tacet Fields** (echo drops and Echo EXP), which the app does not model.

## 2. Remaining dependency / platform work

- [x] `image_processing` removed (unused; v1.1.1).
- [ ] Re-check Ruby (3.4.7 in `.ruby-version`, `mise.toml`, `Dockerfile`) and PostgreSQL (17 in docker-compose and CI) against current releases; change them together.
- [ ] GitHub Actions versions in `ci.yml` are managed by Dependabot.

## 3. Documentation follow-ups

- [ ] Remaining **TODO(owner)** in [DEPLOYMENT.md](DEPLOYMENT.md): Environment-tab variable names and the Neon endpoint type (Render service settings are now recorded).
- [ ] Keep `docs/API.md` examples in sync with `app/serializers/` when response shapes change (the forte-node booleans in the serializer output are intentional; plans store `0/1` integers).

## 4. Code observations (not yet verified as bugs)

- `Api::V1::InventoryController#index` uses `current_user` while the rest of the API uses `@current_user` (works via Devise's memoization; consider switching for consistency).
- `config.hosts` and the mailer host are hard-coded in `config/environments/production.rb`; consider env-driven values.
- Production runs `db:seed` on every boot; seeds are idempotent but add boot time and never delete. Consider a one-off step if boot time matters on the free tier.
- Solid Queue/Cable are installed but there are no jobs; confirm whether they should stay.
- Orphaned guest plans (`guest_token` cookie) are never cleaned up.
- `SKILL_LABEL_OVERRIDES` is duplicated in `db/seeds/01_resonators.rb` and `lib/tasks/forte_icons.rake`; consider a single source (e.g. a YAML file read by both).
- **Stale plans:** `plans.plan_data.output` is computed once at save time. Changing cost tables, mappings or region lists (`LAHAI_ROI_*`) does not update existing plans. The `input` is stored, so a recompute task (for example `plans:recompute`) or recompute-on-read is feasible. Needs a decision first.
- `PlanForm` generates about 30 attributes per skill/node and maps them back into three hand-built hashes; a nested `skills` params shape would remove most of it but changes the form and views.
- The advisor LLM call is still synchronous inside the request (20s timeout). Caching removes repeat calls; moving the first call to a background job or streaming would remove the blocked worker.
- `InventoryItemsController#update` only handles Turbo Stream on validation failure; a plain HTML failure has no response branch.
- Verify the Farming Advisor on production after the `ruby_llm` 2.0 deploy (tests stub the LLM client).
