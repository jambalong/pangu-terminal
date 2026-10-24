# Changelog

Changes to this project will be documented in this file.
This project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html)

## [Unreleased]

### Added
- Share a plan: the new Share button on each plan makes a link you can post anywhere. The page behind it shows the plan and its material totals only (no name, email or inventory), is not listed by search engines, and has a link preview for chats and forums. Copy the link, or stop sharing to turn it off; deleting the plan also ends it.
- Plan priority: order your plans with the up and down arrows on each plan card (new plans go last; each card shows its rank). Lists everywhere use that order. With two or more plans selected, the optimizer shows "farm in this order": the extra farming each plan adds and how long everything up to it takes to regenerate, and the Farming Advisor is told your order. The arrows work with a keyboard and announce the move.
- Quick entry for the inventory: one page with a labelled box per material (by default only what your plans need, with how much they need), moved through with Enter or the arrow keys, with numbers like `1,200` and `25k` accepted and one Save button. If any entry is not a number nothing is saved and the problem entries are listed and marked. The dashboard checklist now sends you there.
- Inventory import and export: download your whole inventory as CSV or JSON (the JSON is the same shape as the API's), edit it anywhere, and import a CSV or JSON file or pasted text. Materials are matched by key or name, only quantities change, and unusable rows are skipped and listed instead of guessed at. Files are limited to 1 MB.
- Waveplate timeline: the optimizer now shows how long the Waveplates you still need take to regenerate (1 every 6 minutes, 240 a day), in plain words such as "9 days 14 h". Enter the Waveplates you have now (optional) and they are subtracted first. A note explains that the bar caps at 240, about a day of regeneration.
- Whole-account optimizer: the optimizer can now run on all your plans at once ("Use all plans", which also picks up plans you create later) or on a chosen set, instead of one plan at a time. Their materials are summed before your inventory is subtracted, and the Farming Advisor looks at the same combined result. The plan chooser works with the keyboard and a screen reader.
- Colors: muted text, the inventory quantity separator and the landing page step numbers now meet WCAG AA contrast (the muted grey is slightly lighter). Messages stay on screen longer: notices fade after 6 seconds instead of 2.5, and error messages stay until you dismiss them with a close button.
- Dialogs (new plan, edit inventory, delete confirmation, optimizer plan picker) are now accessible: they have a close button, announce their title to screen readers, take keyboard focus, keep Tab inside, close with Escape (including the delete confirmation and plan picker, which ignored it) and hand focus back to the button that opened them.
- Accessibility basics: pages declare their language, there is a "Skip to main content" link, the navigation is labelled and marks the current page, flash messages and form errors are announced by screen readers, every page has one top-level heading with a sensible outline, decorative images are hidden from assistive tech, in-text links are underlined, keyboard focus is always visible, and animations respect "reduce motion". The Material Summary header is now a real button that reports whether it is open.
- Contextual onboarding: a new account's dashboard shows a short "Get started" checklist (set your SOL3 phase, create a plan, enter what you own) that ticks itself off from your data and can be hidden for good. Empty pages now explain themselves: the planner offers a first plan (and tells guests no account is needed), the inventory says to start with what you own, and the optimizer points to the planner when there are no plans and warns that results assume an empty inventory. A new account's first sign-in greets you with your username.
- Link previews and search basics: pages now carry a description, canonical URL and Open Graph/Twitter tags (so a shared link shows a title, summary and icon), `robots.txt` keeps the app, accounts and API out of search while allowing the public pages, and a small `sitemap.xml` lists them.
- `test/views/partials_test.rb`: guard rails that fail when a partial lacks a locals declaration or reads an instance variable.
- Security headers: an enforcing Content-Security-Policy (scripts only from the app or with a per-request nonce; no framing) and a Permissions-Policy that turns off camera, microphone, geolocation, payment and USB.
- Abuse limits ahead of wider sharing: the Farming Advisor now has a daily generation budget (20 per account and 500 overall; cached advice and polling are free) and shows a notice when it is spent; plan creation is limited to 60 per hour per IP and the fallback sign-up form to 5 per hour per IP.
- Username: new accounts get a neutral lowercase name like `rover-4821` instead of your Google or Discord name, and you can change it under Account Settings (3 to 16 characters: lowercase letters, numbers, `.`, `_`, `-`). It never needs a password to change. The navbar caps the name's width.
- Privacy policy page at `/privacy` (linked from the landing page footer). Google requires a policy URL to publish the OAuth consent screen.
- Sign in with Google or Discord. New accounts are created through OAuth only: no email address or password is needed, and neither provider is asked for your email (Discord `identify`, Google `openid profile`). Your name is shown in the navbar as a username you can edit. Guest plans are claimed on first sign-in.
- Account Settings has a **Sign-in methods** section to link or unlink Google and Discord (you cannot unlink your last way in). Linking only happens while signed in, never by matching an email.
- Accounts without a password can change settings and delete their account without a current password.
- Rate limit on `/users/auth/*` (20 requests per minute per IP).

### Changed
- Health checks (`/up`) are exempt from rate limiting, so Render's health check and uptime monitors no longer write throttle counters to the database. That lets the free Neon database sleep when nobody is using the app.
- The sign-in page leads with the provider buttons; the email form moves behind **Sign in with email** and the sign-up form is removed. Existing email and password accounts keep working. Until a provider is configured on the server the old sign-up form stays available, so there is always a way to create an account.
- `users.email` is optional (new `identities` table, `users.display_name`).
- Views: every partial now declares strict locals and takes its data as locals instead of controller instance variables (plan cards, materials summary, inventory cards, optimizer results, farming advice). The duplicated modal shell and material/portrait markup moved into `shared/_modal`, `shared/_material_icon` and `shared/_subject_portrait`. `sorted_plan_materials` now takes the materials lookup as an argument. No visible change.
- Docs: `docs/ROADMAP.md` merged into `docs/PRODUCT_ROADMAP.md` (one roadmap: product, maintenance backlog, history). The feature roadmap is reprioritized with username accounts (email optional, with recovery codes) first, and carries a full implementation spec for it.
- Docs: `docs/DEPLOYMENT.md` records the owner's Render and Neon answers (five env vars, pooled Neon endpoint on PostgreSQL 17.11, `WEB_CONCURRENCY=2`, no Render shell) and documents running maintenance tasks from a local checkout against Neon.

### Fixed
- Pages no longer contain nested duplicate `main_content` and `modal` frames (invalid HTML that screen readers and future Turbo versions could trip over). The optimizer's plan picker can still be reopened after choosing a plan.
- The web app manifest pointed at an icon file that did not exist; it now uses `/favicon.png`.

### Removed
- Unused `rarity_border_class` / `rarity_bg_class` helpers.

---

## [1.5.0] - 2026-10-22

### Fixed
- CI: the `system-test` job's database service was the untagged `postgres` image (latest, currently 18) while everything else is documented and tested on 17; it is now pinned to `postgres:17`.
- System tests: the Cuprite options in `test/application_system_test_case.rb` never applied, because Rails registers its own Cuprite driver from the `driven_by` options and overrides a separate `Capybara.register_driver` block. The options now live in `driven_by`, with Cuprite waiting up to 30s (Ferrum default 10s) for Chrome and `no-sandbox` so it also runs as root in containers. A runner had hit `Ferrum::ProcessTimeoutError` before any test ran.
- Plan create/update validation errors over a plain HTML request (no Turbo) returned 406; they now redirect back to the planner with the errors.

### Added
- `docs/PRODUCT_ROADMAP.md`: project identity, principles, non-goals and a proposed Now/Next/Later feature roadmap for the owner to edit. `docs/ROADMAP.md` is now the maintenance backlog, with its stale review date fixed.
- `resonators.region` and `weapons.region` (`base` / `lahai_roi`, default `base`; migration `AddRegionToResonatorsAndWeapons`): which forgery material set a Resonator or weapon uses. The seeds set it from `LAHAI_ROI_RESONATORS` / `LAHAI_ROI_WEAPONS` (moved out of the planners); the planners read the column. `ForgeryRegion` validates the value. Existing plans are unaffected (their totals are stored); the seed runs before the server starts, so no plan is calculated with the default.

### Changed
- The Farming Advisor no longer holds a web thread for the LLM call (up to 20s). `/app/optimizer/advise` serves cached advice instantly; on a miss it enqueues `FarmingAdviceJob` once (`FarmingAdviceRequest`), answers with the loading card and the new `advisor-poll` Stimulus controller re-fetches the frame every 2s until the advice or a short-lived failure fallback arrives. Production uses the in-process `:async` ActiveJob adapter unless `SOLID_QUEUE_IN_PUMA` is set, so no new Render configuration is needed.
- Production boot seeds only when needed: `bin/docker-entrypoint` runs `db:seed:if_changed`, which skips `db:seed` when `db/seeds.rb`, `db/seeds/*.rb` and `config/skill_label_overrides.yml` are unchanged since the last successful run (`SeedGuard`, checksum in `ar_internal_metadata`, recorded only after a confirmed success; `FORCE_SEED=1` forces). A failed seed still does not block the boot and is retried next boot.
- `PlanForm` builds its skill and forte-node hashes and the controller's permitted params from one `SKILLS` list (about 40 fewer lines, same flat form field names, no view changes). Pinned by characterization tests.
- Dependencies: `thruster` 0.1.27 and `ruby_llm` 2.1.1 (brings `json` 3.1, `faraday` 2.15, `rubocop` 1.92, `uri` 1.1.2). Verified on Ruby 3.4.7 and against the live Farming Advisor.

---

## [1.4.1] - 2026-10-22

### Fixed
- Optimizer returned a 500 for a user with no SOL3 phase set when `run=1` was requested; it now shows the phase gate (and the advisor returns no content).
- `User#sol3_phase` accepted any integer; it is now validated against `DropRate::SOL3_PHASES`.
- A plain HTML validation failure when editing an inventory quantity returned 406; it now redirects back with the error.
- `LlmClient` logs timeouts and rate limits too (previously only unexpected errors), so a transient advisor fallback leaves a trace.

### Added
- `bin/rails advisor:check` (one minimal LLM call, exits non-zero on fallback) and `bin/rails plans:prune_guests` (dry run by default; `DAYS`, `APPLY=1`) backed by `GuestPlanPruner`.
- `APP_HOST` and `EXTRA_HOSTS` environment variables for allowed hosts and mailer links (defaults unchanged).

### Changed
- Docs: `AGENTS.md` and `docs/GAME_DATA.md` no longer describe the duplicated `SKILL_LABEL_OVERRIDES` or the three hard-coded phase ranges.
- `DropRate::SOL3_PHASES` replaces the phase range hard-coded in three places.
- `SKILL_LABEL_OVERRIDES` lives in `config/skill_label_overrides.yml`, read by the seeds and `forte:download_skill_icons`.
- `bin/dev` runs `bin/rails server`; `Procfile.dev` removed.
- `docs/ROADMAP.md` records what was verified in production, what was done and what is deliberately left.

---

## [1.4.0] - 2026-10-22

### Added
- `bin/rails plans:recompute`: rebuilds stored plan totals from their stored input after a calculation bug fix. Dry run by default (prints a per-material old -> new diff and any plan whose input no longer validates); `APPLY=1` writes; `PLAN_ID` / `USER_ID` narrow the scope. Backed by `PlanRecomputer` (tested for resonator, weapon and guest plans).

### Changed
- `PlanForm#plan_data` is now the single place plan data is built; `#save` uses it.
- Docs: `AGENTS.md`, `docs/ARCHITECTURE.md`, `docs/DEPLOYMENT.md` and `docs/ROADMAP.md` describe the recompute workflow. Suoming and other new content stay deferred until the owner has the data.

---

## [1.3.0] - 2026-10-22

### Fixed
- Guests can each plan the same Resonator or weapon. The one-plan-per-subject validation was scoped by `user_id`, which is nil for every guest, so one guest's plan blocked all others. Guests are now scoped by `guest_token`.
- API 500 responses now log the exception class and a backtrace excerpt instead of only the message.
- `Api::V1::InventoryController` uses `@current_user` like the other API controllers.

### Changed
- Optimizer computation moved from `OptimizersController` into `OptimizerService`.
- Farming Advisor responses are cached for one day per prompt digest; the unavailable-advisor fallback is never cached.
- `LlmClient` exposes `FALLBACK_MESSAGE` and `fallback?`.
- `Dockerfile` no longer installs the unused `libvips`.
- Agent guidance rewritten: `AGENTS.md` (workflow, definition of done, boundaries, sandbox recipe), `CLAUDE.md`, `.claude/settings.json` guardrails; `docs/ARCHITECTURE.md`, `docs/TESTING.md`, `docs/DEVELOPMENT.md` and `docs/ROADMAP.md` updated.

### Removed
- Tailwind CSS (`tailwindcss-rails`), its `app/assets/tailwind/` input and the `tailwindcss:watch` dev process. Only a handful of utilities were in use; they became small named classes next to the component styles (`.forte-slider-group`, `.header-icon`, `.config-rarity`, `.range-arrow`) or were dropped where already overridden by component CSS (`pt-4`, `transition-all`, `transition-colors`). The browser reset now lives in `app/assets/stylesheets/base/reset.css`. Computed styles on 18 pages were compared before and after with no differences.

- Stylesheets tidied: `application.css` split into `base/tokens.css`, `base/global.css`, `layouts/flash.css` and `layouts/form_errors.css`; 11 selectors that nothing referenced removed; the global `code` color in `user_manual.css` (which a later Tailwind rule always overrode) dropped so the shared blue applies everywhere; two hard-coded token colors replaced with `var(--ctp-*)`.
- README: version, project structure (`OptimizerService`, `assets/stylesheets` layout) and advisor caching brought in line with 1.3.0.
- Web fonts load through `<link rel="preconnect">` + `<link rel="stylesheet">` in `layouts/_fonts.html.erb` instead of a CSS `@import`.

### Added
- Tests for `LlmClient`, `OptimizerService` (with a query-count guard), advisor caching, guest plan uniqueness and the API 500 path.

---

## [1.2.6] - 2026-10-05

### Changed
- Homepage "SYSTEM ONLINE" tag and User Manual version tag updated from the stale `v1.0.0` to the current version

---

## [1.2.5] - 2026-10-05

### Changed
- README: prerequisites and a pointer to `docs/DEVELOPMENT.md`, corrected and expanded Project Structure, fuller Technology Stack table
- `CREDITS.md`: current hosting (Render, Neon, Postmark), image and data sources, Tailwind
- `docs/GAME_DATA.md`: complete "Adding a new weapon" checklist
- `docs/ROADMAP.md`: resolved items closed, new housekeeping items added

---

## [1.2.4] - 2026-10-05

### Changed
- Documentation: Windows/WSL2 development setup (rv, Docker Desktop, build tools, git credentials), local dev account, image workflow (`images:missing`, `images:download`, forte icon overrides) in `docs/GAME_DATA.md`, `docs/DEVELOPMENT.md`, `AGENTS.md`, `docs/TESTING.md` and `docs/ROADMAP.md`
- Removed the stale `libvips` prerequisite (the `image_processing` gem is gone)

---

## [1.2.3] - 2026-10-05

### Fixed
- Hiyuki's Inherent Skill 1 icon (missing from wutheringlab) is now fetched from the Fandom wiki by `forte:download_skill_icons` via `SKILL_ICON_URL_OVERRIDES`

---

## [1.2.2] - 2026-10-05

### Fixed
- Basic-attack skill icons for the 12 new Resonators (Denia, Hiyuki, Hsin, Jingran, Lucilla, Lucy, Qingxiao, Rebecca, Rover-Electro, Sigrika, Suisui, Yangyang: Xuanling) now use the `Normal-Attack` label, which matches the icon source and the other recent Resonators; `forte:download_skill_icons` no longer 404s on them

---

## [1.2.1] - 2026-10-04

### Added
- `bin/rails images:download` now derives Fandom wiki image URLs from record names (`FandomImageUrl`, MD5-hashed MediaWiki paths with `Resonator_`/`Weapon_`/`Item_` prefixes), so no per-image URL is needed; `config/image_sources.yml` ships preconfigured with a `wiki_names` exception for the shared Rover portrait
- `FandomImageUrl` tests covering real wiki URLs, apostrophes, colons and the Rover exception

---

## [1.2.0] - 2026-10-04

### Added
- Game data for versions 3.2 to 3.7 (phase 1): 12 Resonators (Sigrika, Denia, Hiyuki, Lucilla, Lucy, Rebecca, Suisui, Yangyang: Xuanling, Rover-Electro, Qingxiao, Jingran, Hsin) and 11 five-star weapons (Azure Oath, Blooming Jadehaven, Firstlight's Herald, Forged Dwarf Star, Freeze Frame, Frostburn, Glint of Clouds, Skull Thrasher, Solsworn Ciphers, Spectral Trigger, Thousandfold Deliverance)
- New materials: Mengzhou and Lahai-Roi flowers, ascension bosses (Nightmare Flashdrive, Solidarity's Loneflame, Forged Empyrean's Sigh), skill bosses (We Who Question, Skyward Glazed Heart, Remnant of the Wheel) and the Autopuppet Kernel enemy-drop set
- Boss sources Nightmare: Adam Smasher, Myriad Snare: Rustfire Chassis and Calamity Effigy; weekly sources Court of Shackled Souls, Seed of Illusory Origin and Ordinance of the Inevitable (drop rates apply to all SOL3 phases)
- `bin/rails images:missing` lists seeded records whose image files are absent; `bin/rails images:download` fetches them from `config/image_sources.yml` and converts them to 256x256 PNG
- `SeedDataIntegrityTest` guards against incomplete material mappings and sources, plus a Thousandfold Deliverance planner regression test

### Fixed
- Fusion Accretion had no enemy-drop mapping, so plans for it omitted its Ring materials; it now maps to the Ring set
- Corrected the Polarizer (Sword) and Carved Crystal (Broadblade) material descriptions to match their weapon-type mappings
- Gate of the Lost Star location now includes the Exostrider Slumber Site

### Changed
- Regional material lists in the Resonator and weapon planners now include the new Resonators/weapons that use the newer forgery sets
- Image slugs strip `:` so "Yangyang: Xuanling" maps to `yangyang-xuanling.png`

### Notes
- Suoming, Unspoken Rue and Miasmic Branch are deferred until their 2026-10-22 release is confirmed
- Image assets for the new content must be added under `public/images/` (see `bin/rails images:missing`)

---

## [1.1.1] - 2026-10-04

### Removed
- Unused `image_processing` gem (and its `ruby-vips`/`mini_magick` dependencies); the app does not use Active Storage variants. Supersedes Dependabot PR to bump it to 2.2.0.

---

## [1.1.0] - 2026-10-04

### Added
- `AGENTS.md` and `CLAUDE.md` with agent/contributor guidance
- Project documentation under `docs/`: architecture, data model, API, game data, development, testing, deployment, roadmap

### Changed
- Moved the API reference and design decisions from the README into `docs/API.md` and `docs/ARCHITECTURE.md`
- Rewrote `docs/DEPLOYMENT.md` for the Render + Neon deployment
- Upgraded `ruby_llm` 1.16.0 to 2.0.0 (fixes CVE-2026-67991 ReDoS flagged by bundler-audit); removed the ignored `use_new_acts_as` setting
- Switched the Gemini model from the deprecated `gemini-3.1-flash-lite-preview` to `gemini-3.1-flash-lite`
- Verified the Waveplate drop-rate seeds against the community spreadsheet for game version 3.7; no value changes were needed

### Removed
- Retired Kamal deployment: `config/deploy.yml`, `.kamal/`, `bin/kamal`, the `kamal` gem (and its dependencies), the commented-out CI deploy job and related ignore entries. Still available in git history.

### Dependencies
- Bumped rails 8.1.3.1 to 8.1.4, pg 1.6.3 to 1.7.0, solid_queue 1.6.0 to 1.7.0, solid_cable 4.0.2 to 4.1.0, bootsnap 1.25.0 to 1.26.0, thruster 0.1.25 to 0.1.26, brakeman 8.0.6 to 8.1.0, cuprite 0.17 to 0.18, simplecov 1.1.1 to 1.3.2, ruby-lsp 0.26.10 to 0.26.11
- Updated SimpleCov calls in `test/test_helper.rb` to the non-deprecated `skip` / `merging`

---

## [1.0.0] - 2026-05-18

**Estimated Time:** 7-8 hours

### Security
- Scoped password-free account update to SOL3 phase changes only; email updates now require current password verification

### Added
- Test coverage for `Users::RegistrationsController` custom Devise logic
- Test coverage for `PagesController` actions
- Branded error pages (400, 404, 406, 422, 500) styled to match app theme

### Changed
- Updated README with architecture and design decision entries: SHA-256 token hashing, 404 vs 403 enumeration prevention, Rack::Attack per-key rate limiting, LLM context injection, async Turbo Frame pattern, and LlmClient decoupling
- Minor README documentation updates

### Dependencies
- Updated addressable and net-imap to fix security advisories
- Bumped propshaft 1.3.1 to 1.3.2
- Bumped bootsnap 1.23.0 to 1.24.3
- Bumped puma 7.2.0 to 8.0.1
- Bumped ruby_llm 1.14.1 to 1.15.0
- Bumped devise 5.0.3 to 5.0.4
- Bumped webfactory/ssh-agent 0.9.0 to 0.10.0

---

## [0.19.1] - 2026-05-18

**Estimated Time:** 2-3 hours

### Fixed
- SSH known hosts fingerprint stored to prevent key mismatch in CD pipeline
- POSTMARK_API_TOKEN added to CI workflow secrets

---

## [0.19.0] - 2026-05-11

**Estimated Time:** 18-20 hours

### Added
- User manual with route, layout, Stimulus controller, stylesheet, content, and screenshot assets
- User manual link in landing page footer
- Password reset flow via Postmark SMTP with styled reset page
- Getting Started and Features sections on the landing page
- Deployment runbook at `docs/DEPLOYMENT.md` including deploy steps, log checking, and rollback procedure
- POSTMARK_API_TOKEN added to deployment runbook
- CD pipeline via GitHub Actions with auto-deploy on merge to main
- Brakeman security scan enabled in CI workflow

### Fixed
- Replaced `constantize` with an allowlist hash in `PlansController` to address Brakeman warning
- SMTP port changed from 587 to 2525 to fix timeout
- Turbo disabled on password reset form to fix redirect behavior
- Increased wait time for optimizer metrics in system tests
- nokogiri updated to patch security vulnerabilities

### Changed
- Landing page mockup portrait updated, star size enlarged, third column changed to all diamonds
- Dead code `no_waveplate_source?` removed

---

## [0.18.1] - 2026-05-08

**Estimated Time:** 6-8 hours

### Added
- Forte node icons rendered in the planner form with background-image rendering
- Forte icon assets for all resonators: skill icons, stat icons, and inherent skills 1 and 2
- Rake tasks to download forte and inherent skill icon assets
- `forte_icons` JSONB column on resonators
- Seeded forte icon paths and inherent skills for all resonators

### Fixed
- `LlmClient` rescue catches all exceptions to prevent blank advisor frame
- `LlmClient` 20-second timeout added for slow or dropped API connections
- Farming advisor handles flower and `enemy_drop` types and runs without farming priority
- Farming advisor allows synthesis chain coverage for `enemy_drop` materials
- Farming advisor disambiguates `enemy_drop` synthesis status in prompt
- Optimizer total runs and Waveplate cost corrected by accounting for co-drops across shared sources
- Range check on planner sliders now fires on blur instead of input
- `LlmClient` fallback message returned on rate limit and context length errors

### Changed
- FarmingAdvisorService prompt revised for output format clarity
- `sol3_phase` removed as a keyword argument from `FarmingAdvisorService` as it was unnecessary
- No farmable source placeholder changed to "Open-world only"
- Gemini model switched to `gemini-3.1-flash-lite-preview` for 500 RPD free tier headroom

---

## [0.18.0] - 2026-05-03

**Estimated Time:** 14-16 hours

### Added
- LLM Farming Advisor powered by RubyLLM and Gemini, renders farming recommendations on the Waveplate Optimizer page based on the player's actual deficits and inventory
- `FarmingAdvisorService` with context injection: deficits, farming priority, SOL3 phase, and full synthesis chain coverage
- `LlmClient` thin wrapper around RubyLLM with graceful fallback on rate limit errors
- `SynthesisService#chain_coverage` calculates craftable units across the full material tier chain using bottom-up pool accumulation
- Async Turbo Frame for the advisor so optimizer results render immediately while advice loads in the background
- Pulsing loading indicator shown while the advisor Turbo Frame resolves
- Separate `advise` route and controller action for the async advisor request
- Material name tooltips on icon hover in the Planner, Stimulus-based and scoped to the planner page
- Animated accordion for material summary in the Planner with smooth slide animation, chevron rotation, and fading border

### Changed
- Waveplate Optimizer material breakdown redesigned to a 2-column grid with chip-style inline source labels
- RUN OPTIMIZER button restored, plan selection no longer auto-triggers computation
- Gemini model set to `gemini-3.1-flash-lite-preview` for 500 RPD free tier headroom
- `ruby_llm` initializer uses credentials accessor without bang to allow asset precompile without master key

### Fixed
- Eager load material sources in optimizer to eliminate N+1 queries
- Memoized `exp_materials` lookup in `DropRateService` to eliminate redundant queries
- Eliminated redundant `EXISTS` check in `calculate_exp_avg_quantity`
- `ApplicationService.call` now forwards keyword arguments correctly for Ruby 3.4
- `RAILS_MASTER_KEY` added to GitHub Actions secrets and enabled in CI workflow

---

## [0.17.4] - 2026-04-27

**Estimated Time:** 7-9 hours

### Added
- `PATCH /api/v1/profile` endpoint to set SOL3 phase for the authenticated user
- `GET /api/v1/plans/:id/waveplate-summary` endpoint returning materials with active deficits and Waveplate farming estimates
- Capybara system tests with Cuprite covering the critical user journey: sign in, create plan, update inventory, view optimizer
- Optimizer controller tests for index, plans_modal, and select_plan actions
- Test coverage for `PlanForm#from_plan`, `PlansHelper`, `OptimizersHelper`, and `Plan` model branches

### Fixed
- System test CI failures from database seeding timing, Chrome wait conditions, and missing no-sandbox Cuprite configuration

### Changed
- `WaveplateSummaryService` refactored to accept inventory as an argument

---

## [0.17.3] - 2026-04-22

**Estimated Time:** 30 minutes

### Changed
- Updated README with `FarmingPriorityService` documentation and Waveplate Optimizer technical highlights

---

## [0.17.2] - 2026-04-15

**Estimated Time:** 5-6 hours

### Added
- `FarmingPriorityService` ranks farming source types by deficit material coverage, deduplicating interchangeable locations so they count as one source type
- Farming Priority section rendered in the Waveplate Optimizer UI
- `source_type` and `waveplate_cost_per_run` added to `DropRateService` output
- Sources list added to InventoryItem edit modals

### Changed
- Optimizer material cards updated with rarity borders and adjusted spacing

## [0.17.1] - 2026-04-12

**Estimated Time:** 30 minutes

### Added
- Added waveplate icon in place of WP in the Optimizer page

### Changed
- Updated hero subtitle to feature Waveplate optimizer
- Removed the coming soon badge for Optimizer feature card

## [0.17.0] - 2026-04-12

**Estimated Time:** 14-16 hours

### Added
- Waveplate Optimizer at `/app/optimizer`, select a plan and see how many runs and Waveplates it will take to cover each material deficit, broken down by farming source
- SOL3 phase selector on the Dashboard, set your current phase to get accurate drop rate estimates in the optimizer
- Toggle to show or hide materials with no farmable Waveplate source in optimizer results
- Optimizer link in the navbar
- `DropRateService` calculates estimated runs and Waveplate cost per source for a material deficit and SOL3 phase, with EXP cross-rarity conversion and phase fallback when data is unavailable for a given phase
- `drop_rates` table seeded with 617 rows covering forgery, simulation, boss, and weekly challenge sources
- `DropRate` model with validations and uniqueness constraint

### Changed
- Revised drop rates schema to track rarity and material type as discriminators instead of a direct material association

### Fixed
- Optimizer gate now links to the Dashboard instead of account settings
- Optimizer nav link now highlights correctly when on the optimizer page

## [0.16.9] - 2026-04-11

**Estimated Time:** 30 minutes

### Changed
- Updated Rails, ruby-lsp, and Kamal to resolve security advisories

## [0.16.8] - 2026-03-30

**Estimated Time:** 6-8 hours

### Added
- GitHub Actions CI pipeline. Runs tests, linting, and security scans on every pull request
- Code coverage reporting via SimpleCov and Codecov
- CI and coverage badges added to README

### Fixed
- Rate limiting tests now run correctly in parallel without interfering with each other
- Security vulnerabilities in Trix and Devise addressed

## [0.16.7] - 2026-03-20

**Estimated Time:** 8-10 hours

### Added
- Integration tests for all five API endpoints
- Controller tests for Plans, Inventory, API Keys, and Dashboard
- Model validation tests for Plan, Material, and InventoryItem
- Service layer tests for ResonatorAscensionPlanner, WeaponAscensionPlanner, and SynthesisService

### Fixed
- Inventory edit modal now re-renders with errors instead of silently failing on invalid input
- Plan form no longer crashes when subject or plan data is missing
- API key creation now shows a proper error instead of raising an exception on blank name
- Synthesis calculation now uses the full inventory to avoid nil material lookups
- Forte node upgrades now included in the no-change validation check

### Changed
- Refactored SynthesisService for readability
- Reconciliation response now exposes satisfied quantity and renames the higher rarity field for clarity

## [0.16.6] - 2026-03-15

**Estimated Time:** 6-8 hours

### Added
- Source and MaterialSource models and seed data covering all farming locations
- `GET /api/v1/materials` endpoint returning each material with its farming source info
- Model validations for Resonator and Weapon
- Descriptions added to all material seed entries

### Fixed
- Guest plan sync now uses subject_id instead of digging through plan data
- Material types normalized to snake_case across the board
- API now returns 404 for unknown endpoints and 500 for unexpected errors

### Changed
- Updated README with GET /api/v1/materials documentation and curl examples
- Reconciliation response shape updated to match current serializer output
- Font changed from Inter to Oxanium
- Removed Wave-Cutting Tooth material as it has no confirmed in-game source

## [0.16.4] - 2026-03-07

**Estimated Time:** 10 minutes

### Changed
- Replaced Gacha Calculator feature card with REST API feature card
- Updated sync banner to reflect current and upcoming features

## [0.16.3] - 2026-03-07

**Estimated Time:** 30 minutes

### Fixed
- Account settings form now correctly submits to PATCH /settings
- Updating account details no longer redirects to landing page

## [0.16.2] - 2026-03-07

**Estimated Time:** 1 hour

### Added
- Updated README with full endpoint documentation and curl examples

### Changed
- Accepted `subject_name` as input for `POST /api/v1/plans` instead of requiring `subject_id`

## [0.16.1] - 2026-03-07

**Estimated Time:** 1-2 hours

### Added
- Added integration tests for `GET /api/v1/plans/:id/reconciliation` endpoint

## [0.16.0] - 2026-03-06

**Estimated Time:** 1-2 hours

### Added
- Added `GET /api/v1/plans/:id/reconciliation` endpoint
- Added `ReconciliationSerializer` to convert material IDs to snake_case names and omit internal fields from the response

## [0.15.1] - 2026-03-04

**Estimated Time:** 25 minutes

### Fixed
- Fixed rate limiter crashing on request objects instead of path strings

## [0.15.0] - 2026-03-04

**Estimated Time:** 1-2 hours

### Added
- Added Rack::Attack rate limiting for API and login routes
- Added integration tests verifying 429 status and proper error JSON response

### Changed
- Lowered API key count limit from 5 to 3 per user

## [0.14.7] - 2026-03-01

**Estimated Time:** 30-45 minutes

### Changed
- Added turbo frame attributes to dashboard nav links
- Replaced CSS active nav states with a Stimulus navbar controller

## [0.14.6] - 2026-03-01

**Estimated Time:** 10-15 minutes

### Changed
- Moved plan ownership check into the Plan model
- Refactored `#set_guest_token` to use `||=` assignment

## [0.14.5] - 2026-03-01

**Estimated Time:** 5-10 minutes

### Fixed
- Fixed typo on `:weapon_type` for Luuk Herssen resonator seed data

## [0.14.4] - 2026-03-01

**Estimated Time:** 2-3 hours

### Added
- Added integration tests for `POST /api/v1/plans` endpoint

### Fixed
- Fixed params parsing error on plan creation
- Fixed typo on unprocessable entity status code
- Fixed typo in `RoverAscensionCost` class name

## [0.14.3] - 2026-03-01

**Estimated Time:** 30-45 minutes

### Added
- Added uniqueness constraint on plans scoped to user, subject type, and subject ID

### Fixed
- Fixed ascension rank nil crash in planner service

### Changed
- Refactored planner service validation, and memoized common material lookups

## [0.14.2] - 2026-03-01

**Estimated Time:** 1-2 hours

### Added
- Added `GET /api/v1/inventory` endpoint returning a flat hashmap of inventory as JSON
- Added integration tests for the inventory endpoint

## [0.14.1] - 2026-03-01

**Estimated Time:** 30 minutes

### Added
- Added `Material#snake_case_name` method with tests covering multiple cases

### Changed
- Updated `#requirements` to use the new `#snake_case_name` method

## [0.14.0] - 2026-03-01

**Estimated Time:** 1-2 hours

### Added
- Added `POST /api/v1/plans` endpoint
- Added `last_used_at` column to ApiKeys, updated on every successful authentication
- Added flash notice on API key deletion

### Changed
- Refactored API key token storage to use SHA-256 hexdigest instead of plain text token

## [0.13.5] - 2026-02-22

**Estimated Time:** 45 minutes - 1 hour

### Added
- Added integration tests for `GET /api/v1/plans` covering auth, status codes, and serialized response

## [0.13.4] - 2026-02-22

**Estimated Time:** 30-45 minutes

### Added
- Added API key management UI for creating and deleting keys
- Added a limit of 5 API keys per user

### Fixed
- Fixed incorrect keyword argument passed when creating API keys

## [0.13.3] - 2026-02-22

**Estimated Time:** 2-3 hours

### Added
- Added `GET /api/v1/plans` endpoint scoped to authenticated user
- Added `PlanSerializer` to resolve plan data into a proper JSON response shape

### Fixed
- Fixed token authentication not being available in the API base controller
- Fixed misspelled association name on User preventing API key lookups

### Changed
- Refactored PlanSerializer to use the polymorphic subject name instead of digging through `plan_data`
- Used eager loading on plans query to prevent N+1 queries

## [0.13.2] - 2026-02-22

**Estimated Time:** 10-15 minutes

### Added
- Added routes for ApiKey resources (create and destroy only, scoped under `/app`)
- Added `GET /api/v1/plans` route

## [0.13.1] - 2026-02-22

**Estimated Time:** 1 hour

### Added
- Added `ApiKey` model with token generation, name validation, and dependent delete on user model
- Added database migration for ApiKeys with `user_id` and `token` columns

## [0.13.0] - 2026-02-22

**Estimated Time:** 1-2 hours

### Added
- Built `Api::V1::BaseController` with token authentication and standardized 400/401/404 error responses

### Changed
- Updated Rails from 8.1.1 to 8.1.2

## [0.12.0] - 2026-02-17

**Estimated Time:** 6-8 hours

### Added
- Added Resonator and Weapon image icons
- Updated game data seeds to include new Lahai Roi resonators, weapons, and materials (current as of 2026-02-15)
- Added `region` column to the `WeaponTypeMaterial` mapping table to support Lahai Roi weapon materials
- Added MIT License

### Fixed
- Fixed typo in Luuk Herssen image filename
- Fixed Everbright Polestar weapon icon filename (underscore to hyphen)
- Fixed nil seed data from miscellaneous typos
- Fixed database preparation not using bundler when starting the server

### Changed
- Changed Rover icons to show both gender variants
- Resonator and weapon seeds now include image URLs and render in their respective views
- Material seeds now include image URLs and render in all relevant views

## [0.11.2] - 2026-02-08

**Estimated Time:** 5 minutes

### Removed
- Removed unused `separate_materials_by_type` method

## [0.11.1] - 2026-02-08

**Estimated Time:** 20-30 minutes

### Fixed
- Fixed plan filter using stale data on inventory updates
- Ensured synthesis calculations refresh correctly when switching between filtered plans

## [0.11.0] - 2026-02-08

**Estimated Time:** 2-3 hours

### Added
- Implemented plan filtering system for inventory page
- Added plan dropdown selector to filter inventory by specific plan subject requirements
- Implemented `apply_plan_filter` method to keep only plan-required items and relevant EXP potions
- Added filter persistence across edit operations (plan_id param passed through URLs)
- Updated synthesis calculation to use single plan's requirements or aggregated all-plans data

## [0.10.1] - 2026-02-08

**Estimated Time:** 15-20 minutes

### Changed
- Refactored badge icons for better visual distinction between synthesis types
- Improved clarity between higher-rarity satisfaction and lower-tier crafting indicators

## [0.10.0] - 2026-02-08

**Estimated Time:** 4 hours

### Added
- Implemented EXP Potion cross-rarity satisfaction system
- Extended `SynthesisService.reconcile` to return enhanced reconciliation data:
  - `satisfied_qty`: accounts for cross-rarity EXP potion satisfaction
  - `used_higher_rarity`: boolean flag indicating when higher rarities filled the gap
- Added visual indicators for material satisfaction:
  - Anvil badge shows count of EXP from higher rarities (`satisfied_qty - owned`)
  - Anvil badge shows count convertible from lower-tier surplus (`can_convert`)
  - Pulsing teal border for materials that can be synthesized from lower tiers
  - Pulsing sapphire border for materials satisfied by higher-rarity equivalents
- Updated progress bars to display true satisfaction (`satisfied_qty / needed`) rather than just owned count

## [0.9.0] - 2026-02-02

**Estimated Time:** 1-2 hours

### Added
- Merged PR #31: Synthesis Engine & Inventory Management Overhaul
  - Integrated SynthesisService for 3-to-1 material conversion logic
  - Added `item_group_id` to Materials and implemented lower tier checking
  - Migrated inventory quantity updates to Turbo-powered modals
  - Added Synthesis pulse glow indicator and `format_quantity` helper
  - Implemented model-level validations for InventoryItem, Material, and Plan
  - Added unit tests for synthesis logic and model integrity

### Changed
- Refactored validate_inputs! method to use concise error messages with assistance of AI

### Fixed
- Resolved flash notice persistence bug and cleaned up test fixtures

## [0.8.9] - 2026-02-02

**Estimated Time:** 30-45 minutes

### Changed
- Refactored tests to use generic names and variables for better maintainability

## [0.8.8] - 2026-02-02

**Estimated Time:** 5-10 minutes

### Changed
- Adjusted modal-header margin-bottom for improved spacing

## [0.8.7] - 2026-02-02

**Estimated Time:** 30-45 minutes

### Added
- Added InventoryItem validation tests

## [0.8.6] - 2026-02-02

**Estimated Time:** 5 minutes

### Changed
- Kept folder structure for test organization

## [0.8.5] - 2026-02-02

**Estimated Time:** 5 minutes

### Removed
- Removed default controllers test created by Rails generator

## [0.8.4] - 2026-02-02

**Estimated Time:** 45 minutes - 1 hour

### Added
- Added model-level validations to InventoryItem, Material, and Plan models

## [0.8.3] - 2026-02-02

**Estimated Time:** 5-10 minutes

### Changed
- Added margin-bottom to item-header for better visual spacing

## [0.8.2] - 2026-02-02

**Estimated Time:** 30-45 minutes

### Changed
- Refactored inventory view to use `separate_materials_by_type` method for cleaner code

## [0.8.1] - 2026-02-02

**Estimated Time:** 20-30 minutes

### Changed
- Updated dimmed styling for materials not required by plans (progress bar and quantity display)

## [0.8.0] - 2026-02-02

**Estimated Time:** 2-3 hours

### Added
- Implemented Turbo-powered modal for editing inventory item quantities
- Added real-time synthesis family item updates when quantities change
- Enabled seamless inventory management through modal interface

## [0.7.7] - 2026-02-02

**Estimated Time:** 5 minutes

### Removed
- Removed debug print statement from codebase

## [0.7.6] - 2026-02-02

**Estimated Time:** 30-45 minutes

### Changed
- Updated synthesis indicator to use subtle pulse glow animation

## [0.7.5] - 2026-02-02

**Estimated Time:** 5-10 minutes

### Changed
- Reordered Mysterious Code material for better organization

## [0.7.4] - 2026-02-02

**Estimated Time:** 15-20 minutes

### Changed
- Updated quantity displays to use `format_quantity()` helper method

## [0.7.3] - 2026-02-02

**Estimated Time:** 30-45 minutes

### Added
- Added `format_quantity()` helper that formats numbers to game-speak notation (1k, 24.7k, 1.5M)

## [0.7.2] - 2026-02-02

**Estimated Time:** 5-10 minutes

### Changed
- Adjusted position of synthesis indicator icon for better visual alignment

## [0.7.1] - 2026-02-01

**Estimated Time:** 20-30 minutes

### Changed
- Updated planner title font color
- Changed View All button width, dashboard title font size and color for improved aesthetics

## [0.7.0] - 2026-02-01

**Estimated Time:** 3-4 hours

### Added
- Integrated `SynthesisService` into `Inventory` controller
- Added progress indicators and styled progress info for inventory item cards
- Implemented synthesis opportunity detection and visualization

### Fixed
- Fixed bug where `material_id` was returning as integer string instead of integer

## [0.6.3] - 2026-02-01

**Estimated Time:** 1-2 hours

### Added
- Unit tested `SynthesisService` before integration
- Verified core synthesis logic passes all test cases

## [0.6.2] - 2026-02-01

**Estimated Time:** 10 minutes

### Changed
- Disabled fixtures for minitest to improve test isolation

## [0.6.1] - 2026-02-01

**Estimated Time:** 5-10 minutes

### Removed
- Deleted outdated test fixtures

## [0.6.0] - 2026-01-26

**Estimated Time:** 5-7 hours

### Added
- Implemented `SynthesisService` to handle 3-to-1 material conversion logic
- Created synthesis reconciliation system for inventory management
- Used AI as a rubberduck to design the data structure for output

## [0.5.0] - 2026-01-26

**Estimated Time:** 45 minutes - 1 hour

### Added
- Added `item_group_id` column to materials table to enable synthesis chain tracking
- Implemented database migration for 3-to-1 material synthesis support

## [0.4.4] - 2026-01-25

**Estimated Time:** 45 minutes - 1 hour

### Added
- Improved sorting functionality for inventory and plan views

### Fixed
- Fixed bugs that were causing incorrect sorting behavior

## [0.4.3] - 2026-01-25

**Estimated Time:** 30-45 minutes

### Fixed
- Resolved flash notice persistence bug where notices were persisting across page reloads

## [0.4.2] - 2026-01-23

**Estimated Time:** 20-30 minutes

### Changed
- Updated CSS styles for improved visual consistency

## [0.4.1] - 2026-01-22

**Estimated Time:** 15-20 minutes

### Changed
- Updated font styles in certain content areas for better readability

## [0.4.0] - 2026-01-19

**Estimated Time:** 1-2 hours

### Added
- Implemented favicon system with force refresh capability
- Added Apple device-specific favicons for improved mobile experience

## [0.3.6] - 2026-01-11

**Estimated Time:** 20-30 minutes

### Added
- Added changelog documentation for v0.1.0 baseline release

## [0.3.5] - 2026-01-11

**Estimated Time:** 30-45 minutes

### Changed
- Updated styles for `confirm_delete` view and `plan_card` components

## [0.3.4] - 2026-01-11

**Estimated Time:** 20-30 minutes

### Fixed
- Fixed subject access pattern in plan views (changed from subject_name/subject_id to direct subject access)

## [0.3.3] - 2026-01-11

**Estimated Time:** 15-20 minutes

### Added
- Added helper method to titleize Forte Node names for better display formatting

## [0.3.2] - 2026-01-11

**Estimated Time:** 10 minutes

### Changed
- Refactored `planner.call` return statement to remove unnecessary transformation logic

## [0.3.1] - 2026-01-11

**Estimated Time:** 20-25 minutes

### Changed
- Refactored Forte Nodes Map to use standardized keys for consistency

## [0.3.0] - 2026-01-11

**Estimated Time:** 3-4 hours

### Added
- Implemented PlanForm service integration across 7 files
- Added edit and update operations for plans
- Cleaned up local variables and improved code organization

## [0.2.0] - 2026-01-11

**Estimated Time:** 2-3 hours

### Added
- Added `subject_id` column to Plan model for simpler and more efficient queries
- Implemented polymorphic association between Plan and Resonator/Weapon models
- Added duplicate plan detection scope and validation

### Fixed
- Fixed `PG::DuplicateColumn` error by manually adding `subject_type` and updating indexes

## [0.1.1] - 2026-01-11

**Estimated Time:** 1 hour

### Added
- Created PlanForm service to handle translation between form parameters and planner calculator arguments
- Used AI to scaffold form object as a reference

## [0.1.0] - 2026-01-11

### Added
- Added "sync" feature to migrate existing guest data to permanent User account upon registration/sign-up
- Integrated Devise with custom hybrid ownership system
- Added guest_token logic to allow unauthenticated users to create and manage plans
- Utilized Turbo Frames and Turbo Streams for modal management, plan deletion, dynamic sync banner updates, and single page application feel for planner
- Built ResonatorAscensionPlanner and WeaponAscensionPlanner services to calculate material costs based on levels, ascension ranks, and specific Forte Node upgrades
- Configured Kamal 2 deployment for Rails 8 stack with PostgreSQL on DigitalOcean

### Changed
- Rebranded the project to **Pangu Terminal** and updated all internal modules, classes, and namespaces to reflect the new identity
