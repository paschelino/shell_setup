# ADR-0001: Use sandcastle as the engine for unattended agent runs

|            |            |
| ---------- | ---------- |
| **Status** | accepted   |
| **Date**   | 2026-11-06 |

## Context

Unattended runs need: a fresh agent session per task, chained until a queue is
empty; isolation so the agent can only touch its worktree; capture of the
agent's session for resume; handling of agents that hang after finishing; and
support for Claude Code privately and opencode (or Copilot) at work.

Options considered:

- **A custom zsh runner with Claude Code hooks.** A Stop hook that refuses to
  stop while tasks remain, a PreToolUse hook that denies questions during quiet
  hours, `claude -p` in a loop. Full control, no Node dependency, but we would
  own session capture, hanging processes, two harnesses' hook models and every
  edge case, and hooks don't exist inside a sandbox.
- **TUIOS's own `fan`, `task` and `agent-proto`.** Already installed, but it
  ties the runner to one multiplexer while the bake-off is open.
- **workmux's coordinator skill.** Dispatches to worktree agents and waits on
  them, but needs tmux and a coordinating agent, so an AI sits in the status
  path.
- **`@ai-hero/sandcastle`.** TypeScript library, MIT, 8.9k stars, active.
  `run()` chains iterations with a completion signal and idle timeout; native
  sandboxes (Seatbelt on macOS, Bubblewrap on Linux) with no image or daemon;
  Claude Code, opencode, Codex, Copilot, Cursor and Pi providers; session
  capture and resume; structured output; a `cwd` option so one central
  orchestrator can target any repository. Unopinionated about prompts, which is
  where the maintainer's spec practice lives anyway. Costs a Node runtime on the
  host and a fast-moving dependency to pin.

## Decision

- sandcastle is the run engine. Custom code is limited to a multiplexer
  interface (ADR-0002), a thin runner that calls `run()` once per task, the
  prompts, and skills.
- One central installation in `~/.config/fab` with an exact pinned version.
  Nothing of sandcastle lands in project repositories.
- Native sandbox (`seatbelt()` on macOS) for unattended runs. Status reaches the
  multiplexer from the host process, not from inside the sandbox.
- Headless runs are the answer to mid-run questions: with nobody to ask, the
  prompt tells the agent to decide and record, or to park the question and take
  the next task.

## Consequences

- Session capture, hanging processes, provider quirks and sandbox mounts are
  somebody else's maintenance; upgrades are a deliberate version bump plus a
  read of the changelog.
- Global instruction files and harness hooks don't load inside the sandbox. The
  runner injects the instructions through prompt arguments and reports status
  itself.
- The runner is Node, so the work machine needs Node to use it; without it,
  `fab` explains what is missing and does nothing.
- If sandcastle's API changes under us, only `main.mts` and its small library
  files change.
