# unattended-runs: coding agents that work for hours without asking

|                |                                                                                                                                                                                                              |
| -------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Status**     | ready                                                                                                                                                                                                        |
| **Depends on** | [ADR-0001](../../decisions/ADR-0001-sandcastle-as-run-engine.md), [ADR-0002](../../decisions/ADR-0002-mx-multiplexer-interface.md), [ADR-0003](../../decisions/ADR-0003-worktrees-mandatory-prs-optional.md) |
| **Private**    | `~/.config/zp/fab-notes.md` holds the pilot project, its paths and anything else that must not be public                                                                                                     |

## Problem

The maintainer runs several coding agents (Claude Code on private machines,
opencode at work) in parallel multiplexer sessions. Each interruption costs
focus. An analysis of 75 local Claude transcripts found 255 mid-run questions.
Most were a fork reached after research, a fact only the maintainer knows, or a
taste detail. Written instructions such as "decide and record instead of asking"
exist in the maintainer's project run briefs and still don't hold over hours.
The maintainer's projects already have the spec layer (spec template, ADRs,
`progress.md` hand-off, run brief, a `session-handoff` skill) and today start
"one fresh session per task" by hand.

Goal: a run of two hours or more per project, started with one command, that
needs no human until its checkpoint, whose result is reviewable from a summary
and a demo in minutes, and that works with whichever terminal multiplexer wins
the ongoing bake-off (tmux + workmux, Zellij, herdr, TUIOS).

## Principles touched

- **Maintenance-sensitive:** adopt a maintained engine, build only thin layers.
- **Cost-sensitive:** no new paid services. The real budget is the subscription
  rate limit, so runs serialise when throttled.
- **Public repository:** no private project names, paths or accounts here.
- **Work machine out of our control:** nothing installs itself into project
  repositories or runs unless invoked.

## Scope

Three thin layers over `@ai-hero/sandcastle` (ADR-0001):

1. **`mx`**, a multiplexer interface (ADR-0002): one executable that reports
   agent state, notifications and questions to whichever multiplexer the pane
   runs in, and to common sinks, with no AI in between.
2. **`fab`**, the runner: `fab run <project> <spec> [--until 2h]` creates or
   reuses a worktree (ADR-0003), then chains one fresh sandboxed agent session
   per open task of the spec's Tasks table until the queue is empty, the
   deadline passed, or two tasks in a row failed. It parks questions, writes a
   summary, pushes once, and reports through `mx`.
3. **Global skills**: the maintainer's project-local `new-project-spec`,
   `new-adr`, `session-handoff` and `visual-check` skills promoted to this
   repository for both Claude Code and opencode, with `new-project-spec`
   producing the Tasks table `fab` consumes.

## Non-goals

- A custom run engine, sandbox or session capture. sandcastle does that.
- Interactive sessions. The interview and spec session stays a conversation.
- Phone notifications and answers, Beads as a queue, a cross-project knowledge
  repository, and replacing today's per-tool status hooks. These are later
  decisions, listed under T4x, each with its own go or no-go.
- Deciding the multiplexer bake-off. `mx` keeps it open.
- Cloud runs. The same spec and prompts should work there later; not now.

## Contracts

### `mx` verbs

All verbs exit 0 outside any multiplexer. The host is detected from the
environment in this order: `TUIOS_ENV`, `HERDR_ENV`, `ZELLIJ`, `TMUX`. A pane in
TUIOS also sets `HERDR_ENV`, hence the order.

| Verb                                                 | tuios                                    | tmux + workmux              | herdr                       | Zellij   | Always                                   |
| ---------------------------------------------------- | ---------------------------------------- | --------------------------- | --------------------------- | -------- | ---------------------------------------- |
| `mx host`                                            | `tuios`                                  | `tmux`                      | `herdr`                     | `zellij` | `none`                                   |
| `mx state <working\|waiting\|done\|error> [-m text]` | `set-agent-state`, `set-agent-meta`      | `workmux set-window-status` | socket API, as herdr's hook | no-op    | state file `~/.local/state/mx/<id>.json` |
| `mx notify <title> [body]`                           | `send-agent-message` as a session notice | no-op                       | no-op                       | no-op    | macOS notification; later ntfy           |
| `mx ask <question> -o A -o B …`                      | `ask-human`                              | state waiting, answer file  | same                        | same     | prints the answer, exit 1 when none      |
| `mx session <id>`                                    | `set-agent-session`                      | no-op                       | session report              | no-op    | state file                               |

### `fab` command line

```text
fab run <project> <spec> [--until <duration>] [--agent claude|opencode]
        [--branch <name>] [--task <id,…>] [--idle <duration>] [--no-push]
        [--fan [--jobs <n>]]
fab status [<run-id>]
fab runs
fab tail [<run-id>] [-n <lines>] [--no-follow]
fab review [<run-id>] | fab review --done [note]
```

- `<project>` is a name from `~/.config/zp/projects` (`name path [agent]`),
  parsed as `_zp_projects` does in `dotfiles/zsh/.config/zsh/zp.zsh`.
- `<spec>` is a path relative to the project root, to a spec with a Tasks table
  (below).
- `--until` defaults to `2h`. No new task starts after the deadline.
- `--branch` defaults to `fab/<spec-id>`. The worktree comes from
  `git wt --nocd <branch>`. A branch whose worktree holds a live lock file is
  refused.
- `--task` restricts the queue to these rows, taken in table order; an id that
  names no row refuses the run with exit 2. Dependencies outside the list must
  be done already.
- `--idle` defaults to `1h`: sandcastle fails a task whose agent is silent that
  long. One test command can be silent for most of an hour.
- `fab tail` follows `events.jsonl` and the agent's text in `sandcastle.log` as
  readable lines until the run ends. `fab review` prints `summary.md` and
  appends `{startedAt}` to `reviews` in `run.json`; `fab review --done [note]`
  closes the latest open review. `fab runs` shows the summed review minutes
  (MC1).
- Sandbox: `~/.config/fab/mounts` lists host paths, one per line, read-only or
  with a ` rw` suffix read-write; `~/.config/fab/sandbox.env` sets variables for
  every process in the sandbox (tool settings, never secrets).
- Secrets: `~/.config/fab/.env` with `CLAUDE_CODE_OAUTH_TOKEN` (from
  `claude setup-token`), optionally `GH_TOKEN`. Missing file: print setup
  instructions, exit 2.
- State: `~/.local/state/fab/runs/<project>-<YYYYMMDD-HHMMSS>/` with `run.json`
  (parameters, lock), `events.jsonl`, `sandcastle.log`, `summary.md`.

### Tasks table

A spec's `## Tasks` section is a Markdown table with these columns, in this
order: `Task`, `Step`, `Depends on`, `Done when`, `Demo`. A task is done when
its `Step` cell starts with `**Done**`. Dependencies are task ids separated by
commas, or `-`. `fab` takes the first row that is not done and whose
dependencies are done. With `--fan`, every such row runs in parallel.

### Task report

The agent ends each task with this structured output, which sandcastle parses
and `fab` appends to `events.jsonl`:

```json
{
  "task": "T3",
  "status": "done | parked | failed",
  "summary": "one paragraph",
  "decisions": ["…"],
  "parked": [{ "question": "…", "assumption": "…" }],
  "dependencies": ["name@version"],
  "deleted": ["relative/path"],
  "demo": "how to see it, one command or a path"
}
```

### Summary

`summary.md` per run, in this order: shipped (task ids and commits), decisions,
dependencies added, files deleted, parked questions with the assumption taken,
how to try it, next task, run statistics (tasks, duration, stops and why).

## Acceptance criteria

- [ ] AC1: `mx host` prints the host name in a pane of each installed
      multiplexer and `none` outside; every verb exits 0 outside any
      multiplexer.
- [x] AC2: In a TUIOS pane, `mx state working -m test` is visible in the rail
      and `tuios get-agent-state` agrees; `done` and `error` likewise.
- [x] AC3: `mx notify` produces a macOS notification, and in TUIOS a message in
      the person's Inbox, readable with `tuios read-agent-messages -w human`.
- [x] AC4: `fab` without `~/.config/fab/.env` prints setup instructions and
      exits 2; `install` on a machine without Node skips the `npm ci` step.
- [x] AC5: After a `fab run`, the project repository has commits only on the run
      branch and no untracked or ignored files it did not have before, apart
      from what the agent committed.
- [x] AC6: Each task leaves a `progress.md` entry in the project, and the run
      leaves `summary.md` and `events.jsonl` in its state directory.
- [x] AC7: A task containing a known fork ends with status `parked`, the
      question and assumption appear in `progress.md` and `summary.md`, and the
      run continued with the next task.
- [x] AC8: `--until 10m` stops after the task running at the deadline, never
      mid-task, and the summary names the deadline as the reason.
- [x] AC9: Two `fab run` on one project with different branches work side by
      side; a third on a running branch is refused with a message naming the
      run.
- [ ] AC10: `--fan` runs two independent tasks in two worktrees and merges both
      into the run branch; a forced conflict is parked, not merged.
- [ ] AC11: `stow -n` shows no folding under `~/.config/fab`; the opencode skill
      symlinks resolve.
- [x] AC12 (hits read on 2026-11-06: only the rule's own wording and short
      project names that are also common words): `git grep` over `specs/` and
      the two new stow packages finds no `/Users/` path and no name from
      `~/.config/zp/projects`.

Manual checks:

- [ ] MC1: After a pilot run, reviewing `summary.md` and the demo takes the
      maintainer under 15 minutes. How: time it.
- [ ] MC2: A two-hour run on the pilot project completes with no human input,
      while the maintainer works elsewhere. How: start it, note every time it
      asked for or needed attention.

## Metrics

Per run, from `events.jsonl`: tasks done, parked, failed; wall time; stop
reason. Over weeks: interruptions per working day with runs active, compared
with the 255 questions in 75 transcripts before.

## Open questions

- Beads as a second queue source: trial on a project with many small issues, in
  stealth mode, then decide (T4a).
- A private knowledge repository for cross-project facts on the maintainer's own
  git server, included into prompts (T4b).
- Phone: self-hosted ntfy as an `mx` adapter, or an own app (T4c).
- Rate limits on the Max plan with two or three parallel runs: measure in T2.
- How browser checks run: macOS browsers abort inside sandcastle's Seatbelt
  profile, which denies XPC and most Mach services and can't be extended. A
  Playwright server on the host, reached over localhost, works in all three
  engines (T2a). Decide before T2.
- Answered in T2a: the pilot's tools need mise's install directory read-only,
  pnpm's store, metadata cache and lock directory read-write, and variables that
  point mise, pnpm and Playwright there; the project's `mise.toml` then resolves
  without downloads. The paths are in the private notes.

## Tasks

| Task | Step                                                                                                                                                                                                                                                                                                   | Depends on            | Done when                                                                             | Demo                                                |
| ---- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | --------------------- | ------------------------------------------------------------------------------------- | --------------------------------------------------- |
| T0a  | **Done** 2026-11-06. This spec, the run brief, the progress log, ADR-0001 to 0003 and the private notes file.                                                                                                                                                                                          | -                     | AC12 passes; a cleared session can start T0 from the run brief alone                  | `git log -1 -- specs/`                              |
| T0   | **Done** 2026-11-06, check 1 verified in T1c, check 7 pending the work machine. Verify sandcastle on a throwaway repository: what the sandbox hides, nothing written into the repository, host tools, structured output.                                                                   | T0a                   | Every item of the run brief's T0 checklist has a recorded result in `progress.md`     | The throwaway run's log                             |
| T1a  | **Done** 2026-11-06, AC1 checked in TUIOS and outside only; the other hosts' detection is checked when their panes are next at hand. `mx`: host detection, tuios adapter, logging no-op adapters, state file, macOS notification, README section.                                                      | T0a                   | AC1, AC2, AC3                                                                         | `mx state working -m demo` in a TUIOS pane          |
| T1b  | **Done** 2026-11-06, AC6 half pending a real agent. `fab`: stow package, `package.json` pinned, `main.mts` sequential loop, worktree via `git wt`, lock, deadline, events, summary, push once, `mx` reporting. `install` and `.gitignore` changes.                                                     | T0, T1a               | AC4, AC5, AC6, AC8, AC9, AC11                                                         | `fab run <made-up project> …` on the throwaway repo |
| T1c  | **Done** 2026-11-06, verified with a real sandboxed Claude run on a throwaway project. Prompts: `prompts/task.md` from the maintainer's run brief and hand-off checklist, `prompts/summary.md` as the template `lib/summary.mts` fills. Global instructions injected via prompt arguments.             | T1b                   | A throwaway run produces a progress entry, a commit and a valid task report           | The report in `events.jsonl`                        |
| T2a  | **Done** 2026-11-13. Prepare the pilot. `fab`: `--task <id,…>` to restrict the queue, `--idle <duration>` for sandcastle's idle timeout, read-write mounts (` rw` suffix in `mounts`), `fab tail` for a multiplexer pane, `fab review` stamping review time into `run.json`. Pilot: Tasks table in the five columns with Done markers and dependencies, stale run-brief lines fixed, committed on its `main`. | T1c                   | `fab`'s parser lists only the open rows of the pilot's spec; `fab review --done` shows review minutes in `fab runs`; fake-agent test passes with `--task` | `fab runs` with a review column                     |
| T2   | Pilot on the private pilot project: one task with the maintainer present (`--task`, `--until 1h`), then a two-hour run of three tasks, then two parallel runs on two branches. Record measurements.                                                                                                     | T2a                   | AC7, MC1, MC2; rate-limit behaviour recorded                                          | The pilot's `summary.md`                            |
| T2b  | Fan-out: `--fan`, `--jobs`, per-task worktrees branched from the run branch, local merge, conflicts parked.                                                                                                                                                                                            | T2                    | AC10                                                                                  | Two tasks merged in one run                         |
| T3   | Skills: promote `new-project-spec`, `new-adr`, `session-handoff`, `visual-check` to `dotfiles/claude` and `dotfiles/opencode`; `new-project-spec` emits the Tasks table columns and ends with the `fab run` command.                                                                                   | T2                    | A spec written with the skill runs through `fab` on a second project                  | That project's first run summary                    |
| T4a  | Beads trial as a second queue source, stealth mode, on a project with many small issues. Go or no-go recorded as an ADR.                                                                                                                                                                               | T2                    | ADR written                                                                           | `bd ready` feeding a run                            |
| T4b  | Private knowledge repository: `facts.md` on the maintainer's git server, included into global instructions and `fab` prompts.                                                                                                                                                                          | T2                    | A parked "fact only the maintainer knows" question is answered from it in a later run | The include in `fab`'s prompt arguments             |
| T4c  | `mx` adapter for self-hosted ntfy: notify and ask from the phone.                                                                                                                                                                                                                                      | T1a                   | A run's end reaches the phone; an `mx ask` is answered from it                        | Phone screenshot                                    |
| T4d  | Checkpoint auto-continue: a run ends with `mx ask "continue?"` and restarts on yes.                                                                                                                                                                                                                    | T2, T4c               | A run spans two checkpoints with one answer                                           | `events.jsonl` with two segments                    |
| T4e  | `rm` guard hook for interactive sessions: deny, point to `trash` or `git rm`.                                                                                                                                                                                                                          | -                     | A test session's `rm` is refused with the hint                                        | The hook's message                                  |
| T4f  | Replace the per-tool status hooks in Claude's settings and the opencode plugins with `mx`, and `_zp_host` with `mx host`.                                                                                                                                                                              | T1a, bake-off decided | One hook per event in Claude's settings; zp uses `mx host`                            | `grep mx ~/.claude/settings.json`                   |
