@AGENTS.md

## Claude Code notes

- Follow the **Workflow**, **Definition of done** and **Boundaries** sections in `AGENTS.md`. They are the contract for every change.
- Before finishing a change: `bin/rubocop` and `bin/rails test` (system tests via `bin/rails test:system` when UI flows change). They need Postgres (`docker-compose up -d`, or the sandbox recipe in `AGENTS.md`) and a `.env`.
- Keep docs in sync: if you change routes, API responses, schema, seeds workflow or deployment, update the matching file in `docs/` and add a `CHANGELOG.md` entry.
- Never run `db:seed`, `db:reset` or `db:drop` against a production `DATABASE_URL`.
- Don't edit `config/credentials.yml.enc` or print secrets; ask the user for credentials-related changes.
- Open a PR only when asked; develop on the branch you were assigned.
- Commit messages and PR descriptions contain only the change itself: conventional prefix, a short summary, and a body when useful. No trailers or tool/AI attribution lines unless the user asks for them.
- `.claude/settings.json` pre-approves the safe dev commands (tests, rubocop, brakeman) and blocks reading secrets and destructive database tasks. Do not widen it without asking.
- Large or ambiguous work: write a short plan first (scope, files, tests, budget), then execute phase by phase with one commit per phase, each passing rubocop and the full test suite.
