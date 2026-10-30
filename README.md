# paschelino's shell setup for macOS

Hi, great you're here. If you like, make use of what I have put together here.
For me, coming from pure bash and vim, this was like a change from horse riding
to spaceship flying. 😌 I hope this is also helpful for your daily work and
passion.

To get you started easily with nvim, here in particular with LazyVim, make use
of two awesome features provided by the LazyVim distribution used here:

- `<leader>`: Open a pop up to see the next best key to press.
- `<leader>sk`: Open a search for keymappings.
- C+s for saving changes in a buffer. Yes, you did not expect that in a
  Vim-style editor ;-)

What does `<leader>` mean? This is the key to start a command. It is configured
here to be the `<space>` key. Thus to search for keymappings, type `<space>sk`.

## 🧐 Please note

The fact this setup works for me does not mean it works for you, too. Dotfiles
are highly individual.

## preconditions

### Mac Package Manager

If you use MacPorts, this here won't work. Sorry. It uses Homebrew (which will
be installed in case you haven't before).

### Rustup & Rust

Don't install `rustup` via Homebrew. It will be installed via the contained
install script, to have proper use of Cargo. This is the one deliberate
exception to installing global tools with Homebrew. Run `./install --skip-rust`
to skip it.

### Conflicts with existing dotfiles or dotfile folders

You might run into problems with `stow`, in case some dotfiles already exist in
your home directory. Best is to move them into some backup place, before you run
`./install`. A typical example is a `~/.zprofile` or `~/.zshenv` created by the
Homebrew or Rust installers: their content is already part of the `zsh` package.

## what you will install

For a detailed look on what you will install, please have a look into

- the script `./install`
- the `Brewfile`
- the mise config `dotfiles/mise/.config/mise/config.toml`

On a high level after the install you will have

- NeoVim, highly configured to be a fully fledged IDE
- Ghostty, a highly modern TTY
- zsh as login shell, with vi mode, autosuggestions, syntax highlighting and
  carapace completions
- Nushell, a modern shell for structured data, for occasional use: run `nu` from
  zsh
- Starship, a shell prompt on steorids
- tmux, a massive productivity booster when you are working on multiple projects
- mise, managing language runtimes (Node, Ruby, Java, Erlang, Elixir)
- Rustup and Rust, to inspire you to code in Rust ;-)
- and more basic stuff that you need

## How to change things

- Please note, a dotfiles config is highly individual. Use this for creating
  your own dotfiles repository.

## How to install

Open your shell and run `./install` There is no guarantee that this runs
through, but, as I want it to work, it is likely...

## Dotfile management

The install script also installs the tool `stow`. It is used for symlinking the
dotfile folders in this repository into your homefolder. In case you need to run
the command once manually, do it as follows:

```shell
cd <some_parent_folder>/shell_setup/dotfiles
stow --target="$HOME" <package>
```

So let's assume, you have cloned the repository into a folder like
`~/projects/shell_setup` and you wish to symlink the package ghostty:

```shell
cd ~/projects/shell_setup/dotfiles
ls
# output:
# carapace  colima  ghostty  lazygit  mise  nushell  nvim  starship  tmux  zellij  zk  zsh

# now run:
stow --target="$HOME" ghostty
```

### this will create a symlink looking like this

```shell
ls -la ~/.config/ghostty
# output:
# lrwxr-xr-x  1 paschelino  staff  50 Mar 22 10:00 /Users/paschelino/.config/ghostty -> ../projects/shell_setup/dotfiles/ghostty/.config/ghostty
```

## zsh

The interactive shell is zsh in vi mode: `Esc` switches to normal mode (block
cursor), `v` in normal mode opens the command line in nvim. Further helpers:

- `Ctrl-r`: fuzzy history search, `Ctrl-t`: insert a file path, `Alt-c`: cd into
  a subdirectory (all via fzf)
- `→`: accept the grey autosuggestion from your history
- `wt <branch>`: create a git worktree and open it in a new tmux window or
  Zellij tab; `wt` alone selects an existing one (see
  [Git worktrees](#git-worktrees-wt))

## Git worktrees (`wt`)

`wt` is a zsh function (in `.zshrc`) on top of
[git-wt](https://github.com/k1LoW/git-wt), which makes it easy to work on
several branches of one repository side by side, each in its own directory and
tmux window.

| Command            | What it does                                                                                                                                       |
| ------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------- |
| `wt <branch>`      | Create the worktree (and the branch, if needed) and open it in a new tmux window or Zellij tab named `<repo>/<branch>`; outside both, `cd` into it |
| `wt`               | Pick one of the other worktrees with fzf and `cd` into it                                                                                          |
| `wt -d [<branch>]` | Delete the worktree; an unmerged branch is kept. Without a branch, the current one is deleted                                                      |
| `wt -D [<branch>]` | Force delete: also removes the branch, even if unmerged                                                                                            |
| `wt-rm`, `wt-rm!`  | Aliases for `wt --delete` and `wt --force`                                                                                                         |

Tab completion offers your local branches as well as the flags.

`git-wt`, `fzf` and `jq` come with the `Brewfile`. `./install` does not set the
git config `wt` relies on, so run this once:

```shell
# put worktrees next to the repository, e.g. ~/projects/shup-worktrees/<branch>
git config --global wt.basedir "../{gitroot}-worktrees"
# copy ignored files such as .env or mise.local.toml into new worktrees
git config --global wt.copyignored true
```

## tmux

For full developer productivity, I advise you to remap your CAPS_LOCK key to
CTRL, short C. Then it is super simple to use the according key mappings and for
example to press C+a,w to open the window selector. It feels a little bit like
emacs, as every command you will be using will be preceded with C+a.

## Zellij

Zellij is a modern alternative to tmux. Its config
(`dotfiles/zellij/.config/zellij/config.kdl`) drops Zellij's default keys, which
clash with nvim (e.g. `Ctrl-s` to save), and copies the tmux bindings instead.
Everything starts with the prefix `Ctrl-a`:

| Keys after `Ctrl-a`                 | What it does                                            |
| ----------------------------------- | ------------------------------------------------------- |
| `h` `j` `k` `l`                     | Move to the pane on the left, below, above, right       |
| `H` `J` `K` `L`                     | Resize; keep pressing `h` `j` `k` `l`, `Esc` to stop    |
| `\|` or `%`, `-` or `"`             | Split right, split down                                 |
| `z`, `x`, `f`                       | Toggle fullscreen, close pane, toggle floating panes    |
| `c`, `,`, `&`                       | New tab, rename tab, close tab                          |
| `Ctrl-h` / `Ctrl-l`, `1`…`9`, `Tab` | Previous / next tab, go to tab, last tab                |
| `[`, `/`                            | Scroll mode (vi keys), search                           |
| `e`                                 | Open the scrollback in nvim, to search and copy with vi |
| `s`, `d`, `q`                       | Session manager, detach, quit                           |
| `Ctrl-a`                            | Send `Ctrl-a` to the program                            |

The status bar lists the main keys after `Ctrl-a`. Selecting text with the mouse
copies it. The config reloads on save.

The full cheat sheet lives in `dotfiles/zellij/.config/zellij/cheatsheet.md`:
`zp -c` (`--cheat`) opens it in nvim, `zp -cb` (`--cheat --browser`) renders it
in the browser.

### Projects (`zp`)

`zp <project>` opens one Zellij session per project with three tabs: nvim, a
coding agent and a shell (the layout in `layouts/project.kdl`). If the session
exists, it attaches to it; inside Zellij it switches to it. `zp` alone picks a
project with fzf. `zp -a` (`--all`) starts the sessions of all projects in the
background, e.g. after a reboot, and then attaches to the first one. Sessions
that are already running are left alone.

`zp -r <project>` (`--restart`) kills the session and starts it fresh, e.g. to
pick up a changed layout; `zp -ra` does that for all projects. It first lists
what still runs in the sessions (idle shells left out) and asks.

The projects differ from machine to machine and stay private, so they're not
part of this repository. List them in `~/.config/zp/projects`, one per line:
name, path and optionally the agent (default: `opencode`):

```text
# name      path                  agent
shup        ~/shup                opencode
my-api      ~/work/my-api         claude
```

A project that needs different tabs gets its own layout:
`~/.config/zp/<name>.kdl` is used instead of the generic one. Start from
`dotfiles/zellij/.config/zellij/layouts/project.kdl`.

## NeoVim

It will take you some time to become familiar with nvim. Two things to ease
things for you:

1. When you are inside a buffer in normal mode, you can hit the SPACE bar. It
   then expects to type in shortcuts to execute the needed commands. But after
   short time, it opens a pop up with the available keymappings, so that you can
   learn them slowly.
2. When you are in edit mode in a buffer and want to get back to normal mode,
   instead of hitting ESC, you can type short after another `jk`. This will
   enter your muscle memory very quickly and you will never want to miss it
   again.
3. When you want to know all capabilities available, it is best to look into the
   `~/.config/nvim` folder and to browse the plugin configs. Each of the plugin
   configs relates to a GitHub project where you can find more details on how to
   use those. Tools you might love the most:

- LazyGit (hit SPACE+lg)
- Toggle file explorer (hit SPACE+ee to open or SPACE+et to close it.)
- Opening or closing folders in the file explorer: Hit enter to open, hit
  backspace to close. Or use double clicks with the mouse :-D
- Open the key bindings for the file explorer: When in the file explorer hit
  `g?`

## AI coding agents (Claude Code and opencode)

Both agents share one set of global instructions, which apply in every project
next to the project's own `AGENTS.md` or `CLAUDE.md`:

- `dotfiles/opencode/.config/opencode/AGENTS.md` holds the general instructions
  and is read by opencode.
- `dotfiles/opencode/.config/opencode/instructions/*.md` hold instructions about
  this very setup, e.g. how to use the `wt` worktree helper. opencode loads them
  via `instructions` in `opencode.jsonc`.
- `dotfiles/claude/.claude/CLAUDE.md` only imports those files with `@~/...`
  lines, as Claude Code doesn't read `AGENTS.md`. Unlike opencode it can't
  import a glob, so add a line there for each new file in `instructions/`.

Edit those files to change the instructions for both.

`~/.claude` and `~/.config/opencode` also hold the tools' runtime data
(sessions, history, plugins, `node_modules`). So `./install` stows these two
packages with `--no-folding`: stow then links single files and never symlinks
the whole directory into this repository. When stowing them manually, pass the
flag as well:

```shell
stow --no-folding --target="$HOME" claude opencode
```

## Package management (Homebrew and mise)

Two package managers, with a clear split:

- **Homebrew** (`Brewfile`) installs everything global: CLIs, libraries, apps
  and fonts. Prefer a homebrew-core formula, even for npm or PyPI tools: every
  release is reviewed, its sources are pinned by checksum and its bottles carry
  build provenance attestations, which `.zprofile` verifies
  (`HOMEBREW_VERIFY_ATTESTATIONS`; needs `gh` to be logged in, see
  `gh auth login`). Add a third-party tap only when it is the vendor's own, and
  trust its formula in the `brew trust --formula` line of `./install`: Homebrew
  refuses to load formulae from untrusted taps. Uninstalling such a formula
  drops its trust as well, so run `./install` (or `brew trust --formula`) again
  before reinstalling it with `brew bundle`.
- **mise** (`dotfiles/mise/.config/mise/config.toml`) installs language runtimes
  only (`node = "26"`, `ruby = "3.4"`, ...) and the per-project versions in a
  project's `mise.toml` or `.tool-versions`; `.nvmrc` and `.ruby-version` files
  are honoured as well. Stick to the `core` and `aqua` backends: the npm, pipx,
  cargo and http backends install unreviewed releases, and asdf/vfox plugins
  (disabled) run community shell scripts.

mise runs in paranoid mode, so run `mise trust` in a project before mise uses
its config, and again after the config changes. Versions and checksums of the
global runtimes are pinned in `mise.lock`: after editing the config, run
`mise lock --global --bump` and `mise install`, and commit both files.
