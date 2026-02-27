# Wuthering Waves Resource Optimization Platform

**Pangu Terminal** helps *Wuthering Waves* players plan and track the materials needed to max out their Resonators and weapons. Input your current levels and target upgrades, track what you own, and the app automatically shows you what to farm next accounting for synthesis chains so you don't waste time grinding materials you can craft.

**Status:** MVP complete with planning, inventory tracking, synthesis detection, and a REST API.

Live at [panguterminal.ambalong.dev](http://panguterminal.ambalong.dev)

## What This Project Showcases

### Full-Stack Rails Architecture
- Polymorphic associations for heterogeneous plan types (character vs. weapon upgrades)
- Service objects extracting complex business logic (ResonatorAscensionPlanner, SynthesisService)
- JSONB caching for flexible plan data storage and query optimization
- Guest authentication system via secure tokens (no Devise required for trials)
- Turbo Streams for real-time inventory updates without full page reloads

### REST API
- Token-based authentication via Bearer header
- RESTful endpoints exposing core business logic as JSON
- Integration tests verifying authentication, authorization, and response contracts

### Production-Ready Deployment
- Kamal 2 containerized deployment to DigitalOcean
- PostgreSQL JSONB for flexible data modeling
- Docker-compose local development environment
- Automated database migrations and seeding

## Feature Overview

### Ascension Planner
Players manually calculate material costs across multiple upgrade paths (levels, ascension ranks, skills, forte nodes).

Implemented a service-based planner that:
- Validates upgrade ranges against game mechanics (e.g., can't reach level 50 at ascension rank 0)
- Queries cost tables for the delta range (current --> target)
- Resolves material types to material IDs via mapping tables
- Returns a structured material requirement hash cached in JSONB

**Technical Highlights:**
```ruby
# Polymorphic plan design
Plan
  ├── belongs_to :subject, polymorphic: true (Resonator | Weapon)
  ├── plan_data (JSONB)
  │   ├── input: { current_level, target_level, ... }
  │   └── output: { material_id => quantity }
  └── guest_token # (for unauthenticated users)

# Service layer handles complexity
ResonatorAscensionPlanner.new(
  resonator: aemeath,
  current_level: 1,
  target_level: 90,
  # ... validates and calculates
).call
```

By separating game rules (stored in cost tables) from business logic (planner service), it makes the system maintainable and testable.

---

### Inventory Management & Synthesis
Players own materials across 5 rarity tiers. Lower tiers can be synthesized (3:1) into higher tiers, but players can't easily see if they have "enough" when accounting for conversions.

It features a Synthesis Service that:
- Reconciles owned inventory against plan requirements
- Detects EXP potion equivalence (e.g., 20 Basic potions = 2 Premium potions via exp_value)
- Identifies synthesis opportunities (e.g., "You have 18 surplus Cadence Seed -> can craft 6 Cadence Bud")
- Returns detailed satisfaction data with visual indicators

**Technical Highlights:**
```ruby
# Cross-tier equivalence detection
inventory = { premium_potion_id => 3 }  # 60k exp
requirements = { basic_potion_id => 40 }  # 40k exp needed

SynthesisService.new(inventory, requirements).reconcile_inventory
# => { basic_potion_id => { satisfied: true, ... } }

# Synthesis opportunity in output
synthesis_opportunity: {
  can_convert: 6  # (18 / 3).floor
}
```

This solves the core "resource paradox" where players have data but can't act on it without manual spreadsheet recalculation.

---

### Plan Aggregation & Filtering
Users create multiple plans (Jinhsi + Jiyan + Yinlin), and need to see material requirements both aggregated (total across all plans) and filtered (single plan focus).

Two views are supported:

- **Planner Dashboard:** Shows total materials needed across all active plans
- **Inventory Page:** Filtered view (single plan) or aggregated view (all plans), with  a plan dropdown selector

**Technical Highlights:**
```ruby
# Accumulate requirements across all plans
plans.each_with_object({}) do |plan, totals|
  plan.plan_data.dig("output").each do |material_id, qty|
    totals[material_id.to_i] = (totals[material_id.to_i] || 0) + qty
  end
end

# Plan filtering in controller
if @selected_plan.present?
  requirements_hash = (@selected_plan.plan_data.dig("output") || {}).transform_keys(&:to_i)
else
  requirements_hash = Plan.fetch_materials_summary(@plans)
end
```

## API

Pangu Terminal exposes a versioned REST API for developer access to plans and inventory data.

### Authentication

All endpoints require a bearer token in the Authorization header.

```
Authorization: Bearer <your_api_token>
```

Tokens are issued per user via API keys tied to a user account. (Frontend UI work in progress)

### Endpoint

#### GET /api/v1/plans

Returns all plans belonging to the authenticated user.


```bash
curl https://panguterminal.ambalong.dev/api/v1/plans \
  -H "Authorization: Bearer <token>"
```

**Response 200**
```json
[
  {
    "id": 1,
    "subject_name": "Kumokiri",
    "subject_type": "Weapon",
    "configuration": {
      "current_level": 1,
      "target_level": 20,
      "current_ascension_rank": 0,
      "target_ascension_rank": 1
    },
    "requirements": {
      "shell_credit": 25480,
      "basic_resonance_potion": 38,
      "lf_howler_core": 6
    },
    "created_at": "2026-02-16T06:41:08.000Z",
    "updated_at": "2026-02-16T06:41:08.000Z"
  }
]
```

### Error Responses

| Status | Meaning | Response |
| --- | --- | --- |
| 401 | Missing, invalid, or revoked token | `{ "error": "Unauthorized" }` |
| 400 | Malformed request | `{ "error": "<param message>" }` |
| 404 | Record not found | `{ "error": "Record not found" }` |

### Notes

- Material IDs in `plan_data` are resolved to snake_case material names before responding.
- `subject_id` and `user_id` are intentionally omitted (internal implementation details).
- `guest_token` is intentionally omitted (sensitive internal field).

## Architecture & Design Decisions

### Service Objects for Business Logic
Complex calculations live in services, not controllers or models:
- **ResonatorAscensionPlanner:** Character upgrade cost calculation
- **WeaponAscensionPlanner:** Weapon upgrade cost calculation
- **SynthesisService:** Inventory reconciliation and synthesis detection

This keeps controllers thin and logic testable.

### JSONB for Plan Caching
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

### Polymorphic Associations
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

### Guest User System
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

### Turbo Streams for Real-Time Updates
Inventory edits trigger Turbo Stream responses that update the edited item plus all related items in the synthesis family, reflecting the recalculated synthesis opportunities instantly:

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

This updates the edited item immediately, then recomputes synthesis for the entire family (e.g., all Cadence materials) so synthesis opportunities reflect the new inventory state, all without a page reload.

## Technology Stack

| Component | Technology |
| --- | --- |
| Backend | Rails 8.1 + Ruby 3.4 |
| Database | PostgreSQL 17 |
| Frontend | Hotwire (Turbo + Stimulus) |
| Deployment | Docker + Kamal 2 |
| Testing | Minitest |

## Getting Started

### Prerequisites
- Ruby 3.4+ (via `rbenv`, `asdf`, or system)
- Docker & Docker Compose
- Git

### Local Development

1. **Clone and navigate:**
   ```bash
   git clone https://github.com/jambalong/pangu-terminal.git
   cd pangu-terminal
   ```

2. **Install gems:**
   ```bash
   bundle install
   ```

3. **Start the database container:**
   ```bash
   docker-compose up -d
   ```

4. **Prepare the database:**
   ```bash
   bin/rails db:prepare
   ```

5. **Run the server:**
   ```bash
   bin/dev
   ```

   The app will be available at `http://localhost:3000`.

### Running Tests

```bash
bin/rails test
```

### Project Structure
```
app/
├── models/
│   ├── plan.rb              # Core polymorphic plan model
│   ├── inventory_item.rb    # User inventory tracking
│   ├── material.rb          # Game material definitions
│   ├── resonator.rb         # Character model
│   ├── weapon.rb            # Weapon model
│   └── user.rb              # User authentication (Devise)
├── controllers/
│   ├── api/
│   │   └── v1/
│   │       ├── base_controller.rb   # Auth + error handling
│   │       └── plans_controller.rb  # Plans API endpoint
│   ├── plans_controller.rb
│   ├── inventory_controller.rb
│   └── ...
├── services/
│   ├── resonator_ascension_planner.rb  # Resonator cost calculation
│   ├── weapon_ascension_planner.rb     # Weapon cost calculation
│   └── synthesis_service.rb            # Inventory reconciliation
├── views/
│   ├── plans/
│   ├── inventory/
│   └── ...
└── helpers/

db/
├── migrate/          # Schema migrations
├── seeds.rb          # Seed game data (cost tables, materials)
└── schema.rb

test/
├── models/
├── services/
└── controllers/
    └── api/
        └── v1/
            └── plans_controller_test.rb

docker-compose.yml
Kamal configuration files
```

---

### Live Deployment Status

The production version of this application is currently deployed via **Kamal 2** to a **DigitalOcean** droplet.

* **Public IP Address:** `http://panguterminal.ambalong.dev`
* **Deployment Tooling:** The infrastructure is fully managed by **Kamal 2**, with automated Docker image building, secure environment variable injection (`.kamal/secrets`), and container orchestration.

---

**Last Updated:** February 2026  
**Version:** 0.11.2
