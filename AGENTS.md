# AGENTS.md

Guidance for AI coding agents (and humans) working in this repository. Keep this file accurate; update it when conventions change.

## What this is

**Pangu Terminal** is a Rails app for *Wuthering Waves* players: plan material costs for Resonators/weapons, track inventory, detect synthesis (3:1 crafting), estimate Waveplate farming runs, and get LLM farming advice. Live at https://panguterminal.ambalong.dev (Render + Neon). Current version: see `CHANGELOG.md`.

## Stack

Ruby 3.4.7 (`.ruby-version`, `mise.toml`), Rails ~> 8.1.1, PostgreSQL 17, Puma + Thruster, Hotwire (Turbo + Stimulus via importmap), Tailwind (`tailwindcss-rails`) + per-feature CSS, Propshaft, Devise 5, Rack::Attack, RubyLLM (Gemini), Solid Cache/Queue/Cable, Minitest + Capybara/Cuprite, SimpleCov. Lint: rubocop-rails-omakase. Security: Brakeman, bundler-audit, `importmap audit`.

## Commands

```bash
cp .env.example .env && docker-compose up -d   # Postgres 17 on :5432 (POSTGRES_USER/PASSWORD from .env)
bundle install
bin/rails db:prepare                           # create + migrate (+ seeds on first create)
bin/rails db:seed                              # idempotent game-data seed
bin/dev                                        # Procfile.dev: rails server + tailwindcss:watch (http://localhost:3000)

bin/rails test                                 # unit/controller/integration (parallel, seeds per worker)
bin/rails test test/services/synthesis_service_test.rb   # single file
bin/rails test:system                          # Cuprite/Capybara user journey
bin/rubocop                                    # style (add -a to autofix)
bin/brakeman --no-pager && bin/bundler-audit && bin/importmap audit
bin/ci                                         # everything above (config/ci.rb)
```

Run `bin/rubocop` and `bin/rails test` before committing. CI (`.github/workflows/ci.yml`) runs brakeman, bundler-audit, importmap audit, rubocop, tests, system tests.

## Repository map

| Path | What lives there |
| --- | --- |
| `app/services/` | Business logic. Planners (`ResonatorAscensionPlanner`, `WeaponAscensionPlanner`), `SynthesisService`, `DropRateService`, `FarmingPriorityService`, `FarmingAdvisorService`, `WaveplateSummaryService`, `LlmClient`. `ApplicationService.call` = `new(...).call`. |
| `app/forms/plan_form.rb` | Form object that runs the planner and builds `plan_data`. |
| `app/controllers/` | Web controllers; `api/v1/` is the token-authenticated JSON API (`ActionController::API`); `concerns/plan_loading.rb` scopes plans. |
| `app/serializers/` | Plain-Ruby JSON serializers for the API. |
| `app/models/` | `Plan` (polymorphic `subject`), `Material`, `Source`, `DropRate`, cost tables, mapping tables, `User`, `ApiKey`, `InventoryItem`. |
| `db/seeds/01..08_*.rb` | All game data. Loaded in order by `db/seeds.rb` inside one transaction; shares state via `$SEED_DATA`. |
| `public/images/` | Material/resonator/weapon/forte art referenced by seeded `image_url`s. |
| `lib/tasks/forte_icons.rake` | `forte:download_stat_icons`, `forte:download_skill_icons`. |
| `docs/` | Project documentation (index: `docs/README.md`). |
| `config/deploy.yml`, `.kamal/` | **Legacy** Kamal config; production is Render. Not active. |

## Conventions

- **Logic goes in services**, not controllers/models. Controllers stay thin. Services take plain args and return hashes.
- **Plans** store everything in `plans.plan_data` JSONB: `{"input" => {...}, "output" => {material_id_string => qty}}`. Keys come back as strings; use `.transform_keys(&:to_i)` for material ids. A plan belongs to a `user` *or* a `guest_token`, never neither.
- **Scope plans via `load_current_plans`** (web) or `@current_user.plans` (API). Non-owned records must produce **404, not 403**.
- **Game data is data, not code.** Costs, mappings, sources and drop rates live in `db/seeds/`; planners read them from tables. New content = seed changes (see `docs/GAME_DATA.md`).
- Seeds use `find_or_initialize_by` + `update!` and must stay **idempotent**: `bin/docker-entrypoint` runs `db:prepare` and `db:seed` on every production boot.
- Material "keys" in the API are `Material#snake_case_name`.
- Never call RubyLLM directly; go through `LlmClient` (timeout + graceful fallback). Tests stub `LlmClient.ask` in `test/test_helper.rb`.
- Style: rubocop-rails-omakase (spaces inside array brackets, double quotes). Match surrounding code.
- Commit style: conventional-ish (`feat:`, `fix:`, `docs:`, `chore(deps):`, `refactor:`, `ci:`). User-visible changes get a `CHANGELOG.md` entry (SemVer, newest first).

## Gotchas

- `Api::V1::InventoryController` calls `current_user`; this works only because Devise's helper memoizes the `@current_user` that `BaseController#authenticate_api_key!` sets. Other API controllers use `@current_user` directly.
- `User` has an `after_create :initialize_inventory` callback inserting a row per `Material`; tests disable it in `test_helper.rb` and create rows on demand via `inventory_item_for`.
- Production uses one `DATABASE_URL` for primary, cache, queue and cable DBs. New production hostnames must be added to `config.hosts` in `config/environments/production.rb`.
- Farming Advisor needs `gemini_api_key` in Rails credentials (`config/credentials.yml.enc`, key in `config/master.key` or `RAILS_MASTER_KEY`). Without it the advisor falls back to a static message.
- Password-reset email uses Postmark SMTP (`POSTMARK_API_TOKEN`).
- `sol3_phase` (1..8) is per-user; drop rate data currently starts at phase 3 for forgery sources.
- `README.md` is a portfolio piece; reference material lives in `docs/`. Don't re-grow the README.
- Don't commit `config/master.key`, `.env`, or `.kamal/secrets` (gitignored).

## Docs

Start at [docs/README.md](docs/README.md): Architecture, Data Model, API, Game Data, Development, Testing, Deployment, Roadmap.
