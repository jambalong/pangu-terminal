# Documentation index

| Doc | Read it when you need to... |
| --- | --- |
| [ARCHITECTURE.md](ARCHITECTURE.md) | Understand request flows, auth/guest model, services, and the reasoning behind design decisions |
| [DATA_MODEL.md](DATA_MODEL.md) | Look up tables, associations and the `plan_data` JSON shape |
| [API.md](API.md) | Use or change the `/api/v1` REST API |
| [GAME_DATA.md](GAME_DATA.md) | Understand the game concepts and add/update Resonators, weapons, materials, drop rates |
| [DEVELOPMENT.md](DEVELOPMENT.md) | Set up a local environment (Ruby, Docker Postgres, credentials, env vars) |
| [TESTING.md](TESTING.md) | Run tests, understand test helpers, CI jobs and security scans |
| [DEPLOYMENT.md](DEPLOYMENT.md) | Deploy/operate production (Render + Neon) |
| [ROADMAP.md](ROADMAP.md) | See known issues and the "update to current" backlog |

Agent instructions live in the repo root: [`AGENTS.md`](../AGENTS.md) (canonical) and [`CLAUDE.md`](../CLAUDE.md). The top-level [`README.md`](../README.md) is the project showcase; `CHANGELOG.md` records releases.

Conventions: docs are Markdown, describe what the code does *now*, and name the source file that is the source of truth. When code and docs disagree, fix the docs in the same change.
