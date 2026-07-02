---
name: deploy
description: Deploy the whole platform to all servers with one command. Activates on "deploy", "ship", "release", or at the end of a sprint.
triggers: ["deploy", "ship", "release", "push to prod"]
applies_to: ["scripts/deploy-all.sh"]
---

# Deploy

> Sanitized example skill. Real hostnames, IPs, and provider names are replaced with placeholders.
> The sequence, the health checks, and the hard-won lessons are verbatim.

## One command — all servers

```bash
./scripts/deploy-all.sh
```

The script does **everything**, in this order:

1. `git push origin main`
2. Typecheck every workspace
3. Build the web app with production env vars
4. Trigger the API deploy (managed host; migrations run remotely via a prestart hook)
5. Rsync + zero-downtime process reload on the web VPS
6. Build + deploy the edge workers (international traffic)
7. Health checks on every key URL
8. A final ✅/❌ report per server

## Why one command

Manual multi-server deploys drift: you push the API but forget the edge worker, or you deploy the web
build against last week's API schema. A single script makes the order **non-negotiable** and the
health checks **mandatory**. The deploy is either green on every target or it's not done.

## Deploy order matters

The API must deploy **before** any client that pins to its schema. The script enforces this so a
client can never ship against an API that doesn't yet have the migration it depends on.

## The gate runs first

Step 0 of the deploy is the **reviewer gate** (see `../pipeline/`). It inspects the changed files and
refuses to deploy (exit 2) if the mandatory specialist review for that blast radius isn't recorded in
the current sprint file. You cannot ship auth changes without the auth reviewer's sign-off. This is
enforced in the script, not left to memory.

## What breaks — and how to avoid it (the war-story section)

- **A restart does NOT apply a rotated secret.** Restarting the container re-runs the process but does
  *not* re-read environment variables on this host. After rotating a key you must do a **full
  redeploy**, or the app keeps signing requests with the dead credential and every call 401s. This
  cost a real incident: rotated the object-storage key, restarted, and audio playback broke because
  the app was still presenting the old key. Verify a rotation **end-to-end** (mint a token → hit the
  real resource → confirm 200), never by dumping the env var.
- **Two deploys against the same branch race each other** and produce false ❌ in the report (one
  target's auto-deploy webhook collides with the script's explicit trigger). If production is actually
  healthy, don't re-deploy blindly — confirm with a manual health check first.
- **Don't deploy the web app from a git worktree** — the standalone build resolves workspace deps
  differently there and ships a subtly broken bundle. Deploy web from a clean main checkout.

## Definition of done

The sprint is **not closed** until the changelog is updated *and* the script reports ✅ on every
server. "It should be live" is not done. A green health check on the real URL is done.
