# REST API

Source of truth: `config/routes.rb` (`namespace :api / :v1`) and `app/controllers/api/v1/*`. Serializers live in `app/serializers/`.
Base URL (production): `https://panguterminal.ambalong.dev`. All paths below are prefixed with `/api/v1`.


Pangu Terminal exposes a versioned REST API for developer access to plans and inventory data.

## Authentication

All endpoints require a bearer token in the Authorization header.

```
Authorization: Bearer <your_api_token>
```

Tokens are issued per user via API keys tied to a user account. Each user can hold up to 3 active keys. Keys can be revoked at any time.

## Rate Limiting

Requests are rate limited to 60 requests per minute per API key. Exceeding this returns:

**Response 429 Too Many Requests**
```json
{ "error": "Rate limit exceeded. Try again later." }
```

## Endpoints

### GET /api/v1/plans

Returns all plans belonging to the authenticated user.

```bash
curl https://panguterminal.ambalong.dev/api/v1/plans \
  -H "Authorization: Bearer <token>"
```

**Response 200 OK**
```json
[
  {
    "id": 28,
    "subject_name": "Aemeath",
    "subject_type": "Resonator",
    "configuration": {
      "current_level": 1,
      "target_level": 90,
      "current_ascension_rank": 0,
      "target_ascension_rank": 6,
      "current_skill_levels": { "basic_attack": 1, "...": "..." },
      "target_skill_levels": { "basic_attack": 10, "...": "..." },
      "forte_node_upgrades": {
        "basic_attack": { "stat_bonus_tier_1": true, "stat_bonus_tier_2": true },
        "...": "..."
      }
    },
    "requirements": {
      "shell_credit": 3053282,
      "basic_resonance_potion": 2438,
      "...": "..."
    },
    "created_at": "2026-03-07T07:54:16.368Z",
    "updated_at": "2026-03-07T07:54:24.368Z"
  },
  "..."
]
```

---

### POST /api/v1/plans

Creates a new plan for the authenticated user.
```bash
curl -X POST https://panguterminal.ambalong.dev/api/v1/plans \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "subject_type": "Weapon",
    "subject_name": "Kumokiri",
    "current_level": 1,
    "target_level": 90,
    "current_ascension_rank": 0,
    "target_ascension_rank": 6
  }'
```

**Response 201 Created**
```json
{
  "id": 29,
  "subject_name": "Kumokiri",
  "subject_type": "Weapon",
  "configuration": {
    "current_level": 1,
    "target_level": 90,
    "current_ascension_rank": 0,
    "target_ascension_rank": 6
  },
  "requirements": {
    "shell_credit": 1406960,
    "basic_energy_core": 2692,
    "lf_whisperin_core": 6,
    "...": "..."
  },
  "created_at": "2026-03-07T08:31:21.402Z",
  "updated_at": "2026-03-07T08:31:21.402Z"
}
```

---

### GET /api/v1/inventory

Returns the authenticated user's full inventory as a flat hash of material keys to quantities. Materials with no recorded quantity return `0`.
```bash
curl https://panguterminal.ambalong.dev/api/v1/inventory \
  -H "Authorization: Bearer <token>"
```

**Response 200 OK**
```json
{
  "shell_credit": 120000,
  "basic_resonance_potion": 47,
  "cadence_seed": 0,
  "cadence_bud": 12,
  "...": "..."
}
```

---

### GET /api/v1/plans/:id/reconciliation

Returns each material's reconciliation for a specific plan. What you need, what you own, and what you can cover through synthesis.
```bash
curl https://panguterminal.ambalong.dev/api/v1/plans/1/reconciliation \
  -H "Authorization: Bearer <token>"
```

**Response 200 OK**
```json
{
  "shell_credit": {
    "needed": 25480,
    "owned": 30000,
    "satisfied": 30000,
    "deficit": 0,
    "fulfilled": true,
    "higher_rarity_contributed": false,
    "can_synthesize": 0
  },
  "basic_energy_core": {
    "needed": 38,
    "owned": 0,
    "satisfied": 39,
    "deficit": 0,
    "fulfilled": true,
    "higher_rarity_contributed": true,
    "can_synthesize": 0
  },
  "lf_whisperin_core": {
    "needed": 6,
    "owned": 2,
    "satisfied": 2,
    "deficit": 4,
    "fulfilled": false,
    "higher_rarity_contributed": false,
    "can_synthesize": 3
  },
  "...": "..."
}
```

| Field | Description |
| --- | --- |
| `needed` | Total quantity required by the plan |
| `owned` | Current inventory quantity |
| `satisfied` | Effective quantity after EXP cross-rarity equivalence is applied |
| `deficit` | Remaining shortfall after satisfaction is accounted for |
| `fulfilled` | `true` if the requirement is fully covered |
| `higher_rarity_contributed` | `true` if a higher rarity EXP equivalent contributed toward this requirement |
| `can_synthesize` | Additional units craftable from surplus lower-tier materials via 3:1 synthesis |

---

### GET /api/v1/materials

Returns all materials with their farming source info. Materials with no waveplate source (e.g. ascension materials) return `"sources": []`
```bash
curl https://panguterminal.ambalong.dev/api/v1/materials \
  -H "Authorization: Bearer <token>"
```

**Response 200 OK**
```json
[
  {
    "material_key": "shell_credit",
    "display_name": "Shell Credit",
    "rarity": 3,
    "material_type": "credit",
    "sources": [
      {
        "name": "Simulation Training",
        "source_type": "simulation_challenge",
        "waveplate_cost": 40,
        "location": "Jinzhou, Huanglong",
        "region": "Huanglong"
      },
      "..."
    ]
  },
  "..."
]
```

---
### PATCH /api/v1/profile
Sets the authenticated user's SOL3 phase. Required before using the `waveplate-summary` endpoint.

```bash
curl -X PATCH https://panguterminal.ambalong.dev/api/v1/profile \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{ "sol3_phase": 3 }'
```

**Response 200 OK**
```json
{ "sol3_phase": 3 }
```

---

### GET /api/v1/plans/:id/waveplate-summary

Returns materials with an active deficit that have at least one farmable waveplate source. Requires SOL3 phase to be set via `PATCH /api/v1/profile`.

```bash
curl https://panguterminal.ambalong.dev/api/v1/plans/1/waveplate-summary \
  -H "Authorization: Bearer <token>"
```

**Response 200 OK**
```json
{
  "shell_credit": {
    "deficit": 25480,
    "source_type": "simulation_challenge",
    "sources": ["B.1.N.G.O.", "Gladiator's Portrait", "Simulation Training"],
    "estimated_runs": 1,
    "waveplate_cost": 40
  }
}
```

---

## Error Responses

| Status | Meaning | Response |
| --- | --- | --- |
| 400 | Malformed request | `{ "error": "<param message>" }` |
| 401 | Missing, invalid, or revoked token | `{ "error": "Unauthorized" }` |
| 404 | Record not found | `{ "error": "Record not found" }` |
| 422 | Unprocessable entity | `{ "error": "<validation error message>" }` |
| 429 | Rate limit exceeded | `{ "error": "Rate limit exceeded. Try again later." }` |
| 500 | Internal server error | `{ "error": "Internal Server Error" }` |

## Notes

- All material keys are `snake_case` names resolved from internal material IDs.
- `subject_id` and `user_id` are intentionally omitted (internal implementation details).
- `guest_token` is intentionally omitted (sensitive internal field).
- Forte node upgrade values are booleans representing on/off toggles, not quantities.

## Implementation map

| Endpoint | Controller#action | Notes |
| --- | --- | --- |
| `GET /plans` | `Api::V1::PlansController#index` | `PlanSerializer` |
| `POST /plans` | `Api::V1::PlansController#create` | Builds a `PlanForm`; subject looked up by `subject_name`; planner `ValidationError`s become 422 (`errors` array, split on `\|`) |
| `GET /plans/:id/reconciliation` | `#reconciliation` | `SynthesisService#reconcile` via `ReconciliationSerializer` |
| `GET /plans/:id/waveplate-summary` | `#waveplate_summary` | `WaveplateSummaryService`; 422 if user has no `sol3_phase` |
| `GET /inventory` | `Api::V1::InventoryController#index` | |
| `GET /materials` | `Api::V1::MaterialsController#index` | `MaterialSerializer` |
| `PATCH /profile` | `Api::V1::ProfileController#update` | `sol3_phase` must be 1..8, else 422 |
| anything else under `/api/v1/*` | `BaseController#handle_not_found` | 404 JSON, no auth required |

## Auth and rate limiting internals

- Tokens: `pt_` + urlsafe base64; only the SHA-256 digest is stored in `api_keys.token`. Raw token is shown once at creation. Max 3 keys per user (`ApiKey#api_key_limit`). `last_used_at` is touched on each authenticated request.
- Keys are created and revoked in the web UI via `ApiKeysController` (`POST/DELETE /app/api_keys`), not through the API.
- Throttle: `config/initializers/rack_attack.rb` (`api/token`, 60/min keyed by the Authorization header value). See [ARCHITECTURE.md](ARCHITECTURE.md#rackattack-rate-limiting).

## Known doc/code caveats

- Responses for `POST /plans` accept the same parameters as the web `PlanForm` (see `plan_params` in `Api::V1::PlansController`).
- If you change a response shape, update this file, the `test/controllers/api/` tests, and the README summary.
