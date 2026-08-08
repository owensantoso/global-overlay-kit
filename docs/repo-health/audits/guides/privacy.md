# Privacy Audit Guide

## Use When

- The repo handles personal, sensitive, health, location, audio, image, or behavioral data.
- AI prompts/responses, logs, exports, retention, or deletion flows need review.
- Preparing for public release, beta, or app review.

## Inputs

- Data inventory and privacy docs.
- Persistence/schema docs.
- AI/LLM prompt and response logging.
- Diagnostic and evaluation artifact rules.
- Export/delete/account lifecycle docs.
- Product specs involving user data.

Commit summaries and sanitized excerpts only. Keep raw private JSONL, prompts, responses, transcripts, media, health/location/audio/image data, provider payload dumps, and user content local unless explicitly sanitized.

## Core Questions

- What personal data exists, and where does it live?
- What data leaves the device or repo boundary?
- What is retained, for how long, and why?
- Can users export/delete data where expected?
- Are AI payloads and logs safe to store or commit?

## Checks

Start with searches that identify candidate locations. Avoid printing raw private content into audit notes.

```bash
rg -n -l "privacy|personal|retention|delete|export|consent|prompt|transcript|location|health|audio|image" docs src .
```

Adjust paths for the target repo.

## Finding Categories

- missing data inventory
- unclear retention
- unsafe artifact storage
- missing consent/notice
- export/delete gap
- AI payload privacy risk

## Routing Guidance

| Finding Looks Like | Route To |
|---|---|
| Need privacy behavior contract | `SPEC` |
| Need durable retention decision | `ADR` |
| Need implementation | `PLAN` / `IMPL` |
| Need investigate actual captured artifacts | sanitized `DIAG` |
| Need policy/platform research | `RSCH` |

## Done When

- Sensitive evidence is not committed raw.
- Each privacy risk has a route, reasoned deferral, or accepted-risk entry.

For sensitive artifacts, record local-only paths and sanitized summaries rather than raw payloads.
