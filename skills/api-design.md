---
name: api-design
description: API contract and endpoint design rules for a NestJS backend and shared client contracts.
triggers: ["api design", "new endpoint", "change endpoint", "route shape"]
---

# API Design

> Sanitized example skill.

Use this skill when adding or changing backend endpoints.

## First Rule

Check the shared API contract document before changing route shape, payloads, or status semantics.

## Conventions

- resources are nouns
- routes are stable and explicit
- state-changing endpoints require auth unless intentionally public
- response shape should be predictable
- validation happens before business logic

## Preferred Structure

- controller: transport and request mapping only
- service: business logic and orchestration
- prisma/storage helpers: infrastructure details

## Error Handling

- use clear HTTP semantics
- do not expose internal stack traces
- keep unauthorized, forbidden, validation, and not-found states distinct

## Contract Discipline

When changing API behavior:

- update the shared API contract document if the contract changes
- keep all client consumers in mind
- avoid silent breaking changes
