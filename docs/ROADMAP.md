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
- [x] Tailwind removed; stylesheets split into `base/` tokens/global/reset plus per-component files, dead selectors removed, fonts loaded via `<link>`.
- [x] `libvips` removed from the Dockerfile; agent guidance (`AGENTS.md`, `CLAUDE.md`, `.claude/settings.json`) rewritten with workflow, boundaries and a definition of done.

## Done (v1.4.0)

- [x] Stale plans: game data does not change, so plans only need recomputing after a calculation bug fix. `PlanRecomputer` / `bin/rails plans:recompute` (dry run by default, `APPLY=1` to write) rebuilds `output` from the stored `input`.

## Done (v1.4.1)

- [x] Production verified on 2026-10-22: site up on the new build; the Farming Advisor returns real advice and the advice cache works (a repeat request was served from cache). One earlier call fell back, with no trace in the logs, which is why `LlmClient` now logs every failure class (`bin/rails advisor:check` makes one minimal call to diagnose).
- [x] Optimizer no longer returns a 500 when the user has no SOL3 phase set (it shows the phase gate).
- [x] One `DropRate::SOL3_PHASES` range used by drop rate validation, a new `User#sol3_phase` validation (previously any integer could be saved), the dashboard dropdown and the API.
- [x] `SKILL_LABEL_OVERRIDES` has a single source: `config/skill_label_overrides.yml`.
- [x] Plain HTML validation failure on inventory edit redirects back with an alert (was a 406).
- [x] `config.hosts` and the mailer host come from `APP_HOST` / `EXTRA_HOSTS` with the same defaults.
- [x] `bin/dev` runs `bin/rails server` directly; `Procfile.dev` and foreman are gone.
- [x] Orphaned guest plans: `bin/rails plans:prune_guests` (dry run by default, `DAYS=90`, `APPLY=1`). Manual on purpose: nothing deletes user data automatically.

## Done (unreleased, heading for v1.5.0)

- [x] `PlanForm` DRY: one `SKILLS` list drives attributes, the mapping hashes and the controller's permitted params. The flat form field names are unchanged, so no view or JavaScript change was needed (a nested params shape is no longer worth it).
- [x] Seeding on every boot: `db:seed:if_changed` (`SeedGuard`) skips the seed when its inputs are unchanged since the last successful run (about 4s saved per boot locally); failures are retried next boot, `FORCE_SEED=1` forces.
- [x] Region/forgery-set membership is data: `resonators.region` / `weapons.region` (migration `AddRegionToResonatorsAndWeapons`), set by the seeds from `LAHAI_ROI_RESONATORS` / `LAHAI_ROI_WEAPONS` and read by the planners; `ForgeryRegion` validates it.
- [x] Dependabot: `thruster` 0.1.27 and `ruby_llm` 2.1.1 merged; advisor re-verified in production.

## 1. Game data: remaining

- [ ] **Deferred by the owner until they have the data (do not add new Resonators, weapons or materials before then):** Suoming (Electro Sword; flower Miasmic Branch; boss Forged Empyrean's Sigh; enemy set Howler Core; skill boss Remnant of the Wheel; stats unknown) and her weapon Unspoken Rue (Sword on the Polarizer set per wiki "likely"; enemy-drop set unknown).
- [ ] Check cost tables (`04_cost_templates.rb`) and the SOL3 phase range (`DropRate::SOL3_PHASES`) against 3.7. Needs the owner's data.
- [ ] Optional feature: the drop-rate spreadsheet also covers **Tacet Fields** (echo drops and Echo EXP), which the app does not model.

## 2. Remaining dependency / platform work

- [x] `image_processing` removed (unused; v1.1.1).
- [ ] Re-check Ruby (3.4.7 in `.ruby-version`, `mise.toml`, `Dockerfile`) and PostgreSQL (17 in docker-compose and CI) against current releases; change them together.
- [ ] GitHub Actions versions in `ci.yml` are managed by Dependabot.

## 3. Documentation follow-ups

- [ ] Remaining **TODO(owner)** in [DEPLOYMENT.md](DEPLOYMENT.md): Environment-tab variable names and the Neon endpoint type (Render service settings are now recorded).
- [ ] Keep `docs/API.md` examples in sync with `app/serializers/` when response shapes change (the forte-node booleans in the serializer output are intentional; plans store `0/1` integers).

## 4. Code observations and decisions

Decided to leave as is (revisit only if the stated trigger happens):

- Solid Queue and Solid Cable are installed but unused; Solid Cache is in use (advice cache, Rack::Attack). Kept because removing them means changing the multi-database production config for no gain. Revisit if a job is ever needed or the extra tables bother you.
- The advisor LLM call is synchronous inside the request (20s timeout). The lazy Turbo Frame keeps the page responsive and the one-day cache removes repeats, so a background job is not worth it yet.
- Ruby (3.4.7) and PostgreSQL (17) bumps: change together when there is a reason (security release or a gem requiring it).
