---
name: mockup-first-workflow
description: Iterative workflow for UI pages — HTML mockup first, stakeholder feedback loop, multi-agent review, then implementation. Prevents wasted code by validating structure and content before writing production components. Use when building any new customer-facing page.
metadata:
  tags: workflow, marketing, ui, mockup, iteration
---

# Mockup-First Workflow

Build customer-facing pages through progressive refinement: cheap HTML mockup → stakeholder feedback → professional review → production code. This eliminates the #1 waste in UI work — implementing the wrong thing.

## When to Activate

- Building any new marketing/landing page
- Creating a complex interactive UI (calculator, configurator, dashboard)
- Any page where stakeholder approval is required before shipping
- Pages with significant copy/content that needs review
- When the final design isn't clear and needs iteration

## Why This Works

| Without mockup | With mockup |
|---|---|
| Write React code → stakeholder doesn't like it → rewrite 80% of code | Write HTML → stakeholder doesn't like it → change text in 5 min |
| 3 hours wasted per iteration | 20 min per iteration |
| Developer resists changes ("but I already built it") | Changes are cheap, no resistance |
| Copy and layout coupled to framework | Content validated independently of tech |

## The Workflow

### Phase 1: Quick HTML Mockup (v1)

Create a standalone HTML file with:
- Inline CSS (no build tools, opens in any browser)
- Real content (not lorem ipsum — write actual copy from day 1)
- Responsive basics (flexbox/grid, 2-3 breakpoints)
- Interactive elements as static states (show all states: default, hover, active, error)
- If page has a calculator/configurator: implement logic in vanilla JS

Save to a dedicated mockups directory, e.g. `assets/mockups/{page-name}-mockup.html`

**Rules for v1:**
- Spend max 30-45 min
- Use the project's design system values (colors, fonts, border-radius) but don't import CSS files
- Write copy in the target language from the start
- Include all planned sections even if rough
- Add HTML comments marking sections for easy navigation

### Phase 2: Stakeholder Feedback

Present the mockup and collect specific feedback:
- What sections to keep, remove, or reorder?
- What copy feels wrong? (too corporate, too casual, misleading)
- What's missing that they expected to see?
- What competitor pages do they want to reference?

**Key principle:** Don't defend the mockup. It cost 30 minutes. Throw away and rebuild if needed.

### Phase 3: Iterate (v2, v3...)

Apply feedback, create next version. Typical iteration count: 2-3 rounds.

Each round:
1. Apply all feedback from previous round
2. Name the file with version: `{page-name}-mockup-v{N}.html`
3. Present to stakeholder
4. If stakeholder says "looks good" → Phase 4

**When to stop iterating:**
- Stakeholder approves structure AND content
- No critical feedback in last round
- Only "nice-to-have" items remain

### Phase 4: Multi-Agent Review

Before implementation, run the approved mockup through a multi-specialist review pass (SEO, UX, copy, accessibility in parallel). This catches:
- SEO gaps the stakeholder wouldn't notice
- UX issues invisible in static mockup
- Copy that sounds natural to stakeholder but triggers AI-detection patterns
- Missing JSON-LD, meta tags, accessibility

Apply CRITICAL and IMPORTANT findings. Skip NICE-TO-HAVE.
Present updated mockup to stakeholder for final approval.

### Phase 5: Implementation

Convert approved mockup to production code:
1. Server Component (page.tsx) with all SEO metadata and JSON-LD
2. Client Components only for interactive parts (calculator, forms, accordions)
3. Page-specific CSS file with a namespaced prefix (e.g., `pp-*` for pricing, `about-*` for about)
4. Follow existing conventions for shared elements (shared nav, footer, shared utility classes)

**Implementation checklist:**
- [ ] All copy matches approved mockup exactly (don't "improve" during implementation)
- [ ] SEO: title, description, OG, Twitter Card, JSON-LD
- [ ] Responsive: test at 375px, 768px, 1024px, 1440px
- [ ] Links: all internal links point to existing pages
- [ ] Forms: validation, success states, error states
- [ ] Sitemap: add new page to the sitemap
- [ ] Navigation: update header/footer links if needed

### Phase 6: Verification

- Run the project's typecheck
- Check page in browser at all breakpoints
- Run a cross-page consistency check
- Update delivery docs (backlog, changelog, implemented log)

## File Naming Convention

```
assets/mockups/
├── pricing-mockup.html         # v1 (initial)
├── pricing-mockup-v2.html      # after first feedback
├── pricing-mockup-v3.html      # after second feedback (approved)
├── about-mockup.html           # v1
├── about-mockup-v3.html        # approved version
└── ...
```

Keep all versions — they document the decision trail.

## Anti-Patterns

| Don't | Do |
|---|---|
| Skip mockup because "it's a simple page" | Even simple pages need content validation |
| Use React/Next.js for the mockup | Plain HTML — zero build time, zero dependencies |
| Write lorem ipsum | Write real copy from v1 — content IS the design |
| Implement before stakeholder approval | Wait for explicit "looks good" |
| "Improve" copy during implementation | Copy is approved — implement verbatim |
| Delete old mockup versions | Keep all versions for decision history |
| Run multi-agent review on v1 | Run it on the stakeholder-approved version |

## Metrics

Track across projects to validate the workflow:
- **Iterations to approval**: target 2-3 (if >4, mockup quality is too low)
- **Code rework after implementation**: target <10% (if higher, mockup wasn't detailed enough)
- **Time mockup→approved**: target <2 hours total
- **Time approved→implemented**: varies by complexity, but no surprises
