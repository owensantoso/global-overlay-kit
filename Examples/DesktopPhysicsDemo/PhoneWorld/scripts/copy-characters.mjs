import { cp } from "node:fs/promises";

// Preserve the native CC0 frames and their provenance without transformation.
await cp(
  new URL(
    "../../Sources/DesktopPhysicsKit/Resources/StickFigureCC0/",
    import.meta.url,
  ),
  new URL("../dist/characters/", import.meta.url),
  { recursive: true },
);
