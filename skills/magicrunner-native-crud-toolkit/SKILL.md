---
name: magicrunner-native-crud-toolkit
description: Use when reviewing or implementing standard CRUD handling for magicRunner native business models owned by panel or portal, or when deciding whether to reuse the thin magicBase/pkg/toolkit HTTP CRUD helpers instead of Runner fallback routes.
compatibility: Designed for agent clients working on magicRunner panel or portal native models. Assumes local repository access and no network access.
metadata:
  author: rangh-codespace
  domain: magicrunner
  scenario: native-crud-toolkit
  maturity: stable
---

# MagicRunner Native CRUD Toolkit

Use this skill when the task is about standard CRUD handling for `magicRunner` native business models such as application, service, publication, subscription, feedback, notification, catalog, or database models.

This skill is not for generic runtime-object fallback routing. Use `magicrunner-runtime-routing` when the core issue is route ownership or `Runner.RegisterEntityRoute(...)` behavior itself.

This skill assumes the thin CRUD helper rules from `magicbase-http-crud-toolkit`. Do not redefine the `magicBase/pkg/toolkit/http_crud.go` boundary here; only describe `magicRunner`-specific ownership and rollout rules.

## Scope

- Deciding whether a model is owned by `panel` or `portal` directly
- Deciding whether CRUD should stay in business module handlers or fall back to `Runner`
- Reusing `magicBase/pkg/toolkit/http_crud.go` for thin HTTP CRUD shells
- Avoiding over-generalization of business actions into toolkit helpers
- Verifying vendor alignment after toolkit changes

## Ownership boundary

- `panel` and `portal` native business models must be directly owned by their modules.
- Only CRUD derived from entity-defined application models should be left to `Runner.RegisterEntityRoute(...)` fallback.
- Native model CRUD must not drift back into half-owned routing where:
  - some methods are in the business module
  - the rest are implicitly handled by `Runner`

## Native model rule

Treat these as `panel` or `portal` owned business models unless there is strong contrary evidence:

- application definition
- application package
- application release
- service definition
- capability definition
- service capability binding
- service publication
- service subscription
- catalog
- database schema
- database instance
- feedback ticket
- feedback message
- notification

The module should register the normalized standard CRUD path through canonical verb routes in its own `RegisterRoute()`.

## Toolkit usage in magicRunner

When `magicRunner` reuses `magicBase/pkg/toolkit/http_crud.go`, keep the project-specific split clear:

- `magicBase` owns the thin CRUD helper contract
- `magicRunner` owns:
  - model ownership
  - route ownership
  - vendor alignment
  - which native models should or should not adopt the toolkit

## Recommended rollout order

When introducing the toolkit, replace low-risk native models first:

- catalog
- notification
- application definition
- database schema
- database instance

Then expand to models that still need custom hooks but only in view-building or request pre-processing:

- feedback ticket
- feedback message
- capability definition
- service capability binding

Keep explicit handlers for heavy business objects unless there is a clear win and no semantic risk:

- application package
- application release
- service definition
- service publication
- service subscription

## Review workflow

1. Decide whether the target object is a native `panel` or `portal` model, or a derived runtime object.
2. If it is native, confirm the module owns the whole CRUD surface instead of relying on `Runner` fallback.
3. Inspect the service handler and separate:
   - thin HTTP shell logic
   - business logic
4. Move only the thin shell into `magicBase/pkg/toolkit/http_crud.go`.
5. Keep business hooks in the module:
   - current entity injection
   - namespace derivation
   - external view enrichment
   - cascade cleanup
6. Re-run module-level tests after each batch instead of doing a broad mechanical replacement.
7. If `magicRunner` builds in vendor mode, verify the vendor copy of toolkit is aligned with source.

## Common bad patterns

- Letting native `panel` or `portal` models partially depend on `Runner` fallback CRUD
- Moving publish, approve, cleanup, or install semantics into generic toolkit helpers
- Replacing all service handlers at once instead of batching low-risk objects first
- Ignoring vendor mode after editing `magicBase/pkg/toolkit`
- Treating a custom view-enrichment hook as a reason to abandon toolkit entirely

## Validation checklist

- `panel` or `portal` native model CRUD still resolves through the owning module
- Standard REST contract remains unchanged
- Business actions and side effects remain outside toolkit
- Module tests still pass for:
  - `internal/modules/kernel/panel/service`
  - `internal/modules/kernel/panel/biz`
  - `internal/modules/kernel/runner/service`
- If toolkit changed, verify:
  - `magicBase/pkg/toolkit/http_crud.go`
  - `magicRunner/vendor/github.com/muidea/magicBase/pkg/toolkit/http_crud.go`
  are aligned when vendor mode is used
