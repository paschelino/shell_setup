# tmux cheat sheet

Open this sheet with `zpt -c` (in nvim) or `zpt -cb` (in the browser).

## Starting and switching projects

| Command                     | What it does                                                          |
| --------------------------- | --------------------------------------------------------------------- |
| `zpt -a` / `zpt --all`      | Start all project sessions in the background, attach to the first one |
| `zpt <name>`                | Open a project's session, creating it if needed                       |
| `zpt`                       | Pick a project with fzf                                               |
| `zpt -r <name>` / `zpt -ra` | Ask, then kill the session(s) and start them fresh                    |
| `tmux list-sessions`        | List sessions                                                         |

Projects are listed in the private file `~/.config/zp/projects`.

## The prefix: `Ctrl-a`

Every tmux shortcut starts with `Ctrl-a`, followed by a key. The status bar
lists the main keys while the prefix is active. `Ctrl-a Ctrl-a` sends a real
`Ctrl-a` to the program.

## Keys shared with the other multiplexers

| After `Ctrl-a`      | What it does                                      |
| ------------------- | ------------------------------------------------- |
| `h` `j` `k` `l`     | Move to the pane on the left, below, above, right |
| `H` `J` `K` `L`     | Resize; keep pressing while it repeats            |
| `\|` or `%`         | Split right                                       |
| `-` or `"`          | Split down                                        |
| `c`, `,`, `&`       | New, rename, close window                         |
| `Ctrl-h` / `Ctrl-l` | Previous / next window; keep pressing             |
| `1` … `9`           | Go to window                                      |
| `z`, `x`            | Zoom, close pane                                  |
| `w`                 | Pick a session or window from a tree              |
| `d`                 | Detach (the session keeps running)                |
| `[`, `/`            | Copy mode, search the scrollback                  |

## tmux's own keys

| After `Ctrl-a` | What it does                                   |
| -------------- | ---------------------------------------------- |
| `*`            | New floating pane                              |
| `@`            | Float the pane, or put it back into the layout |
| `>`, `<`       | Pane menu, window menu                         |
| `s`            | Pick a session                                 |
| `(`, `)`       | Previous, next session                         |
| `?`            | List all keys                                  |
| `r`            | Reload the config                              |
| `Ctrl-s`       | Save all sessions now                          |
| `Ctrl-r`       | Restore the last save                          |

**In copy mode:** vi keys. `v` selects, `Ctrl-v` toggles a rectangle, `y` copies
to the macOS clipboard, `/` and `?` search, `n` and `N` repeat, `q` leaves.

## Good to know

- `wt <branch>` opens a window.
- Sessions are saved every 5 minutes. After a reboot, `zpt` restores the last
  save, including nvim and the agents.
- Config: `~/.tmux.conf`.
