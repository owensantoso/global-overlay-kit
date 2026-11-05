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
      const { width: actualWidth, height: actualHeight } =
        canvas.getBoundingClientRect();
      const dpr = Math.min(devicePixelRatio || 1, 3);
      if (
        canvas.width !== Math.round(actualWidth * dpr) ||
        canvas.height !== Math.round(actualHeight * dpr)
      ) {
        canvas.width = Math.round(actualWidth * dpr);
        canvas.height = Math.round(actualHeight * dpr);
      }
      context.setTransform(dpr, 0, 0, dpr, 0, 0);
      context.clearRect(0, 0, actualWidth, actualHeight);
      const state = current.current;
      const region =
        state?.nativeOnline && state.connected && state.snapshot
          ? state.region
          : null;
      if (region && actualWidth > 0 && actualHeight > 0) {
        const rotated = region.rotation === 90;
        const width = rotated ? actualHeight : actualWidth;
        const height = rotated ? actualWidth : actualHeight;
        context.save();
        if (rotated) {
          context.translate(actualWidth, 0);
          context.rotate(Math.PI / 2);
        }
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
        context.font = "12px -apple-system, BlinkMacSystemFont, sans-serif";
        context.fillStyle = "#007f9e";
        for (const seam of state?.seams ?? []) {
          const x1 = px(seam.x1),
            y1 = py(seam.y1),
            x2 = px(seam.x2),
            y2 = py(seam.y2);
          context.moveTo(x1, y1);
          context.lineTo(x2, y2);
          if (seam.x1 === seam.x2) {
            const isLeft = Math.abs(seam.x1 - region.x) < 0.5;
            context.textAlign = isLeft ? "left" : "right";
            context.fillText(
              seam.label,
              x1 + (isLeft ? 12 : -12),
              Math.min(y1, y2) + 20,
            );
          } else {
            const isTop = Math.abs(seam.y1 - region.y - region.height) < 0.5;
            context.textAlign = "center";
            context.fillText(
              seam.label,
              (x1 + x2) / 2,
              y1 + (isTop ? 20 : -12),
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
