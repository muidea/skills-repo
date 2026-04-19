---
name: magicbase-http-crud-toolkit
description: Use when implementing or reviewing thin HTTP CRUD shells on top of magicBase/pkg/toolkit/http_crud.go, including standard request decode, REST id handling, model-to-view conversion, and deciding when generic CRUD helpers are appropriate.
compatibility: Designed for agent clients working on services built on magicBase that want to reuse generic HTTP CRUD shell helpers without moving business semantics into the toolkit layer.
metadata:
  author: rangh-codespace
  domain: magicbase
  scenario: http-crud-toolkit
  maturity: stable
---

# MagicBase HTTP CRUD Toolkit

Use this skill when the task is about `magicBase/pkg/toolkit/http_crud.go` or when deciding whether a service handler should reuse the thin CRUD helper instead of repeating standard HTTP shell code.

## Scope

- `filter` decode
- REST `id` decode
- JSON body decode
- model-to-view conversion
- standard CRUD shell assembly
- deciding whether a handler is thin enough to reuse the toolkit

## Core boundary

`magicBase/pkg/toolkit/http_crud.go` is a thin HTTP helper layer only.

It may handle:

- content filter decode
- standard REST id extraction
- JSON body decode
- generic `model -> view` conversion
- generic CRUD shell assembly
- context-aware view build hooks

It must not absorb business semantics such as:

- publish
- approve
- install or uninstall
- file cleanup
- cascade delete
- role policy
- namespace policy
- current entity injection
- external relation enrichment beyond an explicit build hook

If a handler needs business semantics, keep those semantics in the owning module and only reuse the thin shell where safe.

## Supported helper shapes

The toolkit is expected to support two kinds of view assembly:

1. direct view conversion
- plain `Model -> View`

2. context-aware view building
- `context + Model -> (View, Error)`
- use this when the view needs current namespace, auth entity, or controlled enrichment

The context-aware hook is still part of the shell boundary only if the business rule remains in the caller.

## Recommended adoption order

Adopt the toolkit in batches.

Best first targets:

- low-risk CRUD handlers
- standard list/query/create/update/delete shells
- models with plain `ToView()` conversion

Next targets:

- handlers that still need custom view building
- handlers that inject request-derived values before create

Avoid broad mechanical replacement.

## Review workflow

1. Identify the current handler responsibilities.
2. Split them into:
   - HTTP shell work
   - business semantics
3. Move only the shell work into toolkit helpers.
4. Keep business hooks in the owning service module.
5. Re-run module-level tests after each batch.

## Common bad patterns

- moving publish or approve actions into toolkit
- putting cleanup or cascade behavior into toolkit
- assuming any custom behavior blocks toolkit reuse
- replacing a whole module at once without batching

## Validation checklist

- standard REST contract stays unchanged
- business semantics remain in the owning module
- only repeated shell logic moves into toolkit
- tests still pass after each adoption batch
