---
name: magicrunner-runtime-routing
description: Use when reviewing, implementing, or fixing magicRunner runtime-object routing, business-module CRUD route ownership, apps or panel or portal module RegisterRoute definitions, Runner.RegisterEntityRoute fallback behavior, 404 route mismatches, or URL constants that may violate magicRunner framework conventions. Covers route contract design, NormalizeURI effects, canonical CRUD routes, frontend REST paths, and quick diagnosis or repair of route deviations.
compatibility: Designed for agent clients working on magicRunner modules that expose runtime objects through panel, portal, gateway, or other application-layer services. Assumes local repository access and no network access.
metadata:
  author: rangh-codespace
  domain: magicrunner
  scenario: runtime-routing
  maturity: stable
version: 1.0.1
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
- If a module exposes dynamic entity CRUD, treat it as framework-owned CRUD even if the URL looks like a custom app entry. Do not invent multi-segment dynamic CRUD paths such as `/:app/entities/:entity/:id`.
- Runtime selector parameters that are not entity fields, such as application key or entity name, should be explicit query parameters or path IDs owned by the module contract. Remove them before decoding `bc.ContentFilter` so they do not become magicOrm business filters.

## New route contract checklist

Before adding or changing a `magicRunner` module route, write down this contract and keep code, tests, frontend and docs aligned:

- Resource owner: which module owns the behavior, for example `panel`, `portal`, `gateway`, `apps`, or runner fallback.
- Operation type: standard CRUD, custom read action, custom write action, gateway proxy, or static/runtime entry.
- Registration route: the exact constant passed to `AddHandler`, `AddCasHandler`, or `AddPrivilegeHandler`.
- Normalized REST route: the result after `toolkit.NormalizeURI()` plus `bc.ApiVersion`.
- Auth route type: plain, CAS, or role privilege route.
- Caller route: the path used by frontend, metadata, tests, curl, and external callers.
- Selector params: path ID, query params, headers, namespace, application, entity, and which of them must not enter business filters.
- Fallback interaction: whether `Runner.RegisterEntityRoute(...)` may also register the same normalized path.

For standard CRUD, the registration route must be canonical action form:

```text
/<module>/<resource>/filter/
/<module>/<resource>/query/:id
/<module>/<resource>/insert/
/<module>/<resource>/update/:id
/<module>/<resource>/delete/:id
```

The caller route must be the normalized REST path:

```text
/api/v1/<module>/<resource>s/
/api/v1/<module>/<resource>s/:id
```

For custom non-CRUD APIs, define the final REST path directly and avoid path segments named `filter`, `query`, `insert`, `update`, or `delete` unless normalization is intentionally required.

## URL definition rules for dynamic app/entity routes

- Do not encode both application and entity as dynamic path hierarchy for CRUD, for example `/apps/:key/entities/:entity/:id`. This bypasses the standard module CRUD contract and usually leads to custom parsing.
- Prefer one stable framework resource such as `/apps/entity/value/filter/`, normalized to `/api/v1/apps/entity/values/`, and pass `application` and `entity` as explicit selector query parameters.
- Keep only the entity value primary key in the normalized REST detail path, for example `/api/v1/apps/entity/values/:id?application=demo&entity=user`.
- Metadata generators must emit the same normalized caller paths that route dispatch tests exercise.
- Frontend should consume paths from metadata where possible; if it must define an API helper, it must use the normalized caller route, not the canonical registration route.

## Review workflow

1. Identify the standard REST path that the frontend is expected to call.
2. Convert that path back to the canonical verb route using `NormalizeURI()` rules.
3. Check whether the business module `RegisterRoute()` already registers that canonical route and method.
4. Check whether `Runner.RegisterEntityRoute(...)` also targets the same normalized CRUD path as fallback.
5. Confirm the module route is registered early enough that runner fallback only fills missing paths.
6. If business side effects exist, keep the frontend on the standard REST URL and fix the backend route ownership instead of changing the frontend contract.
7. Add entrypoint or integration tests proving that the standard REST path reaches business logic rather than fallback proxy logic.

## Quick diagnosis workflow

Use this sequence for 404, wrong handler, or route-design deviations:

1. Capture the real request: full path including `/api/v1`, method, query string, and auth route type.
2. Find the module constants with `rg -n "AddCasHandler|AddPrivilegeHandler|<resource>|filter/|query/:id" internal/modules`.
3. Compute the normalized pattern from the constant using `toolkit.NormalizeURI()` rules.
4. Compare four paths: frontend request, metadata emitted path, route constant, normalized registered path.
5. If a constant contains multiple dynamic params for CRUD, redesign it as a canonical CRUD route plus explicit selector params.
6. Check startup logs or route dispatch tests to confirm the actual registered route and method.
7. If the route reaches runner fallback instead of business logic, register the canonical business route earlier and ensure fallback skips existing normalized routes.
8. If `ContentFilter.Decode(req)` is used, confirm routing selector params are removed before decode unless they are intentional entity fields.

## Repair workflow

When a route violates the framework contract:

1. Replace non-standard CRUD constants with canonical action constants.
2. Update `RegisterRoute()` to register one handler per action and method.
3. Replace custom path parsing with framework helpers such as `SplitRESTID` or `ExtractID` plus explicit query/header selector decoding.
4. Keep frontend and generated metadata on normalized REST paths.
5. Add or update direct handler tests for argument decoding and route dispatch tests for `/api/v1/...` normalized paths.
6. Update the design or validation document with both registration constants and final caller paths.
7. Run focused module tests and any affected frontend type/API tests.

## Common bad patterns

- Changing frontend URLs to `/delete/:id` or other verb-style alternates because the standard REST path was not properly overridden
- Registering `/services/` or `/services/:id` directly in a `magicRunner` business module and assuming that is the canonical override path
- Treating runner fallback behavior as an engine limitation instead of checking module route ownership
- Registering business routes on non-standard paths while expecting standard CRUD URLs to trigger side effects
- Forgetting that cleanup cascades, file deletion, publication rollback, or capability release must happen in business handlers, not in blind fallback CRUD proxies
- Adding custom parsers for CRUD path segments before checking whether the route should be a canonical action route.
- Letting routing selector params, such as `application` or `entity`, leak into `ContentFilter` and become magicOrm field filters.
- Updating docs or frontend paths without a route dispatch test that proves the final `/api/v1/...` path is registered.

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
