---
name: runpod-force-recycle
description: After a template update (imageName / env vars) on a RunPod serverless endpoint, ALWAYS force-recycle warm workers via a `workersMax 0→N` cycle. Activates on a docker image change, ENV var change, or any deploy that must pick up new workers. RunPod does NOT kill warm workers automatically after a template change — old workers keep serving requests with the old image/env until they idle out.
triggers:
  - "runpod deploy"
  - "recycle workers"
  - "warm workers stale image"
  - "serverless template update"
---

# RunPod Force Recycle Workers

RunPod serverless endpoint behavior:
- **Cold start** — pull image from registry → create worker → init → process job
- **Warm pool** — a worker stays alive N minutes after a job for re-use (default 5 min idle)
- **Template update** — does NOT kill warm workers, only changes config for the **next cold start**

This means that after `saveTemplate(imageName=:new_tag)` the warm workers keep using
the **old** image until one of:
1. Idle timeout (natural exit)
2. Worker crash/restart
3. Manual recycle

## When to Activate

MANDATORY AFTER:
- A `saveTemplate` mutation (new imageName)
- Changing `env` in the template
- Pushing a new image under the same `:latest` tag
- Any deploy that requires "new code in the worker"

## The Recipe

### GraphQL mutation for a workersMax cycle

```bash
ENDPOINT_ID="YOUR_ENDPOINT_ID"  # from the RunPod dashboard or an endpoints query

# Step 1: workerCount=0 — kill all warm workers
curl -s -X POST "https://api.runpod.io/graphql" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $RUNPOD_API_KEY" \
  -d "{\"query\":\"mutation { updateEndpointWorkersMax(input: {endpointId: \\\"$ENDPOINT_ID\\\", workerCount: 0}) { id workersMax } }\"}"

# Step 2: wait 15-30s for workers to terminate (RunPod gracefully drains in-flight jobs)
sleep 20

# Step 3: workerCount back to the original max (e.g. 3)
curl -s -X POST "https://api.runpod.io/graphql" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $RUNPOD_API_KEY" \
  -d "{\"query\":\"mutation { updateEndpointWorkersMax(input: {endpointId: \\\"$ENDPOINT_ID\\\", workerCount: 3}) { id workersMax } }\"}"
```

**Important:** the input field is called `workerCount`, not `workersMax` — a quirk of RunPod's GraphQL schema.

## When It's Not Needed

- Nothing changed in the template (config is identical)
- Endpoint has been idle >10 min (workers already died naturally)
- Nothing to pull (same image)

## Script Wrapper

```bash
#!/bin/bash
set -euo pipefail
ENDPOINT_ID="${1:?endpoint id required}"
MAX_WORKERS="${2:-3}"
DRAIN_SEC="${3:-20}"

# Set workerCount=0
curl -sf -X POST "https://api.runpod.io/graphql" \
  -H "Authorization: Bearer $RUNPOD_API_KEY" \
  -d "{\"query\":\"mutation { updateEndpointWorkersMax(input: {endpointId: \\\"$ENDPOINT_ID\\\", workerCount: 0}) { id workersMax } }\"}" \
  > /dev/null

echo "Workers killed, draining ${DRAIN_SEC}s..."
sleep "$DRAIN_SEC"

# Restore workerCount
curl -sf -X POST "https://api.runpod.io/graphql" \
  -H "Authorization: Bearer $RUNPOD_API_KEY" \
  -d "{\"query\":\"mutation { updateEndpointWorkersMax(input: {endpointId: \\\"$ENDPOINT_ID\\\", workerCount: $MAX_WORKERS}) { id workersMax } }\"}" \
  > /dev/null

echo "Recycled. Next job will be a cold start with the current template."
```

## Incident Reconstruction

```
07:49: docker push <private image>:latest → success
07:50: saveTemplate(imageName=:latest) → success
07:51: job PENDING → worker pickup
07:51: RunPod runId → warm worker (OLD image!)
                  → instant fail: job error
07:53: retry → same warm worker → same fail (×3)
07:56: workersMax 0→3 cycle via GraphQL
07:59: job retry → cold start (new image) → SUCCESS
```

Without the recycle we would have waited for the idle timeout (hours or days) for
the warm workers to die on their own.

## Alternatives

- **`workersMin=0`** as a permanent setting — disables the warm pool entirely.
  Every job = cold start. Worse for latency, but deploy-friendly.
- **CI-driven deploy** with an automatic recycle step in the pipeline.
- **Container digest pinning** in the template instead of a tag — but that fights
  a rolling-deploy approach (you must change the template on every push).
