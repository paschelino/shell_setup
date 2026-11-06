# ADR-0003: Every run gets its own worktree; pull requests are optional

|            |            |
| ---------- | ---------- |
| **Status** | accepted   |
| **Date**   | 2026-11-06 |

## Context

Several agents should work on one repository at the same time, and an unattended
run must never touch the checkout the maintainer has open. On private projects a
pull request per task is too much overhead and each push costs CI minutes; at
work a draft PR is the normal review vehicle. The maintainer already uses
`git-wt` and a `wt` shell function for worktrees, with a configured base
directory and copying of ignored files such as `.env`.

Options considered:

- **sandcastle's `branch` or `merge-to-head` strategies.** They create worktrees
  under `.sandcastle/worktrees/` inside the repository, which lands in the
  project's working tree and ignores the maintainer's worktree config.
- **Run on the maintainer's checkout (`head` on the main worktree).** Fast, but
  a second run or the maintainer's own edits collide.
- **Our own worktree per run, created with `git wt`, and sandcastle's `head`
  strategy pointed at it.** The worktree lives where `wt` puts them, ignored
  files are copied, and sandcastle writes nothing into the repository.

## Decision

- Every run creates or reuses a worktree with `git wt --nocd <branch>` and runs
  sandcastle with `cwd` set to it and `branchStrategy: { type: "head" }`.
- Parallel runs on one project use distinct branches, hence distinct worktrees.
  A branch whose worktree holds a live run lock is refused.
- Fan-out inside a run branches each independent task off the run branch into
  its own worktree and merges it back locally with `git merge --no-ff`. A
  conflict parks the task for the checkpoint instead of merging.
- Pull requests are a review vehicle, not a requirement. Private projects merge
  the run branch locally after review. Work projects open a draft PR. The
  worktree rule holds in both cases.
- A run pushes at most once, at its end, if the policy allows and commits exist.

## Consequences

- The maintainer can keep editing while runs proceed, and runs don't see each
  other's uncommitted files.
- Worktree cleanup is the maintainer's `wt -d`, as today.
- The merge back on private projects is a manual step after reviewing the
  summary; nothing lands on `main` unseen.
- Fan-out adds merge conflicts as a failure mode, handled by parking rather than
  by an agent resolving them unattended.
