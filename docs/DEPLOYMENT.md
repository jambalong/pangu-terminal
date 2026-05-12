# Deployment Runbook

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
