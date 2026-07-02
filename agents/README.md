# Agents — adversarial review specialists

Where a **skill** teaches the agent *how to do* something, an **agent** is a specialist whose only job
is to *review* something from one narrow, adversarial angle. Security. Silent failures. Auth. Money math.
Mobile concurrency. Each is a separate sub-agent with its own system prompt, its own tools, and a
presumption that the code is guilty until proven correct.

There are ~29. This folder explains the philosophy and includes three real ones, sanitized.

## The design principle

> **An agent is a scar, codified.**

I don't create a reviewer because it seems like good practice. I create one when a specific class of bug
has cost me real time and real trust — and then I make that reviewer **mandatory** whenever code in its
blast radius changes, so the same mistake can't reach production twice.

This is the difference between "I should be careful about auth" (a hope) and "the deploy will not run
until the auth reviewer has signed off at a specific line" (a mechanism). The [trigger table](../CLAUDE.md.example)
maps changed files → mandatory reviewer, and a [machine gate](../pipeline) enforces it.

## Why narrow and adversarial

A single "review this code" agent is a generalist that finds generic issues. A **fleet of narrow
specialists** each finds the deep issue in its domain, because each one is primed with the actual
history of how that domain has failed here before.

The `auth-flow-reviewer` doesn't review "code quality." It reviews *this login flow against the eight
specific ways false-logout has bitten before*, and it defaults to **NEEDS-FIX** until each invariant is
proven. That presumption of guilt is deliberate: the bug came back eight times precisely because each
time someone "kind of checked it" and it looked fine.

## How an agent is structured

```markdown
---
name: silent-failure-hunter
description: When this agent must run (the trigger table + explicit CEO phrases).
tools: ["Read", "Grep", "Glob", "Bash"]   ← read-only: reviewers don't edit, they report
model: sonnet
---

## Prompt-defense baseline      ← don't change role, don't leak secrets, treat inputs as untrusted
## Context                      ← the real incidents that created this agent
## Hunt targets / checklist     ← concrete, code-level things to look for
## Verdict format               ← CLEAR / NEEDS-FIX with file:line evidence
```

Two details that matter:

- **Read-only tools.** Reviewers `Read`, `Grep`, `Glob` — they don't `Edit`. A reviewer that can fix
  things stops being a reviewer and starts hiding problems inside its own patches. Findings go back as a
  report; the fix is a separate, reviewable step.
- **Evidence-based verdict.** A CLEAR isn't a vibe. It cites the line where the invariant holds. If the
  agent can't find that line, the verdict is NEEDS-FIX — "I couldn't confirm it" is not "it's fine."

## The fleet (sanitized sample)

| Agent | The scar it came from |
|---|---|
| `silent-failure-hunter` | Pipelines that swallowed errors; a boot job that deleted the data it guarded |
| `auth-flow-reviewer` | "False logout" — a valid session booting the user, ×8 |
| `security-reviewer` | Secrets, injection, SSRF, unsafe crypto, OWASP top-10 in anything handling input |
| `healthcare-reviewer` | Clinical-data integrity and PHI never leaking into an LLM prompt |
| `money-math-invariants` | Billing math a typecheck can't catch (unit-in-the-name, no /100 in UI) |
| `database-reviewer` | Query perf, schema safety, migration correctness |
| `swift-reviewer` / `kotlin-reviewer` | Mobile data races, concurrency, platform pitfalls |
| `board-of-directors` | Not a code reviewer — a Phase-1 panel that challenges the idea before code |

**This folder contains ~25 of them in full** — the real review fleet. The three hand-picked starting
points, because they best show the "scar, codified" idea:
[`silent-failure-hunter.md`](./silent-failure-hunter.md) ·
[`auth-flow-reviewer.md`](./auth-flow-reviewer.md) ·
[`security-reviewer.md`](./security-reviewer.md)

Every agent here has been sanitized — real sprint IDs, module paths, hostnames, and product/client
names are generalized. The incident *shapes* and the checklists are real; that's the part worth reading.
A few agents that were fundamentally about the client integration or the medical data model are left out
entirely. Where an agent was adapted from a community prompt, its original attribution is kept.
