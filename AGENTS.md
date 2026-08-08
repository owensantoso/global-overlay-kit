# GlobalOverlayKit - Agent Index

GlobalOverlayKit is a macOS Swift package for hosting arbitrary native content
in transparent, cross-application overlay surfaces. It owns window mechanics,
not the product rendered inside them.

## Start here

1. `./run` - build, test, and documentation commands.
2. `docs/orientation/CURRENT_STATE.md` - what is actually built today.
3. `docs/orientation/ONBOARDING.md` - package and contributor walkthrough.
4. `docs/orientation/ARCHITECTURE.md` - boundaries and intended module shape.
5. `docs/orientation/ROADMAP.md` - evidence-first sequencing.
6. `docs/product/specs/` - durable package requirements.
7. `docs/product/plans/` - parent plans and bounded implementation briefs.
8. `docs/repo-health/testing-guide.md` - verification and evidence limits.
9. `docs/repo-health/codebase-map.md` - source entry points.
10. `docs/research/` - prior art and source-backed investigations.

## Non-negotiable boundaries

- Keep the public abstraction renderer-neutral and AppKit-based.
- SwiftUI is a convenience adapter; it is not the only supported content path.
- The package does not own chat messages, agents, TTS, STT, physics, render
  loops, game entities, global keyboard capture, or product persistence.
- One `GlobalOverlay` instance owns one native overlay surface. Product-level
  multi-window and multi-display coordination remains caller-owned until two
  real consumers prove a shared seam.
- Do not copy overlay code from Agent Commander, Live Text Chat, or third-party
  projects. Implement from public Apple APIs and record provenance.
- Treat "global" as cross-application presentation, not permission to obscure
  secure system surfaces or bypass macOS security boundaries.
- Click-through, activation, and global keyboard input are separate concerns.
- Essential interactive controls must have a visible, keyboard-reachable
  recovery path; never create an unrecoverable click-through surface.

## Documentation rules

- Use the complete Agent Continuity scaffold already installed in this repo.
- Read `CURRENT_STATE.md` before editing; intended architecture is not proof.
- Capture future ideas as `IDEA-*`, durable concepts as `CONC-*`, decisions as
  `ADR-*`, research as `RSCH-*`, and meaningful sessions as timestamped logs.
- Parent `PLAN-*` documents own intent and scope. `IMPL-*` briefs own bounded
  execution detail and must be read with their parent plan.
- Use `scripts/agent-continuity-docs` for IDs, generated views, and link checks.
- Do not hand-edit generated root views such as `docs/SPECS.md`.

## Change discipline

- Prefer the smallest surface that proves a real consumer need.
- Do not add renderer-specific hooks to the window substrate without evidence.
- Keep framework details behind a small caller-facing API.
- Preserve clean-room provenance and MIT compatibility for every contribution.
- Run `./run check` before meaningful closeout or commit.
- Keep automated, visual, physical, accessibility, and performance evidence
  separate in docs and handoffs.

