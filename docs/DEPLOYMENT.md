# Deployment

Production runs on **Render** (Docker web service) with **PostgreSQL on Neon**, at https://panguterminal.ambalong.dev. The original Kamal 2 / DigitalOcean setup is decommissioned; the Kamal configuration and runbook were removed (see [History](#history)).

> Render and Neon settings below were recorded from the dashboards by the owner on 2026-10-23. Dashboard values are not visible from this repository, so re-check them if something here looks wrong.

## How it deploys

- Render builds the repo's `Dockerfile` (path `./Dockerfile`, build context `.`) and deploys from `main` with Auto-Deploy set to **On Commit**, so every push to `main` deploys. Render does not wait for GitHub Actions; CI results are not a deploy gate, so merge only green PRs. Pre-Deploy Command and Docker Command are empty (the image `CMD`/entrypoint is used). Pull Request Previews are off.
- `Dockerfile`: multi-stage, Ruby 3.4.7-slim, `RAILS_ENV=production`, `BUNDLE_WITHOUT=development`, runs `assets:precompile` with a dummy secret, runs as non-root user `rails` (uid 1000), exposes port 80, `CMD ["./bin/thrust", "./bin/rails", "server"]` (Thruster in front of Puma).
- `bin/docker-entrypoint`: when the command is `./bin/rails server`, it runs `bin/rails db:prepare` then `bin/rails db:seed:if_changed` on **every boot**, then `exec`s the command. So migrations and (idempotent) seed updates ship automatically with each deploy. A failing migration prevents the container from starting. `db:seed:if_changed` (`SeedGuard`) runs the seed only when `db/seeds.rb`, `db/seeds/*.rb` or `config/skill_label_overrides.yml` changed since the last successful run (checksum in `ar_internal_metadata`), saving several seconds per boot. `db/seeds.rb` swallows seed errors, so a failed seed is logged, does not block the boot and is retried on the next boot because no checksum is recorded.
- Health check: Render health check path is `/up` (Rails health). It is excluded from SSL redirect and host authorization (`config/environments/production.rb`) and is safelisted in Rack::Attack, whose throttle counters live in Solid Cache (the database), so pings never write to the database.
- Keeping the free tier awake: a free uptime monitor on `/up` every 5 minutes stops the Render free instance sleeping (one always-on free service is about 744 of the 750 monthly free instance hours; check Render's billing page). Because `/up` does no database work, Neon's free compute (100 CU-hours a month per project, suspended after 5 idle minutes) can still sleep between real visits. Do not point a monitor at a page that queries the database.
- `config.force_ssl` and `assume_ssl` are on; TLS terminates at Render.

## Configuration

| Variable | Purpose |
| --- | --- |
| `RAILS_MASTER_KEY` | Decrypts `config/credentials.yml.enc` (includes `gemini_api_key` for the Farming Advisor) |
| `DATABASE_URL` | Neon connection string. Used for the primary, cache, queue and cable databases (`config/database.yml`), so one Neon database holds all tables. It is the **pooled** endpoint (host contains `-pooler`, PgBouncer). Neon runs **PostgreSQL 17.11**, matching CI and `docker-compose.yml`. `database.yml` sets no `prepared_statements: false` or `advisory_locks: false`; migrations run through the pooler without problems (for example the 2026-10-22 region migration). If you ever see advisory-lock or prepared-statement errors, point `DATABASE_URL` at Neon's direct endpoint. |
| `POSTMARK_API_TOKEN` | Postmark SMTP (port 2525) for password-reset emails (only legacy email/password accounts can reset a password) |
| `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET` | Google OAuth client. Optional: with either unset the Google button is hidden and the provider is disabled. |
| `DISCORD_CLIENT_ID`, `DISCORD_CLIENT_SECRET` | Discord OAuth application. Same behavior. |
| `APP_HOST` | Optional. Public hostname for allowed hosts and mailer links; default `panguterminal.ambalong.dev`. Set it if the custom domain changes. |
| `SOLID_QUEUE_IN_PUMA` | Optional. When set, ActiveJob uses Solid Queue (processed inside Puma) instead of the default in-process `:async` adapter. Not needed: `FarmingAdviceJob` is short and its result is cached, so a restart only costs one regenerated advice. |
| `ADVISOR_DAILY_LIMIT_PER_USER`, `ADVISOR_DAILY_LIMIT_GLOBAL` | Optional. Farming Advisor generations per account and in total per day (defaults 20 and 500). Each new generation is one Gemini call; cached advice and polling are free. Raise them if the Gemini quota allows, lower them to protect it. |
| `EXTRA_HOSTS` | Optional. Comma-separated extra allowed hosts (the default `pangu-terminal.onrender.com` is always allowed). |
| `RAILS_LOG_LEVEL` | Optional, default `info`; logs go to STDOUT |
| `WEB_CONCURRENCY` | Set to **2** on Render (two Puma workers). The Free instance has about 512 MB of RAM; if logs show out-of-memory restarts, lower it to 1. |
| `RAILS_MAX_THREADS`, `PORT` | Not set: Puma uses its default of 3 threads per worker (`config/puma.rb`) and Render supplies the port. |

Render service (from the dashboard settings page): web service `pangu-terminal`, runtime Docker, **Free** instance type, region **Oregon (US West)**, source `jambalong/pangu-terminal` branch `main`, custom domain `panguterminal.ambalong.dev`. The free tier sleeps when idle, so the first request can take up to a minute. Maintenance mode and edge caching are paid-only features and unavailable.

Environment tab (as of 2026-10-23) holds exactly five variables: `DATABASE_URL`, `POSTMARK_API_TOKEN`, `RAILS_ENV` (`production`), `RAILS_MASTER_KEY` and `WEB_CONCURRENCY` (`2`). The optional variables in the table above (`APP_HOST`, `EXTRA_HOSTS`, `SOLID_QUEUE_IN_PUMA`, `RAILS_LOG_LEVEL`) are unset and use their defaults. Never commit secret values.

### OAuth sign-in setup (owner steps)

New accounts are created with Google or Discord (see [ARCHITECTURE.md](ARCHITECTURE.md#authentication-and-ownership)). Until at least one provider is configured, production shows no OAuth buttons and keeps the old email sign-up form as a fallback; once one is configured the sign-up form closes.

- [ ] Google Cloud Console: create an OAuth consent screen and a **Web** OAuth client. Authorized redirect URI: `https://panguterminal.ambalong.dev/users/auth/google_oauth2/callback`.
- [ ] Discord Developer Portal: create an application, OAuth2 page, add redirect `https://panguterminal.ambalong.dev/users/auth/discord/callback`.
- [ ] On the consent screen Branding page set the home page to `https://panguterminal.ambalong.dev` and the privacy policy to `https://panguterminal.ambalong.dev/privacy` (Google requires both to publish), add `ambalong.dev` under authorized domains, and leave the logo empty (a logo triggers verification). Then publish the app so any Google account can sign in.
- [ ] Render: add `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`, `DISCORD_CLIENT_ID`, `DISCORD_CLIENT_SECRET` as environment variables, then redeploy.
- [ ] Check `/sign-in` shows the buttons and that signing in with each provider lands on the dashboard.

Scopes are minimal: Discord `identify`, Google `openid profile`; no email is requested or stored. Redirect URIs are built from the request host, so a new hostname needs its own redirect URI at each provider. Rate limit: 20 requests per minute per IP on `/users/auth/*`.

`public/robots.txt` and `public/sitemap.xml` are static files with the production hostname written in; update them if the custom domain changes. Canonical and Open Graph URLs use `APP_HOST` (default `panguterminal.ambalong.dev`).

Allowed hosts are `panguterminal.ambalong.dev` and `pangu-terminal.onrender.com`. Add any new hostname to `config.hosts` or requests get a 403 from Rails host authorization.

## Release procedure

1. Merge to `main` via PR (CI: brakeman, bundler-audit, importmap audit, rubocop, tests, system tests).
2. Render builds and deploys. Watch the deploy log in the Render dashboard; confirm the boot log shows `db:prepare` and `SEEDING COMPLETED!`.
3. Smoke test: `curl -i https://panguterminal.ambalong.dev/up`, sign in, open the planner and optimizer.
4. Update `CHANGELOG.md` / version in README for user-visible releases.

## Operations

- **Logs:** Render dashboard (STDOUT, tagged with request id).
- **Rollback:** Render dashboard -> service -> Deploys -> pick a previous successful deploy -> Rollback (or push a revert to `main`; Auto-Deploy will redeploy). Disable Auto-Deploy first if you need to hold a bad commit off. Rollback does not reverse migrations; if the bad release included a destructive migration, run `bin/rails db:rollback` from your machine (see [Running tasks without a Render shell](#running-tasks-without-a-render-shell)) or restore Neon from a point-in-time branch.
- **Recompute stored plans after a calculation bug fix:** plans snapshot their material totals in `plans.plan_data` when saved, so a fixed planner does not change existing plans by itself. From your machine (see below) run `bin/rails plans:recompute` (dry run, lists each changed plan with old -> new quantities and any plan whose stored input no longer validates), review it, then `APPLY=1 bin/rails plans:recompute`. `PLAN_ID=<id>` or `USER_ID=<id>` limit the scope. Only the `output` of plans whose totals differ is rewritten.
- **Check the Farming Advisor:** `bin/rails advisor:check` makes one minimal LLM call (needs the Gemini key, so it runs locally only with `RAILS_MASTER_KEY`; otherwise open the optimizer page on the live site as the check). `OK` means the key, model and network work; `FAILED` means it fell back, and the `LlmClient unavailable` / `LlmClient error` line in the logs names the cause (timeout, rate limit, bad key, unknown model).
- **Prune abandoned guest plans:** `bin/rails plans:prune_guests` from your machine (dry run; guest plans untouched for `DAYS`, default 90), then `APPLY=1 bin/rails plans:prune_guests`. Never touches plans owned by a user.
- **Reseed manually:** Seeds run automatically on every deploy when their files change. To force one, set the env var for a deploy or run from your machine `bin/rails db:seed` (or `FORCE_SEED=1 bin/rails db:seed:if_changed` to also refresh the recorded checksum). Seeds never delete rows; removing a record from production requires a console/migration.
- **Console:** not available (no Render shell). Use a local console against Neon only if you must, read-only first.
- **Running tasks without a Render shell:** the Free plan has no Shell tab. Maintenance tasks that only need the database (`plans:recompute`, `plans:prune_guests`, `db:rollback`) can run from your own checkout against Neon:
  1. In Neon, open the connection details, turn **off** "Pooled connection" to get the direct endpoint, and copy the connection string (it contains the password; treat it as a secret and never commit it).
  2. Run, for example: `RAILS_ENV=production SECRET_KEY_BASE_DUMMY=1 DATABASE_URL='<direct connection string>' bin/rails plans:recompute`. No master key is needed for DB-only tasks.
  3. Always do the dry run first and read the output; only then add `APPLY=1`. Never run `db:seed`, `db:reset` or `db:drop` this way (see `AGENTS.md`).
- **Secrets rotation:** `RAILS_MASTER_KEY` changes require re-encrypting credentials locally (`bin/rails credentials:edit`), committing `config/credentials.yml.enc`, and updating the env var.

## Local Docker run (production image)

```bash
docker build -t pangu_terminal .
docker run --rm -p 3000:80 -e RAILS_MASTER_KEY=<config/master.key> \
  -e DATABASE_URL=postgres://... pangu_terminal
```

## History

The app originally deployed with Kamal 2 to a DigitalOcean droplet (capstone-graded deployment). That infrastructure was retired when the credits expired and the app moved to Render + Neon. The Kamal files (`config/deploy.yml`, `.kamal/`, `bin/kamal`, the `kamal` gem, the CI deploy job) were removed in v1.1.0. The old runbook (deploy, lock release, logs, rollback via `kamal rollback`) is available in git history, e.g. `git show 7c3cb68:docs/DEPLOYMENT.md`.
