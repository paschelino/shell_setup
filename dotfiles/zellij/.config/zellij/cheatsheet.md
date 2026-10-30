# Zellij cheat sheet

Open this sheet with `zp -c` (in nvim) or `zp -cb` (in the browser).

## Starting and switching projects

| Command                           | What it does                                                          |
| --------------------------------- | --------------------------------------------------------------------- |
| `zp -a` / `zp --all`              | Start all project sessions in the background, attach to the first one |
| `zp <name>`                       | Open a project's session, creating it if needed                       |
| `zp`                              | Pick a project with fzf                                               |
| `zp -r <name>` / `zp -ra`         | Ask, then kill the session(s) and start them fresh (e.g. new layout)  |
| `zp -c` / `zp --cheat`            | Open this cheat sheet in nvim                                         |
| `zp -cb` / `zp --cheat --browser` | Open this cheat sheet in the browser                                  |
| `zellij list-sessions`            | List sessions, including exited ones                                  |
| `zellij attach <name>`            | Attach to a session                                                   |
| `zellij kill-session <name>`      | Stop a running session                                                |
| `zellij delete-session <name>`    | Remove an exited session; `zp` then starts it fresh                   |

Projects are listed in the private file `~/.config/zp/projects`, one per line:
name, path and optionally the agent (default: `opencode`). A file
`~/.config/zp/<name>.kdl` gives a project its own tabs.

## The prefix: `Ctrl-a`

Every Zellij shortcut starts with `Ctrl-a`, followed by a key. `Esc` cancels.
`Ctrl-a Ctrl-a` sends a real `Ctrl-a` to the program, e.g. to jump to the start
of the line in zsh. The status bar then lists the main keys, and it does the same
in the other modes, like resize and scroll.

## Panes

| After `Ctrl-a`  | What it does                                              |
| --------------- | --------------------------------------------------------- |
| `h` `j` `k` `l` | Move to the pane on the left, below, above, right         |
| `\|` or `%`     | Split right                                               |
| `-` or `"`      | Split down                                                |
| `z`             | Toggle fullscreen for the current pane                    |
| `x`             | Close the pane                                            |
| `S`             | New pane, stacked on the current one                      |
| `o`             | Go to the next pane                                       |
| `f`             | Show or hide floating panes                               |
| `H` `J` `K` `L` | Resize, then keep pressing `h` `j` `k` `l`; `Esc` to stop |
| `m`             | Move mode: `h` `j` `k` `l` moves the pane; `Esc` to stop  |

## Tabs

| After `Ctrl-a`  | What it does                                         |
| --------------- | ---------------------------------------------------- |
| `c`             | New tab                                              |
| `,`             | Rename the tab (`Enter` to confirm, `Esc` to cancel) |
| `&`             | Close the tab                                        |
| `Ctrl-h` or `p` | Previous tab                                         |
| `Ctrl-l` or `n` | Next tab                                             |
| `1` … `9`       | Go to tab number …                                   |
| `Tab`           | Back to the last tab                                 |

## Scrolling, searching, copying

| After `Ctrl-a` | What it does                                                  |
| -------------- | ------------------------------------------------------------- |
| `[`            | Scroll mode                                                   |
| `/`            | Search the scrollback                                         |
| `e`            | Open the scrollback in nvim, to search and copy with Vim keys |

**In scroll mode:** `j`/`k` scroll a line, `d`/`u` or `Ctrl-d`/`Ctrl-u` half a
page, `Ctrl-f`/`Ctrl-b` a page. `G` jumps to the bottom, `[`/`]` to the
previous/next shell prompt, `/` searches. `Esc` or `q` leaves.

**In search:** type the term and press `Enter`. `n`/`N` go to the next/previous
match, `c` toggles case sensitivity, `w` toggles wrap-around. `Esc` leaves.

**Copying:** select with the mouse and the text goes straight to the macOS
clipboard. For keyboard copying, use `Ctrl-a e` and yank in nvim.

## Sessions and tools

| After `Ctrl-a` | What it does                                          |
| -------------- | ----------------------------------------------------- |
| `s` or `w`     | Session manager: switch, create or resurrect sessions |
| `d`            | Detach (the session keeps running)                    |
| `q`            | Quit the session (stops everything in it)             |
| `W`            | Share the session in the browser                      |
| `P`            | Plugin manager                                        |
| `?`            | Zellij's configuration screen                         |

## The generic project layout

| Tab | Runs                                             |
| --- | ------------------------------------------------ |
| 1   | `nvim .`                                         |
| 2   | The project's coding agent (default: `opencode`) |
| 3   | A shell                                          |

Commands run with the project's direnv and mise environment. When a command
ends, you get a shell in that tab.

## Coming from tmux

| tmux                              | Zellij                                             |
| --------------------------------- | -------------------------------------------------- |
| window                            | tab                                                |
| session                           | session (one per project, via `zp`)                |
| `Ctrl-a [` copy mode with `v`/`y` | `Ctrl-a e` (scrollback in nvim) or mouse selection |
| `Ctrl-a r` reload config          | Not needed: Zellij reloads `config.kdl` on save    |
| `wt <branch>` opens a window      | `wt <branch>` opens a tab                          |

## Good to know

- Hold `Shift` while selecting with the mouse to use Ghostty's own selection
  instead of Zellij's.
- Exited sessions, e.g. after a reboot, come back with `zp <name>`, `zp -a` or
  the session manager.
- Config: `~/.config/zellij/config.kdl`, generic layout:
  `~/.config/zellij/layouts/project.kdl`.
