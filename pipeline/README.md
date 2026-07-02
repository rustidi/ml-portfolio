# The delivery pipeline

Every piece of work goes through the same four phases. A big feature, a bugfix, a one-line hotfix — all
of it. The point is simple: I don't get to skip a step because I'm tired or in a hurry. The process runs
the same way every time.

Here are the four phases and what each one is for.

## Phase 1 — Check the idea before writing code

Before anything gets built, the idea gets challenged. For anything non-trivial, a panel of agents plays
CTO, product lead, and CFO and asks the hard questions: Is this worth doing? What's the cheaper version?
What are we not thinking about? It returns a verdict — approved, revise, or rejected.

I skip this only for a real bugfix or a change smaller than half a day. Everything else earns its place
before a line of code is written.

Why it matters: the most expensive code is the code you shouldn't have written. This phase kills bad
ideas while they're still cheap to kill.

## Phase 2 — Plan, and ask what could break

Once the idea is approved, planning starts with one honest question filled in *in writing*:

1. **What already exists near this?** Before building anything new, check what's already there. Most
   "we need a new thing" turns out to be "we need to extend a thing we already have."
2. **What's the path of least change?** Extend, don't duplicate. Fewer new tables, fewer new contracts.
3. **What could this break?** Existing flows, API contracts, the database, money math, other people's
   work. Name it before you write it.

The verdict is either "safe, go" or "this breaks existing logic — stop, find a safer plan."

Why it matters: this is the step that stops a small feature from quietly breaking three old ones.

## Phase 3 — Build

Now the code gets written, with the right layer-specific skills loaded automatically — backend patterns,
database migration safety, mobile UI rules, and so on. This is the part everyone pictures when they think
"AI writes code." It's one phase of four.

## Phase 4 — Verify before a human ever sees it

Nothing gets shown to me until it's checked. In order:

1. Run the verify script (typecheck + consistency checks).
2. Run the mandatory reviewers for whatever files changed (see the [trigger table](../CLAUDE.md.example)).
3. Run a QA pass — for UI, a real browser drives the flow and screenshots it (see [`../qa`](../qa)).
4. If the build is shaky, run a clean-build simulation.

Only when Phase 4 is green does the work get shown.

## "Done" means done

Nothing is called done on the agent's word. Done means I verified it myself: the typecheck is green,
the production health check passes, and a git check confirms the right commit actually shipped. Not "it
should be live." Live, and checked.

## The files in this folder

- [`SPRINT_TEMPLATE.md`](./SPRINT_TEMPLATE.md) — the sprint file every task fills in, including the
  Phase-2 risk block and the Phase-4 reviewer verdicts.
- [`verify-reviewer-gate.sh`](./verify-reviewer-gate.sh) — the machine gate. It reads which files
  changed and **refuses to deploy** if the required reviewer hasn't signed off. This is the part that
  turns "I should review auth carefully" into "the deploy won't run until auth is reviewed."
