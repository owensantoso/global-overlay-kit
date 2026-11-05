# Phone world

Desktop Physics Demo can pair one phone browser as an adjoining screen. The Mac simulates one character; the phone draws the same character in the neighbouring rectangle. Walking and jumping across the opening preserve identity and momentum.

Open the signed app, choose **Phone screen… → Connect phone**, and scan its QR code. The phone must be on the same private Tailscale network. Choose Left, Right, Below or Above and adjust alignment/scale to match the physical arrangement. Rotation follows the phone canvas. The diagram represents the web canvas, excluding browser chrome and controls.

The phone has Left, Right, Jump and Run controls. Release and press Jump again for another jump. Above/below placements include a column of one-way ledges: repeated jumps climb the column; moving beside it lets the character fall. **Return to Mac** recovers the same character. Disconnecting closes the opening and rescues an offscreen character.

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

Pairing capabilities rotate with a new code or native session. One browser holds the phone seat. Native and phone requests carry monotonic sequences; stale held inputs cannot overwrite a newer release. Movement expires after 400 ms without a phone heartbeat; a longer connection grace closes the opening after 750 ms. Native disappearance clears browser state after 1.5 seconds. Hidden-page, cancellation and blur paths release controls. The native physics watchdog independently releases controls if its bridge stops.

## Verification and remaining acceptance

Automated evidence includes real elapsed Mac→phone→Mac traversal with the same native entity and nonzero momentum, climbing every ledge below/above the Mac, layout-preserving state, disconnection rescue, one-way contacts, remote input expiry, pairing exclusivity, request ordering, real HTTP security checks, and portrait/landscape browser controls with the shipped artwork.

The private runtime was also observed paired to a live browser with the native character inside its phone region. This is telemetry evidence; perceived latency, physical scale, QR scanning and actual iPhone Safari toolbar/rotation behaviour remain physical checks. Browser automation uses Chrome and a separate test authority.

The installed Agent Continuity doctor reports document-format/tooling drift. Existing structured docs and generated views are preserved; this plain example-local brief and README record the bounded prototype.
