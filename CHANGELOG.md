# Changelog

Changes to this project will be documented in this file.
This project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html)

## [0.11.2] - 2026-02-08

**Time:** 5 minutes

### Removed
- Removed unused separate_materials_by_type method

## [0.11.1] - 2026-02-08

**Time:** 20-30 minutes

### Fixed
- Fixed plan filter using stale data on inventory updates
- Ensured synthesis calculations refresh correctly when switching between filtered plans

## [0.11.0] - 2026-02-08

**Time:** 2-3 hours

### Added
- Implemented plan filtering system for inventory page
- Added plan dropdown selector to filter inventory by specific plan requirements
- Added validation logic in index action to ensure selected plan belongs to user
- Implemented `apply_plan_filter` method to keep only plan-required items and relevant EXP potions
- Added filter persistence across edit operations (plan_id param passed through URLs)
- Updated synthesis calculation to use single plan's requirements or aggregated all-plans data

## [0.10.1] - 2026-02-08

**Time:** 15-20 minutes

### Changed
- Refactored badge icons for better visual distinction between synthesis types
- Improved clarity between higher-rarity satisfaction and lower-tier crafting indicators

## [0.10.0] - 2026-02-08

**Time:** 4 hours

### Added
- Implemented EXP Potion cross-rarity satisfaction system
- Extended `SynthesisService.reconcile_inventory` to return enhanced reconciliation data:
  - `satisfied_qty`: accounts for cross-rarity EXP potion satisfaction
  - `used_higher_rarity`: boolean flag indicating when higher rarities filled the gap
  - `synthesis_opportunity`: shows craftable surplus from lower tiers
- Added visual indicators for material satisfaction:
  - Anvil badge displays count of EXP from higher rarities (`satisfied_qty - owned`)
  - Craft badge shows count convertible from lower-tier surplus (`can_convert`)
  - Pulsing teal border for materials that can be synthesized from lower tiers
  - Pulsing sapphire border for materials satisfied by higher-rarity equivalents
- Updated progress bars to display true satisfaction (`satisfied_qty / needed`) rather than just owned count

## [0.9.0] - 2026-02-02

**Time:** 1-2 hours

### Added
- Merged PR #31: Synthesis Engine & Inventory Management Overhaul
  - Integrated SynthesisService for 3-to-1 material conversion logic
  - Added item_group_id to Materials and implemented recursive tier checking
  - Migrated inventory quantity updates to Turbo-powered modals
  - Refactored inventory views with type-based partitioning and plan relevance
  - Added Synthesis pulse glow indicator and format_quantity helper
  - Implemented model-level validations for InventoryItem, Material, and Plan
  - Resolved flash notice persistence bug and cleaned up test fixtures
  - Added unit tests for synthesis logic and model integrity

### Changed
- Refactored validate_inputs! method to use concise error messages with assistance of AI

## [0.8.9] - 2026-02-02

**Time:** 30-45 minutes

### Changed
- Refactored tests to use generic names and variables for better maintainability

## [0.8.8] - 2026-02-02

**Time:** 5-10 minutes

### Changed
- Adjusted modal-header margin-bottom for improved spacing

## [0.8.7] - 2026-02-02

**Time:** 30-45 minutes

### Added
- Added InventoryItem validation tests

## [0.8.6] - 2026-02-02

**Time:** 5 minutes

### Changed
- Kept folder structure for test organization

## [0.8.5] - 2026-02-02

**Time:** 5 minutes

### Removed
- Removed default controllers test created by Rails generator

## [0.8.4] - 2026-02-02

**Time:** 45 minutes - 1 hour

### Added
- Added model-level validations to InventoryItem, Material, and Plan models

## [0.8.3] - 2026-02-02

**Time:** 5-10 minutes

### Changed
- Added margin-bottom to item-header for better visual spacing

## [0.8.2] - 2026-02-02

**Time:** 30-45 minutes

### Changed
- Refactored inventory view to use separate_materials_by_type method for cleaner code organization

## [0.8.1] - 2026-02-02

**Time:** 20-30 minutes

### Changed
- Updated dimmed styling for materials not required by plans (progress bar and quantity display)

## [0.8.0] - 2026-02-02

**Time:** 2-3 hours

### Added
- Implemented Turbo-powered modal for editing inventory item quantities
- Added real-time synthesis family item updates when quantities change
- Enabled seamless inventory management through modal interface

## [0.7.8] - 2026-02-02

**Time:** 45 minutes - 1 hour

### Added
- Partitioned inventory items into respective sections for improved organization

## [0.7.7] - 2026-02-02

**Time:** 5 minutes

### Removed
- Removed debug print statement from codebase

## [0.7.6] - 2026-02-02

**Time:** 30-45 minutes

### Changed
- Updated synthesis indicator to use subtle pulse glow animation

## [0.7.5] - 2026-02-02

**Time:** 5-10 minutes

### Changed
- Reordered Mysterious Code material for better organization

## [0.7.4] - 2026-02-02

**Time:** 15-20 minutes

### Changed
- Updated quantity displays to use format_quantity() helper method

## [0.7.3] - 2026-02-02

**Time:** 30-45 minutes

### Added
- Added format_quantity() helper that formats numbers to game-speak notation (1k, 24.7k, 1.5M)

## [0.7.2] - 2026-02-02

**Time:** 5-10 minutes

### Changed
- Adjusted position of synthesis indicator icon for better visual alignment

## [0.7.1] - 2026-02-01

**Time:** 20-30 minutes

### Changed
- Updated planner title font color
- Changed View All button width, dashboard title font size and color for improved aesthetics

## [0.7.0] - 2026-02-01

**Time:** 3-4 hours

### Added
- Integrated SynthesisService into Inventory controller
- Added progress indicators and styled progress info for inventory item cards
- Implemented synthesis opportunity detection and visualization

### Fixed
- Fixed bug where material_id was returning as integer string instead of integer

## [0.6.3] - 2026-02-01

**Time:** 1-2 hours

### Added
- Unit tested SynthesisService before integration
- Verified core synthesis logic passes all test cases

## [0.6.2] - 2026-02-01

**Time:** 10 minutes

### Changed
- Disabled fixtures for minitest to improve test isolation

## [0.6.1] - 2026-02-01

**Time:** 5-10 minutes

### Removed
- Deleted outdated test fixtures

## [0.6.0] - 2026-01-26

**Time:** 5-7 hours

### Added
- Implemented SynthesisService to handle 3-to-1 material conversion logic
- Created synthesis reconciliation system for inventory management
- Used AI as a rubberduck to design the data structure for output

## [0.5.0] - 2026-01-26

**Time:** 45 minutes - 1 hour

### Added
- Added item_group_id column to materials table to enable synthesis chain tracking
- Implemented database migration for 3-to-1 material synthesis support

## [0.4.4] - 2026-01-25

**Time:** 45 minutes - 1 hour

### Added
- Improved sorting functionality for inventory and plan views

### Fixed
- Fixed bugs that were causing incorrect sorting behavior

## [0.4.3] - 2026-01-25

**Time:** 30-45 minutes

### Fixed
- Resolved flash notice persistence bug where notices were persisting across page reloads

## [0.4.2] - 2026-01-23

**Time:** 20-30 minutes

### Changed
- Updated CSS styles for improved visual consistency

## [0.4.1] - 2026-01-22

**Time:** 15-20 minutes

### Changed
- Updated font styles in certain content areas for better readability

## [0.4.0] - 2026-01-19

**Time:** 1-2 hours

### Added
- Implemented favicon system with force refresh capability
- Added Apple device-specific favicons for improved mobile experience

## [0.3.6] - 2026-01-11

**Time:** 20-30 minutes

### Added
- Added changelog documentation for v0.1.0 baseline release

## [0.3.5] - 2026-01-11

**Time:** 30-45 minutes

### Changed
- Updated CSS for confirm_delete view and plan_card components

## [0.3.4] - 2026-01-11

**Time:** 20-30 minutes

### Fixed
- Fixed subject access pattern in plan views (changed from subject_name/subject_id to direct subject access)

## [0.3.3] - 2026-01-11

**Time:** 15-20 minutes

### Added
- Added helper method to titleize Forte Node names for better display formatting

## [0.3.2] - 2026-01-11

**Time:** 10 minutes

### Changed
- Refactored planner.call return statement to remove unnecessary transformation logic

## [0.3.1] - 2026-01-11

**Time:** 20-25 minutes

### Changed
- Refactored Forte Nodes Map to use standardized keys for consistency

## [0.3.0] - 2026-01-11

**Time:** 3-4 hours

### Added
- Implemented PlanForm service integration across 7 files
- Added edit and update operations for plans
- Cleaned up local variables and improved code organization

## [0.2.0] - 2026-01-11

**Time:** 2-3 hours

### Added
- Added subject_id column to Plan model for simpler and more efficient queries
- Implemented polymorphic association between Plan and Resonator/Weapon models
- Added duplicate plan detection scope and validation

### Fixed
- Fixed PG::DuplicateColumn error by manually adding subject_type and updating indexes

## [0.1.1] - 2026-01-11

**Time:** 1 hour

### Added
- Created PlanForm service to handle translation between form parameters and planner calculator arguments
- Used AI to scaffold form object as a reference

## [0.1.0] - 2026-01-12

### Added
- Added "sync" feature to migrate existing guest data to permanent User account upon registration/sign-up
- Integrated Devise with custom hybrid ownership system
- Added guest_token logic to allow unauthenticated users to create and manage plans
- Utilized Turbo Frames and Turbo Streams for modal management, plan deletion, dynamic sync banner updates, and single page application feel for planner
- Built ResonatorAscensionPlanner and WeaponAscensionPlanner services to calculate material costs based on levels, ascension ranks, and specific Forte Node upgrades
- Configured Kamal 2 deployment for Rails 8 stack with PostgreSQL on DigitalOcean

### Changed
- Rebranded the project to **Pangu Terminal** and updated all internal modules, classes, and namespaces to reflect the new identity
