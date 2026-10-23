# Architecture

Pangu Terminal is a conventional Rails 8.1 monolith (Hotwire front end, PostgreSQL, Docker deploy). This document explains how the pieces fit together and why; see [DATA_MODEL.md](DATA_MODEL.md) for tables and [GAME_DATA.md](GAME_DATA.md) for domain concepts.

## Request flows

**Planning (web).** `PlansController` -> `PlanForm` (`app/forms/plan_form.rb`) -> `ResonatorAscensionPlanner` / `WeaponAscensionPlanner` -> result stored in `plans.plan_data` (`input` + `output`, where `output` maps `material_id => quantity`). Plans belong to a `User` or, for guests, to a `guest_token` cookie.

**Inventory and reconciliation.** `InventoryItemsController` edits per-user quantities (Turbo Stream response). `SynthesisService.new(owned, required).reconcile` compares `owned` against a plan's (or all plans') `output` and reports needed / satisfied / deficit / craftable.

**Optimizer.** `OptimizerService` (called from `OptimizersController#index` and `#advise`): reconcile -> keep materials with a deficit -> `DropRateService` per material for the user's `sol3_phase` -> per-source run totals; `FarmingPriorityService` then ranks source types. The advisor panel is a separate Turbo Frame request (`/app/optimizer/advise`) handled by `FarmingAdviceRequest`, which never waits on the model: advice is cached in `Rails.cache` for one day keyed by a SHA-256 digest of the prompt (`FarmingAdvisorService#cache_key`), so identical optimizer state is served instantly. On a miss it marks the key pending, enqueues `FarmingAdviceJob` once (counted against a daily per-user and overall budget, `ADVISOR_DAILY_LIMIT_PER_USER` / `ADVISOR_DAILY_LIMIT_GLOBAL`; when spent it answers `:limited` with a notice and enqueues nothing) and answers with a loading card; the `advisor-poll` Stimulus controller re-fetches the frame every 2s (at most 30 times). The job calls `FarmingAdvisorService#generate` -> `LlmClient` -> RubyLLM (Gemini), caches a real answer, and on `LlmClient::FALLBACK_MESSAGE` leaves a 30s failed marker so the next poll shows the fallback instead of looping (the fallback itself is never cached).

**API.** `/api/v1/*` inherits `Api::V1::BaseController` (`ActionController::API`), authenticates via bearer token, and reuses the same services. See [API.md](API.md).

## Authentication and ownership

- Web users: Devise (`database_authenticatable, registerable, recoverable, rememberable, validatable, omniauthable`). New accounts come from OAuth (Google, Discord): `Users::OmniauthCallbacksController` finds an `Identity` by `(provider, uid)` or creates a `User` plus `Identity`, then signs in (`sync_guest_plans` runs through `after_sign_in_path_for`). Providers are read from ENV by `OauthProviders` (`config/initializers/00_oauth_providers.rb`); a provider with unset variables registers no strategy and shows no button. Scopes request no email, so OAuth users have `email = NULL`. Provider names are never stored: a new account gets a neutral lowercase username (`User.generate_display_name`, `rover-1234`) that the user can edit in Settings (3 to 16 characters so the navbar never needs an ellipsis; CSS still caps `.user-badge` for older long names). The username form posts only `display_name`, which `Users::RegistrationsController` accepts without a password. Linking happens only while signed in (never by matching email, which would allow account takeover via an unverified provider email); `IdentitiesController#destroy` unlinks unless it is the last way in. The email sign-up form (`Users::RegistrationsController#new/create`) is only reachable while no provider is configured, so production always has a way to create an account. The request phase is POST-only (`omniauth-rails_csrf_protection`). Reasons for OAuth-only instead of username accounts: a tester would not give an email, and a username/password scheme needs recovery codes and its own abuse handling, while the providers already handle both.
- Legacy email/password users keep working (sign-in form behind "Sign in with email", password reset by email). Sign-in/sign-up/settings routes are customised in `config/routes.rb` (`/sign-in`, `/signup`, `/settings`); `Users::RegistrationsController` allows a password-free update when the sole param is `sol3_phase`, and for OAuth-only users (no password to confirm); password users must still confirm their current password.
- Guests: `PlansController#set_guest_token` stores a UUID in `cookies.permanent[:guest_token]`. On sign-in/sign-up, `ApplicationController#sync_guest_plans` claims the guest's plans (dropping duplicates of subjects the user already planned) and clears the cookie.
- `PlanLoading#load_current_plans` is the single place that scopes plans to the current user or guest; always go through it (or `current_user.plans`) instead of `Plan.find`.
- Optimizer, inventory, dashboard and API-key pages require `authenticate_user!`; the planner works for guests.

## Background infrastructure

Solid Cache, Solid Queue and Solid Cable are installed (`config/cache.yml`, `queue.yml`, `cable.yml`, `recurring.yml`). In production all four databases (`primary`, `cache`, `queue`, `cable`) point at the same `DATABASE_URL`. The one application job is `FarmingAdviceJob`. Production uses the in-process `:async` ActiveJob adapter unless `SOLID_QUEUE_IN_PUMA` is set (then `:solid_queue`), because Solid Queue only processes jobs when a worker runs; this keeps the advisor working with no extra Render configuration. Solid Cable is installed (Rails 8 default, and the transport Turbo Stream broadcasts would use) but nothing uses it yet. Rack::Attack uses `Rails.cache`.

## Frontend

Importmap + Stimulus (`app/javascript/controllers/`), hand-written plain CSS in `app/assets/stylesheets/` (no CSS framework and no build step), served by Propshaft. Tailwind was removed in v1.3.0; see [Stylesheets](#stylesheets). Static art lives in `public/images/{materials,resonators,weapons,forte,textures}`. `allow_browser versions: :modern` is on in `ApplicationController`.

### Views and partials

- Partials are components: each starts with a strict-locals comment (`<%# locals: (plan:, materials_lookup:) %>`) and never reads controller instance variables; templates pass data in explicitly. `test/views/partials_test.rb` enforces both.
- Shared building blocks live in `app/views/shared/`: `_modal` (the Turbo Frame modal shell, used with `render layout: "shared/modal", locals: { container_class:, content_class:, close_on_esc: } do`), `_material_icon` and `_subject_portrait`.
- Templates are still bound to their controller, so they may read `@ivars` and pass them down as locals.
- Collections are rendered with `render partial: ..., collection: ..., as: ..., locals: {...}` so shared locals reach every item.

### Stylesheets

`stylesheet_link_tag :app` serves every file under `app/assets/stylesheets/`, one `<link>` per file in path order, with no build step.

- `base/reset.css`: browser reset (adapted from Tailwind's preflight, MIT) inside `@layer base`. Layered rules always lose to unlayered ones, so any normal rule in this app overrides the reset regardless of specificity or load order.
- `base/tokens.css`: design tokens (`:root` custom properties: fonts and the Catppuccin palette). Use `var(--ctp-*)` instead of literal colors.
- `base/global.css`: element defaults (`body`, inputs, `code`) and shared helpers (`.hidden`, `.container`, `main.no-scroll`).
- `<feature>/<component>.css`: one file per component or page (`plans/`, `inventory_items/`, `optimizers/`, `devise/`, `layouts/` incl. `flash.css` and `form_errors.css`, `pages/`, `dashboards/`).
- Web fonts are loaded by `<link>` tags in `app/views/layouts/_fonts.html.erb` (rendered by both layouts), not by CSS `@import`, so the browser can fetch them in parallel.

Because all sheets are global and unscoped, prefix class names with their component (`plan-card-*`, `optimizer-*`) and avoid bare element selectors outside `base/`. There is no utility-class framework: add a named class next to the component CSS instead. A rule that is only referenced from CSS is dead; classes built in Ruby (for example `rarity-bg-<n>` in `InventoryItemsHelper`) are not, so search the helpers before deleting.

## Design decisions

The sections below were originally in the README.


## Service Objects for Business Logic
Complex calculations live in services, not controllers or models:
- **ResonatorAscensionPlanner:** Character upgrade cost calculation
- **WeaponAscensionPlanner:** Weapon upgrade cost calculation
- **SynthesisService:** Inventory reconciliation, synthesis detection, and full chain coverage calculation
- **DropRateService:** Waveplate cost and run estimation per farming source
- **OptimizerService:** Reconciles a plan against inventory and estimates farming runs and Waveplates per deficit material
- **FarmingPriorityService:** Ranks farming source types by material breadth and waveplate efficiency
- **FarmingAdvisorService:** Injects optimizer context into a structured prompt and returns a plain-English farming recommendation
- **LlmClient:** Thin wrapper around RubyLLM with a timeout and graceful fallback (`FALLBACK_MESSAGE`, `fallback?`) on any error

This keeps controllers thin and logic testable.

## JSONB for Plan Caching
Plans store requirements as JSONB in a single `plan_data` field:
```ruby
plan_data: {
  "input": { "current_level": 1, "target_level": 90, ... },
  "output": { "1": 2500000, "5": 46, "12": 4, ... }
}
```

Trade-off: a normalized plan_materials table would make individual materials queryable,
but since requirements are computed once and read as a whole, JSONB caching avoids
unnecessary schema complexity.

The snapshot is deliberately not recomputed on read: game data does not change, so a plan only goes stale when a calculation bug is fixed. `PlanRecomputer` (`bin/rails plans:recompute`, dry run by default) rebuilds `output` from the stored `input` for exactly that case.

## Polymorphic Associations
Plans can belong to either a Resonator or Weapon via polymorphic association:
```ruby
class Plan < ApplicationRecord
  belongs_to :subject, polymorphic: true
end

class Resonator < ApplicationRecord
  has_many :plans, as: :subject
end
```

Characters and weapons have different upgrade paths but share identical plan CRUD operations.

## Guest User System
Unauthenticated users can try the planner via secure UUID tokens stored in cookies:
```ruby
# Plan validation
validate :must_have_owner
def must_have_owner
  if user_id.blank? && guest_token.blank?
    errors.add(:base, "Plan must belong to user or guest")
  end
end
```

It lowers friction for guest users with a future migration path to registered accounts.

One plan per subject is enforced by a validation scoped to `user_id` for signed-in users and to `guest_token` for guests. Scoping guests by `user_id` alone would not work: every guest has a nil `user_id`, so one guest's plan would block all other guests from planning the same subject. The unique database index only covers `user_id` rows (Postgres treats NULLs as distinct), so guest uniqueness relies on the validation.

## Turbo Streams for Real-Time Updates
Inventory edits trigger Turbo Stream responses that update the edited item plus all related items in the synthesis family, reflecting the recalculated craftable counts instantly:

**Controller:**
```ruby
# Fetch entire synthesis family for re-render
@related_items = current_user.inventory_items.joins(:material)
  .where(materials: { item_group_id: @inventory_item.material.item_group_id })
```

**View (update.turbo_stream.erb):**
```erb
<%= turbo_stream.replace dom_id(@inventory_item) do %>
  <%= render partial: "inventory_items/inventory_item", locals: { inventory_item: @inventory_item } %>
<% end %>

<% @related_items.each do |item| %>
  <%= turbo_stream.replace dom_id(item) do %>
    <%= render item %>
  <% end %>
<% end %>
```

This updates the edited item immediately, then recomputes synthesis for the entire family (e.g., all Cadence materials) so craftable counts reflect the new inventory state, all without a page reload.

## SHA-256 API Token Hashing
API tokens are hashed with SHA-256 before storage. The plaintext token is generated once, shown to the user, and never stored:

```ruby
before_create :generate_token

def generate_token
  @raw_token = "pt_#{SecureRandom.urlsafe_base64(32)}"
  self.token = Digest::SHA256.hexdigest(@raw_token)
end
```

Authentication hashes the incoming bearer token and looks up the digest:

```ruby
api_key = ApiKey.find_by(token: Digest::SHA256.hexdigest(token))
api_key&.touch(:last_used_at)
```

A database leak exposes only digests. `last_used_at` is updated on every successful authentication so inactive keys can be identified for future auto-revocation.

## 404 Instead of 403 for Non-Owner Resources
Plan queries are scoped to the current user before the lookup in both the web and API controllers:

```ruby
# Web: scoped via load_current_plans helper
def set_plan
  @plan = load_current_plans.find(params[:id])
end

# API: scoped directly to current_user
plan = @current_user.plans.find(params[:id])

# BaseController rescues the result
rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
```

If a plan exists but belongs to another user, the scoped query raises `RecordNotFound` and returns 404. Returning 403 would confirm the resource exists and leak information about other users' data. 404 prevents enumeration.

## Rack::Attack Rate Limiting
The throttles below, plus `plans/create/ip` (60 POSTs per hour on `/app/planner`; guests need no account, so this stops one client filling the database by dropping its cookie), `signups/ip` (5 POSTs per hour on `/signup`, the fallback form) and `oauth/ip` (20 requests per minute per IP on `/users/auth/*`, covering both the request and callback phases). Three separate throttles with different strategies:

```ruby
# General: catch scrapers and misconfigured clients
throttle("req/ip", limit: 300, period: 5.minutes) do |req|
  req.ip
end

# Brute force: limit login attempts by IP and email
throttle("logins/ip", limit: 5, period: 20.seconds) do |req|
  req.ip if req.path == "/sign-in" && req.post?
end

throttle("logins/email", limit: 5, period: 20.seconds) do |req|
  if req.path == "/sign-in" && req.post?
    req.params["user"]&.dig("email").to_s.downcase.presence
  end
end

# API: keyed by token, not IP
throttle("api/token", limit: 60, period: 1.minute) do |req|
  if req.path.start_with?("/api")
    req.get_header("HTTP_AUTHORIZATION")&.delete_prefix("Bearer ")
  end
end
```

The API throttle keys on the bearer token so each consumer gets an independent bucket. One abusive client cannot affect others on the same network. The throttled responder returns JSON for `/api/` routes and plain text elsewhere.

## LLM Context Injection
The Farming Advisor does not rely on the model's game knowledge. Live player data is injected into the system prompt: deficits, farming priority ranking, synthesis chain coverage across all tiers, and SOL3 phase. The model is instructed to reason only over those numbers:

```ruby
FarmingAdvisorService.call(
  results: @results,
  farming_priority: @farming_priority,
  chain_coverage: @chain_coverage
)
```

`SynthesisService#chain_coverage` pre-computes craftable units bottom-up across the full material tier chain before the prompt is built. The model receives a number, not a reasoning problem. This keeps recommendations grounded in the player's actual data rather than generic game advice.

## LlmClient as a Thin Wrapper
`FarmingAdvisorService` does not call RubyLLM directly. All provider interaction goes through `LlmClient`, which handles timeouts, rate limits, and unexpected errors:

```ruby
def self.ask(prompt)
  Timeout.timeout(20) do
    RubyLLM.chat.ask(prompt).content
  end
rescue Timeout::Error, RubyLLM::RateLimitError, RubyLLM::ContextLengthExceededError
  "Advisor is temporarily unavailable. Check your farming priority ranking above for recommendations."
rescue => e
  Rails.logger.error("LlmClient error: #{e.class} #{e.message}")
  "Advisor is temporarily unavailable. Check your farming priority ranking above for recommendations."
end
```

`FarmingAdvisorService` has no direct dependency on RubyLLM. The model is configured in the RubyLLM initializer, not hardcoded in the client.

## Async Turbo Frame for LLM
The Farming Advisor loads via a dedicated `advise` route rendered into a Turbo Frame with a `src`:

```erb
<%= turbo_frame_tag "farming-advisor", src: optimizer_advise_path do %>
  <%# pulsing loading indicator %>
<% end %>
```

The frame fires a separate request to `optimizer_advise_path` after the optimizer results render. The LLM call happens in that request, so farming priority and material breakdown are never blocked by the 20-second timeout window.
