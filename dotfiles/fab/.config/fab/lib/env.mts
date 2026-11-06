// Small helpers: the .env file, durations, and the global instruction files
// the sandbox would otherwise hide from the agent.
import { existsSync, readFileSync, readdirSync } from "node:fs";
import { join } from "node:path";
import { homedir } from "node:os";

// KEY=VALUE lines; comments and blank lines ignored; surrounding quotes dropped.
export function readDotenv(path: string): Record<string, string> {
  if (!existsSync(path)) return {};
  const env: Record<string, string> = {};
  for (const raw of readFileSync(path, "utf8").split("\n")) {
    const line = raw.trim();
    if (!line || line.startsWith("#")) continue;
    const eq = line.indexOf("=");
    if (eq < 0) continue;
    const key = line
      .slice(0, eq)
      .trim()
      .replace(/^export\s+/, "");
    let value = line.slice(eq + 1).trim();
    if (
      (value.startsWith('"') && value.endsWith('"')) ||
      (value.startsWith("'") && value.endsWith("'"))
    ) {
      value = value.slice(1, -1);
    }
    env[key] = value;
  }
  return env;
}

// "2h", "90m", "1h30m", "45s" to milliseconds.
export function parseDuration(text: string): number {
  const m = text.trim().match(/^(?:(\d+)h)?(?:(\d+)m)?(?:(\d+)s)?$/);
  if (!m || m[0] === "")
    throw new Error(`not a duration: ${text} (use e.g. 2h, 90m, 1h30m)`);
  const [, h = "0", min = "0", s = "0"] = m;
  return ((+h * 60 + +min) * 60 + +s) * 1000;
}

// The maintainer's global agent instructions, read on the host. Claude Code
// imports these same files from ~/.claude/CLAUDE.md; opencode loads them via
// its config. Inside the sandbox neither can, so the prompt carries them.
export function readGlobalInstructions(): string {
  const base = join(homedir(), ".config", "opencode");
  const files = [join(base, "AGENTS.md")];
  const dir = join(base, "instructions");
  if (existsSync(dir)) {
    for (const f of readdirSync(dir).sort())
      if (f.endsWith(".md")) files.push(join(dir, f));
  }
  return files
    .filter((f) => existsSync(f))
    .map(
      (f) =>
        `<!-- ${f.replace(homedir(), "~")} -->\n${readFileSync(f, "utf8").trim()}`,
    )
    .join("\n\n");
}

// Optional read-only mounts for the sandbox: one absolute path per line in
// ~/.config/fab/mounts, `~` allowed. Caches under the home directory that a
// project's tools need, such as Playwright's browsers.
export function readMounts(
  configDir: string,
): { hostPath: string; sandboxPath: string; readonly: true }[] {
  const path = join(configDir, "mounts");
  if (!existsSync(path)) return [];
  return readFileSync(path, "utf8")
    .split("\n")
    .map((l) => l.trim())
    .filter((l) => l && !l.startsWith("#"))
    .map((l) => l.replace(/^~(?=\/|$)/, homedir()))
    .filter((p) => existsSync(p))
    .map((p) => ({ hostPath: p, sandboxPath: p, readonly: true as const }));
}
