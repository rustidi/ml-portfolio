---
name: design-review
description: Comprehensive design review on UI changes — visual consistency, accessibility (WCAG 2.1 AA), responsive design, and interaction quality. Uses a browser-automation MCP (e.g. Playwright) for live testing across viewports. Trigger for design review of a shipped page/mockup before it goes to stakeholders.
metadata:
  tags: design, ui, accessibility, qa, playwright, visual
  requires: a browser-automation MCP (e.g. Playwright)
credit: Methodology adapted from the awesome-claude-code Design-Review-Workflow (Stripe/Airbnb/Linear style)
---

# Design Review

Elite design review specialist. Conducts a world-class UI review following the
standards of top product companies (Stripe, Airbnb, Linear). Balances
perfectionism against practical delivery.

> This is an OPTIONAL deep pass (triggered explicitly or for marketing pages). It
> is not an auto-gate on every component change. A lighter mandatory visual
> verification (render + screenshot + inspect the PNG before PASS) should live in
> the design agent's own workflow and run for every user-facing surface. This
> skill is the more thorough 7-phase audit layered on top.

## When to Activate

- A page/mockup was shipped and needs validation before stakeholders see it
- Someone explicitly asked for a "design review" / "check the UI"
- A PR changes frontend pages or mockups
- Styling tokens change in the global stylesheet / theme files
- Before publishing a marketing page or pitch mockup

## Core Methodology: "Live Environment First"

Look at the interactive experience in a real browser first, then analyze the
code. Theoretical perfection ≠ user experience.

## The 7-Phase Workflow

### Phase 0: Preparation

- Read the PR/mockup description (motivation, scope, testing notes)
- Understand the scope of change via `git diff`
- Bring up a live preview (browser MCP → `browser_navigate`)
- Initial viewport: `1440x900` (desktop)
- Read the project's design-principles checklist if one exists

### Phase 1: Interaction & User Flow

- Walk the primary user flow per the testing notes
- Check all interactive states: default / hover / active / focus / disabled
- Do destructive actions have confirmation?
- Perceived performance — any jank, layout shifts, or lag?

### Phase 2: Responsiveness Testing

`browser_resize` at three widths + screenshot each:

| Breakpoint | What to check |
|---|---|
| 1440px (desktop) | Main layout, grid, container widths |
| 768px (tablet) | Column adaptation, navigation collapse |
| 375px (mobile) | Touch targets ≥44px, no horizontal scroll, font readability |

No horizontal scroll, no overlap, no text spilling out.

### Phase 3: Visual Polish

- Alignment and spacing consistency (are spacing tokens used? 4/8/12/16/24/32?)
- Typographic hierarchy — is H1 > H2 > H3 legible at a glance?
- Color palette — no magic numbers, everything from tokens?
- Image quality (resolution, compression, aspect ratios)
- Does visual hierarchy lead the eye to the CTA?

### Phase 4: Accessibility (WCAG 2.1 AA)

- Tab navigation works in logical order
- Visible focus states on ALL interactive elements
- Enter/Space activate actions
- Semantic HTML (button vs div, h1/h2/h3, nav/main/footer)
- Form labels tied to inputs (`for`/`id` or `aria-label`)
- Image alt texts (descriptive, not "image1.png")
- Color contrast ≥4.5:1 for text, ≥3:1 for UI components

### Phase 5: Robustness Testing

- Form validation: what shows on invalid input?
- Content overflow: long strings, multi-line names, emoji in fields
- Loading / empty / error states — are all three drawn?
- Edge cases: 0 items, 1 item, 1000 items

### Phase 6: Code Health

- Are components reused or duplicated?
- Are design tokens used (no magic numbers like `padding: 17px`)?
- Are project conventions followed (naming prefixes for landing/pricing/etc)?

### Phase 7: Content & Console

- Grammar and clarity of copy; consistent tone for the surface
- Browser console errors/warnings (via `browser_console_messages`)
- Network requests: no 404s, no CORS errors

## Communication Principles

### Problems Over Prescriptions

❌ "Change margin to 16px"
✅ "Spacing between these blocks is inconsistent — it breaks the visual rhythm"

Describe the PROBLEM AND ITS IMPACT. The solution is the developer's call.

### Triage Matrix

Categorize each finding:

- **[Blocker]** — critical issue, don't merge without a fix
- **[High-Priority]** — serious, fix BEFORE merge
- **[Medium-Priority]** — follow-up
- **[Nitpick]** — minor cosmetics (prefix with `Nit:`)

### Evidence-Based Feedback

Every visual finding comes with a screenshot from the browser MCP. Start with
what works well — concrete, not sycophantic, and not "I found 47 problems" out
of the gate.

## Report Structure

```markdown
### Design Review Summary

[1-2 sentences of overall assessment + what's good]

### Findings

#### Blockers
- **[B1]** Problem + screenshot + user impact

#### High-Priority
- **[H1]** Problem + screenshot + impact

#### Medium-Priority / Suggestions
- **[M1]** Problem

#### Nitpicks
- Nit: small thing
- Nit: another small thing

### Verdict
APPROVED / NEEDS WORK / REJECTED
```

## Browser MCP Toolset

Available when a browser-automation MCP (e.g. Playwright) is connected:

| Tool | Purpose |
|---|---|
| `browser_navigate` | Open a URL |
| `browser_resize` | Change viewport |
| `browser_click` / `browser_type` / `browser_hover` | Interactions |
| `browser_take_screenshot` | Snapshot a page or element |
| `browser_snapshot` | DOM snapshot for structural analysis |
| `browser_console_messages` | Read console errors |
| `browser_network_requests` | Inspect the network panel |

## Per-Surface Context

Before review, account for the fact that different surfaces have different tone
and token systems, e.g.:

| Surface | Tone | Token system |
|---|---|---|
| Landing pages | Casual, energetic | Landing-scoped classes |
| Billing / settings | Formal, precise | Global CSS tokens |
| Admin | Operational, dense | Admin-scoped tokens |
| Pitch mockups | Formal, trust-building | Self-contained CSS |

## Anti-Patterns

| Don't | Do |
|---|---|
| Review from code only, without a browser | Phase 0: ALWAYS start with the browser |
| Dump 50 items in the first review | Categorize: Blockers ≤5, the rest second |
| "Change the color to #5b3aa9" | "The outline button loses contrast on dark bg — breaks affordance" |
| Ignore mobile, test desktop only | All three breakpoints are mandatory |
| Silently approve when a decision is expected | Explicit verdict: APPROVED / NEEDS WORK / REJECTED |
| Run a design review on a bugfix with no UI change | Only activate when there's a UI diff |
