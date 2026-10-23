# Git worktrees

I work on parallel branches in git worktrees, managed by
[git-wt](https://github.com/k1LoW/git-wt) and my zsh function `wt`:

- `wt <branch>` creates the worktree if needed and opens it in a new tmux window
  named `<repo>/<branch>`; `wt` alone picks an existing one via fzf.
- `wt -d <branch>` deletes a worktree, keeping an unmerged branch;
  `wt -D <branch>` also removes the branch.

`wt` lives in my interactive `.zshrc`, and its `cd` and tmux window don't carry
over to your shell, so call the `git wt` binary instead. Prefer it over plain
`git worktree add`: it applies my git config `wt.basedir` (location) and
`wt.copyignored` (copies ignored files such as `.env`).

- List: `git wt` with no arguments, or `git wt --json`. git-wt has no
  subcommands, so `git wt list` would create a worktree named `list`.
- Create or reuse, without changing directory:
  `WT=$(git wt --nocd <branch> [<start-point>] | tail -1)`. The last line of
  stdout is the worktree path. Then work with absolute paths below `$WT` or
  `git -C "$WT"`.
- Delete only when asked, with `git wt -d <branch>`. It exits 0 even when it
  keeps an unmerged branch, so read its message. Never use `-D` without asking.
- When you hand a worktree back to me, name the branch so I can open it with
  `wt <branch>`.

## Files

- Delete files one by one, each `rm` with its full path written out. Never use
  loops, globs or `find -delete` for cleanup.
