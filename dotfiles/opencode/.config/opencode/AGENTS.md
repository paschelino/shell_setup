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
- Ask before pushing.

## Files

- Delete files one by one, each `rm` with its full path written out. Never use
  loops, globs or `find -delete` for cleanup.
