# herdr cheat sheet

Open this sheet with `zph -c` (in nvim) or `zph -cb` (in the browser).

## Starting and switching projects

Each project is a workspace in herdr's default server.

| Command                     | What it does                                                   |
| --------------------------- | -------------------------------------------------------------- |
| `zph -a` / `zph --all`      | Create the workspaces of all projects, attach to the first one |
| `zph <name>`                | Open a project's workspace, creating it if needed              |
| `zph`                       | Pick a project with fzf                                        |
| `zph -r <name>` / `zph -ra` | Ask, then close the workspace(s) and start them fresh          |
| `herdr workspace list`      | List workspaces                                                |

Projects are listed in the private file `~/.config/zp/projects`.

## The prefix: `Ctrl-a`

Every herdr shortcut starts with `Ctrl-a`, followed by a key. The bottom line
then shows a few hints, `?` all of them. `Ctrl-a Ctrl-a` sends a real `Ctrl-a`
to the program.

## Keys shared with the other multiplexers

| After `Ctrl-a`      | What it does                                                 |
| ------------------- | ------------------------------------------------------------ |
| `h` `j` `k` `l`     | Move to the pane on the left, below, above, right            |
| `H` `J` `K` `L`     | Resize; press `Ctrl-a` each time, or use `r` below           |
| `\|` or `%`         | Split right                                                  |
| `-` or `"`          | Split down                                                   |
| `c`, `,`, `&`       | New, rename, close tab                                       |
| `Ctrl-h` / `Ctrl-l` | Previous / next tab                                          |
| `1` … `9`           | Go to tab                                                    |
| `z`, `x`            | Zoom, close pane                                             |
| `w`                 | Go to a workspace or agent: `↑` `↓` or `j` `k`, then `Enter` |
| `d`                 | Detach (everything keeps running)                            |
| `[`                 | Copy mode                                                    |
| `/`                 | Also copy mode: press `/` again to search                    |

## herdr's own keys

| After `Ctrl-a`     | What it does                                |
| ------------------ | ------------------------------------------- |
| `?`                | All keys; `/` filters them                  |
| `s`                | Settings                                    |
| `S`                | Workspace navigation in the sidebar         |
| `g`                | Same as `w`                                 |
| `G`                | New worktree                                |
| `N`, `W`, `D`      | New, rename, close workspace                |
| `b`                | Toggle the sidebar                          |
| `r`                | Resize mode                                 |
| `e`                | Open the scrollback in your editor          |
| `Tab`, `Shift-Tab` | Next, previous pane                         |
| `o`                | Go to what the latest notification is about |
| `R`                | Reload the config                           |

The sidebar shows each agent's state: working, blocked, done or idle.

**In copy mode:** `h` `j` `k` `l` `w` `b` `e` `{` `}` move, `v` or `Space`
select, `y` or `Enter` copy, `/` and `?` search, `n` and `N` repeat, `q` or
`Esc` leave. The pane keeps running while you're in it.

## Good to know

- `wt <branch>` opens a tab.
- `H` `J` `K` `L` don't repeat: herdr leaves prefix mode after each key.
- Config: `~/.config/herdr/config.toml`.
