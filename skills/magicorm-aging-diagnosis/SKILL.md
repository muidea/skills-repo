---
name: magicorm-aging-diagnosis
description: Use when investigating long-run slowdown or aging warnings on services built with magicOrm and magicBase. Covers distinguishing functional correctness from performance drift, request-level versus full-flow latency, and framework-safe diagnosis steps.
compatibility: Designed for agent clients diagnosing aging or long-run performance behavior in repositories built on magicOrm and magicBase. Assumes local repository access and runtime logs; network access is not required.
metadata:
  author: rangh-codespace
  domain: magicorm
  scenario: aging-diagnosis
  maturity: stable
---

# MagicOrm Aging Diagnosis

Use this skill when aging or long-run pressure tests report slowdown but functional tests still pass.

## Goal

Determine whether the issue is:

- a functional regression
- a single-endpoint performance regression
- a long business flow amplification effect
- or a test-reporting artifact

## Diagnosis rules

- Do not weaken ORM or service contract rules just to reduce timing noise.
- Separate single-request latency from full business-flow latency.
- If one flow contains many requests, small request-level regressions can produce large flow-level degradation.
- Fix report logic when the report semantics are wrong; do not confuse that with runtime performance defects.

## Workflow

1. Confirm functional success rate and failure count first.
2. Measure single-request latency distribution over early and late windows.
3. Compare the heaviest write and read endpoints across those windows.
4. Estimate how many requests exist in one business flow.
5. Decide whether the slowdown is endpoint-local or cumulative across a long chain.
6. Check report logic for false trend labels or misleading aggregates.
7. Only then decide whether to optimize ORM, service access, or test logic.

## Safe conclusions

- If functional success stays at `100%`, treat the issue as performance-only until proven otherwise.
- If request latency drifts only slightly but each flow contains many requests, the slowdown may be cumulative rather than a framework contract break.
- If report trend labels contradict raw metrics, fix the report first.

## Common bad patterns

- Treating aging slowdown as proof of query contract regression
- Optimizing business handlers before checking request distribution
- Ignoring the amplification effect of long business flows
- Leaving obviously wrong report semantics unfixed
