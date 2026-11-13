# ADR-0004: A podman container is the sandbox for projects with browser work

|            |            |
| ---------- | ---------- |
| **Status** | accepted   |
| **Date**   | 2026-11-13 |

## Context

ADR-0001 made macOS's own process sandbox (`seatbelt()`) the sandbox for
unattended runs. The pilot project's "Done when" needs a layout check that
launches Chromium, Firefox and WebKit through Playwright, and all three abort
inside that sandbox: its profile denies XPC and most Mach services, and
sandcastle 0.14.0 doesn't expose the profile. T2a found the missing rules by
bisection: a Mach-port rendezvous service for Chromium; a broad `mach-lookup`
(LaunchServices), a `mach-register` and five `MOZ_DISABLE_*_SANDBOX` variables
for Firefox; the broad lookup, `mach-issue-extension`, a WebKit XPC prefix and
the window server for WebKit, whose helpers run outside the profile under
WebKit's own sandbox.

The question, reframed with the maintainer, is not how browsers start but which
harness survives a Playwright, macOS or sandcastle update and runs unchanged on
a cloud node later (a spec non-goal for now, a stated direction).

Options:

1. **Seatbelt with the T2a rules.** The host's tools, sub-second start-up,
   Safari's engine for WebKit. The rules are a macOS-only list of Mach service
   names and browser-specific variables that nobody publishes, found by
   bisection, and they live in a `patch-package` patch of sandcastle's
   `dist/sandboxes/seatbelt.js` until upstream adds a profile option. The broad
   `mach-lookup` opens LaunchServices and the pasteboard. Every Playwright,
   macOS or sandcastle release can silently break it, and the bisection has no
   denial log to lean on. Nothing of it transfers to Linux.
2. **sandcastle's `podman()` with Playwright's Linux image.** Playwright
   publishes `mcr.microsoft.com/playwright:v<version>-noble` with the three
   engines and their OS libraries pinned per Playwright version. fab's
   Containerfile adds the agent CLI, pnpm and mise, which installs each
   project's pinned tools from its `mise.toml` into a cache fab mounts. The
   image is the same object on this machine, in the podman VM, and on a Linux
   node; an update is a version bump in one file. Costs: podman and a Linux VM
   on macOS, a 3 GB image, Linux WebKit instead of Safari's engine, the worktree
   reaching the container through virtiofs, no hard links into pnpm's macOS
   store, and a second copy of the toolchain to pin.
3. **A verification service outside the sandbox** that the agent asks for a gate
   (`mx ask`-like, or a queue). Verification leaves the agent's hands and
   serialises the browser work, which the pilot wants anyway; it is cloud-
   separable by construction. But it still needs a sandbox for the test run
   itself (so option 1 or 2 inside), adds a service to run, and makes the
   agent's fix loop a round trip per attempt, slow for a layout task that
   iterates on pixels.

What sandcastle's podman provider does, from its code: it never builds. It
checks that an image exists (`imageName`, default `sandcastle:<repo dir>`),
mounts the worktree at `/home/agent/workspace`, the worktree's `.git` file and
the main repository's `.git` at their host paths, plus caller mounts, runs the
container as uid 1000 with `--userns=keep-id`, and removes it after the task.
The CLI's `build-image` reads `.sandcastle/Containerfile` in the repository; the
library has no such expectation, so fab builds from its own file and nothing
lands in a project.

Measured on the throwaway (T2s, fake agent, 2026-11-13; Seatbelt figures from
T2a and this trial):

| Step                                      | Seatbelt           | podman                                         |
| ----------------------------------------- | ------------------ | ---------------------------------------------- |
| One-off: machine init, image pull, build  | none               | 1:54, 3:40 (2.57 GB), 0:29 to 0:37 (3.07 GB)   |
| Per boot: machine start                   | none               | 16.5 s                                         |
| Task start to agent's first line          | 0.4 s              | 1.3 s warm; 191 s cold, mostly `mise install`  |
| `mise install` (tools cached)             | 77 ms              | 371 ms (cold: five tools, about three minutes) |
| `pnpm install --frozen-lockfile` (cached) | 47 to 183 ms       | 237 ms (cold 2.8 s, into a Linux store)        |
| Chromium, Firefox, WebKit launch          | SIGABRT, all three | 0.65 s, 1.65 s, 1.73 s; a worktree file loads  |
| Whole fake-agent task                     | 1.7 s              | 8 s                                            |

The container sees no `/Users`, no host home and no `~/.ssh`; the worktree and
the main repository's `.git` appear at their host paths, so a path under
`/Users/<name>` is visible as a name. `node` is the project's pinned version
through mise's shims, where Seatbelt gives the host's.

## Decision

- **Projects with browser work run in a podman container**, selected per run
  with `fab run --sandbox podman`. Seatbelt stays the default and the sandbox
  for everything else (ADR-0001 holds).
- **The image is fab's**, built from `~/.config/fab/Containerfile` on
  Playwright's `-noble` image, tagged by the file's hash, rebuilt when the file
  changes; the build context is an empty directory. fab starts a stopped podman
  machine and refuses, with the command, when none exists.
- **The container sees** the worktree, its git directories and fab's two cache
  directories under `~/.local/share/fab/podman/` (mise's installs, pnpm's store
  and metadata), read-write, at fixed paths under `/home/agent`. No host home,
  no `~/.config/fab/mounts`, which stays the Seatbelt list.
- **Each project's tools come from its `mise.toml`**: fab runs `mise install` in
  the sandbox before the agent starts, so the first task of a project downloads
  and later tasks find the tools cached. A project whose Playwright version
  differs from the image's downloads its own browsers on first use.
- **Linux WebKit is accepted** as the pilot's third engine. Its checks are
  layout checks across engines, not Safari conformance; Safari stays a manual
  check on the maintainer's machine when a task calls for it.
- **The Seatbelt rules are recorded, not adopted.** If sandcastle gains a
  profile option, a later ADR can revisit; the rules are in the progress log of
  2026-11-13.
- **No verification service.** Serialising browser gates stays a project rule
  ("one agent runs browsers at a time"); the cloud split comes from the image
  being portable, not from a service.

## Consequences

- One more version pin set, in one file: Playwright's image tag, the agent CLI,
  pnpm, mise. The agent inside the container is the image's `claude`, not the
  host's; a `claude` update is a Containerfile edit and a 40-second rebuild.
- podman is a host requirement for `--sandbox podman`: `brew install podman`,
  `podman machine init` once. Without it, fab explains and exits 2. A machine
  that is stopped costs 16 seconds at the first run after a boot.
- The podman VM holds 4 CPUs and 6 GB while it runs; two parallel runs share
  them. The T2 rate-limit measurement should note this.
- Timings of the pilot's checks (its AC16) are taken on Linux WebKit in a VM and
  are not comparable with the maintainer's macOS figures; the pilot's spec
  should say which environment its numbers come from.
- On a Linux node, `podman()` or `docker()` with the same Containerfile is the
  obvious port; `bwrap` would need the Seatbelt-style browser work again.
