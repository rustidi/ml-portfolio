---
name: playwright-browser
description: Browser automation for an AI agent — navigation, clicks, typing, screenshots, console/network inspection. Model-invoked: the agent decides when to drive Playwright and what to do with it. Uses the Playwright MCP. Triggers — "screenshot this page", "walk this user flow", "check that the button works", "what's in the console", "behavioral test".
origin: Adapted from lackeyjb/playwright-skill + the official Playwright MCP
metadata:
  tags: browser, playwright, qa, e2e, screenshot, mcp
  requires: Playwright MCP server installed
---

# Playwright Browser Automation

This skill gives the agent access to a real browser via the Playwright MCP. Not a "simulation" — a real Chromium that clicks, types, scrolls, and takes screenshots.

## When to Activate

- "Screenshot /pricing", "open /admin and show me what you see", "check this page"
- Validating that the frontend rendered correctly after a change
- E2E verification of a user flow before a production deploy
- Catching a runtime error on a page (console / network panel)
- A design-review pass needs a real browser for screenshot evidence

## Available Tools (via MCP)

| Tool | Description |
|---|---|
| `mcp__playwright__browser_navigate` | Go to a URL |
| `mcp__playwright__browser_navigate_back/forward` | History |
| `mcp__playwright__browser_resize` | Change viewport (375 / 768 / 1024 / 1440) |
| `mcp__playwright__browser_click` | Click an element (ref from snapshot) |
| `mcp__playwright__browser_type` | Type into an input |
| `mcp__playwright__browser_hover` | Hover to trigger hover states |
| `mcp__playwright__browser_press_key` | Press a key (Tab, Enter, Escape) |
| `mcp__playwright__browser_select_option` | Select an option in a select |
| `mcp__playwright__browser_file_upload` | Upload a file into input[type=file] |
| `mcp__playwright__browser_drag` | Drag-and-drop |
| `mcp__playwright__browser_take_screenshot` | Snapshot (full page or element) |
| `mcp__playwright__browser_snapshot` | DOM snapshot (accessibility tree) — required before a click to get element refs |
| `mcp__playwright__browser_console_messages` | Read console errors/warnings |
| `mcp__playwright__browser_network_requests` | Network requests (404, CORS, slow API) |
| `mcp__playwright__browser_evaluate` | Run arbitrary JS in the page context |
| `mcp__playwright__browser_wait_for` | Wait for a condition (text appears, element visible) |
| `mcp__playwright__browser_tab_new/select/close/list` | Tab management |
| `mcp__playwright__browser_handle_dialog` | Accept/dismiss alert/confirm |
| `mcp__playwright__browser_install` | Install the browser if not present |

## Core Workflow

### 1. Snapshot before interaction

ALWAYS start with `browser_snapshot` — you get the accessibility tree with element refs. Click/type by ref, not by selector.

### 2. Resize for viewport testing

Before a screenshot, make sure you're in the right viewport. Default 1440x900, for mobile 375x667.

### 3. Verify before screenshot

After a click — `browser_wait_for` (text appears) or `browser_console_messages` (no errors), then screenshot. Otherwise you may capture a loading state.

### 4. Console + network — mandatory

On any bug, first thing — `browser_console_messages` and `browser_network_requests`. 80% of bugs are visible there.

## Patterns

### Pattern 1: "Screenshot page X on three viewports"

```
1. browser_navigate(url)
2. browser_wait_for(text="Some content that means page loaded")
3. browser_resize(1440, 900) → browser_take_screenshot
4. browser_resize(768, 1024) → browser_take_screenshot
5. browser_resize(375, 667) → browser_take_screenshot
```

### Pattern 2: "Walk a user flow and report errors"

```
1. browser_navigate(start_url)
2. browser_snapshot → find the CTA, get the ref
3. browser_click(ref) → browser_wait_for(next state)
4. browser_console_messages → check for errors
5. browser_network_requests → check for 4xx/5xx
6. Continue flow, report findings
```

### Pattern 3: "Visual regression — before/after"

```
1. browser_navigate(baseline_url) → screenshot_a
2. browser_navigate(new_url) → screenshot_b
3. Report visual differences observable to the human eye
   (for pixel precision you need additional tooling; the MCP does not diff on its own)
```

## Environment URLs

Keep a small table of the pages you drive most, e.g.:

| What | Local URL | Prod URL |
|---|---|---|
| Web app | `http://localhost:3000` | `https://<your-web-domain>` |
| API | `http://localhost:3001` | `https://<your-api-domain>` |
| Admin | `http://localhost:3000/admin` | `https://<your-web-domain>/admin` |
| Pricing | `http://localhost:3000/pricing` | `https://<your-web-domain>/pricing` |

Start the web dev server on `:3000` and the API on `:3001` (adjust to your project).

## Anti-Patterns

| Don't | Do |
|---|---|
| Click `selector: ".button"` without a snapshot | `browser_snapshot` first, get the ref |
| Screenshot immediately after a click | `browser_wait_for` in between |
| Ignore the console during review | `browser_console_messages` is mandatory |
| Screenshot desktop only | 3 viewports minimum for UI review |
| Run against prod without a reason | Default — localhost dev server |
| Close the browser after first use | `browser_tab_list` shows what's open; prefer reusing a tab |

## Integration

| Skill / Agent | Relationship |
|---|---|
| design-review | Uses this skill for all visual evidence |
| QA agent | Uses it for evidence-required verdicts |
| e2e-testing skill | For writing Playwright tests under `*.spec.ts` |
| verification-loop | For iterative UI verification after fixes |
