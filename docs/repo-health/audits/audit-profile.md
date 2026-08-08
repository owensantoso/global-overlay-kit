# Audit Profile

Repo-local map for reusable Agent Continuity audit guides.

Keep reusable audit method in `docs/repo-health/audits/guides/`. Keep repo-specific paths, commands, exclusions, and sensitive surfaces here.

## Canonical Docs

- Agent index:
- Current state:
- Roadmap:
- Architecture:
- Specs:
- Plans:
- ADRs:
- Session logs:
- Generated views:

## Code And Config Roots

- App/source roots:
- Tests:
- Schemas/migrations:
- Persistence/sync:
- CI:
- Release/deploy:
- Dependency manifests:

## Standard Commands

Read-only checks:

```bash
agent-continuity docs check
agent-continuity docs check-links
agent-continuity docs check-todos
```

Write-mode cleanup commands, only when explicitly in scope:

```bash
agent-continuity docs update
agent-continuity docs health --write
agent-continuity docs roadmap --write
```

Test/build commands:

```bash

```

## Audit-Kind Notes

| Audit Kind | Extra Sources | Extra Commands | Notes |
|---|---|---|---|
| `roadmap-alignment` |  |  |  |
| `ontology` |  |  |  |
| `architecture` |  |  |  |
| `schema` |  |  |  |
| `security` |  |  |  |
| `privacy` |  |  |  |
| `performance` |  |  |  |
| `accessibility` |  |  |  |
| `docs-health` |  |  |  |
| `test-coverage` |  |  |  |
| `paper-trail` |  |  |  |

## Sensitive Or Excluded Surfaces

Never paste raw secrets, tokens, private keys, auth headers, raw user content, transcripts, full logs, media, provider payload dumps, or private JSONL into committed audit docs.

Local-only or sensitive paths:

- `.env*`
- logs:
- traces:
- private artifacts:
- generated dumps:

## Unavailable Tools

Record missing tools here so audits do not pretend unavailable checks passed.

-
