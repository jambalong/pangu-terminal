# Development Setup

## Prerequisites

- Ruby 3.4.7 (`.ruby-version`; `mise.toml` pins it for mise users). [rv](https://github.com/spinel-coop/rv) also works (see [Windows / WSL2](#windows--wsl2))
- Docker + Docker Compose (PostgreSQL 17 for dev/test), or a native PostgreSQL 16+
- A C compiler and headers for gems with native extensions (`build-essential`, `pkg-config`, `libssl-dev`, `libpq-dev`, `libyaml-dev`, `zlib1g-dev`, `libffi-dev` on Debian/Ubuntu). Precompiled rubies do not remove this: the gems still compile
- Optional: ImageMagick (`magick`/`convert`) for the `forte:*` and `images:*` rake tasks; Chromium for system tests

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

## Local account

Any email-shaped address and a password of 6 to 128 characters works (no email confirmation). A throwaway dev account:

```bash
bin/rails runner 'User.create!(email: "dev@example.com", password: "password123")'
```

or sign up at `http://localhost:3000/signup`. Guest plans created at `/app/planner` move to the account on sign-in. Remove it with `bin/rails runner 'User.find_by(email: "dev@example.com")&.destroy'`.

## Windows / WSL2

Developed and tested on WSL2 (Ubuntu or another distro) with zsh/bash.

- Keep the repo in the Linux filesystem (`~/Dev/...`), not under `/mnt/c`: Bundler and file watching are very slow there.
- **Ruby with rv:** `curl -LsSf https://rv.dev/install | sh`, then `source $HOME/.cargo/env`. In the repo, `rv clean-install` installs the Ruby from `.ruby-version` plus the gems. Run `rv shell zsh` (or `bash`) and add what it prints to `~/.zshrc`; after that plain `bin/dev` and `bin/rails ...` use the project Ruby. Without the shell integration, use `rv run bin/rails ...` for Ruby scripts only: `bin/dev` is a `sh` script and fails with "no Ruby script found".
- **Build tools first:** `rv clean-install` fails with "You have to install development tools first" on every native gem until the compiler and headers above are installed.
- **Docker Desktop:** enable WSL integration for your distro (Settings, Resources, WSL Integration). Do not also install Docker Engine inside the distro: two daemons fight over `/var/run/docker.sock`. If `docker compose up -d` says "permission denied while trying to connect to the docker API", add yourself to the group and restart the shell: `sudo usermod -aG docker $USER` (run `wsl --shutdown` from PowerShell if it persists).
- **Git credentials:** if `git push` prints "git-credential-manager.exe: not found", point git at the real helper: `git config --global credential.helper "/mnt/c/Program\ Files/Git/mingw64/bin/git-credential-manager.exe"` (check the path with `ls "/mnt/c/Program Files/Git/"*/bin/git-credential-manager*.exe`), or use `gh auth login && gh auth setup-git`.

## Images

New game data needs image files (see [GAME_DATA.md](GAME_DATA.md#images)): `bin/rails images:missing` lists what is absent, `DRY_RUN=1 bin/rails images:download` previews the URLs, `bin/rails images:download` fetches portraits, weapon icons and material icons, and `bin/rails forte:download_skill_icons` fetches the forte skill icons. Commit the files on a branch and open a PR.

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
bin/rails images:missing                # list seeded records whose image files are missing
bin/rails images:download               # fetch missing portraits/weapons/materials from the Fandom wiki (KIND=..., DRY_RUN=1 to preview URLs)
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
| `You have to install development tools first` while installing gems | Install the compiler and headers listed under Prerequisites, then rerun `rv clean-install` / `bundle install` |
| `permission denied ... /var/run/docker.sock` | Add your user to the `docker` group and restart the shell; check Docker Desktop's WSL integration |
| `rv run bin/dev`: `no Ruby script found in input` | `bin/dev` is a shell script: set up `rv shell` integration and run `bin/dev` directly |
| `git-credential-manager.exe: not found` on push | Fix `credential.helper` (see Windows / WSL2) |
