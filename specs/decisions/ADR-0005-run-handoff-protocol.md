# ADR-0005: The hand-off protocol between a finished run and the maintainer

|            |            |
| ---------- | ---------- |
| **Status** | proposed   |
| **Date**   | 2026-11-14 |

## Context

The pilot (T2, four runs, six tasks) showed that a run's hand-off costs more
than its review. The agents worked 2 h 26 min; the wall time from the first
start to the last merge was about twelve hours, the maintainer's night and
review pace. In that stretch, every step after the run's end was done by hand or
by the session that had started the run, and each one produced feedback:

- A blocking `mx ask` "merged?" outlived the merge and had to be hidden before
  `fab review` could start. A question that waits for an event the maintainer
  performs anyway is the wrong shape.
- Run ids (`<project>-<date>-<time>`) are not readable, and with two finished
  runs it was unclear which to review first; the clean merge should have gone
  first, the conflicting one second.
- `fab review` prints `summary.md` with `cat`; a review wants to scroll and read
  rendered Markdown.
- The project's demo (a dev server in the run's worktree) was started by hand,
  and the merge, the worktree removal and the branch deletion were done by the
  session on a four-option question, since `fab` has no verb for them.
- A parked question's answer had no home: the row stays open, the agent's
  assumption is built, and the next run offers the row again.
- Reviewed runs stay in `fab runs` and in `fab review`'s default forever.

The interview with the maintainer (2026-11-14, five rounds) settled who does
what. Options for the shape of the hand-off:

1. **`fab` asks.** At the run's end and before the merge, `mx ask` questions in
   the multiplexer; the maintainer answers when they come by. Every question is
   a blocking element on the screen for hours, and the pilot showed they outlive
   the events they ask about.
2. **`fab` stays passive**, today's state: one notice, then the maintainer runs
   git and `wt -d` by hand or asks a session to. Cheap to build; the pilot
   measured what it costs per run.
3. **Three actors, one protocol.** `fab` reports and executes the mechanical
   steps without asking; an interactive agent session in the project, the
   orchestrator, runs `fab`'s verbs on the maintainer's word and records
   findings in the project; the maintainer reads, tries and decides, at their
   own pace. The only stop is a merge conflict, which is an exit code, not a
   question.

## Decision

Option 3. The protocol below is the contract; the verbs that implement it are
listed after it. "Live" means a run directory under `~/.local/state/fab/runs/`;
a reviewed run is archived and no longer live.

### Actors

- **fab**: the runner (`fab run`) and its read-and-close verbs (`fab runs`,
  `fab review`, `fab review --done`). It never asks a question.
- **The orchestrator**: an interactive agent session in the project's main
  checkout that the maintainer talks to. It runs `fab review` and
  `fab review --done` on the maintainer's word, resolves a conflict when asked,
  and writes feedback, new rows and parked answers into the project's spec and
  progress log. Every verb also works by hand, without it.
- **The maintainer**: reads the summary, tries the demo, decides. They wait for
  nobody; the finished run waits for them.

### Protocol

1. **The run ends** (fab). `fab run` writes `summary.md`, records the run's
   label in `run.json`, sends one `mx notify` and sets the pane state to `done`
   or `error`. The notice carries the label, the outcome (done, parked, failed
   counts and the stop reason), the position of this run in the project's review
   order with the reason, and the exact command `fab review <id>`. The process
   exits; nothing waits on fab from here. The run is finished and live.
2. **The maintainer comes by** at their pace. Nothing repeats the notice (a
   phone channel is T4c). While a project has a live finished run, `fab run` on
   that project is refused with exit 2, naming the run; `--force` overrides.
   Parallel runs started together are not affected: the refusal looks at
   finished runs, not running ones.
3. **The maintainer says "review"**; the orchestrator runs `fab review [<id>]`
   (or the maintainer does). Without an id, the next run in the review order:
   runs whose branch merges cleanly onto the project's default branch first,
   then by end time. fab stamps the review start, opens two panes in the current
   multiplexer session through `mx open`: the summary in a Markdown pager
   (`glow` or `bat` when installed, else `$PAGER`), and the project's demo in
   the foreground, in the run's worktree, so its output is visible. Its own
   stdout stays short for the orchestrator: label, commits over the default
   branch, the merge check (clean, or the conflicting files), the parked
   questions with their assumptions, the demo command, and the closing command.
   Outside a multiplexer it pages inline and prints the demo command. The
   orchestrator now waits for the maintainer.
4. **The maintainer reads and tries**, then tells the orchestrator what they
   found: accept; a fix is needed before the merge; a new row for later; the
   answer to a parked question. A fix before the merge is the orchestrator's
   attended work in the run's worktree, on the run branch, with the project's
   checks; `--done` is not run until it is in.
5. **Close** (fab): `fab review --done <id> [note]`, scoped to the id so that
   two open reviews can't be confused. In order, asking nothing: stop the demo
   and close the panes it opened; run the merge check; if clean, merge the run
   branch into the project's default branch in the main checkout with
   `git merge --no-ff` and a conventional message naming branch and task ids;
   remove the worktree and the merged branch with `git wt -d`; push the default
   branch once if a remote exists and `--no-push` was not given (the global push
   rule: a worktree being merged back is a push's consumer); stamp the review's
   end with the note; move the run directory to `~/.local/state/fab/archive/`.
   The maintainer waits the seconds this takes.
6. **Conflict** (fab, then the orchestrator): when the merge check fails,
   `--done` stops after stopping the demo, exits 3, names the conflicting files,
   and keeps worktree, branch and the open review. The orchestrator, on the
   maintainer's word, merges the default branch into the run branch in the
   worktree, runs the project's checks, commits, and step 5 runs again. No
   separate verb, no sandboxed agent: the session already in the conversation
   does it, as in the pilot's run B.
7. **Record** (the orchestrator): after the merge, feedback, new rows and the
   answers to parked questions go into the project's spec and progress log on
   the default branch, committed there. A parked row stays open with its answer
   recorded, so the next `fab run` takes it with the decision in hand. The
   project is now ready for the next run.

With several finished runs the steps run per run, in the review order. The first
merge does not wait for the second review; the second run's merge check sees the
first merge and reports the conflict it may cause.

### What fab never asks

- Anything during a run. A fork is parked with an assumption and the run goes on
  (AC7).
- "Merged?", "reviewed?" or any question about an event the maintainer performs:
  fab reads the stamp, the merge or the archive as the answer.
- "Review now?" or "start the demo?": the notice names the command; starting is
  the maintainer's move, with `--no-demo` and `--no-pager` to skip the panes.
- Confirmations of cleanup, merge message or archiving, once the branch is
  merged. Without a merge, nothing is removed.

### Verbs and conventions this changes

- **`fab run`**: the label `<project> <branch> <task ids>` in `run.json`, shown
  everywhere the id is shown; the end notice as in step 1; the refusal of step 2
  with `--force`.
- **`fab runs`**: label column; live runs only; `--all` includes the archive,
  which also keeps the review-minute measurement (MC1) readable.
- **`fab review [<id>] [--no-demo] [--no-pager]`**: step 3.
- **`fab review --done <id> [note] [--no-push]`**: steps 5 and 6; the id is
  required; exit 3 on conflict.
- **`mx open <title> -- <command>`**: a new verb, extending ADR-0002's list. It
  opens a pane running the command in the current multiplexer session; one
  adapter per host, a printed command outside any multiplexer, exit 0 always.
- **The project's demo**: `scripts/demo` in the project, executable, zero
  arguments, run with the worktree as working directory and `FAB_RUN`,
  `FAB_BRANCH` and `FAB_WORKTREE` in the environment; the project decides what
  it does and the script serves people and tools alike. For a repository the
  maintainer can't change, a `demo` line in `~/.config/fab/projects/<name>`
  names the command instead. No `.fab/` directory in any project: the run
  brief's rule against fab configuration in a repository holds.
- **State**: `~/.local/state/fab/archive/<id>/` for reviewed runs, same layout
  as a live run.

## Consequences

- ADR-0003's "merge back after review" and "worktree cleanup is the maintainer's
  `wt -d`" become `fab review --done`'s work; its rule that nothing lands on the
  default branch unseen holds, because `--done` follows a review the maintainer
  asked for. The run's own end-of-run push of the branch stays as ADR-0003 has
  it.
- The orchestrator is a role, not a tool: today it is the Claude session the
  maintainer already has open in the project. T3's `session-handoff` skill and
  the project run briefs should name the verbs it runs.
- `fab review`'s panes need `mx open` on every host in the bake-off; a host
  without a pane API falls back to the printed command, which the maintainer
  runs by hand. That goes on the bake-off scorecard.
- The refusal in step 2 serialises runs per project behind their reviews. It is
  what the maintainer asked for; `--force` exists for the case where a second
  branch should start anyway.
- T4d's "a run ends with `mx ask 'continue?'`" contradicts the never-ask list.
  Its shape changes to a policy given at `fab run` time or a decision taken in
  the review; T4d decides which.
- T4c (phone) carries step 1's notice and nothing else of this protocol: the
  review and the close stay at the machine, where the panes are.
- Work projects that review through a draft pull request (ADR-0003) need a
  `--done` that pushes the branch and opens the PR instead of merging. That
  variant is specified when a work project first runs fab, not here.
- Reviewed runs leave the default listings. A later session that wants the
  pilot's measurements reads `fab runs --all` or the archive directory.
