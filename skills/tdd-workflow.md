---
name: tdd-workflow
description: Test-first workflow for features and bug fixes in a TypeScript monorepo, with proportionate verification.
triggers: ["tdd", "write test first", "test-driven"]
---

# TDD Workflow

Use this for code changes that introduce or change behavior.

## Core Rule

Write or update the failing test first when the task changes runtime behavior.

## Red -> Green -> Refine

1. RED
   - write the smallest useful failing test
   - confirm it exercises the intended behavior
2. GREEN
   - implement the minimal change to pass
3. REFINE
   - improve names, extraction, and readability
   - keep behavior stable

## Apply Proportionately

Use the smallest meaningful test layer:

- unit for pure logic and helpers
- integration for API/module/service interactions
- E2E for critical user flows only

If the task is docs-only, config-only, or scaffolding-only, document why no new test was needed.

## Repo Notes

- API behavior changes should usually add service or controller-level coverage
- web UI logic should prefer component or integration-style verification
- background queue/state work should favor deterministic local-state tests once that layer exists

## Verification After TDD

- run the type checker
- run the relevant workspace build or test command
- run the repo's sync/consistency check
