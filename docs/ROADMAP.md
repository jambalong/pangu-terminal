# Roadmap & Known Issues

Working backlog for bringing the project "up to current". Seeded from a documentation audit on 2026-10-04; items marked **needs owner input** cannot be decided from the repository alone. Check items off (and add a `CHANGELOG.md` entry) as they land.

## 1. Game data currency (needs owner input)

Baseline in the repo: 47 Resonators seeded, drop rates "updated as of 2026.04.04" (`db/seeds/08_drop_rates.rb`), SOL3 phases 1..8, last seed-data change before the May 2026 release (v1.0.0, 2026-05-18).

- [ ] Decide the target game version/patch and list the Resonators, weapons, materials, sources and SOL3 phases released since the baseline.
- [ ] Add new Resonators/weapons/materials following the checklist in [GAME_DATA.md](GAME_DATA.md) (including images in `public/images/` and forte icons).
- [ ] Refresh `08_drop_rates.rb` (and add phases > 8 if the game added them: `DropRate` validation, dashboard dropdown and `ProfileController` all hard-code `1..8`).
- [ ] Update `LAHAI_ROI_RESONATORS` (`app/services/resonator_ascension_planner.rb`) for any new region-specific Resonators; consider moving region membership into the data (e.g. a `resonators.region` column) so patches don't need a code change.
- [ ] Verify cost tables (`04_cost_templates.rb`) against any game balance changes (level/skill/forte costs, new max levels).
- [ ] Production never deletes seeded rows; if data is renamed/removed, add a data migration.

## 2. Dependencies (`bundle outdated --only-explicit`, 2026-10-04)

| Gem | Locked | Latest | Notes |
| --- | --- | --- | --- |
| rails | 8.1.3.1 | 8.1.4 | patch; Gemfile allows `~> 8.1.1` |
| ruby_llm | 1.16.0 | 2.0.0 | **major**; constrained by `~> 1.15`. Read the changelog; `LlmClient` is the only call site, and `config/initializers/ruby_llm.rb` sets the Gemini model |
| image_processing | 1.14.0 | 2.2.0 | major; constrained by `~> 1.2`; check whether Active Storage variants are used at all |
| pg | 1.6.3 | 1.7.0 | constrained by `~> 1.6` |
| brakeman, bootsnap, cuprite, simplecov, solid_cable, solid_queue, thruster, ruby-lsp | | | minor/patch bumps |

- [ ] Update in small steps (patch/minor first, then `ruby_llm` 2.x), running `bin/ci` each time.
- [ ] Re-check Ruby (3.4.7 pinned in `.ruby-version`, `mise.toml`, `Dockerfile`) and PostgreSQL (17 in docker-compose/CI) against current releases; they must be changed together.
- [ ] Revisit the Gemini model id in `config/initializers/ruby_llm.rb` (`gemini-3.1-flash-lite-preview` is a preview model and may be retired).
- [ ] GitHub Actions versions in `ci.yml` (checkout v6, cache v5, etc.) are managed by Dependabot.

## 3. Cleanup of retired Kamal deployment

- [ ] Remove or archive `config/deploy.yml`, `.kamal/`, `bin/kamal`, the `kamal` gem, the commented `deploy` job in `ci.yml`, and Kamal wording in `Dockerfile`/`.gitignore`/`.dockerignore` (or decide to keep as a reference). Documented in [DEPLOYMENT.md](DEPLOYMENT.md).
- [ ] `CREDITS.md`/README mention check after cleanup.
- [ ] `thruster` is still used by the Docker CMD; keep it.

## 4. Documentation follow-ups

- [ ] Fill the **TODO(owner)** items in [DEPLOYMENT.md](DEPLOYMENT.md) (Render settings, env var values, rollback method).
- [ ] README "Last Updated: August 2026" / "Version: 1.0.0" footer: update when releasing.
- [ ] Add API request/response contract tests if any API doc example drifts (e.g. `forte_node_upgrades` booleans vs stored integers).

## 5. Code observations (not yet verified as bugs)

- `Api::V1::InventoryController#index` uses `current_user` while the rest of the API uses `@current_user` (works via Devise's memoization; consider switching for consistency).
- `config.hosts` / mailer host are hard-coded in `config/environments/production.rb`; consider env-driven values.
- Production runs `db:seed` on every boot; seeds are idempotent but add boot time and never delete. Consider a one-off `release`/migration step if boot time matters on the free tier.
- Solid Queue/Cable are installed but there are no jobs; confirm whether they should stay.
- Guest plan cookies (`guest_token`) have no expiry cleanup of orphaned guest plans.

## Open questions for the owner

1. Which game version should "current" mean, and do you have a source for new drop-rate data?
2. Keep the portfolio/MVP scope, or add features (e.g. more optimizer inputs, other languages)?
3. Is the Render free-tier setup staying, or should deployment move elsewhere?
4. Dependency policy: bump everything including `ruby_llm` 2.x now, or patch/minor only?
