---
name: env-preflight
description: Environment pre-flight check before heavy work — run at the start of a session and before any expensive git/build/deploy/worktree operation. Catches the class of failures where the repo lives in a cloud-synced folder and the sync daemon deadlocks git and builds.
---

# env-preflight — check the environment BEFORE heavy work

> Mandatory pre-flight at the start of a session and before any heavy operation
> (git across the whole tree, build, creating a worktree, deploy).
>
> Origin: an incident where the repo lived inside a cloud-synced folder (iCloud /
> Dropbox / OneDrive style). The sync daemon spiked CPU trying to materialize
> "dataless" placeholder files, and git/build hung indefinitely — nearly losing
> uncommitted work.

## The core rule

Work from a **local, non-cloud-synced** working copy. A cloud-synced copy is a
backup only — never build or run git operations inside it.

Cloud-synced paths to avoid as a working directory include anything under an
iCloud "Mobile Documents" tree, `~/Documents` or `~/Desktop` when those are
synced, or a Dropbox/OneDrive/Google Drive folder.

## Pre-flight (run at the start of a session)

```bash
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"

# 1) Repo must NOT be on a cloud-synced path — otherwise STOP
case "$ROOT" in
  *"Mobile Documents"*|*"/Dropbox/"*|*"/OneDrive"*|*"Google Drive"*)
    echo "🛑 REPO ON A CLOUD-SYNCED PATH ($ROOT). Do not work here —"
    echo "   git/build will hang and risk data loss. Move to a local working copy." ;;
  *)
    echo "✅ non-synced path: $ROOT" ;;
esac

# 2) Free disk (cloud sync starts evicting files when low)
free_gb=$(df -g "$ROOT" 2>/dev/null | awk 'NR==2{print $4}')
[ "${free_gb:-999}" -lt 30 ] && echo "⚠️ low disk: ${free_gb}GB (<30). Clean up before working."

# 3) Bloat from agent worktrees (a common disk hog)
wt=$(ls "$ROOT/.worktrees" 2>/dev/null | wc -l | tr -d ' ')
[ "${wt:-0}" -gt 5 ] && echo "⚠️ $wt worktrees — prune stale ones before creating more"
```

## Rules

1. **Cloud-synced path → STOP.** Don't run heavy git/build/deploy inside a
   repo under a sync daemon. Move to a local working copy. This is a recurring
   class of incident — make it a hard barrier, not a "I'll remember".
2. **Low disk / bloated worktrees → clean up BEFORE working**, not after a crash.
3. **Don't fight the sync daemon.** If a repo is stuck in a cloud-synced folder,
   do NOT `mv`/`rsync`/`git` it out (those hang on dataless files). The reliable
   path is a fresh `git clone` from the remote into a local directory, then a
   targeted copy of untracked files. Recover uncommitted work via `git reflog`.
   Keep the cloud copy read-only as a backup until fully reconciled.
4. **Verified-Done gate.** "Done / deployed" means confirmed by fact — the
   commit is an ancestor of the remote branch and production health is green —
   not just a claim.
