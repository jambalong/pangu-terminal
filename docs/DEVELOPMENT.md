# Development Setup

## Prerequisites

- Ruby 3.4.7 (`.ruby-version`; `mise.toml` pins it for mise users)
- Docker + Docker Compose (PostgreSQL 17 for dev/test)
- `libpq` headers for the `pg` gem; `libvips` if you exercise Active Storage variants
- Optional: ImageMagick (`magick`/`convert`) for the `forte:*` icon rake tasks; Chromium for system tests

## First run

```bash
git clone https://github.com/jambalong/pangu-terminal.git && cd pangu-terminal
bundle install
cp .env.example .env          # POSTGRES_USER / POSTGRES_PASSWORD (both default to pangu_terminal)
docker-compose up -d          # Postgres 17 on 127.0.0.1:5432, volume `pangu-terminal-pgdata`
bin/rails db:prepare          # creates pangu_terminal_development / _test, migrates, seeds
bin/dev                       # http://localhost:3000
```

`bin/setup` does the gem + database steps and then starts `bin/dev` (`--skip-server`, `--reset` supported).

**Password-authentication errors**: the Docker volume keeps the credentials from its first run. Recreate with `docker-compose down -v && docker-compose up -d`.

`.env` is loaded by `dotenv-rails` and gitignored. `config/database.yml` connects to `127.0.0.1:5432` using those variables for development and test; production uses `DATABASE_URL`.

## Processes

`Procfile.dev` (via `bin/dev`): `web: bin/rails server` and `css: bin/rails tailwindcss:watch`. Solid Queue is not needed locally (no app jobs). Tailwind output goes to `app/assets/builds/` (gitignored).

## Credentials and the Farming Advisor

The advisor reads `Rails.application.credentials.gemini_api_key` (`config/initializers/ruby_llm.rb`; model `gemini-3.1-flash-lite`, 30 s request timeout, 20 s `LlmClient` timeout). Credentials are encrypted in `config/credentials.yml.enc`; the key is `config/master.key` (gitignored, not in the repo). Without the key the app runs and the advisor shows a static fallback message. To use your own key: `bin/rails credentials:edit` (this replaces the repo's encrypted file and master key for your checkout; do not commit that change).

## Handy tasks

```bash
bin/rails db:seed                       # re-run game-data seeds (idempotent)
bin/rails db:seed:replant               # wipe + reseed (dev/test only)
bin/rails forte:download_stat_icons     # fetch forte stat icons into public/images/forte/stats
bin/rails forte:download_skill_icons    # fetch per-Resonator skill icons into public/images/forte/skills
bin/rails console
bin/rails routes
```

## Editor/tooling

`.rubocop.yml` inherits rubocop-rails-omakase; `ruby-lsp` is in the development group; `.herb.yml` configures the Herb ERB linter/formatter.

## Troubleshooting

| Symptom | Fix |
| --- | --- |
| `PG::ConnectionBad` / connection refused | `docker-compose up -d`; check port 5432 is free |
| `password authentication failed` | Recreate the volume (above) or make `.env` match the existing volume |
| Missing CSS | Run `bin/dev` (not `bin/rails server`) so Tailwind builds, or `bin/rails tailwindcss:build` |
| `ActiveSupport::MessageEncryptor::InvalidMessage` | No/incorrect `config/master.key`; only needed for credentials (advisor key, production) |
