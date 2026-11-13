// The sandbox a run uses (ADR-0004): `seatbelt`, macOS's own process sandbox
// with the host's tools, or `podman`, a Linux container from fab's
// Containerfile with Playwright's browsers, for projects with browser work.
// Both leave the project untouched: the image is built from ~/.config/fab,
// the container mounts only the worktree, its git directories and fab's own
// tool caches.
import { createHash } from "node:crypto";
import { execFileSync } from "node:child_process";
import {
  existsSync,
  mkdirSync,
  mkdtempSync,
  readFileSync,
  rmSync,
} from "node:fs";
import { homedir, tmpdir } from "node:os";
import { join } from "node:path";
import type { SandboxHooks, SandboxProvider } from "@ai-hero/sandcastle";
import { seatbelt } from "@ai-hero/sandcastle/sandboxes/seatbelt";
import { podman } from "@ai-hero/sandcastle/sandboxes/podman";
import { readMounts, readSandboxEnv } from "./env.mts";

export const SANDBOXES = ["seatbelt", "podman"] as const;
export type SandboxKind = (typeof SANDBOXES)[number];

export interface SandboxSetup {
  provider: SandboxProvider;
  hooks?: SandboxHooks;
  // What run.start records about it.
  info: Record<string, unknown>;
}

// Inside the container: sandcastle's home for the agent, and where fab's
// persistent caches appear. The Containerfile's MISE_DATA_DIR must agree.
const AGENT_HOME = "/home/agent";
const CONTAINER_CACHES = {
  mise: `${AGENT_HOME}/.local/share/mise`,
  pnpm: `${AGENT_HOME}/.local/share/pnpm`,
};

function podmanStateDir(): string {
  return join(
    process.env.XDG_DATA_HOME || join(homedir(), ".local", "share"),
    "fab",
    "podman",
  );
}

function podmanOut(args: string[]): string {
  return execFileSync("podman", args, {
    encoding: "utf8",
    stdio: ["ignore", "pipe", "pipe"],
  }).trim();
}

// On macOS containers run in a Linux VM. Start the machine when it exists and
// is stopped; without one, explain how to make it (once, about two minutes).
export function ensurePodmanMachine(log: (line: string) => void): void {
  if (process.platform !== "darwin") return;
  const machines = JSON.parse(
    podmanOut(["machine", "list", "--format", "json"]),
  ) as {
    Name: string;
    Running: boolean;
  }[];
  if (machines.some((m) => m.Running)) return;
  if (!machines.length)
    throw new Error(
      "no podman machine. Once: podman machine init --cpus 4 --memory 6144 && podman machine start",
    );
  log(`starting podman machine ${machines[0].Name}`);
  execFileSync("podman", ["machine", "start", machines[0].Name], {
    stdio: ["ignore", "pipe", "pipe"],
  });
}

// fab's image, tagged by the Containerfile's hash so an edited file builds a
// new image and an unchanged one is reused. The build context is an empty
// directory: the file copies nothing in.
export function ensureImage(
  configDir: string,
  log: (line: string) => void,
): string {
  const file = join(configDir, "Containerfile");
  const hash = createHash("sha256").update(readFileSync(file)).digest("hex");
  const tag = `fab:${hash.slice(0, 12)}`;
  try {
    podmanOut(["image", "inspect", "--format", "{{.Id}}", tag]);
    return tag;
  } catch {
    /* not built yet */
  }
  log(`building ${tag} from ${file} (first time; minutes)`);
  const context = mkdtempSync(join(tmpdir(), "fab-build-"));
  try {
    execFileSync("podman", ["build", "-f", file, "-t", tag, context], {
      stdio: ["ignore", "inherit", "inherit"],
    });
  } finally {
    rmSync(context, { recursive: true, force: true });
  }
  return tag;
}

export function makeSandbox(
  kind: SandboxKind,
  configDir: string,
  log: (line: string) => void,
): SandboxSetup {
  switch (kind) {
    case "seatbelt": {
      const mounts = readMounts(configDir);
      const env = readSandboxEnv(configDir);
      return {
        provider: seatbelt({ mounts, env }),
        info: {
          sandbox: kind,
          mounts: mounts.map((m) => `${m.hostPath}${m.readonly ? "" : " rw"}`),
          sandboxEnv: Object.keys(env),
        },
      };
    }
    case "podman": {
      ensurePodmanMachine(log);
      const image = ensureImage(configDir, log);
      // Tool caches survive the container, which doesn't: mise's installs of
      // each project's pinned tools, pnpm's store and metadata.
      const state = podmanStateDir();
      const mounts = Object.entries(CONTAINER_CACHES).map(
        ([name, sandboxPath]) => {
          const hostPath = join(state, name);
          if (!existsSync(hostPath))
            mkdirSync(hostPath, { recursive: true, mode: 0o700 });
          return { hostPath, sandboxPath };
        },
      );
      const env = {
        TMPDIR: "/tmp",
        pnpm_config_store_dir: `${CONTAINER_CACHES.pnpm}/store`,
        pnpm_config_cache_dir: `${CONTAINER_CACHES.pnpm}/cache`,
      };
      return {
        provider: podman({ imageName: image, mounts, env }),
        hooks: {
          sandbox: {
            onSandboxReady: [
              // The project's pinned tools, into the mounted cache; a no-op
              // once installed. A failure here fails the task at once.
              {
                command: "if [ -f mise.toml ]; then mise install; fi",
                timeoutMs: 900_000,
              },
            ],
          },
        },
        info: {
          sandbox: kind,
          image,
          mounts: mounts.map((m) => `${m.hostPath} -> ${m.sandboxPath} rw`),
          sandboxEnv: Object.keys(env),
        },
      };
    }
  }
}
