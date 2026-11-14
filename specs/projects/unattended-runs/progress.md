# unattended-runs progress log

Handoff notes between sessions. Newest entry on top. Each entry covers: done,
open, surprises, next step.

---

## 2026-11-14: T2p, the hand-off protocol interviewed and proposed as ADR-0005

- **Done:** the interview with the maintainer, five rounds of three to four
  questions, and ADR-0005 (status proposed) with the protocol as seven
  numbered steps, the actors, the never-ask list and the verbs it changes.
  The T2h implementation row and its kickoff prompt are added. `fab` itself is
  unchanged, as the kickoff asked. No agent session spent.
- **What the interview settled**, beyond the ADR's text:
  - Three actors: `fab`, which never asks; an orchestrator, the interactive
    agent session in the project that runs the verbs on the maintainer's word
    and records findings in the project; the maintainer, who waits for nobody.
  - The end notice names the review order and the `fab review <id>` command.
    Labels are `<project> <branch> <task ids>`; the id stays the key and
    `fab review --done` requires it, so two open reviews can't be confused.
  - `fab run` refuses a project with a live finished run (`--force` overrides).
    The maintainer chose the refusal over a warning.
  - `fab review` opens the summary pager and the demo as two panes in the
    current multiplexer session (new `mx open` verb), demo in the foreground so
    its output is visible, and prints a short brief for the orchestrator.
  - The demo is the project's own `scripts/demo`, zero arguments, worktree as
    cwd, `FAB_*` variables; a private override in `~/.config/fab/projects/<name>`
    for repositories the maintainer can't change. The maintainer first asked
    for a `<project>/.fab/` indirection on top, then agreed it adds a layer
    and breaks the run brief's rule.
  - `--done` asks nothing: stop demo, merge check, `--no-ff` merge, `git wt
    -d`, one push, stamp, archive. Review feedback and parked answers are the
    orchestrator's to record, after the merge. A conflict is exit 3, worktree
    kept, resolved by the orchestrator in the worktree, then `--done` again.
  - Reviewed runs move to `~/.local/state/fab/archive/`; `fab runs --all`.
  - Push after the merge: the global rule lists "a worktree being merged back"
    as a consumer, so `--done` pushes once; `--no-push` skips it. The pilot
    sessions not pushing `main` after their merges was more cautious than the
    rule asks.
- **Open, for the maintainer:**
  - **Accept ADR-0005** (edit its status to `accepted`), then mark T2p done.
    T2h's kickoff stops if the ADR is still proposed.
  - **The pilot's `main` is unpushed** since the four merges. Recommendation:
    push it once now, as the rule's "worktree being merged back" case.
  - **T4d's shape** changes with the never-ask list (a consequence in the ADR):
    a `--continue` policy at `fab run`, or a decision in the review.
    Recommendation: decide when T4d is next, not now.
  - **A `scripts/demo` for the pilot** is a pilot commit (private notes), to be
    made before T2h's first real review with the verbs.
- **Surprises:**
  - The maintainer's first instinct was interactivity at `--done` (per parked
    question); thinking about where the feedback is written moved it to the
    orchestrator session and left `--done` with no question at all.
  - The global push rule already answers the merge-push question; nobody had
    read it against `fab`'s merges before.
- **Next step:** T2h once ADR-0005 is accepted; in parallel T3 is unblocked
  (depends on T2 only).

## 2026-11-14: T2 done, the pilot's three steps; two parallel runs show no throttling

- **Done:** T2. The third step, two parallel runs on two branches from the
  merged `main`, started one second apart, each
  `--task <id> --until 1h --no-push --sandbox podman` in the shared podman VM (4
  CPUs, 6 GB):
  - Run A: its task done in 20.5 minutes, 49 tool calls, three commits.
  - Run B: its task done in 24.5 minutes, 60 tool calls, three commits.
  - Both containers started within a second (1.0 s and 0.8 s). No parked
    question, no intervention. **Rate limits:** neither log holds a rate-limit,
    overload or API-error line, and the durations sit in the range of the single
    runs (12 to 50 minutes per task), so two parallel runs on the Max plan
    showed no throttling at this size, and the shared VM no slowdown.
  - The predicted conflict is there: both agents extended the viewer and the
    layout check, so the second branch conflicts in those two files on top of
    the first, and after the first merge in the spec, progress log and viewer
    test too. Reviews: 7 and 7 minutes. Both merged by the session on the
    maintainer's answers: the first at once, the second after the session
    resolved the conflict in the branch's worktree (both functions kept, main's
    test signature), 182 unit tests and both new browser checks passing in
    Chromium on the host. The second review found a fix for a new row, added to
    the pilot's spec with its AC rather than done before the merge.
  - Totals over the pilot (four runs, six tasks): five done, one parked, none
    failed; 24 commits; stop reason always "queue empty"; zero questions to the
    maintainer during a run; reviews 6, 34, 7 and 7 minutes, 54 in all.
- **Measured:**
  - The second review, three tasks, took 34 minutes against 6 for one task.
    MC1's 15 minutes hold per task, not per run of three.
  - A run's hand-off costs more than its review: the maintainer's pace to
    review, verify and answer is hours, not minutes, between runs. The pilot's
    wall time from first start to last merge was about twelve hours, of which
    the agents worked 2 h 26 min; the rest was the night and the reviews.
- **Decisions:**
  - Merging and worktree cleanup were done by the session on the maintainer's
    answer to a four-option question (merge, keep or drop worktrees, message
    style), since `fab` has no verb for it yet.
  - A merge commit another branch already builds on is not amended: the first
    merge keeps git's default message after an amend doubled it in history and
    was undone.
  - `git wt -d` on a merged branch removes the branch too; accepted, every
    commit is in `main`.
- **Open, for the maintainer:**
  - **fab's hand-off verbs**, after the protocol session: `fab review --done`
    offering the merge into `main` and the worktree's removal, and `fab review`
    starting the project's demo (configurable per project). Both came up at the
    exact moment they were missing. Recommendation: one task row for both, after
    the protocol ADR.
  - **Run ids aren't human-readable** (`<project>-<date>-<time>`), and with two
    runs to review it wasn't clear which to take first. Feedback from the
    maintainer, 2026-11-14. Recommendation: keep the id and add a readable label
    on top (branch, task ids), shown by `fab runs`, `fab review` and the
    hand-off message, which also says the review order (the clean merge first)
    and why. Part of the hand-off task row above.
  - **`fab review` prints the summary with `cat`**; a review wants to scroll
    both ways and read Markdown rendered, so a pager (`$PAGER`, `less`) or a
    Markdown-aware viewer such as `bat` or `glow` when installed. Feedback from
    the maintainer, 2026-11-14. Recommendation: pipe through `$PAGER` by
    default, `bat` when present, `--no-pager` for scripts; same task row.
  - **The parked M5.3 question** (five prepared sets, three or two) is still the
    pilot's; its next `fab run` offers M5.3 again, with the assumption already
    built. The pilot's queue now reads two ready rows, M5.3 and the new M5.7,
    then the two M6 rows.
  - **The pilot's M6 tasks** stop for a mock-up approval and the sandbox has no
    Artifact tool: decide the mock-up route before M6 (private notes).
  - **Delete list** below: the four pilot runs under `~/.local/state/fab/runs/`
    are the measurements; keep them until T3's first run, then they can go.
- **Surprises:**
  - Starting two containers in the same second cost nothing visible; the T2s
    worry about VM contention didn't show at one browser gate per run.
  - `git merge-tree --write-tree` with `--name-only` is the cheap way to see a
    conflict before merging; it named the two files at once.
- **Next step:** T2p, the hand-off protocol with the maintainer present (row
  and kickoff prompt added after the T2 entry); then T3, since a second
  project is the next real test, with T2b if fan-out matters sooner.

## 2026-11-14: T2 in progress; the attended run and the two-hour run are done

- **Done:** two of T2's three steps, both `--sandbox podman`, `--no-push`, the
  pilot's spec and run brief unchanged by `fab`. Each run's worktree came from
  the pilot's `main` with `git wt --nocd <branch> main`.
  - **Attended run** (one task, `--task`, `--until 1h`, the maintainer on
    `fab tail`): the task finished in 12.5 minutes with 53 tool calls and three
    conventional commits; stop reason "queue empty"; no parked question, no
    intervention. The container started in 0.8 s (mise cache warm). The agent
    marked the row `**Done**`, ticked its AC and left a progress entry with
    measurements, decisions, open points and surprises. Review by `fab review`
    stamps: 6 minutes, note "Works as expected"; merged into the pilot's `main`
    as its first merge commit. **MC1 holds.**
  - **Two-hour run** (three tasks, `--until 2h`, MC2): ended after 87 minutes
    with the queue empty, two tasks done and one parked, 15 commits, 233 tool
    calls, no question to the maintainer and no intervention. Task durations
    from `events.jsonl`: 49.9, 25.1 and 12.2 minutes. The parked task is a real
    fork: the spec's AC asks for five prepared leaf sets, the run brief caps
    them at two for phone memory; the agent built the half that needs no
    decision, recorded question and assumption in the pilot's `progress.md` and
    the run's `summary.md`, left the AC unticked and the row unmarked, and the
    run went on to the next task. **AC7 observed on the pilot; MC2 holds** (a
    two-hour budget, finished early). No rate-limit sign in either log.
- **Measured:**
  - The agent runs the pilot's browser checks per check and per engine, as
    background `nohup` chains polled every five seconds, so no tool call hits
    the ten-minute limit. The full three-engine gate didn't fit either run; the
    agent says so under Open and leaves it to the maintainer's merge gate.
  - What the sandbox can't run, by design: the four export-based checks of the
    pilot's `pnpm check` (their data directory is not in the worktree) and the
    leaf-frame comparison (the saved mock-up is not there). The agent reported
    both instead of weakening a check.
  - Chromium's mock-up comparison shows 62 text-width lines off by 0.6 to 2.4 px
    in the container, the same before and after the task: Linux text metrics
    against values measured on the Mac (ADR-0004's consequence).
  - Hand-off cost: the maintainer's review of run 1 took 6 minutes; run 2's
    review is pending at the time of writing.
- **Decisions:**
  - Hand the review over with a tuios message that names the commands, and read
    the merge into `main` (or the review stamp) as the answer. A blocking
    `ask-human` question for "merged?" was the wrong shape: it outlived the
    merge and had to be hidden before `fab review` could start.
  - The two parallel runs wait for the two-hour run's merge, as the run plan
    says, so their branches start from the merged `main`.
- **Open, for the maintainer:**
  - **Review and merge of the two-hour run's branch**, with the parked AC19
    question: five prepared sets as the spec asks, or three as the agent
    assumed, or the run brief's two. Recommendation: three, the run brief's
    sentence changed to say so, as the agent assumed.
  - **The hand-off protocol** between fab and you, after T2's measurements and
    before the feedback items are built: no blocking question during review;
    `fab review` optionally starting the project's demo (for the pilot
    `hugo server` in the run's worktree), configurable per project; the human
    pace of review, verify and answer. Recommendation: a short joint session
    ending in a proposed ADR, which also informs T4c and T4d, then a task row.
  - The agent's `nextTask` in `summary.md` names the parked row again, since it
    is the first row not done. Fine for a queue; say "parked" there?
    Recommendation: leave it until the summary format is revisited with MC1.
  - The merge commits in the pilot are git's default "Merge branch" messages,
    not conventional. Recommendation: your call per merge; nothing is pushed.
- **Surprises:**
  - The agent, in the container, found prettier and markdownlint missing from
    `PATH` and used `npx --yes` with a cache in `$TMPDIR`; the pilot's `pnpm`
    scripts assume them.
  - A `cut` stage in a log-watching pipeline block-buffers and swallowed the
    task events for an hour; `grep -o` instead.
  - tuios `ask-human --timeout` takes a bare integer; `50s` is an error that
    returns at once, so a wait loop built on it spun through its iterations in
    seconds.
- **Next step:** T2, the two parallel runs on M5.5 and M5.6 once the two-hour
  run's branch is merged; then the T2 entry with the rate-limit measurement.
## 2026-11-13: T2s, podman is the sandbox for browser work; ADR-0004; fab --sandbox

- **Done:** T2s. ADR-0004 accepted: projects with browser work run in a podman
  container built from fab's own `Containerfile` on Playwright's
  `v1.65.0-noble` image; Seatbelt stays the default. `fab run --sandbox
  seatbelt|podman` (commit below) with `lib/sandbox.mts`: the podman sandbox
  starts a stopped machine, builds the image tagged by the Containerfile's hash
  with an empty build context, mounts fab's two caches
  (`~/.local/share/fab/podman/{mise,pnpm}`) under `/home/agent/.local/share`,
  sets `TMPDIR` and pnpm's store variables, and runs `mise install` as a
  sandcastle `onSandboxReady` hook. README, spec contracts, the T2 kickoff and
  the private notes carry it. Verified with the fake agent on the throwaway's
  `fab/probe`: a cold run (image build, five tools downloaded) and a warm run in
  which Chromium 158, Firefox 159 and WebKit 27.2 launched headless and loaded
  a worktree file. The pilot's `check-layout.mjs` ran in the container once,
  on a throwaway clone in the scratchpad (built with hugo and pagefind from
  mise, `--ac 1,2`, all three engines): PASS. No real agent session spent.
- **Read in sandcastle 0.14.0's podman provider:** it never builds; it checks
  that `imageName` (default `sandcastle:<repo dir>`) exists and otherwise says
  to run `podman build`. Only the CLI's `build-image` reads
  `.sandcastle/Containerfile`. It mounts the worktree at
  `/home/agent/workspace`, the worktree's `.git` file and the main
  repository's `.git` at their host paths, caller mounts as given, runs as uid
  1000 with `--userns=keep-id`, `--entrypoint sleep infinity`, and removes the
  container after the task. Hooks: `sandbox.onSandboxReady` runs before the
  agent, fails the task on a non-zero exit, 60 s default timeout.
- **Measured** (fake agent; Seatbelt from T2a and a baseline run today):
  - One-off: `podman machine init` 1:54; image pull 3:40 (2.57 GB); fab's
    image build 29 to 37 s (3.07 GB). Machine start after a boot 16.5 s.
  - Task start to the agent's first line: Seatbelt 0.4 s; container 1.3 s warm,
    191 s cold (`mise install` of node, python, hugo, pagefind, pnpm; 186 s of
    it in sandcastle's "Setting up sandbox").
  - `mise install` cached: 77 ms vs 371 ms. `pnpm install --frozen-lockfile`
    cached: 47 to 183 ms vs 237 ms (cold 2.8 s into the Linux store).
  - Browsers: Seatbelt SIGABRT, all three; container 0.65 s, 1.65 s, 1.73 s to
    launch and load a page. Whole fake task 1.7 s vs 8 s.
  - Pilot clone in the container: `pnpm install` 0.4 s, build 61 s,
    `check-layout --ac 1,2` in three engines 4.6 min, PASS.
- **Decisions:**
  - The Containerfile is committed in the stow package: it holds versions, no
    paths. Its hash is the image tag, so an edit rebuilds and nothing else does;
    the build context is an empty temp directory, so the file can't copy
    anything in. Pinned there: Playwright 1.65.0 (the pilot's), Claude Code
    2.1.311 (the host's today), pnpm 12.16.1, mise v2026.11.8. opencode is not
    in the image yet.
  - `~/.config/fab/mounts` and `sandbox.env` stay Seatbelt's. The container's
    mounts are fab's own caches at fixed paths, not user-configurable yet:
    macOS cache paths mean nothing in Linux, and pnpm's macOS store is better
    left alone.
  - Each project's tools come from its `mise.toml` through `mise install`
    before the agent starts, with `MISE_TRUSTED_CONFIG_PATHS` set to the
    workspace and shims first on `PATH`. Inside the container `node` is
    therefore the pinned version, unlike under Seatbelt.
  - fab starts a stopped machine but doesn't create one: init takes two
    minutes and chooses CPU and memory. This session's machine: 4 CPUs, 6 GB,
    40 GB disk, libkrun.
  - `--sandbox` is per run, default `seatbelt`; no per-project field in the
    project list. The pilot's run plan in the private notes says `--sandbox
    podman` on every run.
  - Linux WebKit stands in for Safari's engine (ADR-0004).
  - Seatbelt's T2a rules stay a record in the previous entry, not a patch.
- **Open, for the maintainer:**
  - The podman machine and the two images live in
    `~/.local/share/containers/`; the caches in `~/.local/share/fab/podman/`.
    Keep them for T2. If you don't want the VM at all,
    `podman machine rm podman-machine-default`.
  - Two parallel runs (T2's third step) share the VM's 4 CPUs and 6 GB and one
    container each; a browser gate per run may slow both. Recommendation: leave
    it for the measurement, `podman machine set --cpus 6 --memory 8192` if it
    hurts.
  - The pilot's gate: two ACs in three engines took 4.6 minutes in the VM. The
    full gate may be slower than the 45 to 60 minutes on macOS; the 10-minute
    tool-call limit makes per-AC runs necessary anyway. Recommendation: the
    pilot's spec notes that AC16 timings come from the container.
  - The image's `claude` is pinned to 2.1.311 and will drift from the host's.
    Recommendation: bump `CLAUDE_CODE_VERSION` when a run needs a newer
    feature, not on every release; the build is 30 seconds.
- **Surprises:**
  - podman creates a bind mount's missing parent directories as root, so
    `/home/agent/.local` was root's and mise couldn't make
    `~/.local/state/mise`. The Containerfile pre-creates `.local/share`,
    `.local/state` and `.cache` for the agent.
  - In the Playwright image uid 1000 is `ubuntu`, `pwuser` is 1001; the
    Containerfile renames whoever holds 1000 to `agent`.
  - The main repository's `.git` is mounted at its host path, so the container
    sees the path's name (for the pilot, `/Users/<name>/dev/<project>/.git`).
    Only the git directory, not the checkout.
  - The probe's `[ -e ~/.ssh ]` says "visible" under Seatbelt: stat is allowed,
    read is denied (T2a). An existence test is not a read test.
  - The podman machine's `inspect` lists no mounts, yet `/Users` and
    `/private` bind-mount fine; libkrun shares them implicitly.
- **Next step:** T2, with `--sandbox podman`.

## 2026-11-13: browsers in the sandbox explored; the question reframed as T2s

- **Done:** an hour of profile bisection with plain `sandbox-exec` and
  sandcastle's own Seatbelt profile text, on the throwaway's `fab/probe`
  worktree. No real agent session. The crashes reproduce outside sandcastle and
  are missing rules, not a limit of sandboxing: all three headless engines
  launch and render with these additions, while `~/.ssh` stays unreadable and
  `~` unwritable:
  - Chromium: `mach-register` and `mach-lookup` for
    `^org\.chromium\.Chromium\.MachPortRendezvousServer\.`; nothing else. Its
    helpers are forked children and stay inside. It refuses `file://`.
  - Firefox: a broad `mach-lookup` (it needs LaunchServices for
    `_RegisterApplication`), `mach-register` for `^org\.mozilla\.`, and
    `MOZ_DISABLE_{CONTENT,GPU,RDD,SOCKET_PROCESS,UTILITY}_SANDBOX=1`, because
    macOS doesn't nest sandboxes; it crashes even under `(allow default)`
    without them. Its helpers stay inside: a worktree file loads, `~/.zshrc` is
    refused.
  - WebKit: the broad `mach-lookup`, `mach-issue-extension`, and
    `(allow mach-lookup (xpc-service-name-prefix "com.apple.WebKit"))` after
    sandcastle's XPC deny. Its Networking, GPU and WebContent helpers are
    started by launchd (parent pid 1), so they run outside the profile under
    WebKit's own sandbox; the UI process hands them extensions. It also needs
    `com.apple.windowserver.active`. No hidden file could be read through it,
    but neither could a worktree file (`file://` timed out), so that boundary is
    unverified. `process-info*` beyond the sandbox is not needed.
- **Measured:** the broad `mach-lookup` is the cost. Apple Events stay blocked
  (`appleevent-send` is denied) and `lsopen` too, but `pbcopy` succeeded: the
  pasteboard is writable, and `com.apple.pasteboard.1` is not its service name.
  Denying `pasteboard.1`, `appleevents` and `tccd` after the allow keeps the
  engines working; denying `launchservicesd` or `coreservicesd` breaks Firefox
  and WebKit. `sandbox-exec` offers no denial log without root, so the exact
  lookup list couldn't be enumerated.
- **Decisions:**
  - Not recording the host Playwright server or a no-sandbox run as options any
    more: the first opens every `file://` path the maintainer can read, the
    second everything.
  - The question is reframed, with the maintainer: not how browsers start, but
    what harness survives a Playwright, macOS or sandcastle update and runs
    unchanged on a cloud node. The Seatbelt rules are a macOS-only list of
    service names and browser variables; a container pins browsers and OS
    dependencies per Playwright version. A verification service the agent asks
    for a gate is a third shape (verification outside the agent's hands,
    serialised gates, cloud-separable) that still needs a sandbox for the test
    run and is slower for the agent's fix loop. Decided as T2s with ADR-0004
    before T2; the spec's open question and the run brief carry it.
- **Open, for the maintainer:**
  - T2s weighs: Linux WebKit is not Safari's engine, and the pilot's
    three-engine checks and AC16 timings are calibrated on macOS; sandcastle's
    `podman()` builds from a Containerfile, whose place must leave no trace in
    the project; worktree I/O through the podman machine; pnpm's store can't
    hard-link into a container. Seatbelt stays the sandbox for projects without
    browser work.
  - If Seatbelt is chosen after all, the route is `patch-package` on
    `dist/sandboxes/seatbelt.js` plus an upstream proposal for an opt-in profile
    option, in the spirit of sandcastle's hardening issue #1282.
  - The probe profiles are in `/tmp/fab-tests/sb/` (`combined.sb` is the working
    one) until macOS cleans `/tmp`; the rules above are the record.
- **Surprises:**
  - `sandbox-exec` rejects `(with report)` on deny rules and wrote no
    `(trace …)` file; the kernel logged no denials either. Bisection it was.
  - The pasteboard probes overwrote the maintainer's clipboard twice
    (`fab-probe`, `fab-probe-2`). Don't probe the pasteboard by writing.
  - Chromium's headless shell refuses `file://` even for the worktree; the
    pilot's check serves pages by request interception, so it doesn't matter.
- **Next step:** T2s.

## 2026-11-13: T2a, fab ready for the pilot; browsers don't launch in the sandbox

- **Done:** T2a. `fab` gained `--task <id,…>`, `--idle <duration>` (default
  `1h`), read-write mounts (` rw` suffix), a private `sandbox.env` for variables
  inside the sandbox, `fab tail`, and `fab review` with
  `fab review --done [note]`; `fab runs` shows done, parked and failed, run time
  and review minutes. Commits `cf03a3c`, `263fab3`, `e55d100`, `db05318`,
  `65ac694`. The pilot's spec and run brief are converted on its `main`, in two
  commits of its own. Verified with the fake agent on `/tmp/fab-tests/alpha`,
  recreated from the private notes:
  - `--task T3` with T1 open stops with "queue empty; T3 waits for T1";
    `--task 'T3, T1'` runs T1, then T3; an id that names no row refuses the run
    with exit 2; a done row is skipped with a message.
  - `--idle 2s` fails a fake agent silent for 6 s with sandcastle's idle error;
    `run.json` holds `idleSeconds` 3600 by default; `--idle 0s` and
    `--idle soon` are refused.
  - A ` rw` mount that didn't exist was created and written from inside; the
    read-only Playwright cache refused a write.
  - `fab tail` followed a three-task run live and exited at its end.
    `fab review` refuses a running run, stamps a finished one, keeps an open
    review on a second call; `--done` closed it, and `fab runs` showed 13
    minutes for a review backdated by 13 minutes.
  - Regression: park, deadline, busy worktree and two failures in a row behave
    as in T1b.
  - The pilot's spec through `fab`'s parser: 23 rows, 15 done, the 8 open ones
    M5.1 to M6.2, and only M5.1 ready. `--task M5.2,M5.3,M5.4`, M5.5 and M5.6
    become ready once M5.1 is merged into the pilot's `main`, which is the plan.
  - `stow --no-folding fab` linked `cli.mts`, `lib/runs.mts` and `lib/tail.mts`;
    `zsh -n` and prettier pass on the changed files.
- **Measured:** inside the sandbox, with the pilot's `mise.toml` and lockfile on
  the throwaway: `pnpm install --frozen-lockfile` 35 to 140 ms from the shared
  store (before: failed); pnpm, hugo, python and pagefind resolve in under a
  second each (before: mise downloaded each into the private home, 3 to 22 s per
  tool, per task). No real agent session spent.
- **Decisions:**
  - `--task` takes rows in table order, whatever order it is given, so
    dependencies hold. Dependencies outside the list must be done already.
  - An unknown `--task` id refuses the run after the worktree exists, since the
    spec is read from the worktree.
  - Every run's stop reason names rows left blocked, as in "queue empty; T3
    waits for T1", not only with `--task`.
  - A missing read-write mount directory is created, mode 700: pnpm's lock
    directory lives in `/tmp`, which macOS cleans. Missing read-only mounts are
    still skipped.
  - Sandbox variables go into a new private `~/.config/fab/sandbox.env`, not
    `.env`: they are tool settings, not secrets, and every tool that looks under
    the private home needs one. Without them the rw store mount alone didn't
    help.
  - Reviews are a list in `run.json` (`reviews: [{startedAt, endedAt, note}]`).
    `fab review` on a run with an open review doesn't open another; `--done`
    closes the most recently started open review of any run; `fab runs` sums the
    closed ones.
  - `fab tail` drops sandcastle's per-task boilerplate (sandbox setup,
    iteration, commit collection), which the events already say, and keeps the
    agent's text, tool calls and errors. `-n` (default 40) counts the lines it
    shows.
  - `fab runs`, `tail` and `review` are Node (`cli.mts`): `run.json` now holds
    lists, and parsing JSON with `sed` was fragile. `fab runs` sorts by the run
    id's time, not by name.
  - The pilot's `Covers` column became its "Done when", for done rows too (their
    ACs "pass"), rather than a sixth column. Done rows got the dependencies they
    were built in (T2 on T1, T3 to T8 on T2, M0 on T1, M1 to M4 a chain) and
    dates from its progress log; M4 is dated 2026-11-09, when MC5 and MC6 closed
    it. M5.3 names M5.2 only; M5.1 follows through it.
  - The pilot's run brief: commits only on the run's `fab/*` branch or the
    branch an interactive prompt names; an unattended run starts in its
    worktree; `$TMPDIR` as scratch; a full gate outlasts a 10-minute tool call;
    no `pnpm browsers` in an unattended run. Its checks: prettier and
    markdownlint. `pnpm check` needs a build and the export, not run for a docs
    change.
- **Open, for the maintainer:**
  - **Browsers in the sandbox, blocking T2.** With the browsers found
    (`PLAYWRIGHT_BROWSERS_PATH`), Chromium, Firefox and WebKit all abort at
    launch inside `seatbelt()`. Its profile denies every XPC service and all but
    a short list of Mach services, and sandcastle 0.14.0 offers no way to extend
    it. Every M5 row's "Done when" needs `pnpm check:layout`, so each task would
    park or fail. Options:
    1. Browsers on the host: `playwright run-server` bound to 127.0.0.1, and the
       pilot's `check-layout.mjs` connecting when a variable names the endpoint
       (it has two `launch()` calls). Verified: all three engines, driven from
       inside the sandbox, loaded a worktree file. Cost: the host browser reads
       any `file://` path the maintainer can, so the agent could read through it
       what the sandbox hides; AC16's timings cross a websocket.
    2. No sandbox for the pilot (sandcastle's `noSandbox()`, a `--sandbox none`
       in `fab`): everything runs, but the agent sees the home directory, global
       hooks fire, and it can write anywhere.
    3. Ask sandcastle for a profile extension point and wait. Recommendation: 1
       for the pilot, with `fab` starting and stopping the server per run, an
       ADR with status `proposed` naming the read hole, and 3 filed upstream.
       The pilot's `check-layout.mjs` change is the pilot's work: a row before
       M5.1, or M5.1's first step.
  - `node` in the sandbox is the host's global 26.13.1, first on `PATH`, not the
    pilot's pinned 26.12.0. Its `engines` asks for 26.12.0 or later.
    Recommendation: leave it.
  - The pilot's main checkout has `node_modules` now, and `.wt/docs/` and
    `.wt/feat/` hold only a `README.md` each, left from deleted worktrees. Not
    touched; they are yours.
  - About thirty fake runs sent state changes and notifications to this
    session's tuios Inbox. Dismiss them.
- **Surprises:**
  - pnpm 12 keeps its store locks in `/tmp/pnpm-store-operation-locks-<uid>`,
    ignoring `TMPDIR`: "Failed to open the store operation lock", even with the
    store inside the private home.
  - In the sandbox mise trusts the project's `mise.toml` but installs each
    pinned tool into the private home. Outside it, a changed `HOME` makes mise
    refuse the same file as untrusted.
  - pnpm 12 reads `pnpm_config_*` variables, not `npm_config_*`.
  - Playwright looks for its browsers under `HOME` too.
  - The browsers' aborts leave no sandbox denial in `log show`.
  - The fake agent was broken since T1c moved the task fields into a nested
    list; T1c ran the real agent only. And `local x=$(…)` in `fab` had hidden a
    failed project lookup or a bad `--until` since T1b.
  - A shell whose current directory is `~/.config/fab` makes every mise shim
    complain that `package.json` there isn't trusted.
- **Next step:** T2, once the browser question is decided.

## 2026-11-13: hard limits reworked; T2 planned with the maintainer, T2a added

- **Done:** the run brief's hard limits after four sessions (commit
  `0db7f8e`), with the global push and deletion rules in `AGENTS.md`
  (`481a460`). T2 planned with the maintainer: the pilot's design branch is
  merged, its open work is a milestone of six tasks plus two mock-up tasks,
  and the private notes hold the run plan (which rows each run takes, branch
  names, traps). A preparation task T2a is new in the spec: `fab` options the
  plan needs and the pilot's table conversion.
- **Decisions:**
  - `--task <id,…>` instead of a `--tasks <n>` count: two parallel runs on one
    spec would otherwise both take the same first ready row.
  - `--idle` defaults to an hour: the pilot's browser gate can be silent inside
    one tool call for longer than sandcastle's default of ten minutes.
  - Review time for MC1 is measured by `fab review` stamps, not by hand.
  - Package caches the agent needs (pnpm store and metadata) are mounted
    read-write; the mounts file gets a ` rw` suffix for that.
- **Open, for the maintainer:**
  - Mock-up tasks (the pilot's M6) can't produce a claude.ai Artifact from the
    sandbox. Decide before M6: a local HTML mock-up with screenshots as the
    demo, or interactive mock-ups and only the build through `fab`.
  - The pilot's two parallel runs will both touch one JavaScript file; a small
    merge conflict for you is accepted for the rate-limit measurement.
- **Surprises:** the session scratchpads from 2026-11-06 were gone a week
  later; `/tmp` is cleaned. `/tmp/fab-tests` is therefore for repositories a
  session recreates cheaply.
- **Next step:** T2a.

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
