# TUIOS cheat sheet

Open this sheet with `zpu -c` (in nvim) or `zpu -cb` (in the browser).

## Starting and switching projects

| Command                     | What it does                                                          |
| --------------------------- | --------------------------------------------------------------------- |
| `zpu -a` / `zpu --all`      | Start all project sessions in the background, attach to the first one |
| `zpu <name>`                | Open a project's session, creating it if needed                       |
| `zpu`                       | Pick a project with fzf                                               |
| `zpu -r <name>` / `zpu -ra` | Ask, then kill the session(s) and start them fresh                    |
| `tuios ls`                  | List sessions                                                         |

Projects are listed in the private file `~/.config/zp/projects`.

## Words

A tmux window is a TUIOS **workspace**, shown as a number in the top bar. A tmux
pane is a TUIOS **window**.

## The prefix: `Ctrl-a`

Every TUIOS shortcut starts with `Ctrl-a`, followed by a key. Wait a moment and
a popup lists the keys. `Ctrl-a Ctrl-a` sends a real `Ctrl-a` to the program.

## Keys shared with the other multiplexers

| After `Ctrl-a`      | What it does                                               |
| ------------------- | ---------------------------------------------------------- |
| `h` `j` `k` `l`     | Move to the window on the left, below, above, right        |
| `H` `J` `K` `L`     | Narrow, heighten, shorten, widen the window; keep pressing |
| `\|` or `%`         | Split right                                                |
| `-` or `"`          | Split down                                                 |
| `c`, `,`, `&`       | New, rename, close workspace                               |
| `Ctrl-h` / `Ctrl-l` | Previous / next workspace; keep pressing                   |
| `1` … `9`           | Go to workspace                                            |
| `z`, `x`            | Zoom, close window                                         |
| `w`                 | Session switcher                                           |
| `d`                 | Detach (the session keeps running)                         |
| `[`, `/`            | Copy mode, search the scrollback                           |

## TUIOS's own keys

| After `Ctrl-a` | What it does                                          |
| -------------- | ----------------------------------------------------- |
| `Ctrl-t`       | The TUIOS keys that the tmux keys replaced, see below |
| `i`, `o`       | Agents view, next window                              |
| `{`, `}`       | Previous, next agent                                  |
| `b`, `y`, `e`  | Sidebar, other sidebar, focus the sidebar             |
| `G`            | Go to any agent, session, workspace or window         |
| `W`, `Tab`     | Workspace switcher, last workspace                    |
| `Space`        | Next layout: BSP, master-stack, scrolling             |
| `v`            | Review the window's changes                           |
| `g`            | Scratch session                                       |
| `:` or `P`     | Command palette                                       |
| `C`, `Ctrl-k`  | Settings, keybinding manager                          |
| `?`            | Help                                                  |

| After `Ctrl-a Ctrl-t` | What it does                               |
| --------------------- | ------------------------------------------ |
| `c`, `r`, `p`         | New, rename, previous window               |
| `0` … `9`             | Go to window                               |
| `Space`               | Toggle tiling (floating windows)           |
| `s`, `E`              | Scrollback browser, scrollback in editor   |
| `f`                   | Search files                               |
| `w`, `m`, `L`, `T`    | Workspace, minimize, layout and tape menus |
| `o`                   | Oldest item waiting for you                |
| `q`                   | Quit: kills the session                    |

**In copy mode:** vi keys. `v` and `V` select, `y` copies, `/` and `?` search,
`n` and `N` repeat, `q` or `Esc` leave.

## Good to know

- `wt <branch>` opens a window, not a workspace.
- In window mode, single keys run commands: `w` and `x` close a window, `q`
  quits. `i` or `Enter` goes back to typing. `Ctrl-a Esc` is the way into it.
- `H` and `L` don't move a divider left and right as in tmux. They narrow and
  widen the focused window, so on the right-hand window, the divider moves the
  other way.
- `Ctrl-p`, `Alt-Space` and some `Alt` keys work without the prefix, so programs
  in a window don't get them. See `tuios keybinds doctor`.
- Settings changed in the UI get written to `config.toml`, so they show up as a
  change in this repository.
- Config: `~/.config/tuios/config.toml`.
