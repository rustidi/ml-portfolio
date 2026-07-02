---
name: security-review
description: Security checklist for auth, uploads, object storage, local config, and API boundaries.
---

# Security Review

Use this skill for API, auth, upload, storage, local config, and external integration work.

## High-Risk Surfaces

- JWT auth and current-user flows
- presigned upload orchestration
- object storage keys and bucket access
- local client config and token persistence
- file paths, staging directories, and cleanup logic
- external API and webhook integrations

## Mandatory Checks

- no hardcoded secrets
- input validation at boundaries
- authorization checks on protected routes
- no trust in client-provided price, object key, or upload-complete state
- no unsafe file-path joins from user-controlled values
- errors do not leak secrets or internals

## Upload and Storage Checklist

- backend remains source of truth for object keys
- multipart lifecycle is validated server-side
- signed URLs are scoped and time-limited
- upload completion checks part metadata before finalization
- abort paths clean up server-side state safely

## Local Client Checklist

- secrets and tokens stored intentionally, not ad hoc
- no broad filesystem writes without a clear base directory
- local state is resumable and recoverable after failure

## Verification

- inspect changed auth and storage code directly
- review env var usage
- run relevant verification commands before closing
