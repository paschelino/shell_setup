# unattended-runs progress log

Handoff notes between sessions. Newest entry on top. Each entry covers: done,
open, surprises, next step.

---

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
