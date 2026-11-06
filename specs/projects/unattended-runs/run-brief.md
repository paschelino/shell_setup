# unattended-runs run brief

Everything a session needs to work on this project without the maintainer. The
spec says what to build; this file says how, and what must never happen. Start
every task in a cleared session with its kickoff prompt below, and end every
session with the hand-off checklist at the bottom.

## Hard limits

- **This repository is public.** No private project names, paths under
  `/Users/`, account names or hostnames in any committed file. Docs use made-up
  project names. Private details go to `~/.config/zp/fab-notes.md`. Before every
  commit, grep the staged diff for `/Users/`, `~/` and each name in
  `~/.config/zp/projects`; read the hits, don't just count them.
- **Don't push** without asking the maintainer. Commit on `main` is fine for
  this repository, as the stow links point at the main checkout.
- **Atomic conventional commits** with explicit paths: `git commit -- <paths>`.
  Never commit `dotfiles/mise/.config/mise/mise.lock` as part of this work.
- **Delete files one by one**, each `rm` with its full path. No loops, globs or
  `find -delete`, also in scratch directories.
- **Never run two sandcastle runs on one worktree.** Never start a run on a
  project's `main`.
- **Don't edit the maintainer's live settings** (`~/.claude/settings.json`,
  tuios, herdr and workmux integrations) in this project. T4f does that later,
  with the maintainer.
- **Don't install anything into project repositories.** No `.sandcastle/`, no
  `package.json`, no skills. Project-local files belong to the projects.
- **Throwaway tests** run in the session's scratchpad or a fresh directory under
  `/tmp`, never in a real project. Real agents started from tests need the
  maintainer's normal `HOME`; redirect `XDG_CONFIG_HOME` and `XDG_STATE_HOME`
  instead, and unset `CLAUDE_CODE_CHILD_SESSION` when starting Claude Code from
  inside Claude Code.
- **Don't weaken ADRs.** If one looks wrong, write a new one with status
  `proposed`.

## Conventions

- Shell code is zsh, in the style of `dotfiles/zsh/.config/zsh/zp.zsh`: short
  functions, a comment per function saying what it is for, `print -u2` for
  errors, exit codes that mean something.
- TypeScript in `dotfiles/fab/.config/fab/` is plain `.mts` run by Node 26 with
  no build step and no `tsx`. Pin every dependency to an exact version.
- Stow packages follow the existing layout: `dotfiles/<pkg>/<path under home>`.
  `fab` is in `NO_FOLDING` in `install`, so `~/.config/fab` is a real directory;
  `node_modules/` and `.env` live there and never in the repo.
- Made-up names in docs and tests: projects `alpha` and `beta`, branch
  `fab/demo`.
- The hand-off log is `progress.md` next to this file. The spec's Tasks table is
  the queue: mark a task's Step cell with `**Done** <date>.` when its "Done
  when" holds.
- Read before building: `dotfiles/zsh/.config/zsh/zp.zsh` (project list, host
  detection, worktree rules), `install` (stow and `NO_FOLDING`),
  `~/.config/zp/multiplexer-plan.md` (private; the bake-off, what each tool can
  and can't do), and the sandcastle docs at
  <https://github.com/mattpocock/sandcastle/tree/main/docs/guide>.

## Kickoff prompts

Paste one into a cleared session in `~/shup`. Replace nothing.

### T0: verify sandcastle

```text
Work on T0 of specs/projects/unattended-runs/spec.md in this repository. Read
specs/README.md, the spec, specs/projects/unattended-runs/run-brief.md,
progress.md and the three ADRs in specs/decisions/. Then read
~/.config/zp/fab-notes.md for private details. Set up @ai-hero/sandcastle in a
throwaway directory under the scratchpad, not in any real project, and work
through the T0 checklist in the run brief. Record every result in progress.md,
including what the sandbox hides and which mounts the pilot needs. Make
reasonable decisions and record them instead of asking. Finish with the
hand-off checklist in the run brief and a summary naming the next task.
```

T0 checklist, each with a recorded result:

1. `claude setup-token` and `CLAUDE_CODE_OAUTH_TOKEN` in `.env` work inside
   `seatbelt()` on this macOS version.
2. With `branchStrategy: { type: "head" }`, `cwd` set to a worktree made with
   `git wt --nocd`, and `logging: { type: "file", path }` outside the repo,
   nothing appears in the repository but the agent's commits. If `.sandcastle/`
   appears anyway, note it: `fab run` will add it to the worktree's
   `.git/info/exclude`.
3. Inside the sandbox, the repository's own `CLAUDE.md`, `AGENTS.md` and
   `.agents/skills/` are visible; `~/.claude/CLAUDE.md` and
   `~/.config/opencode/AGENTS.md` are not.
4. Hooks from `~/.claude/settings.json` don't fire inside the sandbox, and an
   `mx`-like call (`tuios set-agent-state`) made by the host process does reach
   the pane.
5. Host tools run inside the sandbox: `node`, `hugo`, `playwright` with its
   browsers. Note which paths under the home directory had to be mounted
   read-only via `seatbelt({ mounts })`.
6. `Output.object(...)` with `maxIterations: 1` returns the task report schema
   from the spec.
7. The `opencode()` provider starts at all in the sandbox, even if it is not
   used in the pilot.

### T1a: mx

```text
Work on T1a of specs/projects/unattended-runs/spec.md in this repository. Read
specs/README.md, the spec, specs/projects/unattended-runs/run-brief.md,
progress.md and ADR-0002. Build dotfiles/mx/.local/bin/mx as the spec's
contracts describe, with the tuios adapter complete, the other adapters as
no-ops that log what they would do to the state file, host detection in the
spec's order, the state file and the macOS notification. Add a README section
with made-up names. Test every verb inside a tuios pane and outside any
multiplexer. Make reasonable decisions and record them in progress.md instead
of asking. Finish with the hand-off checklist and a summary naming the next
task.
```

### T1b: fab

```text
Work on T1b of specs/projects/unattended-runs/spec.md in this repository. Read
specs/README.md, the spec, specs/projects/unattended-runs/run-brief.md,
progress.md (especially the T0 results), ADR-0001 and ADR-0003, and
~/.config/zp/fab-notes.md. Build the fab stow package as the spec's contracts
describe: the zsh entry point, the pinned package.json, main.mts with the
sequential task loop, worktrees via git wt, the lock, the deadline, events,
summary and mx reporting; the install and .gitignore changes. Test on a
throwaway repository with the made-up project names from the run brief. Make
reasonable decisions and record them in progress.md instead of asking. Finish
with the hand-off checklist and a summary naming the next task.
```

### T1c: prompts

```text
Work on T1c of specs/projects/unattended-runs/spec.md in this repository. Read
specs/README.md, the spec, specs/projects/unattended-runs/run-brief.md,
progress.md and ~/.config/zp/fab-notes.md, which names the maintainer's
project whose run-brief.md and session-handoff skill are the sources. Write
dotfiles/fab/.config/fab/prompts/task.md and summary.md so a sandboxed agent
takes one task, verifies it, writes the progress entry, commits atomically and
emits the task report, parking questions instead of asking. Inject the global
instruction files through prompt arguments. Test on the throwaway repository.
Make reasonable decisions and record them in progress.md instead of asking.
Finish with the hand-off checklist and a summary naming the next task.
```

### T2: pilot

```text
Work on T2 of specs/projects/unattended-runs/spec.md in this repository. Read
specs/README.md, the spec, specs/projects/unattended-runs/run-brief.md,
progress.md and ~/.config/zp/fab-notes.md for the pilot project, its branch
and spec. Run the pilot as the spec's T2 describes, starting with one task and
--until 1h, and record every measurement in progress.md: stop reason, parked
questions, review time, rate-limit behaviour with two parallel runs. Private
details go to ~/.config/zp/fab-notes.md, never to progress.md. Finish with the
hand-off checklist and a summary naming the next task.
```

For T2b, T3 and the T4x tasks, use the same shape: name the task, list the files
to read, point at the private notes, ask for decisions to be recorded, and end
with the hand-off checklist.

## Hand-off checklist

Do these in order before ending a session.

1. **Verify.** Run what applies: `zsh -n` on shell scripts, `node --check` or a
   dry run on `.mts` files, `stow -n` for new packages, the verb tests in the
   spec's ACs. Report failures with their output; don't hand over red as done.
2. **Update the spec.** Tick an AC only when its check ran and passed. Mark a
   task's Step cell `**Done** <date>.` when its "Done when" holds.
3. **Write the `progress.md` entry**, newest on top under the first `---`,
   headed `## <YYYY-MM-DD>: <what happened>`, with **Done**, **Open** (decisions
   for the maintainer as questions with a recommendation), **Surprises**, and
   **Next step** (one task id).
4. **Privacy grep** of the staged diff, then **commit** atomically with explicit
   paths and the attribution line the session gives you. `git status` must be
   clean afterwards, apart from `mise.lock`. Don't push.
5. **Tell the maintainer**: what's done and verified, what isn't, the decisions
   they need to make, and the next task id.
