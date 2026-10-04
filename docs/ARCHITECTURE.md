# Architecture

Pangu Terminal is a conventional Rails 8.1 monolith (Hotwire front end, PostgreSQL, Docker deploy). This document explains how the pieces fit together and why; see [DATA_MODEL.md](DATA_MODEL.md) for tables and [GAME_DATA.md](GAME_DATA.md) for domain concepts.

## Request flows

**Planning (web).** `PlansController` -> `PlanForm` (`app/forms/plan_form.rb`) -> `ResonatorAscensionPlanner` / `WeaponAscensionPlanner` -> result stored in `plans.plan_data` (`input` + `output`, where `output` maps `material_id => quantity`). Plans belong to a `User` or, for guests, to a `guest_token` cookie.

**Inventory and reconciliation.** `InventoryItemsController` edits per-user quantities (Turbo Stream response). `SynthesisService.new(owned, required).reconcile` compares `owned` against a plan's (or all plans') `output` and reports needed / satisfied / deficit / craftable.

**Optimizer.** `OptimizersController#compute_optimizer_results`: reconcile -> keep materials with a deficit -> `DropRateService` per material for the user's `sol3_phase` -> `FarmingPriorityService` ranks source types. The advisor panel is a separate Turbo Frame request (`/app/optimizer/advise`) that calls `FarmingAdvisorService` -> `LlmClient` -> RubyLLM (Gemini).

**API.** `/api/v1/*` inherits `Api::V1::BaseController` (`ActionController::API`), authenticates via bearer token, and reuses the same services. See [API.md](API.md).

## Authentication and ownership

- Web users: Devise (`database_authenticatable, registerable, recoverable, rememberable, validatable`). Sign-in/sign-up/settings routes are customised in `config/routes.rb` (`/sign-in`, `/signup`, `/settings`); `Users::RegistrationsController` allows a password-free update only when the sole param is `sol3_phase`.
- Guests: `PlansController#set_guest_token` stores a UUID in `cookies.permanent[:guest_token]`. On sign-in/sign-up, `ApplicationController#sync_guest_plans` claims the guest's plans (dropping duplicates of subjects the user already planned) and clears the cookie.
- `PlanLoading#load_current_plans` is the single place that scopes plans to the current user or guest; always go through it (or `current_user.plans`) instead of `Plan.find`.
- Optimizer, inventory, dashboard and API-key pages require `authenticate_user!`; the planner works for guests.

## Background infrastructure

Solid Cache, Solid Queue and Solid Cable are installed (`config/cache.yml`, `queue.yml`, `cable.yml`, `recurring.yml`). In production all four databases (`primary`, `cache`, `queue`, `cable`) point at the same `DATABASE_URL`. No application jobs exist yet (`app/jobs/application_job.rb` only). Rack::Attack uses `Rails.cache`.

## Frontend

Importmap + Stimulus (`app/javascript/controllers/`), Tailwind via `tailwindcss-rails` (`app/assets/tailwind/application.css`) plus hand-written per-feature CSS in `app/assets/stylesheets/`, served by Propshaft. Static art lives in `public/images/{materials,resonators,weapons,forte,textures}`. `allow_browser versions: :modern` is on in `ApplicationController`.

## Design decisions

The sections below were originally in the README.


## Service Objects for Business Logic
Complex calculations live in services, not controllers or models:
- **ResonatorAscensionPlanner:** Character upgrade cost calculation
- **WeaponAscensionPlanner:** Weapon upgrade cost calculation
- **SynthesisService:** Inventory reconciliation, synthesis detection, and full chain coverage calculation
- **DropRateService:** Waveplate cost and run estimation per farming source
- **FarmingPriorityService:** Ranks farming source types by material breadth and waveplate efficiency
- **FarmingAdvisorService:** Injects optimizer context into a structured prompt and returns a plain-English farming recommendation
- **LlmClient:** Thin wrapper around RubyLLM with graceful fallback on rate limit errors

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
Three separate throttles with different strategies:

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
