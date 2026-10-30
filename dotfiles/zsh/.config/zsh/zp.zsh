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
# zp -c|--cheat  open the Zellij cheat sheet in nvim; with -b|--browser (or
#                -cb) in the browser instead.
zp() {
  local all= cheat= browser=
  while [[ $1 == -* ]]; do
    case $1 in
      -a | --all) all=1 ;;
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
    '(-a --all -c --cheat 1)'{-c,--cheat}'[open the Zellij cheat sheet in nvim]' \
    '(-a --all -b --browser 1)'{-b,--browser}'[with --cheat: open it in the browser]' \
    '1:project:->project'
  if [[ $state == project ]]; then
    compadd -- ${(f)"$(_zp_projects | cut -f1)"}
  fi
}
compdef _zp zp
