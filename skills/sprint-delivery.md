---
name: sprint-delivery
description: The mandatory delivery lifecycle. Guarantees every change is captured — backlog → sprint → changelog → implemented — and nothing ships untracked. Fires at the start and end of any task.
triggers: ["sprint", "close sprint", "new feature", "hotfix"]
applies_to: ["docs/03-delivery/**"]
---

# Sprint delivery pipeline

> Sanitized example skill. The golden rule and the lifecycle are verbatim; paths are generic.

## Golden rule

**Every code change is a sprint. No exceptions.** Even a one-line hotfix is a mini-sprint. This sounds
heavy; it isn't. It's what makes a solo operation auditable: months later I can answer "why does this
line exist" from the sprint file, the changelog entry, and the reviewer verdicts — not from memory.

## The pipeline

```
BACKLOG.md          →     SPRINT_NN.md          →     CHANGELOG.md
(prioritized queue)       (spec + tasks + gates)      (what actually shipped)
    planned                    in_progress                 done
```

## Before starting work

- If told "start sprint NN": read the state doc, the sprint file, and the backlog; work to the spec.
- If told "do X" with no number: find the active sprint or create the next one; add the task to the
  backlog if it isn't there.
- Even a hotfix gets a file. The overhead is a minute; the traceability is permanent.

## The sprint file

A sprint file carries, at minimum:
- **Goal & hypothesis** — what we believe and why it's worth doing.
- **Integration & risks** (Phase-2 gate) — what already exists nearby, the least-change path, what
  this could break.
- **Tasks & DoD** — a checklist that must all be `[x]` before the sprint closes.
- **Reviewer gate (Phase 4)** — one line per mandatory reviewer with their verdict.

A full template is in [`../pipeline/SPRINT_TEMPLATE.md`](../pipeline/SPRINT_TEMPLATE.md).

## After finishing (all steps mandatory)

1. **Sprint file** → stamp `DONE <date> <time>` on line one; flip every DoD item to `[x]`.
2. **Backlog** → status `done`, result = one-sentence summary referencing the sprint.
3. **Changelog** → context / what was done / modules touched.
4. **Implemented registry** → a summary line so the capability index stays current.
5. **Rename** `SPRINT_NN.md` → `✅ SPRINT_NN.md` (a glance at the folder shows what's open).
6. **Deploy** → update the changelog *first*, then run the deploy script; the sprint is not closed
   until it reports ✅ on every server.

## The anti-patterns this kills

- **"I'll remember to write it up later."** You won't. The write-up *is* the work; a feature with no
  changelog entry is a feature no one can reason about in three months.
- **Materialize conclusions to disk immediately, not into the chat.** Any audit, plan, or result goes
  into a file first. In the chat it's one context-loss away from gone; on disk it's saved.
- **A green typecheck is not a closed sprint.** Done means shipped and health-checked, tracked end to
  end.
