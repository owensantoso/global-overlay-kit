import { execFileSync } from "node:child_process";
import { existsSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";

// Agent-run tests respect the local incident gate; ordinary public clones do
// not require Owen's workstation tooling to run their disposable test servers.
export function testPreflight(action, scope) {
  const helper = join(
    homedir(),
    ".codex/skills/critical-incident-response/scripts/incident_lock.py",
  );
  if (!existsSync(helper)) {
    if (process.env.CODEX_THREAD_ID)
      throw new Error("Agent incident preflight is unavailable");
    return;
  }
  execFileSync(
    "python3",
    [helper, "preflight", "--action", action, "--scope", scope],
    { stdio: "pipe" },
  );
}
