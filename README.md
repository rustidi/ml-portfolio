# How I build: an AI-orchestrated engineering system

I run a full production platform on my own — iOS app, Android app, web, backend, and the GPU workers that do the heavy AI work. One person, but the output of a small team. Not because AI types fast, but because I built a system around it: a set of reusable skills, a team of review agents, and gates that stop a bad deploy before it happens.

This repo explains that system. The patterns are general and you can reuse them. I use them every day on a live healthcare product. The product's own code stays private — it holds patient data, it's a commercial product, and it has live integrations. **What's public here is the method,** shown with clean, representative examples.

If you build with AI agents, the real question isn't "can it write a function." Of course it can. The question is: *how do you get reliable, reviewable, production-quality work out of it at scale — and keep it honest?* This repo is my answer.

---

## The one idea

Most people use an AI coding agent like a faster autocomplete. I use it like a team I designed — with specialists, a process, and gates that don't let me cut corners when I'm tired or rushing.

Three moving parts:

| Part | What it is | Count |
|---|---|---|
| **Skills** | Codified procedures the agent loads on demand — how to deploy, how to migrate a DB safely, how to verify a build, how to price an LLM call | ~79 |
| **Agents** | Adversarial specialists that review code from one narrow angle — security, silent failures, auth, mobile concurrency, DB, money math | ~29 |
| **Gates** | Shell scripts wired into deploy that **fail the deploy** (non-zero exit) unless the right specialist has signed off on the code that changed | 2 machine gates |

The process isn't a suggestion I try to remember. It's enforced in the pipeline.

---

## Why agents, and why *these* agents

The design principle behind every review agent:

> **An agent is a scar, codified.**

Each specialist exists because a specific class of bug cost real time and real trust. Instead of "try to remember to check for X," the check becomes a standing reviewer that is *mandatory* whenever code in its blast radius changes.

- **`silent-failure-hunter`** — born after a run of incidents where a pipeline swallowed an error and rendered "0 results" as success. A boot-time cleanup job that deleted the very data it was meant to protect. Zero tolerance for swallowed errors and dangerous fallbacks. "Couldn't verify" must never render as "nothing there."
- **`auth-flow-reviewer`** — born after "false logout" (a user booted from the app mid-session, despite a valid session) recurred **eight times**. It owns the entire login / refresh / session / unlock flow and reviews on a *presumption of guilt*: default verdict is NEEDS-FIX until every invariant is proven at a specific line.
- **`healthcare-reviewer` + PHI-compliance** — clinical-data safety, and a hard rule that protected health information never leaks into an LLM prompt beyond an explicit allow-list.
- **`money-math-invariants`** — six invariants for billing math that a typecheck can't catch (the unit is in the variable name; no dividing by 100 in the UI; DTO parity front-to-back).

See [`agents/`](./agents) for the full philosophy and sanitized examples.

---

## The delivery pipeline

Every piece of work — feature, bugfix, even a one-line hotfix — is a **sprint** with four phases. Nothing is skipped.

1. **Validate the hypothesis** *before* writing code. For anything non-trivial, a "board of directors" agent panel (CTO / CPO / CFO lenses) challenges the idea and returns a verdict: approved / revise / rejected.
2. **Plan** with an *integration-safety gate*: what already exists nearby (don't rebuild it), the path of least change, and — explicitly — what the change could break in existing flows, contracts, and the DB schema.
3. **Implement** with layer skills auto-loaded (backend, DB migrations, mobile UI, etc.).
4. **Verify** before anything is shown to a human: typecheck, the mandatory reviewers for the touched files, a QA pass, and a clean-build simulation.

Nothing is reported "done" on the model's word. **Done = verified by me** — green typecheck, production health check, a git check that the right commit actually shipped. Not a proxy.

See [`pipeline/`](./pipeline) for the phase-by-phase breakdown, a sprint-file template, and the actual machine gate.

---

## How a feature is checked before I ever see it

The thing that makes this trustworthy isn't the writing — it's the **verification loop**. For a UI change, the agent doesn't just say "done." It drives a real browser (Playwright): navigates the flow, clicks every interactive element, fills the forms, screenshots each state, and reads back the DOM to confirm the thing actually rendered and worked. Broken states come back as findings, not as a cheerful "looks good."

See [`qa/`](./qa) for how the automated QA loop works.

---

## Memory that compounds

The system extracts a reusable lesson from each session and stores it as an atomic, linked memory file — every recurring bug root, every infra gotcha, every hard-won preference. The next session loads the index and doesn't repeat the mistake.

Real lessons this produced (sanitized):

- "A container restart doesn't re-read environment variables — you need a full redeploy to apply a rotated secret."
- "Diagnose auth bugs from the production token table *before* theorizing about the client."
- "Verify output coverage against the source duration — never trust a bullet count as proof of completeness."

See [`memory/`](./memory) for the format and why atomic + linked beats a giant notes file.

---

## What's in this repo

```
ai-engineering-showcase/
├── README.md            ← you are here
├── CLAUDE.md.example    ← the "project constitution" the agent reads first (generalized)
├── skills/              ← reusable procedures (deploy, safe migrations, sprint delivery, build verification)
├── agents/             ← adversarial review specialists (the "scar, codified" philosophy + examples)
├── pipeline/           ← the 4-phase delivery process, a sprint template, the machine review-gate
├── qa/                 ← the automated browser QA loop (Playwright: navigate → click → screenshot → verify)
└── memory/             ← compounding lessons: atomic, linked, loaded every session
```

Every example here is **sanitized and representative** — the shape and the reasoning are real; client names, domains, secrets, and medical specifics are removed.

---

## What this shows

For an AI-first team, this is the skill that actually matters. Not "can prompt a model" — everyone can do that now. The skill is **designing a system where AI agents produce reliable, reviewable, production work at scale, with guardrails that keep it honest.** I've been running this against a real clinical product with real users, not a demo.

*— Rustem Idiatullin. Building AI products for healthcare; relocating to Australia or New Zealand.*
