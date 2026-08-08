# Security Audit Guide

## Use When

- Auth, authorization, secret handling, dependencies, logging, or external integrations need review.
- A feature changes access boundaries or handles sensitive operations.
- Preparing for public release or wider testing.

## Inputs

- Auth and authorization docs.
- Environment variable and secret handling.
- Dependency manifests and lockfiles.
- Network clients, server endpoints, policies, and storage rules.
- Logs, diagnostics, AI payload capture, and release checklists.

## Core Questions

- Who can access what?
- Where are secrets stored, loaded, logged, or transmitted?
- Are authorization checks enforced server-side where needed?
- Are dependencies and external services trusted intentionally?
- Could diagnostic or audit artifacts leak sensitive data?

## Checks

Start with location-only searches. Do not print secret values into terminal output that might be copied into audit notes.

```bash
rg -n -l "api[_-]?key|secret|token|password|private|auth|bearer" .
```

Add platform-specific security checks for the target repo.

When a match may contain a live secret, report only file path, line number when safe, secret class, and mitigation. Never paste secret values, bearer tokens, private keys, auth headers, or raw request/response payloads into committed audit docs.

## Finding Categories

- secret exposure
- missing authorization check
- unsafe logging
- risky dependency
- insecure transport/storage
- ambiguous trust boundary

## Routing Guidance

| Finding Looks Like | Route To |
|---|---|
| Confirmed bug or exposure | sanitized `DIAG` plus immediate fix |
| Needs durable security decision | `ADR` |
| Needs requirement | `SPEC` |
| Needs implementation | `PLAN` / `IMPL` |
| Needs external/security research | `RSCH` |
| Low risk accepted knowingly | `Status` = `accepted-risk`, `Route` = `none` |

## Done When

- High-severity findings have an owner or immediate mitigation.
- Sensitive evidence is summarized or sanitized before committing.

For live secret exposure: stop copying evidence, revoke or rotate the secret, remove it from staging/history if applicable, document only redacted class/location, and keep raw artifacts local-only.
