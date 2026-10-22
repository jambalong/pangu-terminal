# Product roadmap (proposal)

> **Status: proposal drafted for the owner to edit.** It was derived from the project's stated identity and the current code, not from user research. Reorder, cut or rename anything. The maintenance backlog (bugs, platform, docs) lives in [ROADMAP.md](ROADMAP.md); this file is only about what the product could become.

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
- **Zero friction to try.** Guests can plan without an account; signing up adds inventory and the optimizer.
- **Game data is data.** Patch content should be a seed change, not code (see [GAME_DATA.md](GAME_DATA.md)).
- **Honest about uncertainty.** Drop rates are averages from a community spreadsheet; say so wherever they are used.
- **Small and fast.** One Rails app, no heavy infrastructure, cheap to run on a free tier.

## Non-goals

- Reading or automating a player's game account, memory or screen (no credentials, no scraping of player data).
- Damage calculators, echo/build optimizers, gacha pull trackers: other tools do them well and they dilute the loop.
- Paid tiers, ads or selling data.

## Roadmap

Size: S under a day, M a few days, L a week or more. "Data" means it needs game data from the owner first.

### Now: strengthen the loop with what already exists

| # | Feature | Why it fits | Size | Needs |
| --- | --- | --- | --- | --- |
| 1 | **Whole-account optimizer**: run the optimizer over all plans (or a chosen set) instead of one at a time | The core question is "what should I farm next across everything I want", not per Resonator. `Plan.fetch_materials_summary` and `SynthesisService` already aggregate. | M | none |
| 2 | **Waveplate timeline**: turn total Waveplates into "about N days of regeneration" | Makes the plan feel real and helps players choose what to build first. | S | confirm the regen rate and cap with the owner (assumed 1 Waveplate per 6 minutes, cap 240) |
| 3 | **Plan priority**: order plans and weight the optimizer toward the top ones | Lets "farm for X first" be explicit instead of implied. | M | pairs with 1 |
| 4 | **Faster inventory entry**: grid with keyboard navigation, JSON/CSV export and import (the API already exposes inventory) | Inventory is the highest-effort part of using the app; less friction means more accurate advice. | M | none |
| 5 | **Shareable read-only plan link**: a tokenized public page of a plan and its totals | Community growth and "help me plan" threads; works for guests. | M | a nullable `share_token` on `plans` (schema change) |

### Next: complete the Waveplate picture

| # | Feature | Why it fits | Size | Needs |
| --- | --- | --- | --- | --- |
| 6 | **Tacet Fields and Echo EXP** as farming sources | Finishes Waveplate coverage; the drop-rate spreadsheet already has the numbers. | M | Data |
| 7 | **"Log a run"**: after farming a source, add the expected average drops to inventory in one click | Closes step 4 of the loop without retyping counts. | M | none |
| 8 | **Event multipliers**: manual toggle such as "2x forgery drops this week" that scales source drop rates | Events change the right answer; a manual toggle is cheap and honest. | S | none |
| 9 | **This-week view**: weekly boss and challenge runs left, reset timers, what to run today | The advisor already prioritizes weekly content; make it a checklist. | M | reset times from the owner |
| 10 | **Patch-day tooling**: `rake content:check` that reports missing images, mappings or drop rates for new content, plus a single data file per patch | Keeps content updates minutes long, which protects the "stays current" promise. | M | none |

### Later: validate demand first

| # | Feature | Notes | Size |
| --- | --- | --- | --- |
| 11 | **Discord bot or other API clients** using `/api/v1` tokens ("what should I farm today?") | The API and rate limiting exist; a thin client would test whether players want it outside the web app. | M |
| 12 | **Localization** (for example zh, ja, ko): UI strings and game terms | Large player base; needs a translation source for material names. | L |
| 13 | **PWA and offline** (manifest is stubbed in the layout) | Useful on mobile while playing. | M |
| 14 | **Account backup/restore** (JSON) | Reassures users; overlaps with item 4. | S |

## How to pick

A feature belongs if it reduces wasted Waveplate or shortens the time to "I know what to farm". Prefer items that need no new game data, because game data depends on the owner's time. Each shipped item should add a `CHANGELOG.md` entry, tests, and an update to this file.

## Suggested order

1 and 2 first (high value, no data, mostly existing services), then 4 (accuracy of everything else), then 3 and 5. Start 6 when the Tacet Fields data is available.
