# Roadmap & Known Issues

Working backlog for bringing the project "up to current". Last reviewed 2026-10-04 (game version 3.7 released 2026-09-30). Check items off (and add a `CHANGELOG.md` entry) as they land.

## Done (v1.1.0)

- [x] Documentation foundation (`docs/`, `AGENTS.md`, `CLAUDE.md`).
- [x] Drop rates re-verified against the community spreadsheet screenshot for 3.7. Weekly boss, world boss, forgery and simulation (Shell / Resonator EXP / Weapon EXP) values for all SOL3 phases match `db/seeds/08_drop_rates.rb`; no changes were needed.
- [x] Kamal deployment removed (kept only in git history; see [DEPLOYMENT.md](DEPLOYMENT.md#history)).
- [x] Dependencies: patch/minor bumps plus `ruby_llm` 2.0.0 (required: 1.16.0 had a high-severity ReDoS advisory, CVE-2026-67991, that failed `bin/bundler-audit`) and Gemini model moved off the deprecated preview id.

## 1. Game data: catch up from 3.2 to 3.7 (needs owner input)

Baseline: the newest Resonator in the seeds is **Aemeath (3.1)**, so content from **3.2 onward** is missing. From public coverage (verify against a wiki before seeding):

| Version | New 5* Resonators (reported) | Signature weapons (reported) |
| --- | --- | --- |
| 3.2 | Sigrika | |
| 3.3 | Hiyuki | |
| 3.4 | Lucilla | |
| 3.5 | Yangyang: Xuanling (SP form), Suisui, Rover: Electro | |
| 3.6 | Qingxiao, Jingran | Glint of Clouds, Thousandfold Deliverance |
| 3.7 | Hsin, Suoming | Blooming Jadehaven, Unspoken Rue |

Also missing: any 4* Resonators, other weapons and the new materials (boss/weekly/forgery/enemy drops), art and mappings introduced in these patches. Blocker: this environment cannot reach game wikis (network egress is restricted) and search results lack reliable material names and costs, so nothing was invented.

- [ ] Provide per-patch lists (Resonators, weapons, new materials), or enable network access to a wiki (see below), or paste wiki tables/screenshots.
- [ ] Add them following the checklist in [GAME_DATA.md](GAME_DATA.md): `01`, `02`, `03`, `05`, `07` seeds; images in `public/images/`; forte icons via `forte:*` tasks. Work patch by patch (3.2 first) so each PR is reviewable.
- [ ] A new **Rover** element (Electro) and an **SP form** (Yangyang: Xuanling) may need modeling decisions: Rover variants use `RoverAscensionCost` and `Rover-<Element>` names; an SP form may need to be a separate Resonator row.
- [ ] Update `LAHAI_ROI_RESONATORS` (`app/services/resonator_ascension_planner.rb`) if any new Resonator uses region-specific materials; consider moving region into data (e.g. `resonators.region`).
- [ ] Check cost tables (`04_cost_templates.rb`) and the SOL3 phase cap (hard-coded `1..8` in `DropRate`, the dashboard dropdown and `Api::V1::ProfileController`) against 3.7.
- [ ] Optional feature: the spreadsheet also covers **Tacet Fields** (echo drops and Echo EXP), which the app does not model.

## 2. Remaining dependency / platform work

- [ ] `image_processing` 1.14.0 -> 2.2.0 (major; constrained by `~> 1.2`). Check whether Active Storage variants are used at all before bumping or dropping it.
- [ ] Re-check Ruby (3.4.7 in `.ruby-version`, `mise.toml`, `Dockerfile`) and PostgreSQL (17 in docker-compose and CI) against current releases; change them together.
- [ ] Confirm the Farming Advisor works with `gemini-3.1-flash-lite` and ruby_llm 2.0 against the live API (cannot be done without the Gemini key; tests stub `LlmClient`).
- [ ] System tests (`bin/rails test:system`) could not be run in the authoring sandbox (headless Chromium would not start); rely on the CI `system-test` job.
- [ ] GitHub Actions versions in `ci.yml` are managed by Dependabot.

## 3. Documentation follow-ups

- [ ] Remaining **TODO(owner)** in [DEPLOYMENT.md](DEPLOYMENT.md): Environment-tab variable names and the Neon endpoint type (Render service settings are now recorded).
- [ ] Add API contract tests if any API doc example drifts (e.g. `forte_node_upgrades` booleans vs stored integers).

## 4. Code observations (not yet verified as bugs)

- `Api::V1::InventoryController#index` uses `current_user` while the rest of the API uses `@current_user` (works via Devise's memoization; consider switching for consistency).
- `config.hosts` and the mailer host are hard-coded in `config/environments/production.rb`; consider env-driven values.
- Production runs `db:seed` on every boot; seeds are idempotent but add boot time and never delete. Consider a one-off step if boot time matters on the free tier.
- Solid Queue/Cable are installed but there are no jobs; confirm whether they should stay.
- Orphaned guest plans (`guest_token` cookie) are never cleaned up.
