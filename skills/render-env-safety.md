---
name: env-vars-replace-safety
description: Protection against accidentally wiping production secrets when a hosting platform's bulk env-vars endpoint uses REPLACE (not MERGE) semantics. Activates BEFORE any change to environment variables on a managed host. Covers a per-key PATCH protocol + a diff between the host and your local env file + capturing host-only secrets locally.
triggers:
  - "env vars"
  - "production secrets"
  - "feature flag"
  - "rotate key"
---

# Env-Vars REPLACE Safety

Some managed hosting platforms expose a bulk env-vars endpoint —
`PUT /v1/services/{id}/env-vars` — whose semantics are **REPLACE, not MERGE**.
It wipes every key that is not present in the payload. This semantics killed
production twice:

- **Incident 1:** a monitoring rollout did a bulk PUT with 5 new keys and wiped
  30+ existing secrets (API keys, auth secrets, cache URLs, mail keys, storage
  credentials, and more). Five deploys in a row failed on `update_failed`. An
  hour of debugging + recovery via a preserve-all PUT rebuilt from the local env file.
- **Incident 2:** the tail of Incident 1 — a bucket-name key existed on the host
  manually but was never mirrored into the local env file. The bulk wipe removed it;
  the restore from the local file could not bring it back (it was never there).
  Avatars 404'd in production until it was noticed.

This skill is a hard guard against a third time.

## When to Activate

**ALWAYS**, BEFORE any of these actions:

- `curl -X PUT .../services/{id}/env-vars` (bulk endpoint) — **forbidden**, see below
- `curl -X PUT .../services/{id}/env-vars/{KEY}` (single-key, safe) — needs a diff-check first
- Running any env-update script
- Any ad-hoc Python/Node script that mutates host env via API
- Restoring env after an ops incident
- Adding new secrets for a new service (monitoring, etc.)

## Hard Rules

### Rule 1: Per-key PATCH only

```bash
# ✅ OK — per-key PATCH
curl -X PUT \
  -H "Authorization: Bearer $HOST_API_KEY" \
  -H "Content-Type: application/json" \
  "$HOST_API/services/$SVC/env-vars/MY_NEW_KEY" \
  -d '{"value":"my-value"}'
```

```bash
# ❌ NEVER — bulk PUT (REPLACE semantics)
curl -X PUT \
  "$HOST_API/services/$SVC/env-vars" \
  -d '[{"key":"NEW_KEY","value":"v"}]'
```

Your env-update script should already use per-key. If you are about to propose an
alternative approach — **stop and use per-key.**

### Rule 2: Diff host vs local env file BEFORE any env-write

This catches "host-only secrets" (keys added manually in the host dashboard but
never synced into the local env file):

```bash
# 1. Pull the list of keys from the host
curl -s -H "Authorization: Bearer $HOST_API_KEY" \
  "$HOST_API/services/$SVC/env-vars?limit=100" \
  | python3 -c "import sys,json; [print(e['envVar']['key']) for e in json.load(sys.stdin)]" \
  | sort > /tmp/host-keys.txt

# 2. Pull the list of keys from the local env file
grep -E "^[A-Z_][A-Z0-9_]*=" .env.local | cut -d= -f1 | sort > /tmp/local-keys.txt

# 3. Diff — which host keys are missing locally (host-only)
comm -23 /tmp/host-keys.txt /tmp/local-keys.txt
```

**If the diff is non-empty → STOP.** For each host-only key:

a) Pull its value via API:
```bash
curl -s -H "Authorization: Bearer $HOST_API_KEY" \
  "$HOST_API/services/$SVC/env-vars" \
  | python3 -c "import sys,json,os; key=os.environ['K']; \
    [print(f\"{e['envVar']['key']}={e['envVar']['value']}\") \
     for e in json.load(sys.stdin) if e['envVar']['key']==key]" \
  K=A_BUCKET_NAME
```

b) Add it to the local env file (with a descriptive comment — origin, who first
   added it, and what it is for).

c) Log it (date, key, reason for the sync).

**Only then** perform your new env operation.

### Rule 3: No guessing on default values

If code has `process.env.X ?? "default-value"` — **the default is not a security
boundary.** Production must have an explicitly set value. If the default fires,
that is a bug (e.g. a bucket-name fallback to a bucket that does not exist).

When creating new env-dependent code:
- Add it to `.env.local.example` with a comment about the default
- Log it explicitly

## Pre-flight Checklist

BEFORE any env operation on the host — run through:

- [ ] Using per-key PATCH (not bulk PUT)
- [ ] Ran a diff of host keys vs local env keys
- [ ] All host-only secrets pulled into the local env file + commented (origin)
- [ ] Env-change log updated
- [ ] Explicit commit message: "what env var changed, on what service, why"

If even one item is open — **STOP.**

## Recovery if Already Wiped

If you already did a bulk PUT and realize you wiped secrets:

1. **IMMEDIATELY** pull the diff from the git history of the local env file — which keys existed there.
2. Use your per-key env-update script to restore from the local env file.
3. Diff host keys vs local keys — you will find host-only keys that were lost.
   These **will not come back from the local file**; restore them by hand (from
   memory, chat, or logs).
4. Record the incident with lessons learned.
