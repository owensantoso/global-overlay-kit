# Architecture

Use this folder for stable architecture boundaries and subsystem invariants.

These docs should answer:

- what boundary each area owns
- which subsystem owns what
- which domain terms and lifecycle states belong to each area
- which caller-facing interfaces create important seams
- what must remain true across refactors
- where current code diverges from intended architecture

These docs should not hold:

- full current-state inventories
- implementation checklists
- session journals
- long rationale that belongs in ADRs

Put current reality in `../orientation/CURRENT_STATE.md`, execution details in plans or implementation briefs, and durable decisions in ADRs.

## Reading Order

1. `areas/AREA-MODEL.md`
2. `areas/AREA-SYNC.md`
3. `diagrams.md`

## Area Registry

Area docs use a strict mapping:

```text
AREA-ID == Markdown filename without extension
```

Examples:

```text
AREA-MODEL -> docs/architecture/areas/AREA-MODEL.md
AREA-SYNC -> docs/architecture/areas/AREA-SYNC.md
```

| Area ID | Doc | Owns |
|---|---|---|
| `AREA-MODEL` | `areas/AREA-MODEL.md` | <canonical model and data ownership> |
| `AREA-SYNC` | `areas/AREA-SYNC.md` | <sync, auth, and remote/local boundaries> |

Use area IDs in:

- plan and implementation-brief frontmatter
- session logs
- `Area:` commit trailers
- PR paper trails
- issue bodies and labels when useful

A commit, PR, issue, or plan can reference multiple areas.

## Which Doc Answers Which Question

- "<question>"
  - `areas/AREA-<NAME>.md`
- "I need the fastest visual map of how the system fits together"
  - `diagrams.md`

## Cross-Cutting Invariants

- <invariant that cuts across multiple areas>
- <invariant that cuts across multiple areas>

## Cross-Cutting Interfaces

- `<interface or seam>` - <areas involved and ownership rule>
- `<interface or seam>` - <areas involved and ownership rule>

## Known Boundary Pressure

- <current implementation mismatch or pressure point>
- <current implementation mismatch or pressure point>

Do not turn this README into the full architecture. It is the map; area docs own the vocabulary, boundaries, and interfaces.
