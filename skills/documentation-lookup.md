---
name: documentation-lookup
description: Verify version-sensitive library and framework behavior against official docs before making changes.
---

# Documentation Lookup

Use current documentation instead of memory when behavior may have changed.

## When to Use

- Framework routing / rendering behavior (e.g. Next.js App Router)
- ORM schema or migration behavior (e.g. Prisma)
- Desktop runtime main/preload/renderer behavior (e.g. Electron)
- Browser-automation usage or test configuration (e.g. Playwright)
- S3-compatible / object-storage upload semantics
- Any library setup or API question with a non-trivial chance of drift

## Priority Order

1. Official framework or vendor docs
2. Primary package docs or reference material
3. Repository examples
4. Broader web search only if primary docs are insufficient

## Expected Output

- State what was verified
- Name the library or version if relevant
- Avoid guessing when docs are unclear

## Typical Targets

Check docs first for:

- The web framework powering your frontend
- The ORM/migration tool in your data layer
- The backend framework and its patterns
- Any desktop runtime in use
- The E2E/browser-automation tool once testing work begins
