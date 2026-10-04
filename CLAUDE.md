@AGENTS.md

## Claude Code notes

- Before finishing a change: `bin/rubocop` and `bin/rails test` (system tests via `bin/rails test:system` when UI flows change). They need Postgres from `docker-compose up -d` and a `.env`.
- Keep docs in sync: if you change routes, API responses, schema, seeds workflow or deployment, update the matching file in `docs/` and add a `CHANGELOG.md` entry.
- Never run `db:seed`, `db:reset` or `db:drop` against a production `DATABASE_URL`.
- Don't edit `config/credentials.yml.enc` or print secrets; ask the user for credentials-related changes.
- Open a PR only when asked; develop on the branch you were assigned.
