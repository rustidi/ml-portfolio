#!/bin/bash
# =============================================================
# verify-reviewer-gate.sh  —  the machine gate
#
# What it does: looks at which files changed since the last deploy, works out
# which specialist reviewers are MANDATORY for that blast radius, and checks the
# current sprint file for a PASS verdict from each one. If any is missing, it
# exits non-zero and BLOCKS the deploy.
#
# Why it exists: for a long time, review was "by text" and optional. Typecheck
# was green, so code shipped — and then production bugs appeared that a reviewer
# would have caught. This turns "please review auth carefully" into "the deploy
# will not run until auth is reviewed."
#
# It runs as Step 0 of the deploy script, before push/build.
#
# Explicit, logged escape hatch: REVIEWER_GATE_BYPASS=1 (use with your name on it).
#
# This is a sanitized version. Real reviewer names and paths are generalized.
# =============================================================
set -u

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

if [ "${REVIEWER_GATE_BYPASS:-0}" = "1" ]; then
  echo -e "${YELLOW}[gate] BYPASS=1 — gate skipped, explicitly, on your responsibility.${NC}" >&2
  exit 0
fi

# --- 1. What changed since the last successful deploy ---
# SCOPE_KNOWN=0 means we couldn't determine scope. In that case an empty change
# list must NOT be read as "no risk" — we fail closed (see below).
MARKER=".deploy-state/last-deploy-sha"
SCOPE_KNOWN=1
if [ -f "$MARKER" ] && git cat-file -e "$(cat "$MARKER" 2>/dev/null)^{commit}" 2>/dev/null; then
  CHANGED=$(git diff --name-only "$(cat "$MARKER")" HEAD 2>/dev/null)
else
  CHANGED=$(git diff --name-only HEAD~5 HEAD 2>/dev/null || true)
  [ -z "$CHANGED" ] && SCOPE_KNOWN=0
fi

# --- 2. Map risky paths -> mandatory reviewers (mirrors the trigger table) ---
# Over-matching is safe: an extra requirement just means adding one CLEAR line.
require=""
add_req() { case " $require " in *" $1 "*) ;; *) require="$require $1" ;; esac; }

while IFS= read -r f; do
  [ -z "$f" ] && continue
  case "$f" in
    *modules/auth/*|*/payments/*)  add_req security-reviewer; add_req silent-failure-hunter ;;
  esac
  case "$f" in
    *[Aa]uth*|*[Ll]ogin*|*[Rr]efresh*|*[Ss]ession*|*[Uu]nlock*|*[Tt]oken*) add_req auth-flow-reviewer ;;
  esac
  case "$f" in
    *modules/records/*|*modules/patients/*|*/medical/*) add_req healthcare-reviewer; add_req silent-failure-hunter ;;
  esac
  case "$f" in *.swift)                    add_req swift-reviewer ;; esac
  case "$f" in *android*/*.kt)             add_req kotlin-reviewer ;; esac
  case "$f" in *schema.prisma|*/migrations/*) add_req database-reviewer ;; esac
  case "$f" in workers/*)                  add_req silent-failure-hunter ;; esac
  case "$f" in *payments*|*billing*|*pricing*) add_req money-math-invariants ;; esac
done <<< "$CHANGED"

require="$(echo "$require" | xargs 2>/dev/null)"

if [ -z "$require" ]; then
  if [ "$SCOPE_KNOWN" = "0" ]; then
    # FAIL CLOSED: scope unknown, so an empty requirement set can't be trusted.
    echo -e "${RED}[gate] BLOCK: deploy scope could not be determined (no marker, no HEAD~5).${NC}" >&2
    echo -e "${YELLOW}  First deploy on this machine? Review manually, then: REVIEWER_GATE_BYPASS=1 ./deploy.sh${NC}" >&2
    exit 2
  fi
  echo -e "${GREEN}[gate] the changed scope needs no mandatory reviewers.${NC}"
  exit 0
fi

# --- 3. The current sprint file ---
SPRINT_FILE="$(ls -t docs/sprints/*SPRINT_*.md 2>/dev/null | head -1)"
if [ -z "$SPRINT_FILE" ] || [ ! -f "$SPRINT_FILE" ]; then
  echo -e "${RED}[gate] BLOCK: scope needs reviewers ($require) but no sprint file was found.${NC}" >&2
  exit 2
fi

# --- 4. Check for a PASS verdict per required reviewer ---
PASS_RE='CLEAR|SAFE|APPROVE|APPROVED|PASS|FIXED|RESOLVED'
missing=""
for r in $require; do
  # a line mentioning the reviewer (as a literal, not a regex) AND a pass token
  if grep -iF -- "$r" "$SPRINT_FILE" 2>/dev/null | grep -qiE "$PASS_RE"; then
    :
  else
    missing="$missing $r"
  fi
done
missing="$(echo "$missing" | xargs 2>/dev/null)"

if [ -n "$missing" ]; then
  echo -e "${RED}[gate] DEPLOY BLOCKED.${NC}" >&2
  echo -e "${RED}  The changed scope needs review, but ${SPRINT_FILE} has no PASS verdict from:${NC}" >&2
  for m in $missing; do echo -e "${RED}    - $m${NC}" >&2; done
  echo -e "${YELLOW}  Run those reviewers and add to the sprint's 'Reviewer-gate' section a line like:${NC}" >&2
  echo -e "${YELLOW}    - <reviewer>: CLEAR — short summary${NC}" >&2
  exit 2
fi

echo -e "${GREEN}[gate] all mandatory reviewers have a PASS verdict: $require${NC}"
exit 0
