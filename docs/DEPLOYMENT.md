# Deployment

Production runs on **Render** (Docker web service) with **PostgreSQL on Neon**, at https://panguterminal.ambalong.dev. The original Kamal 2 / DigitalOcean setup is decommissioned; its runbook is kept in the [legacy appendix](#appendix-legacy-kamal-runbook).

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

## Legacy / inactive files

`config/deploy.yml`, `.kamal/`, `bin/kamal`, the `kamal` gem and the commented-out `deploy` job in `.github/workflows/ci.yml` belong to the retired Kamal pipeline. See [ROADMAP.md](ROADMAP.md) for cleanup.

---

# Appendix: Legacy Kamal runbook

> Historical. Not used by the current production deployment. Note that this runbook said seeds do not run automatically; the current `bin/docker-entrypoint` does run them.

## Prerequisites

- Ruby 3.4+
- Docker
- Kamal 2 (`gem install kamal`)
- SSH access to the production server (configured in `config/deploy.yml`)
- `.kamal/secrets` configured with required environment variables

## Kamal Secrets

Required in `.kamal/secrets` before deploying:

| Key | Description |
|-----|-------------|
| `RAILS_MASTER_KEY` | Found in `config/master.key`. Decrypts Rails credentials. |
| `KAMAL_REGISTRY_PASSWORD` | Docker Hub password or access token for pushing images. |
| `POSTGRES_PASSWORD` | Production database password. Must match the value used when the database was initialized. |
| `DATABASE_URL` | Full PostgreSQL connection string for the production database. Example: `postgres://rails:${POSTGRES_PASSWORD}@pangu-terminal-db/pangu_terminal_production`|
| `POSTMARK_API_TOKEN` | API token for Postmark. Used by Action Mailer to send transactional emails (password reset). Found in your Postmark account under Servers -> your server -> API Tokens. |

## Deploy

```bash
kamal deploy
```

Builds the Docker image, pushes it to the registry, boots the new container on the server, and runs database migrations automatically. Pruning of old containers and images happens after a successful boot.

Seeds do **not** run automatically. If a deploy requires seeding:

```bash
kamal app exec --reuse 'bin/rails db:seed'
```

## Stuck Deploy

If a deploy fails mid-way, the lock may be left in place. Check lock status:

```bash
kamal lock status
```

If locked, release it:

```bash
kamal lock release
```

Then retry the deploy.

## Checking Logs

Tail live logs from the running container:

```bash
kamal app logs
```

Check what version is currently running:

```bash
kamal app version
```

View the full deploy audit trail:

```bash
kamal audit
```

## Rollback

Find the version hash to roll back to from the audit log:

```bash
kamal audit
```

Look for the last known good `Booted app version` entry. Then roll back to that version:

```bash
kamal rollback <version-hash>
```

Example:

```bash
kamal rollback 0ba23d0b25f872835d0a72f42e78c868a2b8b7a1
```

Rollback does not re-run migrations. If the bad deploy included a migration, rolling back the app without reversing the migration may cause errors. In that case, run:

```bash
kamal app exec --reuse 'bin/rails db:rollback'
```

before or after the rollback depending on whether the migration was destructive.

