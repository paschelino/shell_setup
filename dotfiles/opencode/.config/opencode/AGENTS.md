# Global agent instructions

These apply to every project. A project's own `AGENTS.md` or `CLAUDE.md` takes
precedence where they disagree.

## Git

- Make atomic commits: one logical change per commit, each leaving the project
  in a working state.
- Write conventional commit messages (`type(scope): subject`) and follow the
  style of the repository's existing history.
- Commit with explicit paths (`git commit -- <paths>`), so unrelated staged
  changes don't end up in the wrong commit.
- Pushing costs: it triggers CI on several repositories, which spends paid
  minutes, machine time and energy for nothing when nobody consumes the
  result. Push when the push has a consumer: a pull request to open or
  update, a worktree being merged back, a review done from the remote, or a
  long unattended run whose work would otherwise exist on one machine only.
  Push once per such occasion, with all commits of that unit of work, never
  per commit, and say in the hand-off that you did. When unsure whether a
  push has a consumer, it doesn't.

## Files

Deleting is tiered by what is recoverable:

- **Scratch:** directories a session created under its scratchpad or under a
  throwaway root such as `/tmp/fab-tests` are the session's own. Remove them
  whole when done (`rm -r <full path>`), without asking.
- **Tracked files:** `git rm` with explicit paths. Git keeps the history.
- **Everything else**, untracked files in a repository, worktrees, anything
  under the home directory: don't delete it during the task. List each in the
  hand-off under **Delete**, with the path, the reason and the command, and
  run the list after a Go.

Outside scratch, write every path out: no loops, globs or `find -delete`.
