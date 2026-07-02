---
name: ios-live-activity
description: iOS Live Activity (ActivityKit) for an in-progress recording indicator on the Lock Screen + Dynamic Island. Covers the single-configuration concept, keeping sensitive data off the lock screen, and a set of hard-won build/testing gotchas.
triggers:
  - "Live Activity"
  - "Dynamic Island"
  - "ActivityKit"
  - "lock screen widget"
  - "recording indicator"
---

# iOS Live Activity (ActivityKit)

A Live Activity shows a live, in-progress status (e.g. an active recording) on the locked screen and in the Dynamic Island. Read this before touching your widget extension or the activity attributes / controller types.

## Concept (don't confuse the two surfaces)

A Live Activity is **one** ActivityKit activity that the system renders in **two** places:

1. **Lock Screen** — a banner card at the bottom of the locked screen.
2. **Dynamic Island** — the capsule at the top (compact / expanded / minimal).

They are not built separately: a single `ActivityConfiguration { lockScreenView } dynamicIsland { … }` produces both surfaces. It is never "the island OR the lock screen" — it is one and the same activity.

## Keep sensitive data off the lock screen

The Lock Screen and Dynamic Island are visible without unlocking the device. Show only non-sensitive content there: an anonymized status label + a timer + a progress percentage. Do **not** put user names, identifiers, or any private/regulated content into the activity attributes.

A practical pattern: pass only an opaque identifier (e.g. a UUID) into the activity attributes and never render it. Keep any human-readable, sensitive fields in the app's in-memory coordinator and never hand them to the Live Activity. When the domain is regulated (health, finance, etc.), have a compliance reviewer confirm no new field has leaked sensitive data onto the lock screen.

## Brand / styling notes

- The widget extension target **cannot see the app's design system** — app-target color/type definitions are not visible to the extension. Duplicate the palette as hex literals in the widget file and keep it 1:1 with the app's color definitions.
- Follow the platform convention for status colors. For a recording indicator, use the system norm of **red = recording in progress** rather than a brand accent — users read "recording" in half a second. Reserve brand colors for secondary states (e.g. uploading, paused).
- Distinguish states by **glyph**, not just hue (e.g. an audio-issue state uses the recording color plus a warning triangle so it reads differently from the normal recording state).
- Confirm the deployment target: iOS 17 / Swift 5.9 projects do **not** have iOS 26 APIs (e.g. `glassEffect` / Liquid Glass).

## Gotchas (each cost a cycle)

1. **"e"-class models (e.g. 16e/17e) physically have no Dynamic Island.** On such a simulator you only see the Lock-Screen banner. To accept the island you need a Pro simulator or device. Don't promise stakeholders "you'll see the island" on a non-Pro device.
2. **`NSSupportsLiveActivities=true` is required in the *app's* Info.plist** (not the widget's). Without it the activity silently never appears. Verify it in the **built bundle**, not just in your project config:
   ```bash
   plutil -extract NSSupportsLiveActivities raw "$APP/Info.plist"
   ```
3. **Flaky `xcodebuild` "type does not conform to protocol" errors with no notes** are often a spurious cascade — a type in a signature failed to compile in a parallel compilation unit (especially when another process is writing to the same folder). Fix with `xcodebuild clean build`. Don't chase a phantom conformance error; do a clean build and re-check.
4. **The activity controller is best-effort and must NEVER block or crash the recording.** `start` should gate on `ActivityAuthorizationInfo().areActivitiesEnabled` and swallow throws. Every exit path of the recording (cancel / finalize / error / timeout) MUST call `.end()` — otherwise the banner "hangs" (leaks on error paths and on polling timeouts are a classic bug here).
5. **Timer without push:** `Text(timerInterval: startedAt...Date.distantFuture, countsDown: false)` — the system ticks it for you; the app does NOT need to push an update every second.

## Testing on the simulator

- **After any iOS change, rebuild and reinstall on the simulator proactively**, otherwise stakeholders test a stale build:
  ```bash
  xcodebuild clean build -project App.xcodeproj -scheme App \
    -destination 'platform=iOS Simulator,id=<UDID>' -derivedDataPath ./.build-fresh
  APP=$(find ./.build-fresh/Build/Products -name App.app -type d | head -1)
  xcrun simctl terminate <UDID> <bundle-id>; xcrun simctl install <UDID> "$APP"; xcrun simctl launch <UDID> <bundle-id>
  ```
- **Never `simctl uninstall` between rebuilds** — it wipes locally persisted app state (drafts, cached user data). Use `terminate + install + launch` only.
- For a Live Activity to actually appear you need the triggering condition to be active (e.g. an in-progress recording). It won't show in an idle state.
- The simulator is unreliable for final visual acceptance of the Dynamic Island — final sign-off should be on a real Pro device.

## Reviewer Gate

For any change to the widget or the activity attributes contract, require both a Swift API/exhaustiveness/no-crash review and — for regulated domains — a compliance review that no sensitive data reaches the lock screen.
