# zp: open a project's multiplexer session. Sourced by ~/.zshrc. This file holds
# what all tools share, the zp*.zsh files beside it one adapter per tool.

# Private, machine-local project list for zp; deliberately not in this repo.
# One project per line: <name> <path> [<agent>], e.g. `shup ~/shup claude`.
# A layout file <name>.kdl next to it replaces the generic project layout.
ZP_DIR=${XDG_CONFIG_HOME:-$HOME/.config}/zp

# Adapter prefix -> tool, whose config directory holds its cheat sheet
typeset -gA ZP_TOOLS=(zpz zellij zpt tmux zph herdr zpu tuios)

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

# _zp_run <command...>   for layouts: run a command in the pane's directory with
# its direnv and mise environment, then stay in a shell.
# Needed because those hooks only run on a prompt, which `zsh -ic` never shows.
_zp_run() {
  eval "$(direnv export zsh 2>/dev/null)"
  eval "$(mise hook-env -s zsh 2>/dev/null)"
  "$@"
  exec zsh
}

# Print the adapter prefix of the multiplexer this shell runs in, if any. TUIOS
# comes first because its panes set $HERDR_ENV too, for herdr plugins.
_zp_host() {
  if [[ -n $TUIOS_ENV ]]; then
    print zpu
  elif [[ -n $HERDR_ENV ]]; then
    print zph
  elif [[ -n $ZELLIJ ]]; then
    print zpz
  elif [[ -n $TMUX ]]; then
    print zpt
  fi
}

# _zp_cli <adapter> [args]   the commands zp, zpt, zph and zpu, whose adapters
# provide _<adapter>_sessions (all, including ones to resurrect), _running,
# _open <name> <dir>, _start <name> <dir> (in the background), _attach <name>,
# _current, _delete <name> and _busy <name>.
#
# <command> [project]   open the project's session, creating it if needed;
#                       without a name, pick via fzf. Works from inside the same
#                       multiplexer by switching, and refuses to run inside
#                       another one, whose prefix key would swallow ours.
# <command> -a|--all    start the sessions of all projects in the background
#                       (e.g. after a reboot), then attach to the first one.
# <command> -r|--restart [-a|project]
#                       kill the session(s) first and start them fresh, e.g. to
#                       pick up a changed layout; lists what runs in them and
#                       asks first.
# <command> -c|--cheat  open the tool's cheat sheet in nvim; with -b|--browser
#                       (or -cb) in the browser instead.
_zp_cli() {
  local prog=$funcstack[2] tool=$1
  shift
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
        print -u2 "$prog: unknown option $1"
        return 1
        ;;
    esac
    shift
  done
  if [[ -n $cheat ]]; then
    _zp_cheat $browser
    return
  fi
  local host=$(_zp_host)
  if [[ -n $host && $host != $tool ]]; then
    print -u2 "$prog: refusing to run inside $ZP_TOOLS[$host]; detach from it first"
    return 1
  fi
  if [[ ! -r $ZP_DIR/projects ]]; then
    print -u2 "$prog: no project list, create $ZP_DIR/projects with lines like: <name> <path> [<agent>]"
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
    print -u2 "$prog: unknown project '$name' (see $ZP_DIR/projects)"
    return 1
  fi
  local dir=${${entry#*$'\t'}%$'\t'*}
  [[ -n $restart ]] && { _zp_kill "$name" || return }
  _${tool}_open "$name" "$dir"
}

# Start every project's session in the background; running ones are left
# alone, exited ones (e.g. after a reboot) are resurrected.
_zp_all() {
  local running=$(_${tool}_running)
  local name dir agent first
  while IFS=$'\t' read -r name dir agent; do
    : ${first:=$name}
    if print -r -- "$running" | grep -qxF -- "$name"; then
      print "$prog: $name is already running"
      continue
    fi
    print "$prog: starting $name"
    _${tool}_start "$name" "$dir" </dev/null
  done < <(_zp_projects)
  [[ -z $host && -n $first ]] && _${tool}_attach "$first"
}

# _zp_kill <name...>   kill and delete those of the sessions that exist, after
# listing what runs in them and asking; fails when declined. Refuses the
# session it's called from, which would take the terminal down with it.
_zp_kill() {
  local -a sessions=(${(f)"$(_${tool}_sessions)"})
  local -a hits=(${argv:*sessions})
  (( $#hits )) || return 0
  local current=$(_${tool}_current)
  if [[ -n $current ]] && (( ${hits[(Ie)$current]} )); then
    print -u2 "$prog: can't restart $current from inside it"
    return 1
  fi
  local s busy
  for s in $hits; do
    if ! busy=$(_${tool}_busy "$s"); then
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
    _${tool}_delete "$s" >/dev/null
  done
}

# _zp_busy_panes <pid...>   print "pid command" of what runs in the panes with
# these shell pids: a pane's child processes, or the pane itself if it isn't an
# idle shell. A shell busy with builtins only (e.g. `while :; do :; done`) has
# no child and looks idle.
_zp_busy_panes() {
  local pane kids
  for pane; do
    kids=$(pgrep -P $pane)
    if [[ -n $kids ]]; then
      ps -o pid=,args= -p ${(j:,:)${(f)kids}}
    elif [[ $(ps -o args= -p $pane) != (-|)(*/|)zsh ]]; then
      ps -o pid=,args= -p $pane
    fi
  done | sed 's/^ */  /'
}

# _zp_cheat [browser]   open the tool's cheat sheet in nvim, or rendered as
# HTML in the default browser when an argument is given
_zp_cheat() {
  local name=$ZP_TOOLS[$tool]
  local sheet=${XDG_CONFIG_HOME:-$HOME/.config}/$name/cheatsheet.md
  if [[ ! -r $sheet ]]; then
    print -u2 "$prog: no cheat sheet at $sheet"
    return 1
  fi
  if [[ -z $1 ]]; then
    nvim "$sheet"
    return
  fi
  local html=${TMPDIR:-/tmp}/$name-cheatsheet.html
  {
    print -r -- "<!doctype html><html><head><meta charset=\"utf-8\"><title>${(C)name} cheat sheet</title>"'<style>
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
    '(-a --all -r --restart -c --cheat 1)'{-c,--cheat}'[open the cheat sheet in nvim]' \
    '(-a --all -r --restart -b --browser 1)'{-b,--browser}'[with --cheat: open it in the browser]' \
    '1:project:->project'
  if [[ $state == project ]]; then
    compadd -- ${(f)"$(_zp_projects | cut -f1)"}
  fi
}
compdef _zp zp

source "$XDG_CONFIG_HOME/zsh/zpz.zsh"
