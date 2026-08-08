# Session Logs

Short, repo-native receipts for meaningful human/agent work sessions.

Use these when a future reader may need to reconstruct:

- what the session was trying to do
- which plans, briefs, specs, or ADRs guided it
- what product/code/docs areas changed
- when important things happened
- which commits came out of it
- what verification ran
- what follow-up debt remains

Session logs are not transcripts. Keep them brief and link outward instead of copying long chat context.

## When To Add One

Add a session log for:

- any implementation session that produces one or more commits
- a planning session that changes roadmap, plan, spec, ADR, or architecture docs
- a debugging session with important conclusions, even if no code changes land
- any AI-heavy session where the reasoning would otherwise live only in chat

Skip a session log for tiny typo fixes, mechanical formatting, or work already captured fully in a commit body.

## Naming

Use:

```text
YYYY-MM-DD-<short-slug>.md
```

## Required Shape

Start from the nearby `YYYY-MM-DD-session-title.md` example.

New session logs should start with YAML frontmatter:

- `type: session-log`
- `status`: `in_progress`, `completed`, or `archived`
- `created_at`, `updated_at`, `started_at`, and `ended_at`
- `timezone`
- `participants`
- `areas`
- `related_plans`, `related_briefs`, `related_specs`, `related_adrs`
- `commits`

Keep the main body sections:

- Session metadata
- Goal
- Timeline
- Context read
- Changes
- Decisions
- Verification
- Follow-ups

## Timestamps

Record exact local timestamps for session start/end when known, plus a short timeline of meaningful actions.

Use this format:

```text
YYYY-MM-DD HH:MM:SS TZ +0000
```

If an exact earlier timestamp is not known, write `unknown` rather than inventing one.

## Commit Trailers

For meaningful commits, add searchable trailers in the commit body:

```text
Plan: <plan path>
Brief: <brief path>
Spec: <spec path>
ADR: <adr path>
Todo: TODO-####
Session: <session log path>
Area: <area>
Verification: <commands/checks>
```
