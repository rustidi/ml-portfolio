---
name: backend-patterns
description: NestJS and Prisma backend patterns for controllers, services, uploads, orchestration, and worker-facing contracts.
triggers: ["backend patterns", "controller", "service layer", "upload flow", "worker contract"]
---

# Backend Patterns

> Sanitized example skill.

Use these patterns for backend and worker-facing changes.

## Layering

- modules define bounded areas
- controllers stay thin
- services hold business rules
- Prisma access stays explicit and reviewable

## Good Defaults

- validate input early
- prefer explicit return values over hidden side effects
- isolate storage and external-service calls
- keep orchestration readable

## Upload and Recording Flows

For recording and upload logic:

- persist state transitions explicitly
- make retries safe
- separate initiate, sign, complete, and abort responsibilities
- do not trust client progress as the source of truth

## Worker-Friendly Design

- use durable identifiers
- design for idempotency
- keep status transitions observable
- avoid coupling worker internals into controller code
