---
name: magicorm-transaction-operations
description: Use when implementing or reviewing magicOrm mutation and transaction behavior. Covers Insert, Update, Delete, Count, transaction boundaries, relation persistence, and the rule that mutation semantics must stay inside magicOrm rather than app-side wrappers.
compatibility: Designed for agent clients working on repositories that use magicOrm for transactional mutation and relation persistence. Assumes local repository access and test tooling; no network access is required.
metadata:
  author: rangh-codespace
  domain: magicorm
  scenario: transaction-operations
  maturity: stable
---

# MagicOrm Transaction Operations

Use this skill when the task is about write-path correctness, transaction boundaries, relation persistence, or mutation rollback semantics.

## Scope

- `Insert`, `Update`, `Delete`, `Count`
- Transaction begin, commit, rollback
- Relation save order and mutation consistency

## Core rules

- Mutation semantics belong in `magicOrm`.
- Relation persistence must stay transactionally consistent with the host entity.
- If a write path must be atomic, fix it with ORM transaction handling rather than app-side retry-only logic.
- `Count(filter)` should reflect the same filter semantics as batch query.

## Review workflow

1. Identify whether the bug is pre-validation, SQL execution, relation persistence, or response projection.
2. Check whether the mutation runs inside the right transaction boundary.
3. Check whether host and relation writes commit or roll back together.
4. Verify delete behavior for owned relations where applicable.
5. Add ORM tests for commit and rollback before changing service code.

## Common bad patterns

- Splitting host and relation writes across separate non-atomic service calls
- Rebuilding transaction semantics in business code
- Fixing rollback gaps only in one mutation path
- Treating mutation response projection as persistence success
