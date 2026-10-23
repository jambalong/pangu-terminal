# Roadmap

One document for where the project is going and what keeps it healthy. Part 1 is the product roadmap (the feature list is a proposal drafted from the project's identity; the owner set the first priority). Part 2 is the maintenance backlog and decisions. Part 3 is the history of what shipped. Check items off and add a `CHANGELOG.md` entry as they land. Last reviewed 2026-10-23 (game version 3.7 released 2026-09-30).

# Part 1: Product

## Identity

Pangu Terminal "tracks material needs against your inventory, shows what you can craft instead of farm, and prioritizes what's left to farm" for *Wuthering Waves* players.

**Mission:** never spend a Waveplate (or an evening) farming something you already own, can craft, or do not need yet.

The product has one loop, and every feature should strengthen it:

1. **Plan** what you want to build (costs).
2. **Know** what you own (inventory) and what synthesis already covers.
3. **Decide** where the next Waveplate goes (farming priority, advisor).
4. **Update** as the game gives you drops, then repeat.

## Principles

- **Numbers first, advice second.** The LLM advisor only explains numbers the app computed; it never invents data.
- **Zero friction to try.** Guests can plan without an account; signing up adds inventory and the optimizer. Accounts must not force players to hand over personal data.
- **Game data is data.** Patch content should be a seed change, not code (see [GAME_DATA.md](GAME_DATA.md)).
- **Honest about uncertainty.** Drop rates are averages from a community spreadsheet; say so wherever they are used.
- **Small and fast.** One Rails app, no heavy infrastructure, cheap to run on a free tier.

## Non-goals

- Reading or automating a player's game account, memory or screen (no credentials, no scraping of player data).
- Damage calculators, echo/build optimizers, gacha pull trackers: other tools do them well and they dilute the loop.
- Paid tiers, ads or selling data.

## Feature roadmap

Size: S under a day, M a few days, L a week or more. "Data" means it needs game data from the owner first. Order within each group is the recommended order.

### Now

| # | Feature | Why it fits | Size | Needs |
| --- | --- | --- | --- | --- |
| 1 | **OAuth sign-in (Google, Discord)** (owner priority; a tester did not want to share an email). **Shipped**; owner still has to create the OAuth clients and set the env vars, see [DEPLOYMENT.md](DEPLOYMENT.md#oauth-sign-in-setup-owner-steps). | "Zero friction to try": players should not have to hand over an email. | L | done |
| 2 | **Whole-account optimizer**: run the optimizer over all plans (or a chosen set) instead of one at a time | The core question is "what should I farm next across everything I want". `Plan.fetch_materials_summary` and `SynthesisService` already aggregate. | M | none |
| 3 | **Waveplate timeline**: turn total Waveplates into "about N days of regeneration" (builds on 2) | Makes the plan feel real and helps players choose what to build first. | S | confirm the regen rate and cap (assumed 1 Waveplate per 6 minutes, cap 240) |
| 4 | **Faster inventory entry**: grid with keyboard navigation, JSON/CSV export and import (the API already exposes inventory) | Inventory is the highest-effort part of using the app; less friction means more accurate advice. | M | none |
| 5 | **Plan priority**: order plans and weight the optimizer toward the top ones | Lets "farm for X first" be explicit instead of implied. | M | pairs with 2 |
| 6 | **Shareable read-only plan link**: a tokenized public page of a plan and its totals (shows no username or email unless the owner opts in) | Community growth and "help me plan" threads; works for guests. | M | a nullable `share_token` on `plans` |

### Next

| # | Feature | Why it fits | Size | Needs |
| --- | --- | --- | --- | --- |
| 7 | **"Log a run"**: after farming a source, add the expected average drops to inventory in one click | Closes step 4 of the loop without retyping counts. | M | none |
| 8 | **Event multipliers**: manual toggle such as "2x forgery drops this week" that scales source drop rates | Events change the right answer; a manual toggle is cheap and honest. | S | none |
| 9 | **This-week view**: weekly boss and challenge runs left, reset timers, what to run today | The advisor already prioritizes weekly content; make it a checklist. | M | reset times from the owner |
| 10 | **Patch-day tooling**: `rake content:check` that reports missing images, mappings or drop rates for new content, plus a single data file per patch | Keeps content updates minutes long, which protects the "stays current" promise. | M | none |
| 11 | **Tacet Fields and Echo EXP** as farming sources | Finishes Waveplate coverage; the drop-rate spreadsheet already has the numbers. | M | Data |

### Later (validate demand first)

| # | Feature | Notes | Size |
| --- | --- | --- | --- |
| 12 | **Discord bot or other API clients** using `/api/v1` tokens ("what should I farm today?") | The API and rate limiting exist; a thin client would test whether players want it outside the web app. | M |
| 13 | **Localization** (for example zh, ja, ko): UI strings and game terms | Large player base; needs a translation source for material names. | L |
| 14 | **PWA and offline** (manifest is stubbed in the layout) | Useful on mobile while playing. | M |
| 15 | **Account backup/restore** (JSON) | Reassures users; overlaps with 4. | S |

**How to pick:** a feature belongs if it reduces wasted Waveplate or shortens the time to "I know what to farm". Prefer items that need no new game data. Each shipped item adds a `CHANGELOG.md` entry, tests, and an update to this file.

**Why this order:** 1 (done) was the owner's priority and unblocks wider testing. 2 and 3 are the biggest mission gains from code that already exists. 4 improves the accuracy of everything after it. 5 and 6 build on 2. Items 7 to 11 extend the loop once the core is strong; start 11 when the Tacet Fields data is available.

### Item 1: OAuth sign-in (replaces the username spec)

The earlier plan (username accounts, optional email, recovery codes, `/recover`) is **superseded**. The owner chose OAuth-only account creation: players sign in with Google or Discord, no email or password is entered, and the app requests no email scope (Discord `identify`, Google `openid profile`). Reasons: it removes the email objection directly, avoids building recovery codes and a recovery throttle, and offloads credential storage and account recovery to the providers. Legacy email/password users keep working; the sign-up form stays only as a fallback while no provider is configured. Design and decisions are in [ARCHITECTURE.md](ARCHITECTURE.md#authentication-and-ownership); `users.email` is nullable and `identities` holds `(provider, uid)`.

# Part 2: Maintenance backlog

## Game data (waiting on the owner)

- [ ] **Deferred until the owner has the data (do not add new Resonators, weapons or materials before then):** Suoming (Electro Sword; flower Miasmic Branch; boss Forged Empyrean's Sigh; enemy set Howler Core; skill boss Remnant of the Wheel; stats unknown) and her weapon Unspoken Rue (Sword on the Polarizer set per wiki "likely"; enemy-drop set unknown). Adding a Lahai-Roi-era Resonator or weapon is a seed-list edit (`LAHAI_ROI_*`, see [GAME_DATA.md](GAME_DATA.md)).
- [ ] Check cost tables (`04_cost_templates.rb`) and the SOL3 phase range (`DropRate::SOL3_PHASES`) against 3.7. Needs the owner's data.
- [ ] Tacet Fields data (see feature 11).

## Platform

- [x] Production database confirmed: Neon PostgreSQL **17.11** (pooled endpoint), matching CI and `docker-compose.yml`. CI's `system-test` job now pins `postgres:17` too.
- [ ] Ruby 3.4.7 and PostgreSQL 17 bumps: change together when there is a reason (security release or a gem requiring it). No reason today.
- [ ] GitHub Actions versions in `ci.yml` are managed by Dependabot.

## Documentation

- [x] `TODO(owner)` items in [DEPLOYMENT.md](DEPLOYMENT.md) answered by the owner on 2026-10-23: five Render env vars, pooled Neon endpoint, `WEB_CONCURRENCY=2`, no Render shell (maintenance tasks run from a local checkout against Neon; see "Running tasks without a Render shell").
- [ ] Keep `docs/API.md` examples in sync with `app/serializers/` when response shapes change (the forte-node booleans in the serializer output are intentional; plans store `0/1` integers).

## Observations and decisions

- A single full-suite failure was seen once locally on the first run after a branch switch and migration (18 runs since, including from freshly created parallel-worker databases, and every CI run, were green). It could not be reproduced and its text was not captured. If it shows up again, keep the Minitest seed and the failure output before re-running.

Decided to leave as is (revisit only if the stated trigger happens):

- Solid Queue is only used if `SOLID_QUEUE_IN_PUMA` is set (default is the in-process `:async` adapter, so no Render change is needed). Solid Cable is installed but unused (Rails 8 default; Turbo Stream broadcasts would use it). Kept because removing them means changing the multi-database production config for no gain. Revisit if the extra tables bother you.
- With no Render shell, rake tasks run from a local checkout against Neon. If a paid instance is ever used, the shell makes these simpler.

# Part 3: History

## v1.1.0

- Documentation foundation (`docs/`, `AGENTS.md`, `CLAUDE.md`).
- Drop rates re-verified against the community spreadsheet screenshot for 3.7 (no changes needed).
- Kamal deployment removed (kept only in git history; see [DEPLOYMENT.md](DEPLOYMENT.md#history)).
- Dependencies bumped, including `ruby_llm` 2.0.0 (1.16.0 had a high-severity ReDoS advisory) and the Gemini model moved off the deprecated preview id.

## v1.2.x

- Game data 3.2 to 3.7 phase 1: 12 Resonators, 11 weapons, new materials, sources and mappings; seed data integrity tests.
- Image tooling (`images:missing`, `images:download`, Fandom URL derivation) and image assets for the new content.
- `image_processing` removed (unused).

## v1.3.0

- Guest plan uniqueness scoped by `guest_token`; API 500s log class and backtrace; `LlmClient` fallback is one constant.
- `OptimizerService` extracted; farming advice cached one day per prompt digest.
- Tailwind removed; stylesheets split into `base/` plus per-component files; fonts loaded via `<link>`.
- `libvips` removed; agent guidance rewritten with workflow, boundaries and a definition of done.

## v1.4.0 and v1.4.1

- Stale plans: `PlanRecomputer` / `bin/rails plans:recompute` (dry run by default) rebuilds stored totals after a calculation bug fix.
- Production verified; optimizer no longer 500s without a SOL3 phase; one `DropRate::SOL3_PHASES` range and a `User#sol3_phase` validation.
- `SKILL_LABEL_OVERRIDES` single source; inventory edit HTML failure redirects; `APP_HOST` / `EXTRA_HOSTS`; `bin/dev` runs the server directly.
- `bin/rails plans:prune_guests` (manual, dry run by default); `LlmClient` logs every failure class; `bin/rails advisor:check`.

## v1.5.0

- `PlanForm` driven by one `SKILLS` list; plan errors over plain HTML redirect instead of 406.
- `db:seed:if_changed` (`SeedGuard`) skips the seed when unchanged; `FORCE_SEED=1` forces.
- Region/forgery-set membership is data (`resonators.region`, `weapons.region`), validated by `ForgeryRegion`.
- Farming Advisor off the request thread (`FarmingAdviceRequest`, `FarmingAdviceJob`, `advisor-poll` controller); `:async` adapter unless `SOLID_QUEUE_IN_PUMA`.
- `thruster` 0.1.27 and `ruby_llm` 2.1.1; CI `system-test` pinned to Postgres 17 and the Cuprite options fixed; this roadmap.
