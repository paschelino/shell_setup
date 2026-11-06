# unattended-runs progress log

Handoff notes between sessions. Newest entry on top. Each entry covers: done,
open, surprises, next step.

---

## 2026-11-06: T1a, mx built and stowed

- **Done:** T1a. `dotfiles/mx/.local/bin/mx`, stowed to `~/.local/bin/mx`
  (folding allowed, the directory already exists), README section, commit
  `037ff3f`. Verbs `host`, `state`, `notify`, `ask`, `answer`, `session`. Tested
  in this TUIOS pane: all six states land in `tuios get-agent-state` (`waiting`
  as `needs_input --kind question`, `error` as `errored`), `notify` arrives as
  mail to the person's Inbox (`send-agent-message -w human`, which waits for
  them, rather than a session notice) and `osascript` exits 0. With the
  multiplexer variables stripped: `host` prints `none`, every verb exits 0, the
  fallback `ask` was answered from a second process via `mx answer` and times
  out with exit 2, cleaning its question file.
- **Open:**
  - AC1 is checked for TUIOS and outside only. Detection for tmux, herdr and
    Zellij follows the `_zp_host` logic but hasn't run in their panes yet; the
    tmux adapter (`workmux set-window-status`, `tmux display-message`) is
    untested. Check when such a pane is at hand, at the latest in T4f.
  - `README.md` was already not prettier-clean before this work; a separate
    `style` commit would reformat 16 unrelated lines. Left for the maintainer.
  - The herdr adapter could use its socket API as its Claude hook does (python
    over a Unix socket). Deferred to T4f with the bake-off.
- **Surprises:**
  - Inside zsh functions `$0` is the function name, so the usage text reads the
    script through `${0:A}` captured at top level.
  - BSD `grep` has no `\|` alternation in basic regexps; use `-E` or `-F`.
- **Next step:** T1b (`fab`).

## 2026-11-06: T0, sandcastle verified in a sandbox, token pending

- **Done:** T0 checks 2 to 6, on `@ai-hero/sandcastle` 0.14.0 (2026-11-02, the
  last stable release; the GitHub docs describe the `1.0.0-v1-next` nightlies,
  whose API matched for everything used here). Instead of an agent, a custom
  `AgentProvider` ran a shell script as the "agent" (`buildPrintCommand` returns
  `sh -s` with the prompt as stdin), so the sandbox could be probed without a
  token. Scripts are in the session scratchpad only.
  - **Check 2, clean repository:** `seatbelt()`, `branchStrategy: head`, `cwd`
    set to a worktree from `git wt --nocd`, `logging.path` outside the repo.
    Nothing appeared in the worktree or the main checkout besides the probe's
    own file; no `.sandcastle/` anywhere. `git wt` puts worktrees under `.wt/`
    in the repository by default and the main checkout's `git status` stays
    clean.
  - **Check 3, visibility:** the worktree's `CLAUDE.md` and `.agents/skills/`
    are readable inside. The real home is not: `ls ~/.claude` and reading
    `~/.config/opencode/AGENTS.md` fail with "Operation not permitted". The
    sandbox home is a fresh temp dir holding only a `.gitconfig`; the
    environment is `HOME PATH PWD SHLVL TMPDIR`. Writing outside the worktree is
    denied. The network is open.
  - **Check 4, status path:** harness hooks can't load (settings hidden). But
    `tuios get-agent-state` run inside the sandbox still found the pane, through
    the controlling terminal, so the tuios socket is reachable from inside. `mx`
    stays a host-side call as decided; this only means a project-local hook
    would also work.
  - **Check 5, tools:** `node` 26 (mise install dir), `python3` (mise shim),
    `git`, `claude` 2.1.311, `opencode` and `tuios` run inside. `playwright` is
    not on `PATH` (it is a project dependency, run through `npx`). Playwright's
    browser cache under `~/Library/Caches/ms-playwright` is hidden; a read-only
    `seatbelt({ mounts })` entry for it was accepted. `hugo` is a dangling mise
    shim on the host itself, unrelated to the sandbox.
  - **Check 6, structured output:** `Output.object` with a Zod schema of the
    spec's task report round-tripped from a `<report>` tag; the prompt must
    contain the opening tag literal.
- **Open:**
  - **Check 1, OAuth token in the sandbox:** needs the maintainer to run
    `claude setup-token` and put the result in `~/.config/fab/.env` as
    `CLAUDE_CODE_OAUTH_TOKEN`. Verified at the first real run in T1b.
  - **Check 7, opencode in the sandbox:** opencode's auth lives under the hidden
    home too. Deferred to the first work-machine use; note the likely need for a
    read-only mount or env-based auth.
  - mise shims inside the sandbox resolve without the global mise config (python
    did), but a project's tool versions come from its own `mise.toml`, which is
    visible. Confirm with the pilot's `hugo` in T2.
- **Surprises:**
  - tuios `set-agent-state` states are
    `none, working, needs_input, idle, done, errored, unknown`, with `-m`,
    `--kind question|approval|auth`, `--if-state` and `-w`. `mx` maps `waiting`
    to `needs_input --kind question` and `error` to `errored`.
  - tuios `notify` already pushes Inbox items to a phone (Web Push and providers
    in `config.toml`). Relevant for T4c before building anything.
- **Next step:** T1a (`mx`). T0's remaining two checks ride along with T1b.

## 2026-11-06: Spec drafted after the interview

- **Done:** T0a. Interview with the maintainer over several rounds, an analysis
  of 75 local Claude transcripts (255 clarifying questions, no plan mode use), a
  read of the maintainer's three spec-driven projects and of the sandcastle and
  Beads documentation. Result: adopt sandcastle (ADR-0001), build `mx`
  (ADR-0002) and `fab`, worktrees mandatory and PRs optional (ADR-0003). Spec,
  run brief, this log and the private notes file written.
- **Decisions recorded in the spec**, not repeated here: queue is the spec's
  Tasks table; pilot is the maintainer's static-site project named in the
  private notes; notifications tuios plus macOS first; sandbox yes, with status
  reported by the host process through `mx`, never by an agent; checkpoints
  relative to kickoff, first after about two hours; policy inside a run (commit
  yes, push once at the end, dependencies allowed and listed, deletes confined
  to the worktree and listed).
- **Open:**
  - T0's seven checks. The biggest unknowns: whether `seatbelt()` hides
    Playwright's browser cache, and whether sandcastle writes anything into a
    `head`-strategy worktree.
  - Rate limits on the Max plan with parallel runs. Measure in T2.
  - Beads (T4a) and a private knowledge repository (T4b) are deferred on
    purpose: both add state to maintain, and the pilot decides whether they earn
    it.
  - Names `mx` and `fab` are proposals the maintainer may change before T1a.
- **Surprises:**
  - `~/.claude/projects/` directory names start with `-`, so globs there need
    `--` or `./` prefixes in shell commands.
  - The maintainer's live `~/.claude/settings.json` holds three parallel status
    hooks (tuios, workmux, herdr) and no permissions block; auto mode handles
    approvals. Don't touch it in this project (run brief).
  - sandcastle's native sandbox gives the agent a fresh private home: global
    instructions and hooks don't load inside. The project's own files do.
  - sandcastle's `branch` and `merge-to-head` strategies create
    `.sandcastle/worktrees/` inside the repository; `head` with our own `git wt`
    worktree avoids that.
- **Next step:** T0.
