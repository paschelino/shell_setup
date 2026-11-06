# unattended-runs progress log

Handoff notes between sessions. Newest entry on top. Each entry covers: done,
open, surprises, next step.

---

## 2026-11-06: T1c, prompts written and verified with a real sandboxed run

- **Done:** T1c. `prompts/task.md` rewritten from the pilot project's run brief
  and its `session-handoff` skill: precedence (run brief over prompt over
  global instructions), parking rules, `$TMPDIR` for temporary files, no
  worktrees or branch switches, verify before done and never weaken a check,
  a clean tree at the end because leftovers leak into the next session, a
  progress entry for parked and failed tasks too, and a `DATE` argument so the
  agent needn't compute it. `prompts/summary.md` is now the summary's
  wording, a template with `{{KEY}}` slots that `lib/summary.mts` fills with
  the lists already rendered. First real run: three tasks on a throwaway
  project (T2 asks for a fact only the maintainer knows). Result in 3 minutes:
  T1 done, T2 parked, T3 done, stop reason "queue empty". Each task left an
  entry in the project's `progress.md` in the asked shape, atomic conventional
  commits with the attribution line, the spec row marked and ACs ticked;
  the parked task committed only its entry, with the question and
  recommendation under **Open**, and `summary.md` carries question and
  assumption. Nothing outside the agent's commits appeared in the worktree or
  the main checkout. That verifies T0 check 1 (the OAuth token works inside
  `seatbelt()`), AC6 and AC7. AC12's grep ran; hits read.
- **Decisions:**
  - Kept the summary rendered by code, as T1b decided, but moved its wording
    into `prompts/summary.md` so the spec's file exists and the maintainer can
    edit the text without touching TypeScript. A slot without a value throws.
  - The prompt tells the agent to create `progress.md` next to the spec when
    the project has none, so every run leaves a hand-off log.
  - Agent commands get `CLAUDE_CODE_TMPDIR="$TMPDIR/claude"` and
    `TMPPREFIX="$TMPDIR/zsh"` prefixed in `main.mts` (`withSandboxTmp`), for
    Claude and opencode alike. The command runs through `/bin/sh` inside the
    sandbox, so `$TMPDIR` expands to its private temp dir.
- **Open, for the maintainer:**
  - The agent's `summary` fields came back long (four sentences with commit
    ids); the prompt now asks for two to four sentences. Fine for the pilot?
    Recommendation: leave it, judge on the pilot's summary (MC1).
  - Three real sessions and one host `claude -p` call were spent on this
    test, all on the Max plan. Rate limits showed nothing at this size.
  - The fab tests again sent a few state changes and notifications to this
    tuios pane's Inbox. Dismiss them.
- **Surprises:**
  - Claude Code refuses to start in the sandbox with
    `EPERM: operation not permitted, open '/tmp/claude-501'`: it keeps its
    scratch directory under `/tmp/claude-<uid>`, ignoring `TMPDIR`, and the
    seatbelt profile allows writes only in the worktree, the private home and
    the private temp dir. `CLAUDE_CODE_TMPDIR` moves it, and Claude creates
    the directory itself. Neither T0 nor T1b could see this: no real agent ran.
  - zsh heredocs fail inside the sandbox ("can't create temp file for here
    document"): zsh's `TMPPREFIX` defaults to `/tmp/zsh`. The agent's Bash
    tool uses zsh because the sandbox passes `SHELL=/bin/zsh`. `/bin/sh` and
    bash heredocs were fine. The agent worked around it with `printf` before
    the fix.
  - Session capture lands in the host's `~/.claude/projects/<encoded worktree
    path>/`, so `claude --resume` from the worktree finds the run's sessions.
  - The sandbox's git identity comes from the host's `user.name` and
    `user.email`; the agent's commits are authored as the maintainer, with the
    `Co-Authored-By` line Claude Code adds.
  - sandcastle's prompt files execute `` !`command` `` blocks; the prompt must
    never contain a backtick right after an exclamation mark.
- **Next step:** T2, the pilot. Before it: check the pilot's `mise.toml` for
  `hugo` (T0 note) and read `~/.config/zp/fab-notes.md` for the branch and
  spec.

## 2026-11-06: T1b, fab built; T1c drafted; waiting for the token

- **Done:** T1b, commits `6f7ac74` (fab) and `c22cb74` (install wiring).
  `dotfiles/fab` stowed with `--no-folding`, `npm ci` run in `~/.config/fab`,
  sandcastle pinned at 0.14.0 with a lockfile. `fab run`, `fab runs`,
  `fab status`; `main.mts` with `lib/{tasks,status,report,summary,env}.mts`;
  `prompts/task.md` (T1c's draft) and `test/fake-agent.sh`. README section.
  Verified with the fake agent on the throwaway repository from T0: AC4 (no
  `.env`: instructions, exit 2), AC5 (only the agent's commits appear, main
  checkout clean, no `.sandcastle/`), AC6 half (`summary.md`, `events.jsonl`),
  AC7 half (parked question and assumption reach `summary.md`; the run continued
  with tasks that don't depend on it), AC8 (`--until 0s` starts nothing,
  `--until 3s` with a 4-second task stops after it, both named in the summary),
  AC9 (second run on a busy worktree refused with run id and pid, a run on
  another branch proceeds, lock removed afterwards). The tuios pane went
  working, done, and the run's notification reached the Inbox.
- **Decisions:**
  - `fab run` accepts a directory as `<project>` besides a name from the zp
    list, so tests never touch the private list.
  - The summary is rendered by `lib/summary.mts`, not from `prompts/summary.md`:
    lists need loops. Spec deviation, noted in T1c's row.
  - Dependencies and retries are two sets: a parked or failed task is not
    offered again in the run, and tasks depending on it wait. First version
    treated parked as done for dependencies; caught by the fake test.
  - A failed-only run exits 1; a run with any task done exits 0. The default
    model for Claude is `claude-fable-5-1`; opencode needs `--model`.
  - Private `~/.config/fab/mounts` created with Playwright's cache path.
- **Open, for the maintainer:**
  - **Token:** run `claude setup-token`, then
    `umask 077; print 'CLAUDE_CODE_OAUTH_TOKEN=<token>' > ~/.config/fab/.env`.
    That unblocks T0 check 1, T1c's real run and T2.
  - The fab tests sent about eight notification mails and state changes to this
    tuios pane's Inbox. They are harmless; dismiss them.
  - The fake agent runs with `--agent fake` and `FAB_FAKE_AGENT=<script>` only.
    It can't model a Claude session's progress entry, so AC6's first half and
    the prompt's wording stay unverified until a real run.
  - Push isn't tested (the throwaway has no remote). First real run with a
    remote: watch `summary.md`'s Push line.
- **Surprises:**
  - Node's strip-only TypeScript rejects constructor parameter properties.
  - Node resolves imports from a symlink's real path, so a stowed `main.mts`
    would look for `node_modules` inside the repository; `fab` runs Node with
    `--preserve-symlinks --preserve-symlinks-main`.
  - The sandbox can't read a test script under the home directory (exit 126);
    the fake provider inlines the script text into the command.
  - zsh expands `$id` before assigning it when both are on one `local` line.
  - A `git wt` worktree under `.wt/` in the repository leaves the main
    checkout's `git status` clean.
- **Next step:** T1c with a real agent as soon as `.env` exists (one task on the
  throwaway repository, `--agent claude`), then T2.

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
