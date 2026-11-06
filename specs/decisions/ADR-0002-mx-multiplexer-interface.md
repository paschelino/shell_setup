# ADR-0002: One executable, `mx`, between tooling and the terminal multiplexer

|            |            |
| ---------- | ---------- |
| **Status** | accepted   |
| **Date**   | 2026-11-06 |

## Context

Four multiplexers are in a bake-off (tmux + workmux, Zellij, herdr, TUIOS).
Three of them show agent state, each through its own CLI or socket, and today
the harness hooks call all three in parallel. The unattended runner, future
hooks and other tooling need to report state, send notifications and ask the
person a question without knowing which multiplexer is active, and without an AI
agent relaying the status.

Options considered:

- **Call each tool's CLI from every place that reports status.** What the hooks
  do today. Every new reporter repeats the dispatch, and the bake-off's loser
  leaves dead code everywhere.
- **A terminal escape protocol** such as TUIOS's OSC 7501 `status`. Elegant, but
  only TUIOS reads it today.
- **One executable with per-host adapters**, like the `_zp_host` detection and
  per-tool primitives already used by the `zp` commands.

## Decision

- `mx` is a zsh executable in its own stow package, callable from any language.
  Verbs: `host`, `state`, `notify`, `ask`, `session`.
- Host detection order: `TUIOS_ENV`, `HERDR_ENV`, `ZELLIJ`, `TMUX`, else `none`.
  TUIOS first, because its panes also set `HERDR_ENV`.
- One adapter function per host. Adapters without a native concept are no-ops
  that log to the state file. Every verb exits 0 outside any multiplexer.
- Common sinks run regardless of host: a state file under `~/.local/state/mx/`,
  and for `notify` a macOS notification. Further sinks (ntfy) are adapters, not
  callers' business.
- `mx` is called by host processes only. Nothing inside a sandbox is expected to
  reach it.

## Consequences

- The runner, hooks and future tools call `mx` and stay ignorant of the
  bake-off. When it is decided, the losers' adapters are deleted in one place.
- Zellij shows no agent state without workmux, which goes on the scorecard as a
  finding.
- `_zp_host` and the three parallel status hooks become candidates for
  replacement by `mx` later (spec task T4f), not now.
- An `ask` outside TUIOS falls back to a waiting state plus an answer file,
  which is slower than a native prompt but works everywhere.
