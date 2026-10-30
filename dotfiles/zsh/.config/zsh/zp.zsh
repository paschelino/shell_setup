# zp: open a project's Zellij session. Sourced by ~/.zshrc.

# Private, machine-local project list for zp; deliberately not in this repo.
# One project per line: <name> <path> [<agent>], e.g. `shup ~/shup claude`.
# A layout file <name>.kdl next to it replaces the generic project layout.
ZP_DIR=${XDG_CONFIG_HOME:-$HOME/.config}/zp

# Print the projects as "name<TAB>absolute path<TAB>agent", skipping comments
_zp_projects() {
  [[ -r $ZP_DIR/projects ]] || return
  local line p
  local -a f
  while IFS= read -r line; do
    f=(${(z)line})
    [[ -z $f[1] || $f[1] == \#* ]] && continue
    p=${f[2]/#\~/$HOME}
    print -r -- "$f[1]"$'\t'"${p:A}"$'\t'"${f[3]:-opencode}"
  done < "$ZP_DIR/projects"
}

# Start the coding agent configured for the project in $PWD (used by the
# project layout's agent tab); defaults to opencode.
_zp_agent() {
  local agent=$(_zp_projects | awk -F'\t' -v d="${PWD:A}" '$2 == d { print $3; exit }')
  ${agent:-opencode}
}

# _zp_run <command...>   for Zellij layouts: run a command in the pane's
# directory with its direnv and mise environment, then stay in a shell.
# Needed because those hooks only run on a prompt, which `zsh -ic` never shows.
_zp_run() {
  eval "$(direnv export zsh 2>/dev/null)"
  eval "$(mise hook-env -s zsh 2>/dev/null)"
  "$@"
  exec zsh
}

# zp [project]   open the project's Zellij session (nvim, agent and shell
#                tabs), creating it if needed; without a name, pick via fzf.
#                Works from inside Zellij as well, by switching sessions.
# zp -a|--all    start the sessions of all projects in the background (e.g.
#                after a reboot), then attach to the first one.
# zp -r|--restart [-a|project]
#                kill the session(s) first and start them fresh, e.g. to pick
#                up a changed layout; lists what runs in them and asks first.
# zp -c|--cheat  open the Zellij cheat sheet in nvim; with -b|--browser (or
#                -cb) in the browser instead.
zp() {
  local all= restart= cheat= browser=
  while [[ $1 == -* ]]; do
    case $1 in
      -a | --all) all=1 ;;
      -r | --restart) restart=1 ;;
      -ra | -ar) all=1 restart=1 ;;
      -c | --cheat) cheat=1 ;;
      -b | --browser) browser=1 ;;
      -cb | -bc) cheat=1 browser=1 ;;
      *)
        print -u2 "zp: unknown option $1"
        return 1
        ;;
    esac
    shift
  done
  if [[ -n $cheat ]]; then
    _zp_cheat $browser
    return
  fi
  if [[ ! -r $ZP_DIR/projects ]]; then
    print -u2 "zp: no project list, create $ZP_DIR/projects with lines like: <name> <path> [<agent>]"
    return 1
  fi
  if [[ -n $all ]]; then
    [[ -n $restart ]] && { _zp_kill ${(f)"$(_zp_projects | cut -f1)"} || return }
    _zp_all
    return
  fi
  local name=$1
  if [[ -z $name ]]; then
    name=$(_zp_projects | cut -f1 | fzf --height 40% --reverse --prompt="project> ") || return
  fi
  local entry=$(_zp_projects | awk -F'\t' -v n="$name" '$1 == n { print; exit }')
  if [[ -z $entry ]]; then
    print -u2 "zp: unknown project '$name' (see $ZP_DIR/projects)"
    return 1
  fi
  local dir=${${entry#*$'\t'}%$'\t'*}
  local layout=$(_zp_layout "$name")
  [[ -n $restart ]] && { _zp_kill "$name" || return }

  if zellij list-sessions --short --no-formatting 2>/dev/null | grep -qxF -- "$name"; then
    if [[ -n $ZELLIJ ]]; then
      zellij action switch-session "$name"
    else
      zellij attach "$name"
    fi
  elif [[ -n $ZELLIJ ]]; then
    zellij action switch-session "$name" --cwd "$dir" --layout "$layout"
  else
    (cd "$dir" && zellij --session "$name" --new-session-with-layout "$layout")
  fi
}

# The project's private layout if there is one, else the generic one
_zp_layout() {
  if [[ -r $ZP_DIR/$1.kdl ]]; then
    print -r -- "$ZP_DIR/$1.kdl"
  else
    print project
  fi
}

# Start every project's session in the background; running ones are left
# alone, exited ones (e.g. after a reboot) are resurrected.
_zp_all() {
  local running=$(zellij list-sessions --no-formatting 2>/dev/null | grep -v EXITED | cut -d' ' -f1)
  local name dir agent first
  while IFS=$'\t' read -r name dir agent; do
    : ${first:=$name}
    if print -r -- "$running" | grep -qxF -- "$name"; then
      print "zp: $name is already running"
      continue
    fi
    print "zp: starting $name"
    (cd "$dir" && zellij attach --create-background "$name" options --default-layout "$(_zp_layout "$name")")
  done < <(_zp_projects)
  [[ -z $ZELLIJ && -n $first ]] && zellij attach "$first"
}

# _zp_kill <name...>   kill and delete those of the sessions that exist, after
# listing what runs in them and asking; fails when declined. Refuses the
# session it's called from, which would take the terminal down with it.
_zp_kill() {
  local -a sessions=(${(f)"$(zellij list-sessions --short --no-formatting 2>/dev/null)"})
  local -a hits=(${argv:*sessions})
  (( $#hits )) || return 0
  if (( ${hits[(Ie)$ZELLIJ_SESSION_NAME]} )); then
    print -u2 "zp: can't restart $ZELLIJ_SESSION_NAME from inside it"
    return 1
  fi
  local s busy
  for s in $hits; do
    if ! busy=$(_zp_busy "$s"); then
      print -r -- "$s: exited"
    elif [[ -z $busy ]]; then
      print -r -- "$s: only idle shells"
    else
      print -r -- "$s:"$'\n'"$busy"
    fi
  done
  if ! read -q "?Kill and restart these sessions? [y/N] "; then
    print
    return 1
  fi
  print
  for s in $hits; do
    zellij delete-session --force "$s" >/dev/null
  done
}

# _zp_busy <session>   print "pid command" of what runs in the session's
# panes: a pane's child processes, or the pane itself if it isn't an idle
# shell. Fails if the session has no server (exited). A shell busy with
# builtins only (e.g. `while :; do :; done`) has no child and looks idle.
_zp_busy() {
  local server=$(ps -axo pid=,args= | awk -v s="$1" '$3 == "--server" && $2 ~ /zellij$/ { n = split($4, p, "/"); if (p[n] == s) { print $1; exit } }')
  [[ -n $server ]] || return
  local pane kids
  for pane in $(pgrep -P $server); do
    kids=$(pgrep -P $pane)
    if [[ -n $kids ]]; then
      ps -o pid=,args= -p ${(j:,:)${(f)kids}}
    elif [[ $(ps -o args= -p $pane) != (-|)(*/|)zsh ]]; then
      ps -o pid=,args= -p $pane
    fi
  done | sed 's/^ */  /'
}

# _zp_cheat [browser]   open the Zellij cheat sheet in nvim, or rendered as
# HTML in the default browser when an argument is given
_zp_cheat() {
  local sheet=${XDG_CONFIG_HOME:-$HOME/.config}/zellij/cheatsheet.md
  if [[ -z $1 ]]; then
    nvim "$sheet"
    return
  fi
  local html=${TMPDIR:-/tmp}/zellij-cheatsheet.html
  {
    print -r -- '<!doctype html><html><head><meta charset="utf-8"><title>Zellij cheat sheet</title><style>
body { font: 16px/1.5 -apple-system, sans-serif; max-width: 52rem; margin: 2rem auto; padding: 0 1rem; color: #cdd6f4; background: #1e1e2e; }
h1, h2 { color: #89b4fa; } a { color: #89b4fa; }
code { font-family: "Meslo LGS Nerd Font Mono", monospace; background: #313244; padding: 0 .3em; border-radius: 4px; }
table { border-collapse: collapse; margin: 1rem 0; } th, td { border: 1px solid #45475a; padding: .3rem .7rem; text-align: left; }
th { background: #313244; }
</style></head><body>'
    cmark-gfm --extension table "$sheet"
    print -r -- '</body></html>'
  } > "$html"
  open "$html"
}

_zp() {
  _arguments \
    '(-a --all -c --cheat 1)'{-a,--all}'[start all projects in the background]' \
    '(-r --restart -c --cheat -b --browser)'{-r,--restart}'[kill the session(s) first, after asking]' \
    '(-a --all -r --restart -c --cheat 1)'{-c,--cheat}'[open the Zellij cheat sheet in nvim]' \
    '(-a --all -r --restart -b --browser 1)'{-b,--browser}'[with --cheat: open it in the browser]' \
    '1:project:->project'
  if [[ $state == project ]]; then
    compadd -- ${(f)"$(_zp_projects | cut -f1)"}
  fi
}
compdef _zp zp
