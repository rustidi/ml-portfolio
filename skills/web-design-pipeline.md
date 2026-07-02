---
name: web-design-pipeline
description: A step-by-step pipeline for building high-converting web pages. Orchestrates three design roles in sequence — conversion-strategist (narrative + copy) → brand-designer (visual language + generated imagery) → frontend-designer (code + a visual self-critique loop) → optional deep design review. Cures "stubborn, repetitive blocks" and "the designer only reads code, never looks at the result."
triggers: ["build a landing page", "design a page for X", "rewrite the landing", "high-converting page"]
---

# Web Design Pipeline

An orchestrator for the step-by-step development of high-converting pages. Turns "build a page for X" into a considered result — not a stack of look-alike blocks.

## Why (the root pain)

> "The design is stubborn and unconsidered, with lots of duplicated blocks. It feels like the agent reads code but never actually looks at the page — hence the repeats and the layering."

Two root causes, each fixed by the pipeline's structure:
1. **No narrative → duplicated blocks.** Fix: the `conversion-strategist` sets the story and the exact number of unique sections **before** any markup.
2. **The designer can't see the result.** Fix: the `frontend-designer` must render, take a full-page screenshot, and critique it with their own eyes in a loop until the repeats are gone (Phase 4.5).

Plus the `brand-designer` provides a single visual language and real imagery so there's no visual mismatch.

## When to activate

- "build a page / landing for X", "I need a high-converting page about Y", "rewrite landing Z", "assemble a sales page".
- Any new or substantially reworked marketing/landing page.
- NOT for a small one-button fix (go straight to `frontend-designer`; its Phase 4.5 visual check still applies).

## Flow (5 steps, in order, with review gates)

### Step 1 — Brief + strategy → `conversion-strategist`
Invoke the agent. It asks **3–5 questions** (who's the reader, the single target action, the main pain, the main objection, why-you're-better) and **waits for answers**. Then it produces a **Conversion Brief**: positioning, message hierarchy, narrative (sections with roles), ready copy, primary CTA, anti-duplication notes.
**Gate:** show the Conversion Brief to the stakeholder. Don't proceed until the narrative/copy is approved (or corrected).

### Step 2 — Visual language + distinctiveness → `brand-designer`
Pass the Conversion Brief. The agent anchors on the existing brand (reads the design-system CSS + any platform design tokens) and does **two distinctiveness passes** (`references/distinctiveness.md`): a token plan (Color/Type/Layout/**Signature**) + a mirror-test against generic AI defaults. It produces a **Visual Direction Spec**: palette (tokens), type scale, spacing rhythm, a **vocabulary of block shapes (4–6 types)**, a **signature element** (the page's distinctive touch), icon style, image style + prompts for the image-generation step, and motion standards (`references/motion-spec.md`).
**Gate (distinctiveness):** show the Visual Direction Spec. Ask and show: what here is NOT the default, what's the signature, what risk was taken? If it all looks "like everyone else," send it back for another pass.

### Step 3 — Asset generation (image-gen) → the image-gen script
The brand-designer (or you, following its spec) generates images in the approved style:
```bash
node gen-image.mjs "<prompt built to the formula>" --out public/landing/_gen/hero.png --model flux --size landscape_16_9
# a set in a single consistent style — use a fixed seed
```
- ⚠️ **The image API costs money.** Before bulk generation, estimate the number of calls and warn the stakeholder; for prompt testing without spend, use `--dry-run`.
- Compress for web (webp ~82); don't commit large PNGs into the public assets folder.

### Step 4 — Markup + visual loop → `frontend-designer`
Pass BOTH artifacts (Brief + Spec) and the asset paths. The designer:
- assembles the page ONLY from the vocabulary of block shapes, alternating them along the narrative;
- does not invent tokens, does not rewrite the copy;
- **runs the visual loop (Phase 4.5):** render → full-page screenshot → self-critique for repeats/rhythm/hierarchy → fix → repeat, until the page reads as a whole;
- produces a Quality Report with screenshots at 375/768/1440 and a description of what was seen.
**Gate:** PASS is forbidden without attached screenshots the agent actually inspected.

### Step 5 — Deep review (optional) → the design-review skill
For important/public pages, run a 7-phase audit via a headless browser (interactions, responsiveness, accessibility WCAG AA, content, console). Verdict: APPROVED / NEEDS WORK / REJECTED.

## Artifact map

| Step | Agent/tool | Input | Output |
|-----|------------------|------|-------|
| 1 | conversion-strategist | the request | Conversion Brief |
| 2 | brand-designer | Conversion Brief + brand tokens | Visual Direction Spec |
| 3 | image-gen script | prompts from the Spec | images in `_gen/` |
| 4 | frontend-designer | Brief + Spec + assets | page + Quality Report |
| 5 | design-review | finished page | verdict |

## Orchestration rules

- **Keep the order.** Narrative before style, style before code. Jumping ahead brings back the stubbornness.
- **Review gates after steps 1, 2 and 4.** It's cheap to fix narrative/style in words, expensive to re-lay the whole page.
- **One primary CTA** across the whole page (the strategist watches for this).
- **No invented numbers/case studies** — flag gaps for the stakeholder instead.
- **The image API costs money** — agree bulk generation, use `--dry-run` for estimates.
- For small fixes the pipeline isn't needed — call `frontend-designer` directly (its Phase 4.5 still enforces visual verification).

## Reference library (agents read on demand)

Rich knowledge is factored into files (structure like coreyhaines: SKILL + references) so agent prompts stay light while depth is at hand:

| File | Cures | Read by |
|------|-------|------------|
| `references/distinctiveness.md` | sameness, no face/signature | brand-designer, frontend-designer |
| `references/motion-spec.md` | no quality animations/transitions (timings, easing, 60fps) | brand-designer, frontend-designer |
| `references/conversion-playbook.md` | no marketing logic/triggers/offer (value equation, anatomy, sections, templates, psychology) | conversion-strategist |

Sources: Anthropic's `frontend-design` skill, contains-studio/agents (ui-designer, brand-guardian, whimsy-injector, visual-storyteller), coreyhaines/marketingskills (copywriting, cro, offers, marketing-psychology), and web-animation best practices.

## Related skills/agents

`mockup-first-workflow` (HTML mockup before production code), `design-review` (deep audit), a browser-automation skill (render/screenshots), `frontend-design` (built-in helper).
