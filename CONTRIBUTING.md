# Contributing

Thanks for helping make cross-application macOS overlays easier to build.

## Before changing the API

1. Read [`docs/orientation/CURRENT_STATE.md`](docs/orientation/CURRENT_STATE.md)
   and [`docs/orientation/ARCHITECTURE.md`](docs/orientation/ARCHITECTURE.md).
2. Open an issue describing the concrete consumer that needs the change.
3. Keep renderer, physics, message, speech, and global-input policy outside the
   window substrate unless two real consumers demonstrate a shared seam.

## Development

```bash
git clone https://github.com/owensantoso/global-overlay-kit.git
cd global-overlay-kit
./run check
```

Pull requests should include focused tests and state which evidence was
actually gathered. Compilation is not proof of focus preservation, Spaces,
full-screen, accessibility, or multi-display behavior.

## Licensing and provenance

Contributions are accepted under the repository's MIT License. Do not copy
code from another overlay project without a compatible license and an explicit
provenance record.

