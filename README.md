# A Resource Optimization Platform for Wuthering Waves

## A Resource Planner for Wuthering Waves

**Pangu Terminal** helps *Wuthering Waves* players plan and track the materials needed to max out their Resonators and weapons. Input your current levels and target upgrades, track what you own, and the app automatically shows you what to farm next—accounting for synthesis chains so you don't waste time grinding materials you can craft.

**Status:** MVP complete with planning, inventory tracking, and synthesis detection. Live at [panguterminal.ambalong.dev](http://panguterminal.ambalong.dev)

## What This Project Showcases

### Full-Stack Rails Architecture
- Polymorphic associations for heterogeneous plan types (character vs. weapon upgrades)
- Service objects extracting complex business logic (ResonatorAscensionPlanner, SynthesisService)
- JSONB caching for flexible plan data storage and query optimization
- Guest authentication system via secure tokens (no Devise required for trials)
- Turbo Streams for real-time inventory updates without full-page reloads

### Production-Ready Deployment
- Kamal 2 containerized deployment to DigitalOcean
- PostgreSQL JSONB for flexible data modeling
- Docker-compose local development environment
- Automated database migrations and seeding

---

## Feature Overview

### 1. Ascension Planner
Players manually calculate material costs across multiple upgrade paths (levels, ascension ranks, skills, Forte Nodes).

Implemented a Service-based planner that:
- Validates upgrade ranges against game mechanics (e.g., can't reach level 50 at ascension rank 0)
- Queries cost tables for the delta range (current → target)
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
  └── guest_token (for unauthenticated users)

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

### 2. Inventory Management & Synthesis
Players own materials across 5 rarity tiers. Lower tiers can be synthesized (3:1) into higher tiers, but players can't easily see if they have "enough" when accounting for conversions.

It features a Synthesis Service that:
- Reconciles owned inventory against plan requirements
- Detects **EXP potion equivalence** (e.g., 20 Basic potions = 2 Premium potions via exp_value)
- Identifies **synthesis opportunities** (e.g., "You have 18 surplus Cadence Seed -> can craft 6 Cadence Bud")
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
  source_material_id: 22,
  source_name: "Cadence Seed",
  surplus_available: 18,
  can_convert: 6  # (18 / 3).floor
}
```

This solves the core "resource paradox" where players have data but can't act on it without manual spreadsheet recalculation.

---

### 3. Multi-Plan Aggregation & Filtering
Users create multiple plans (Jinhsi + Jiyan + Yinlin), and need to see material requirements both aggregated (total across all plans) and filtered (single plan focus).

It allows aggregation logic + plan filtering with two views:

- **Planner Dashboard:** Shows total materials needed across all active plans
- **Inventory Page:** Filtered view (single plan) or aggregated view (all plans), with plan dropdown selector

**Technical Highlights:**
```ruby
# Aggregation method
def self.fetch_materials_summary(plans)
  totals = {}
  plans.each do |plan|
    materials = plan.plan_data.dig("output") || {}
    materials.each do |material_id, quantity|
      totals[material_id.to_i] ||= 0
      totals[material_id.to_i] += quantity
    end
  end
  totals
end

# Plan filtering in controller
@requirements = params[:plan_id].present? 
  ? Plan.find(params[:plan_id]).plan_data["output"]
  : Plan.fetch_materials_summary(user_plans)
```

Flexibility for both "big picture" planning and focused farming sessions.

---

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

**Trade-off:** Harder to query individual plan attributes, but plans are write-once-read-many, so caching is ideal. Avoids normalization overhead.

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

**Why?** Characters and weapons have different upgrade paths, but share identical plan CRUD operations.

### Guest User System
Unauthenticated users can try the planner via secure UUID tokens stored in cookies:
```ruby
def set_guest_token
  if cookies.permanent[:guest_token].blank?
    cookies.permanent[:guest_token] = SecureRandom.uuid
  end
end

# Plan validation
validate :must_have_owner
def must_have_owner
  if user_id.blank? && guest_token.blank?
    errors.add(:base, "Plan must belong to user or guest")
  end
end
```

It lowers friction for guest users; future migration path to registered accounts.

### Turbo Streams for Real-Time Updates
Inventory edits trigger Turbo Stream responses that update the edited item plus all related items in the synthesis family, reflecting the recalculated synthesis opportunities instantly:

**Controller:**
```ruby
def update
  if @inventory_item.update(inventory_item_params)
    load_inventory_and_plans
    @selected_plan = @plans.find_by(id: params[:plan_id]) if params[:plan_id].present?
    compute_synthesis_data
    @related_items = current_user.inventory_items.joins(:material)
      .where(materials: { item_group_id: @inventory_item.material.item_group_id })
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to inventory_items_path }
    end
  else
    render :edit, status: :unprocessable_entity
  end
end
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

This updates the edited item immediately, then recomputes synthesis for the entire family (e.g., all Cadence materials) so synthesis opportunities reflect the new inventory state. All without a page reload—fast, Rails-native reactivity.

---

## Technology Stack

| Component | Technology |
| --- | --- |
| Backend | Rails 8.1 + Ruby 3.4 |
| Database | PostgreSQL 17 |
| Frontend | Hotwire (Turbo + Stimulus) |
| Deployment | Docker + Kamal 2 |
| Testing | Minitest |

---

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
│   ├── plans_controller.rb
│   ├── inventory_controller.rb
│   └── ...
├── services/
│   ├── resonator_ascension_planner.rb  # Char cost calculation
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
└── services/

docker-compose.yml
Kamal configuration files
```

---

### Live Deployment Status

The production version of this application is currently deployed via **Kamal 2** to a **DigitalOcean** droplet.

* **Public IP Address:** `http://panguterminal.ambalong.dev`
* **Deployment Tooling:** The infrastructure is fully managed by **Kamal 2**, demonstrating automated Docker image building, secure environment variable injection (`.kamal/secrets`), and container orchestration.

---

**Last Updated:** February 2026  
**Version:** 0.11.2
