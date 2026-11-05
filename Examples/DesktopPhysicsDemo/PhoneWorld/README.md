# Phone world

Desktop Physics Demo can pair up to eight phone browsers as adjoining screens. The Mac simulates one character; the phone draws the same character in the neighbouring rectangle. Walking and jumping across the opening preserve identity and momentum.

Open the signed app, choose **Phone screens… → Connect phones**, and scan the same QR code from each phone. All phones need the same private Tailscale network. The page and native canvas display matching **Phone 1**, **Phone 2** labels. New screens join beside the active world.

Drag a numbered phone rectangle next to the Mac or another connected screen. A ghost previews the snapped position; an invalid drop returns to its prior position. The character crosses the highlighted shared openings. The Mac stays fixed. Select a phone and drag its labelled corner Resize handle, or adjust its Scale slider. Resize ghosts preview the changed screen and its dependent neighbours before committing. Use Rotate view for a clockwise quarter-turn between portrait and landscape; the world canvas turns too, while movement controls keep their world direction. Focus a screen and use arrow keys along its snapped edge (Shift moves farther). Rotation preserves attachments where possible. Controls and browser chrome remain outside the measured world canvas.

Phone Left, Right, Jump and Run controls move the same character. Opposite directions from different phones cancel. Higher/lower neighbours have one-way ledges; repeated jumps climb the column and moving beside it permits falling. **Return to Mac** recovers the same character.

An offline middle phone closes its region; downstream screens show **Needs connection** until reattached. Removing a phone retires that browser's screen without renumbering the others. Its page can join again by explicitly scanning the QR code. **Disconnect all phones** closes the phone world. **Reset all pairings** retires the entire session and provides a new code.

## Development

Use Node 22.12+ and the paired native workspace described in the parent README. From this directory:

```sh
npm ci --ignore-scripts
npm run verify
```

The normal check covers formatting, ESLint, TypeScript, production build, real HTTP/relay tests and Chrome browser controls. It uses installed Google Chrome; it does not download a browser. From the repository root, `./run phone-world-check` runs the web checks, and `./run desktop-physics-check` also runs native tests and the signed app build. Browser smoke tests use a clearly separate test authority. Native elapsed SpriteKit tests own crossing and stair traversal evidence.

`npm run build` copies the existing CC0 character frames and licence files from the native target to `dist/characters`. No renderer or simulation is copied from Place Game. See [DESIGN.md](DESIGN.md) for authority, state ownership, design review and evidence limits.

## Local companion

The production companion is `server/server.mjs`. It reads a machine-local JSON config with `nativeSecret`, `port`, `publicURL` and `staticRoot`, then binds only `127.0.0.1`. The native app reads its bounded secret/port config from `~/Library/Application Support/Desktop Phone World/config.json`. No credentials belong in this repository.

The deployment helper writes this companion's files and LaunchAgent definition; use the maintained private-tailnet-delivery protected wrapper for deployment, service and route changes. A subpath proxy must retain `/phone-world` in its backend target because Tailscale strips the matched frontend prefix. Preserve unrelated routes. Never use Funnel.

Pairing capabilities rotate with a new code or native session. Each browser has its own stable screen identity, sequence, viewport and heartbeat. Native requests also carry monotonic sequences; stale held inputs cannot overwrite a newer release. Only screens in the native active component contribute input. Movement expires after 400 ms without a phone heartbeat; a longer connection grace closes the opening after 750 ms. Native disappearance clears browser state after 1.5 seconds. Hidden-page, cancellation and blur paths release controls. The native physics watchdog independently releases controls if its bridge stops.

## Verification and remaining acceptance

Automated evidence includes real elapsed Mac→Phone 1→Phone 2→Phone 1→Mac traversal with the same native entity and nonzero momentum, climbing every ledge below/above the Mac, layout-preserving state, disconnection rescue, one-way contacts, remote input expiry, independent simultaneous pairing, request ordering, real HTTP security checks, and portrait/landscape browser controls with the shipped artwork.

Owen accepted single-phone traversal on 2026-11-05: “yeah it works, i can go into the phone and back.” That version was merged in PR #1. The multiple-phone arrangement and its physical feel require a new acceptance check. Actual iPhone Safari toolbar/rotation behaviour remains a device check. Browser automation uses Chrome and a separate test authority.

The installed Agent Continuity doctor reports document-format/tooling drift. Existing structured docs and generated views are preserved; this plain example-local brief and README record the bounded prototype.
