# SPRINT_NN — <short title>

> Status line goes here. On completion it becomes: `DONE <date> <time>`.

This is the template every task fills in. It's short on purpose. The value isn't ceremony — it's that
six months later, anyone (including me) can read this file and understand why the code exists, what it
might have broken, and who checked it.

---

## Goal & hypothesis

One or two sentences. What do we believe, and why is it worth doing? If you can't state the hypothesis,
you're not ready to build.

## Integration & risks (Phase-2 gate — mandatory)

Fill this in *before* writing code.

- **What already exists near this:** which modules/contracts does this touch or duplicate? (Check the
  capability index and grep the codebase first.)
- **Path of least change:** extend what's there, or build new? Justify.
- **What this could break:** existing flows, API contracts, the DB schema, parallel work, money/PHI
  invariants.
- **Verdict:** SAFE → build · BREAKS LOGIC → stop, bring a safer plan.

## Tasks & definition of done

- [ ] Task 1
- [ ] Task 2
- [ ] Verify script green
- [ ] Deployed and health-checked

Every box must be `[x]` before the sprint closes.

## Reviewer-gate (Phase 4)

One line per mandatory reviewer for the files this sprint touched. The machine gate reads this section
and blocks the deploy if a required verdict is missing. A pass is `CLEAR` / `SAFE` / `APPROVED`; anything
else is `NEEDS-FIX` / `BLOCK`.

- `<reviewer>`: CLEAR — one-line summary of what was checked
- `<reviewer>`: NEEDS-FIX — what's wrong (blocks deploy until resolved)

## Result

Filled on completion: one-sentence outcome. Details go in the changelog.
