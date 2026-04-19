---
name: magicbase-routing-auth
description: Use when reviewing magicBase routing, request entry handling, auth boundaries, or endpoint-level request processing after routes and privileges are defined. Covers route ownership, auth checks, and the rule that entrypoint behavior must not distort magicOrm and magicBase service contracts; use magicbase-role-routing for route and privilege definition.
compatibility: Designed for agent clients working on repositories that expose HTTP services through magicBase routing and auth layers. Assumes local repository access and handler code; no network access is required.
metadata:
  author: rangh-codespace
  domain: magicbase
  scenario: routing-auth
  maturity: stable
  version: 1.0.1
---

# MagicBase Routing And Auth

Use this skill when the task is about HTTP routing, auth checks, request-to-service mapping, or handler-level consistency on `magicBase`.

Use `magicbase-role-routing` first when the task is to define a new route, choose ordinary vs CAS vs privilege route registration, define `Privilege` values, or debug role privilege matching. Return here when reviewing whether a handler preserves auth and service-contract boundaries.

## Scope

- Route definition and ownership
- Auth and request boundary checks
- Handler-level request translation
- Entry-to-service consistency

## Core rules

- Routing and auth should enforce access boundaries, not redefine data contracts.
- Handler code must not distort `magicOrm` or `magicBase` query semantics.
- Auth failures and contract failures should remain distinguishable.
- Request translation should stay thin and deterministic.

## Review workflow

1. Identify the route, auth gate, and downstream service call.
2. Verify the handler is not reshaping query semantics or masking framework errors.
3. Confirm auth checks happen at the correct boundary.
4. Fix shared handler or routing patterns before adding endpoint-specific exceptions.
5. Add handler or integration tests at the entrypoint layer.

## Common bad patterns

- Mixing auth decisions with response-shape logic
- Query handlers overriding ORM response semantics
- Endpoint-specific contract exceptions that bypass shared routing rules
- Returning the same error shape for auth, validation, and framework failures
