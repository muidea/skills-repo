---
name: magicorm-regression-testing
description: Use when validating that business services still follow magicOrm and magicBase contracts. Covers definition-alignment checks, module tests, framework regressions, and how to distinguish test expectation bugs from framework bugs.
compatibility: Designed for agent clients validating repositories that use magicOrm definitions and magicBase service plumbing. Assumes local repository access and project test tooling; no network access is required.
metadata:
  author: rangh-codespace
  domain: magicorm
  scenario: regression-testing
  maturity: stable
---

# MagicOrm Regression Testing

Use this skill when the task is to confirm that framework behavior, service behavior, and tests are still aligned.

## Testing goals

- Verify framework contract, not just endpoint availability.
- Keep entity definitions, runtime behavior, and tests aligned.
- Catch regressions in views, relation-lite behavior, readonly handling, and query semantics.

## Required test layers

- Framework regression tests
- Service-level guard tests
- Definition alignment tests
- Business acceptance tests

## Alignment rules

- If the test expects an undeclared public field, fix the test.
- If runtime violates a declared contract, fix `magicOrm` first.
- If service plumbing distorts the framework contract, fix `magicBase`.
- Avoid app-side patches that make tests pass while the framework contract remains wrong.

## Recommended workflow

1. Start from the active entity definition.
2. Check whether the failing assertion is actually promised by the definition.
3. Check whether the failing behavior comes from ORM core, service access, or business logic.
4. Add or update the smallest regression test at the layer where the contract lives.
5. Re-run the higher-level suite only after the lower-level regression is in place.

## Useful test categories

- Query contract:
  top-level detail, filter `ValueMask > view`, child `lite`
- Write contract:
  insert and update response projection, readonly preservation
- Definition alignment:
  active model source and test baseline stay in sync
- Acceptance:
  business CRUD and end-to-end flow still conform to the declared model

## Common bad patterns

- Relaxing business assertions before checking the model definition
- Fixing a framework bug only in one project test
- Mixing baseline definitions from different repositories without alignment checks
- Treating module green status as proof that framework contract coverage is complete
