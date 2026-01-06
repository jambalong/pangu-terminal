# A Wuthering Waves Companion (Pangu Terminal)

### Project Overview

**Pangu Terminal** is a high-performance logistics and statistical engine designed to optimize resource management in *Wuthering Waves*. The project is designed as a suite of modular services aimed at solving complex player progression challenges and gacha probability.

#### Phase 1: Ascension Planner (MVP)
* **Goal:** Calculate total materials needed to reach character level goals.
* **Technical:** Implements **Recursive Active Record** associations to model multi-tier crafting costs (Basic → Advanced → Premium).

#### Phase 2: Inventory Hub & Wiki (The Data Nexus)
* **Goal:** Create a "Single Source of Truth" for user data and game knowledge.
* **Technical:** Implementing **Devise** for authentication and **Turbo Frames** for fast, inline inventory edits.

#### Phase 3: Astrite Analytics (Gacha Simulator)
* **Goal:** Advanced predictive modeling for gacha and resource spending.
* **Technical:** Using **Ruby Service Objects** for pity logic (Soft/Hard Pity) and **Solid Queue** for background processing.

---

### Technology Stack

| Component | Technology | Rationale |
| :--- | :--- | :--- |
| **Backend Core** | **Ruby on Rails 8.x** | Industry standard for rapid, scalable web development. |
| **Database** | **PostgreSQL 17** | Robust, production-ready, and ideal for complex data relationships. |
| **Frontend** | **Hotwire** | Optimized Rails-native stack (Turbo & Stimulus) for fast navigation and reactive frontend components. |
| **Deployment** | **Kamal 2** | Demonstrates modern, full-stack deployment via Docker on a DigitalOcean VPS. |

---

### Local Development Setup

To run this application locally:

#### Prerequisites

* Docker and Docker Compose installed.
* Ruby 3.4+ (recommended via a version manager like `rbenv` or `asdf`).

#### Quick Start

1. **Clone the repository:**

    ```bash
    git clone https://github.com/jambalong/pangu-terminal.git
    cd pangu-terminal
    ```

2. **Install Gems:**

    ```bash
    bundle install
    ```

3. **Start the Local Database:**
    The local database runs in a container defined by `docker-compose.yml`.

    ```bash
    docker-compose up -d
    ```

4. **Prepare the Database:**
    Create the databases and run the initial migrations.

    ```bash
    bin/rails db:prepare
    ```

5. **Run the Server:**

    ```bash
    bin/dev
    ```

The application will be available at `http://localhost:3000`.

---

### Live Deployment Status

The production version of this application is currently deployed via **Kamal 2** to a **DigitalOcean** droplet.

* **Public IP Address:** `http://panguterminal.ambalong.dev`
* **Deployment Tooling:** The infrastructure is fully managed by **Kamal 2**, demonstrating automated Docker image building, secure environment variable injection (`.kamal/secrets`), and container orchestration.
