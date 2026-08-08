---
type: docs-index
title: Diagnostic Records
status: ready
created_at: "YYYY-MM-DD HH:MM:SS TZ +0000"
updated_at: "YYYY-MM-DD HH:MM:SS TZ +0000"
---

# Diagnostic Records

Use `DIAG-*` diagnostic records for significant real-run investigations where structured evidence should outlive chat history.

A diagnostic record is not the raw trace itself. The doc preserves the symptom, run context, evidence summary, key events, current theory/root cause, and cleanup plan. JSONL traces, OS logs, screenshots, and payload captures live under the artifact root and are committed only when sanitized.

Create new diagnostic records with:

```bash
agent-continuity docs new diag "<Title>" --domain <domain>
```

## Artifact Shape

```text
artifacts/diagnostics/DIAG-####/
  run-YYYYMMDD-HHMMSS-zone/
    trace.jsonl
    notes.md
```

The default `artifacts/diagnostics/` root is git-ignored. Force-add only reviewed sanitized artifacts.

Prefer event records with both wall-clock time and monotonic elapsed time:

```json
{"schema_version":1,"seq":42,"ts":"2026-04-27T10:30:15.123+09:00","elapsed_ms":1284.52,"diag_id":"DIAG-0001","run_id":"run-20260427-103015-jst","span_id":"span-003","parent_span_id":"span-001","operation":"transcribe_attachment","event":"request.started","event_kind":"start","component":"VoiceTranscription","outcome":"ok","redaction":{"classification":"private","contains_raw_user_content":false,"safe_to_commit":false},"attrs":{"attempt":1}}
```

Do not put raw `prompt`, `response`, `transcript`, `note_text`, `audio_path`, auth headers, URL query strings, location, email, health data, or full provider payloads in trace events. Prefer sizes, content types, hashes, status codes, and error domains.

## Layout

- [templates/diagnostic-record-template.md](templates/diagnostic-record-template.md) - template for `DIAG-*` records.
