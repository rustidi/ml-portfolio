---
name: frontend-patterns
description: Frontend patterns for Next.js web apps and Electron renderer UI — explicit state handling, thin client components, and safe boundaries between UI and privileged operations.
---

# Frontend Patterns

Use this skill for Next.js app work and renderer-side desktop UI.

## Principles

- explicit loading, empty, error, and success states
- small components with clear ownership
- avoid pushing business logic into presentational components
- keep client components minimal

## Next.js Guidance

- prefer server-driven data when practical
- use client components only where interactivity is required
- keep route structure aligned with the app's organization

## Desktop Renderer Guidance

- keep renderer UI thin
- prefer preload or explicit service boundaries for privileged operations
- do not leak Node or filesystem access directly into UI code

## Forms and Inputs

- validate user input explicitly
- use status-driven submission flows
- show recoverable failures clearly
