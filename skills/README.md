# Skills — codified procedures the agent loads on demand

A **skill** is a small, self-contained document that teaches the AI agent *how to do one thing
correctly* in this codebase — deploy, migrate a database safely, verify a build, price an LLM call.
The agent pulls a skill into context only when it's relevant, so the base context stays lean.

Think of a skill as an operational runbook that a senior engineer would write for the rest of the
team — except the "team" is the AI agent, and the runbook is enforced every time.

## Why skills instead of just prompting

Three reasons:

1. **Consistency.** "Deploy the app" should mean the exact same 8 steps every time, in the same
   order, with the same health checks — not whatever the model improvises today.
2. **Hard-won detail survives.** A skill is where a costly lesson gets frozen. The deploy skill knows
   that a restart doesn't apply a rotated secret because that once cost a production incident. That
   knowledge would evaporate from a plain chat; in a skill it's permanent.
3. **Token economy.** 69 public skills would blow the context window if all loaded at once. On-demand
   loading means the agent carries only what the current task needs.

## How a skill is structured

Every skill is a markdown file with frontmatter:

```markdown
---
name: deploy
description: When to activate this skill (the agent matches the task against this).
triggers: ["deploy", "ship", "release"]
applies_to: ["scripts/deploy-all.sh"]
---

# Title

## The one command / the golden rule
## Step-by-step
## What breaks and how to avoid it   ← the war-story section
```

The `description` and `triggers` are how the agent decides to load it. The body is the runbook.

## The catalog (sanitized sample)

The current public catalogue contains 69. A representative slice, by category:

**Delivery & ops**
- `sprint-delivery` — the mandatory lifecycle: backlog → sprint → changelog → done-stamp
- `deploy` — one command, all servers, with health checks and the "restart ≠ redeploy" lesson
- `clean-build-verification` — why a green typecheck is not proof of a correct build
- `env-preflight` — checks before any heavy git/build/deploy (disk, repo location, verified-done gate)

**Database safety**
- `database-migrations` — migrations are irreversible in prod; the safe recipe
- `prisma-rename-recipe` — renaming a column without breaking every consumer
- `env-preflight` — checks before any heavy git/build/deploy, and a "verified-done" gate

**AI/LLM engineering**
- `cost-aware-llm-pipeline` — per-call cost telemetry; don't send an LLM what a regex can do
- `eval-harness` — so a model swap can't silently regress output quality
- `regex-vs-llm-structured-text` — when deterministic parsing beats a model call
- `content-hash-cache-pattern` — never re-transcribe the same file twice

**Correctness invariants**
- `money-math-invariants` — six billing invariants a typecheck can't catch
- `output-coverage-assertion` — assert coverage against source duration, not bullet count
- `silent-failure` patterns — surfaced errors, no dangerous fallbacks

**This folder contains ~68 of them in full** — the real working set, not just examples. Each has been
stripped of product-specific hostnames, IPs, credentials, internal paths, and client details; the
*method* is intact. A handful of the most product- or client-specific skills (the client-integration
connectors, the medical-compliance ones, the deploy topology with real hosts) are deliberately left out.

### An honest note on authorship

This is my actual toolkit, so it's a mix — and I'd rather be straight about which is which:

- **Built from our own incidents** — the ones that carry a hard-won lesson from this product:
  `money-math-invariants`, `output-coverage-assertion`, `prisma-rename-recipe`, `content-hash-cache-pattern`,
  `regex-vs-llm-structured-text`, `runpod-force-recycle`, `clean-build-verification`, `env-preflight`,
  `streaming-chunk-boundary`, and more. These are mine.
- **Adapted from the community** — a number of the general-purpose skills (e.g. `agentic-engineering`,
  `continuous-learning`, `deep-research`, `prompt-optimizer`, `iterative-retrieval`) started from
  open-source skills I collected and adapted. Where an original author is credited in a file, I've kept
  that attribution.

The skill isn't "I invented all of these." It's "I assembled and enforce a working system out of them."
