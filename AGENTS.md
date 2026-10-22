# AGENTS.md

Guidance for AI coding agents (and humans) working in this repository. Keep this file accurate; update it when conventions change. Deeper reference lives in `docs/` (index: `docs/README.md`).

## What this is

**Pangu Terminal** is a Rails app for *Wuthering Waves* players: plan material costs for Resonators/weapons, track inventory, detect synthesis (3:1 crafting), estimate Waveplate farming runs, and get LLM farming advice. Live at https://panguterminal.ambalong.dev (Render + Neon). Current version: see `CHANGELOG.md`.

## Stack

Ruby 3.4.7 (`.ruby-version`, `mise.toml`), Rails ~> 8.1.1, PostgreSQL 17, Puma + Thruster, Hotwire (Turbo + Stimulus via importmap), plain per-feature CSS (no CSS framework or build step), Propshaft, Devise 5, Rack::Attack, RubyLLM 2.x (Gemini), Solid Cache/Queue/Cable, Minitest + Capybara/Cuprite, SimpleCov. Lint: rubocop-rails-omakase. Security: Brakeman, bundler-audit, `importmap audit`.

## Commands

```bash
cp .env.example .env && docker-compose up -d   # Postgres 17 on :5432 (POSTGRES_USER/PASSWORD from .env)
bundle install
bin/rails db:prepare                           # create + migrate (+ seeds on first create)
bin/rails db:seed                              # idempotent game-data seed
bin/dev                                        # rails server on :3000 (no CSS build step, no foreman)

bin/rails test                                 # unit/controller/integration (parallel, seeds per worker)
bin/rails test test/services/synthesis_service_test.rb   # single file
bin/rails test:system                          # Cuprite/Capybara user journey
bin/rubocop                                    # style (add -a to autofix)
bin/brakeman --no-pager && bin/bundler-audit && bin/importmap audit
bin/ci                                         # everything above (config/ci.rb)
```

### Cloud/sandbox sessions without Docker

Docker is usually unavailable in cloud sessions, and the pinned Ruby may not be downloadable. What works:

```bash
service postgresql start                       # local Postgres (16 is fine for tests)
# one-time: create a superuser role matching .env.example
su postgres -c "psql -c \"CREATE ROLE pangu_terminal SUPERUSER LOGIN PASSWORD 'pangu_terminal'\""
export POSTGRES_USER=pangu_terminal POSTGRES_PASSWORD=pangu_terminal
export RBENV_VERSION=3.3.6                     # only if 3.4.7 cannot be installed; the app runs on 3.3
RAILS_ENV=test bin/rails db:prepare && bin/rails test
```

System tests also run in the sandbox: `BROWSER_PATH=/opt/pw-browsers/chromium-1194/chrome-linux/chrome bin/rails test:system` (use `ls /opt/pw-browsers` if the directory name differs).

Treat results on a different Ruby/Postgres than CI as strong evidence, not proof; CI (3.4.7, Postgres 17) is the authority. Say which versions you verified on.

## Repository map

| Path | What lives there |
| --- | --- |
| `app/services/` | Business logic. Planners (`ResonatorAscensionPlanner`, `WeaponAscensionPlanner`), `SynthesisService`, `DropRateService`, `FarmingPriorityService`, `OptimizerService`, `PlanRecomputer`, `GuestPlanPruner`, `FarmingAdvisorService`, `FarmingAdviceRequest`, `WaveplateSummaryService`, `LlmClient`. Background work is in `app/jobs/` (`FarmingAdviceJob`). `ApplicationService.call` = `new(...).call`. |
| `app/forms/plan_form.rb` | Form object that runs the planner and builds `plan_data`. |
| `app/controllers/` | Web controllers; `api/v1/` is the token-authenticated JSON API (`ActionController::API`); `concerns/plan_loading.rb` scopes plans. |
| `app/serializers/` | Plain-Ruby JSON serializers for the API. |
| `app/models/` | `Plan` (polymorphic `subject`), `Material`, `Source`, `DropRate`, cost tables, mapping tables, `User`, `ApiKey`, `InventoryItem`. |
| `db/seeds/01..08_*.rb` | All game data. Loaded in order by `db/seeds.rb` inside one transaction; shares state via `$SEED_DATA`. |
| `public/images/` | Material/resonator/weapon/forte art referenced by seeded `image_url`s. |
| `lib/tasks/forte_icons.rake`, `lib/tasks/images.rake` | `forte:download_*` (skill/stat icons; label and URL overrides), `images:missing`, `images:download` (Fandom URLs via `FandomImageUrl`, configured in `config/image_sources.yml`). |
| `docs/` | Project documentation (index: `docs/README.md`). |

## Conventions

- **Logic goes in services**, not controllers/models. Controllers stay thin. Services take plain args and return hashes.
- **Plans** store everything in `plans.plan_data` JSONB: `{"input" => {...}, "output" => {material_id_string => qty}}`. Keys come back as strings; use `.transform_keys(&:to_i)` for material ids. A plan belongs to a `user` *or* a `guest_token`, never neither. Plan uniqueness per subject is scoped by user, or by guest token for guests (guests all have a nil `user_id`).
- **Scope plans via `load_current_plans`** (web) or `@current_user.plans` (API). Non-owned records must produce **404, not 403**.
- **Game data is data, not code.** Costs, mappings, sources and drop rates live in `db/seeds/`; planners read them from tables. New content = seed changes (see `docs/GAME_DATA.md`).
- Seeds use `find_or_initialize_by` + `update!` and must stay **idempotent**: `bin/docker-entrypoint` runs `db:prepare` and `db:seed:if_changed` on every production boot (`SeedGuard` skips the seed when `db/seeds*` and `config/skill_label_overrides.yml` are unchanged since the last successful run; add a new seed input file to `SeedGuard::INPUTS`).
- Material "keys" in the API are `Material#snake_case_name`.
- Never call RubyLLM directly; go through `LlmClient` (timeout + graceful fallback). It returns `LlmClient::FALLBACK_MESSAGE` on failure; use `LlmClient.fallback?(text)` to detect it and never cache or treat it as real advice. Tests stub `LlmClient.ask` in `test/test_helper.rb` (the real method is kept as `LlmClient.real_ask` for its own tests).
- API controllers use `@current_user` (set by `BaseController#authenticate_api_key!`), never Devise's `current_user`.
- CSS: plain CSS, no framework or build step. Colors come from `var(--ctp-*)` tokens in `app/assets/stylesheets/base/tokens.css`; one file per component under `app/assets/stylesheets/<feature>/`; no bare element selectors outside `base/`. See `docs/ARCHITECTURE.md#stylesheets`.
- Style: rubocop-rails-omakase (spaces inside array brackets, double quotes). Match surrounding code.
- Commit style: conventional-ish (`feat:`, `fix:`, `docs:`, `chore(deps):`, `refactor:`, `ci:`). User-visible changes get a `CHANGELOG.md` entry (SemVer, newest first).

## Workflow

1. Read the relevant `docs/` page and the code before editing. Reproduce a bug with a failing test first.
2. Make the smallest change that solves the problem. No drive-by refactors; note extra findings in `docs/ROADMAP.md` instead.
3. Run the gate (below). Fix failures at the root; never skip, disable or weaken a test to get green.
4. Update docs and `CHANGELOG.md` in the same change when behavior, routes, API responses, schema, seeds workflow or deployment change.
5. Commit with a conventional message. Develop on the assigned branch; open a PR only when asked.

## Definition of done

- [ ] `bin/rubocop` clean
- [ ] `bin/rails test` green (and `bin/rails test:system` if a UI flow changed)
- [ ] `bin/brakeman --no-pager` clean when controllers, params or queries changed
- [ ] New behavior and every bug fix has a test; a bug-fix test failed before the fix
- [ ] Coverage did not drop (SimpleCov prints it after the test run)
- [ ] Docs and `CHANGELOG.md` updated where required
- [ ] Final report states what was verified, on which Ruby/Postgres, and anything not run

## Boundaries

**Always**: scope data by owner, return 404 for records the caller does not own, keep seeds idempotent, go through `LlmClient`, add tests with changes.

**Ask first**: schema migrations on existing tables, changing the `plan_data` shape, new gems, changing seeded game values (costs, drop rates, mappings), changing auth/Rack::Attack limits, Ruby/Rails/Postgres version bumps, anything touching deployment or Render/Neon settings.

**Never**: run `db:seed`, `db:reset`, `db:drop` or `db:migrate` against a production `DATABASE_URL`; read, print, edit or commit `config/master.key`, `.env` or `config/credentials.yml.enc`; push to branches other than the assigned one; force-push shared branches; skip hooks or CI checks; invent game data (verify against the wiki/spreadsheet or leave it out and say so).

## Testing notes

- No fixtures. Tests create records in `setup` and use seeded game data (`Resonator.find_by!(name: "Aalto")`).
- `minitest/mock` is not available. Stub by redefining a singleton method and restoring it in `ensure` (see `test/services/llm_client_test.rb`, `test/services/farming_advisor_service_test.rb`).
- The test cache store is `:null_store`. To test caching, swap `Rails.cache` for a `MemoryStore` and restore it afterwards.
- Pin query counts on hot paths with an upper bound (see `test/services/optimizer_service_test.rb`).
- Details: `docs/TESTING.md`.

## Gotchas

- `User` has an `after_create :initialize_inventory` callback inserting a row per `Material`; tests disable it in `test_helper.rb` and create rows on demand via `inventory_item_for`.
- Production uses one `DATABASE_URL` for primary, cache, queue and cable DBs. New production hostnames must be added to `config.hosts` in `config/environments/production.rb`.
- Farming Advisor needs `gemini_api_key` in Rails credentials (`config/credentials.yml.enc`, key in `config/master.key` or `RAILS_MASTER_KEY`). Without it the advisor falls back to a static message. Advice is generated by `FarmingAdviceJob` (never in the request) and cached for one day per prompt digest in `Rails.cache` (Solid Cache in production); the optimizer frame polls until it appears.
- Stored plans keep the quantities computed when they were saved. Game data does not change, so this only matters after you fix a calculation bug (planner, cost table or mapping error): then run `bin/rails plans:recompute` (dry run, prints a per-material diff) and `APPLY=1 bin/rails plans:recompute` to write. Optional `PLAN_ID=` / `USER_ID=` narrow the scope. See `docs/DEPLOYMENT.md#operations`.
- Password-reset email uses Postmark SMTP (`POSTMARK_API_TOKEN`).
- `sol3_phase` (`DropRate::SOL3_PHASES`, 1..8) is per-user and validated on `User`; drop rate data currently starts at phase 3 for forgery sources.
- Image slugs strip `'"#&:` (e.g. `yangyang-xuanling.png`). Skill icon label overrides live in `config/skill_label_overrides.yml` (read by the seeds and `forte:download_skill_icons`). After adding data, run `bin/rails images:missing`.
- `README.md` is a portfolio piece; reference material lives in `docs/`. Don't re-grow the README.
- Don't commit `config/master.key` or `.env` (gitignored).

## Docs

Start at [docs/README.md](docs/README.md): Architecture, Data Model, API, Game Data, Development, Testing, Deployment, Roadmap.
