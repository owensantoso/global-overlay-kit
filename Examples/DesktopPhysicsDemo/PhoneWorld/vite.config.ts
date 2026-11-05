import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

export default defineConfig({
  base: "/phone-world/",
  plugins: [react()],
  server: { proxy: { "/phone-world/api": "http://127.0.0.1:9137" } },
});
