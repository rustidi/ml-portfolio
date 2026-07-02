# QA — how a feature gets tested before I ever see it

The thing that makes AI-written code trustworthy isn't the writing. It's the checking. So for anything
with a UI, the agent doesn't just say "done." It opens a real browser and actually uses the feature.

## What the automated QA pass does

The agent drives a real browser (Playwright) through the flow like a person would:

1. **Navigate** to the page or screen that changed.
2. **Click every interactive thing** — buttons, tabs, menus, dialogs. Not the happy path only. The
   thing that opens a popup, the thing that closes it, the thing that submits the form.
3. **Fill the forms** with real input and submit them.
4. **Screenshot each state** — before, during, after. So there's a visual record, not a claim.
5. **Read the DOM back** to confirm the thing actually rendered and did what it should — the right text
   appeared, the row was added, the error showed when it should.
6. **Test at different sizes** — phone width, tablet, desktop — so "works" doesn't secretly mean "works
   on my screen only."

If something is broken, it comes back as a finding with the screenshot, not as a cheerful "looks good."

## Why a real browser and not just unit tests

Unit tests check the pieces. They don't catch the button that's there but does nothing, the popup that
opens off-screen, the form that submits but shows no confirmation. Those are the bugs a user actually
hits — and they only show up when something actually clicks the button. So something actually clicks the
button.

## Where this sits in the process

This is Phase 4, step 3 (see [`../pipeline`](../pipeline)). It runs after the typecheck and the
mandatory code reviewers, before anything is shown to a human. A feature isn't "ready to show" until a
browser has walked through it and the screenshots prove it works.

## The principle underneath

Screenshots beat adjectives. "The dashboard looks clean" is an opinion. A screenshot of the dashboard at
three widths, with the new row visible and the empty-state handled, is evidence. The whole system is
built to replace "trust me" with "here's the proof."
