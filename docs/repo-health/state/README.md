# State History

Historical snapshots of repo state.

Use this folder when a detailed state ledger is useful for archaeology but too bulky for the compact current-state doc.

## Purpose

`CURRENT_STATE.md` is the short truth page: what exists now, what is not built, major gotchas, and where to look next.

This folder is for longer historical state snapshots:

- detailed built/not-built inventories
- old milestone-status tables
- state ledgers preserved before trimming or reshaping root-level docs
- dated snapshots that explain what the repo looked like at a point in time

This folder is not a replacement for session logs, ADRs, plans, or git history.

## When To Add A Snapshot

Add a state snapshot when:

- `CURRENT_STATE.md` is being compacted and old detail should be preserved
- a major milestone changes the shape of the project enough that a dated state record is useful
- a human/agent needs a stable historical reference that should not keep growing in the root state page

Do not add a new snapshot for every small session. Use session logs for that.

## Current Snapshots

- `<snapshot path>` - <why it exists>
