import { useEffect, useRef } from "react";
import type { PhoneState, Viewport } from "./protocol.ts";

type Props = {
  world: PhoneState | null;
  message: string;
  onResize: (viewport: Viewport) => void;
};

export function WorldView({ world, message, onResize }: Props) {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const images = useRef(new Map<string, HTMLImageElement>());
  const current = useRef(world);

  useEffect(() => {
    current.current = world;
  }, [world]);

  useEffect(() => {
    const canvas = canvasRef.current!;
    const bounds = () => {
      const box = canvas.getBoundingClientRect();
      onResize({
        width: Math.round(box.width),
        height: Math.round(box.height),
      });
    };
    const observer = new ResizeObserver(bounds);
    observer.observe(canvas);
    bounds();
    return () => observer.disconnect();
  }, [onResize]);

  useEffect(() => {
    const canvas = canvasRef.current!;
    const context = canvas.getContext("2d")!;
    let frame = 0;
    const draw = () => {
      const { width, height } = canvas.getBoundingClientRect();
      const dpr = Math.min(devicePixelRatio || 1, 3);
      if (
        canvas.width !== Math.round(width * dpr) ||
        canvas.height !== Math.round(height * dpr)
      ) {
        canvas.width = Math.round(width * dpr);
        canvas.height = Math.round(height * dpr);
      }
      context.setTransform(dpr, 0, 0, dpr, 0, 0);
      context.clearRect(0, 0, width, height);
      const state = current.current;
      const region =
        state?.nativeOnline && state.connected && state.snapshot
          ? state.region
          : null;
      if (region && width > 0 && height > 0) {
        // A rotation can precede the next native region update. Fit uniformly
        // through that interval so the same character never stretches.
        const scaleX = Math.min(width / region.width, height / region.height);
        const scaleY = scaleX;
        const fittedWidth = region.width * scaleX;
        const fittedHeight = region.height * scaleY;
        const offsetX = (width - fittedWidth) / 2;
        const offsetY = (height - fittedHeight) / 2;
        const px = (x: number) => offsetX + (x - region.x) * scaleX;
        const py = (y: number) => height - offsetY - (y - region.y) * scaleY;
        context.save();
        context.beginPath();
        context.rect(offsetX, offsetY, fittedWidth, fittedHeight);
        context.clip();
        context.strokeStyle = "#121a20";
        context.lineWidth = 2;
        for (const platform of state?.snapshot?.platforms || []) {
          context.beginPath();
          context.moveTo(px(platform.x), py(platform.y));
          context.lineTo(px(platform.x + platform.width), py(platform.y));
          context.stroke();
        }
        context.strokeStyle = "#0095b8";
        context.lineWidth = 4;
        context.beginPath();
        const snapshot = state!.snapshot!;
        context.font = "12px -apple-system, BlinkMacSystemFont, sans-serif";
        context.fillStyle = "#007f9e";
        if (state?.edge === "right" || state?.edge === "left") {
          const low = Math.max(0, region.y);
          const high = Math.min(snapshot.height, region.y + region.height);
          const x = px(
            state.edge === "right" ? region.x : region.x + region.width,
          );
          if (high > low) {
            context.moveTo(x, py(low));
            context.lineTo(x, py(high));
            context.textAlign = state.edge === "right" ? "left" : "right";
            context.fillText(
              "To Mac",
              x + (state.edge === "right" ? 12 : -12),
              py(high) + 20,
            );
          }
        } else {
          const low = Math.max(0, region.x);
          const high = Math.min(snapshot.width, region.x + region.width);
          const y = py(
            state?.edge === "top" ? region.y : region.y + region.height,
          );
          if (high > low) {
            context.moveTo(px(low), y);
            context.lineTo(px(high), y);
            context.textAlign = "center";
            context.fillText(
              "To Mac",
              px((low + high) / 2),
              y + (state?.edge === "top" ? -12 : 20),
            );
          }
        }
        context.stroke();
        const player = state?.snapshot?.player;
        if (player) {
          const centerX = px(player.x);
          const centerY = py(player.y + (player.spriteOffsetY || 0));
          const spriteWidth = (player.spriteWidth || player.width) * scaleX;
          const spriteHeight = (player.spriteHeight || player.height) * scaleY;
          let image: HTMLImageElement | undefined;
          if (player.asset) {
            image = images.current.get(player.asset);
            if (!image) {
              image = new Image();
              image.src = `${import.meta.env.BASE_URL}characters/${player.asset}`;
              images.current.set(player.asset, image);
            }
          }
          context.save();
          context.translate(centerX, centerY);
          context.scale(player.facing === "left" ? -1 : 1, 1);
          if (image?.complete && image.naturalWidth > 0) {
            context.drawImage(
              image,
              -spriteWidth / 2,
              -spriteHeight / 2,
              spriteWidth,
              spriteHeight,
            );
          } else {
            context.fillStyle = "#121a20";
            context.beginPath();
            context.roundRect(
              (-player.width * scaleX) / 2,
              (-player.height * scaleY) / 2,
              player.width * scaleX,
              player.height * scaleY,
              8,
            );
            context.fill();
          }
          context.restore();
        }
        context.restore();
      }
      frame = requestAnimationFrame(draw);
    };
    frame = requestAnimationFrame(draw);
    return () => cancelAnimationFrame(frame);
  }, []);

  return (
    <section className="world" aria-label="Phone screen in the shared world">
      <canvas
        ref={canvasRef}
        aria-label="Live view of the character and phone platforms"
      />
      {message && <p className="world-message">{message}</p>}
    </section>
  );
}
