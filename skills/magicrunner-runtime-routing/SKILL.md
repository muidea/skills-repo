---
name: magicrunner-runtime-routing
description: Use when reviewing or implementing magicRunner runtime-object routing, Runner.RegisterEntityRoute fallback behavior, or business-module overrides of standard REST paths. Covers route ownership between runner-generated CRUD proxies and module RegisterRoute handlers.
compatibility: Designed for agent clients working on magicRunner modules that expose runtime objects through panel, portal, gateway, or other application-layer services. Assumes local repository access and no network access.
metadata:
  author: rangh-codespace
  domain: magicrunner
  scenario: runtime-routing
  maturity: stable
---

# MagicRunner Runtime Routing

Use this skill when the task is about `magicRunner` runtime-object routes, especially when business modules and `Runner.RegisterEntityRoute(...)` may both affect the same REST path.

## Scope

- `Runner.RegisterEntityRoute(...)` fallback CRUD proxy behavior
- Business module `RegisterRoute()` ownership of standard REST paths
- Runtime-object route override checks
- Standard REST consistency for frontend and backend

## Core rules

- Treat `Runner.RegisterEntityRoute(entityView)` as the fallback registrar for runtime-object CRUD routes.
- Distinguish three layers clearly:
  - external contract: frontend and callers use standard REST paths such as `/services/` and `/services/:id`
  - module registration: business modules register runtime-object canonical verb routes such as `/filter/`, `/query/:id`, `/insert/`, `/update/:id`, `/delete/:id`
  - framework normalization: `magicBase/pkg/toolkit.NormalizeURI()` maps canonical verb routes to standard REST paths
- Business modules own override behavior. If business side effects are required on a standard CRUD path, register the corresponding canonical verb route in the module `RegisterRoute()` first.
- Frontend URLs should stay on standard REST contracts. Do not fork frontend URLs into verb-style business paths merely to trigger backend side effects.
- Do not register standard REST paths directly in `magicRunner` business modules when overriding runtime-object CRUD. Register the canonical verb route and let `NormalizeURI()` claim the standard REST path.
- When a business module explicitly claims the normalized CRUD path through its canonical verb route, `Runner.RegisterEntityRoute(...)` should skip fallback registration through `ExistRoute(...)`.
- Route override belongs to `magicRunner` application-layer framework logic, not to `magicEngine` itself.

## Review workflow

1. Identify the standard REST path that the frontend is expected to call.
2. Convert that path back to the canonical verb route using `NormalizeURI()` rules.
3. Check whether the business module `RegisterRoute()` already registers that canonical route and method.
4. Check whether `Runner.RegisterEntityRoute(...)` also targets the same normalized CRUD path as fallback.
5. Confirm the module route is registered early enough that runner fallback only fills missing paths.
6. If business side effects exist, keep the frontend on the standard REST URL and fix the backend route ownership instead of changing the frontend contract.
7. Add entrypoint or integration tests proving that the standard REST path reaches business logic rather than fallback proxy logic.

## Common bad patterns

- Changing frontend URLs to `/delete/:id` or other verb-style alternates because the standard REST path was not properly overridden
- Registering `/services/` or `/services/:id` directly in a `magicRunner` business module and assuming that is the canonical override path
- Treating runner fallback behavior as an engine limitation instead of checking module route ownership
- Registering business routes on non-standard paths while expecting standard CRUD URLs to trigger side effects
- Forgetting that cleanup cascades, file deletion, publication rollback, or capability release must happen in business handlers, not in blind fallback CRUD proxies

## Runtime Entity Override Rule

For runtime-object routes in `magicRunner`, the effective rule is:

1. Business modules register canonical verb routes first in their own `RegisterRoute()`.
2. `toolkit.NormalizeURI()` makes those verb routes occupy the corresponding standard REST paths.
3. `Runner.RegisterEntityRoute(entityView)` runs later and only fills in missing normalized CRUD routes.
4. Therefore standard REST override is an application-layer concern:
   - keep frontend URLs on standard REST paths
   - override by explicitly registering the canonical verb route in the business module
   - rely on runner fallback only for routes the business module did not claim

Example:

- canonical runtime route:
  - `/panel/hub/service/insert/`
- normalized external route:
  - `/panel/hub/services/`

If business side effects are needed for `POST /panel/hub/services/`, the module should register:
- `POST /panel/hub/service/insert/`

not:
- `POST /panel/hub/services/`

Use this rule when reviewing delete or update handlers that need business side effects such as cascading cleanup, file removal, publication-state restoration, or capability release.
