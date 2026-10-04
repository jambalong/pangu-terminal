# Deployment

Production runs on **Render** (Docker web service) with **PostgreSQL on Neon**, at https://panguterminal.ambalong.dev. The original Kamal 2 / DigitalOcean setup is decommissioned; the Kamal configuration and runbook were removed (see [History](#history)).

> Items marked **TODO(owner)** are configured in the Render/Neon dashboards, which are not visible from this repository. Fill them in.

## How it deploys

- Render builds the repo's `Dockerfile` and deploys from `main` on push (per README; **TODO(owner)**: confirm auto-deploy setting and whether CI must pass first).
- `Dockerfile`: multi-stage, Ruby 3.4.7-slim, `RAILS_ENV=production`, `BUNDLE_WITHOUT=development`, runs `assets:precompile` with a dummy secret, runs as non-root user `rails` (uid 1000), exposes port 80, `CMD ["./bin/thrust", "./bin/rails", "server"]` (Thruster in front of Puma).
- `bin/docker-entrypoint`: when the command is `./bin/rails server`, it runs `bin/rails db:prepare` then `bin/rails db:seed` on **every boot**, then `exec`s the command. So migrations and (idempotent) seed updates ship automatically with each deploy. A failing migration or seed prevents the container from starting.
- Health check: `GET /up` (Rails health). It is excluded from SSL redirect and host authorization (`config/environments/production.rb`).
- `config.force_ssl` and `assume_ssl` are on; TLS terminates at Render.

## Configuration

| Variable | Purpose |
| --- | --- |
| `RAILS_MASTER_KEY` | Decrypts `config/credentials.yml.enc` (includes `gemini_api_key` for the Farming Advisor) |
| `DATABASE_URL` | Neon connection string. Used for the primary, cache, queue and cable databases (`config/database.yml`), so one Neon database holds all tables. **TODO(owner)**: note whether the pooled or direct Neon endpoint is used. |
| `POSTMARK_API_TOKEN` | Postmark SMTP (port 2525) for password-reset emails |
| `RAILS_LOG_LEVEL` | Optional, default `info`; logs go to STDOUT |
| `RAILS_MAX_THREADS`, `PORT`, `WEB_CONCURRENCY` | Optional Puma tuning; **TODO(owner)**: record the values set on Render |

**TODO(owner)**: list the actual Render service name, region, instance type, and any custom domain/DNS setup for `panguterminal.ambalong.dev`; note that the free tier sleeps when idle (first request can take up to a minute).

Allowed hosts are `panguterminal.ambalong.dev` and `pangu-terminal.onrender.com`. Add any new hostname to `config.hosts` or requests get a 403 from Rails host authorization.

## Release procedure

1. Merge to `main` via PR (CI: brakeman, bundler-audit, importmap audit, rubocop, tests, system tests).
2. Render builds and deploys. Watch the deploy log in the Render dashboard; confirm the boot log shows `db:prepare` and `SEEDING COMPLETED!`.
3. Smoke test: `curl -i https://panguterminal.ambalong.dev/up`, sign in, open the planner and optimizer.
4. Update `CHANGELOG.md` / version in README for user-visible releases.

## Operations

- **Logs:** Render dashboard (STDOUT, tagged with request id).
- **Rollback:** redeploy a previous successful deploy from the Render dashboard (**TODO(owner)**: confirm). Rollback does not reverse migrations; if the bad release included a destructive migration, run `bin/rails db:rollback` (**TODO(owner)**: confirm shell access on your Render plan) or restore Neon from a point-in-time branch.
- **Reseed manually:** Render shell, `bin/rails db:seed`. Seeds never delete rows; removing a record from production requires a console/migration.
- **Console:** Render shell, `bin/rails console`.
- **Secrets rotation:** `RAILS_MASTER_KEY` changes require re-encrypting credentials locally (`bin/rails credentials:edit`), committing `config/credentials.yml.enc`, and updating the env var.

## Local Docker run (production image)

```bash
docker build -t pangu_terminal .
docker run --rm -p 3000:80 -e RAILS_MASTER_KEY=<config/master.key> \
  -e DATABASE_URL=postgres://... pangu_terminal
```

## History

The app originally deployed with Kamal 2 to a DigitalOcean droplet (capstone-graded deployment). That infrastructure was retired when the credits expired and the app moved to Render + Neon. The Kamal files (`config/deploy.yml`, `.kamal/`, `bin/kamal`, the `kamal` gem, the CI deploy job) were removed in v1.1.0. The old runbook (deploy, lock release, logs, rollback via `kamal rollback`) is available in git history, e.g. `git show 7c3cb68:docs/DEPLOYMENT.md`.
