---
name: magicorm-error-observability
description: Use when diagnosing magicOrm failures, error-code handling, metrics output, or instrumentation behavior. Covers framework error boundaries, metrics interpretation, and observability-safe debugging.
compatibility: Designed for agent clients working on repositories that expose magicOrm metrics or error flows and need framework-level diagnostics. Assumes local repository access and runtime logs or tests; no network access is required.
metadata:
  author: rangh-codespace
  domain: magicorm
  scenario: error-observability
  maturity: stable
---

# MagicOrm Error And Observability

Use this skill when the task is about ORM error codes, validation failures, query runner timing, or how to diagnose framework behavior without guessing.

## Scope

- Error code meaning and error propagation
- Metrics and profiling output
- Query and update timing interpretation
- Observability-safe debugging

## Core rules

- Diagnose from framework evidence first: tests, logs, metrics, runtime traces.
- Preserve error semantics; do not hide ORM failures behind vague service errors.
- Metrics and timing should help explain behavior, not redefine it.
- If a report or metric label is wrong, fix the reporting logic explicitly.

## Review workflow

1. Capture the concrete error or timing evidence.
2. Identify whether the failure is validation, provider, SQL execution, projection, or service plumbing.
3. Check whether the reported code or metric matches the actual condition.
4. Fix ORM reporting or propagation at the layer where it originates.
5. Add a regression if the diagnostic surface itself was misleading.

## Common bad patterns

- Collapsing different ORM failures into one generic error
- Ignoring runner profiles when debugging query slowdown
- Treating observability labels as ground truth without checking raw metrics
- Fixing only dashboard output when the underlying signal is wrong
