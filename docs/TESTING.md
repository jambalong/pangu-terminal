# Testing, CI and Quality Gates

Framework: Minitest (`rails/test_help`), SimpleCov (+ Cobertura for Codecov), Capybara + Cuprite for system tests. There is no `test/fixtures`; tests create records in `setup` and rely on seeded game data.

## Running

```bash
bin/rails test                                 # everything except system tests
bin/rails test test/models/plan_test.rb        # one file
bin/rails test test/models/plan_test.rb:12     # one test by line
bin/rails test:system                          # test/system/user_journey_test.rb (headless Chrome)
bin/ci                                         # full local gate defined in config/ci.rb
```

Prerequisite: Postgres running (see [DEVELOPMENT.md](DEVELOPMENT.md)). Coverage reports are written to `coverage/` (gitignored); CI uploads `coverage/coverage.xml` to Codecov.

## Layout

| Dir | Covers |
| --- | --- |
| `test/models/` | Validations/associations for each model (cost tables, maps, plan, user, source, drop rate...) |
| `test/services/` | Planners, `SynthesisService`, `DropRateService`, `FarmingPriorityService`, `FarmingAdvisorService` |
| `test/controllers/` | Web controllers, `api/` (v1 endpoints, auth), `users/registrations` |
| `test/forms/`, `test/helpers/` | `PlanForm`, view helpers |
| `test/integration/rate_limiting_test.rb` | Rack::Attack throttles (uses an isolated `MemoryStore`) |
| `test/system/user_journey_test.rb` | Sign in -> set SOL3 phase -> create plan -> edit inventory -> optimizer |

## Test helper behavior (`test/test_helper.rb`)

- **Parallel**: `parallelize(workers: :number_of_processors)`; each worker has its own DB and `parallelize_setup` loads `db/seeds` once per worker (stdout silenced). The seeds are therefore part of every test's world: use real seeded records (e.g. `Resonator.find_by!(name: "Aalto")`).
- **LLM stub**: `LlmClient.ask` is redefined to return `"Stub farming advice."`; no network calls in tests.
- **Inventory callback**: `User#initialize_inventory` is skipped (set/unset in `setup`/`teardown`); create rows with `user.inventory_item_for(material)` or call `user.send(:initialize_inventory)` (system test does this).
- Devise integration helpers (`sign_in`) are included.
- `config/environments/test.rb` eager loads when `CI` is set.

## CI (`.github/workflows/ci.yml`, on PRs and pushes to `main`)

| Job | Command |
| --- | --- |
| `scan_ruby` | `bin/brakeman --no-pager`, `bin/bundler-audit` |
| `scan_js` | `bin/importmap audit` |
| `lint` | `bin/rubocop -f github` (cached) |
| `test` | `bin/rails db:test:prepare test` against Postgres 17; needs `RAILS_MASTER_KEY`, `CODECOV_TOKEN` secrets |
| `system-test` | `bin/rails db:test:prepare test:system`; uploads `tmp/screenshots` on failure |

The deploy job is commented out (Render deploys itself). Dependabot (`.github/dependabot.yml`) opens weekly bundler and GitHub Actions update PRs. Gem advisories can be ignored in `config/bundler-audit.yml` (currently only a placeholder).

## Writing tests: conventions

- Test the service layer directly with seeded data; keep controllers' tests about auth/scoping/response shape.
- For any ownership-sensitive endpoint, test that another user's record returns **404**.
- API tests assert JSON contracts (keys, status codes) because [API.md](API.md) documents them.
- When you add seed data, add/adjust tests that depend on counts or names.
