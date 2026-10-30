# zpu: the TUIOS adapter of zp, see zp.zsh. One session per project.

zpu() { _zp_cli zpu "$@" }

# With no daemon running, `tuios ls` lists the saved sessions, marked "saved"
_zpu_sessions() {
  tuios ls --json 2>/dev/null | jq -r '.[]?.name'
}

_zpu_running() {
  tuios ls --json 2>/dev/null | jq -r '.[]? | select(.saved != true) | .name'
}

_zpu_open() {
  _zpu_sessions | grep -qxF -- "$1" || _zpu_start "$1" "$2"
  _zpu_attach "$1"
}

# A saved session comes back with the daemon. Else the project's private layout
# if there is one, or nvim, a coding agent and a shell, each in its own workspace.
# No tapes: they need an attached client, so they can't start in the background.
# An attached `tuios new` opens an empty desktop, a detached one a shell.
_zpu_start() {
  if _zpu_sessions | grep -qxF -- "$1"; then
    tuios start-server >/dev/null 2>&1
    return
  fi
  tuios new "$1" --detach --cwd "$2" >/dev/null
  if [[ -r $ZP_DIR/$1.tuios ]]; then
    source "$ZP_DIR/$1.tuios" "$1" "$2"
    return
  fi
  _zpu_tab "$1" 1 nvim "$2" "_zp_run nvim ."
  _zpu_tab "$1" 2 agent "$2" "_zp_run _zp_agent"
  _zpu_tab "$1" 3 shell "$2"
}

# _zpu_tab <name> <workspace> <tab> <dir> [command]   name the workspace and open
# a window in it; workspace 1 uses the session's first window.
_zpu_tab() {
  local id
  if [[ $2 == 1 ]]; then
    id=$(tuios list-windows -s "$1" --json | jq -r '.windows[0].window_id')
  else
    id=$(tuios new-window -s "$1" "$3" --workspace "$2" --cwd "$4" --no-focus --print-id)
  fi
  tuios set-workspace-name -s "$1" "$2" "$3" >/dev/null
  [[ -z $5 ]] || tuios send-text -s "$1" -w "$id" "$5"$'\n' >/dev/null
}

# `tuios attach` inside a pane would nest; switch-session doesn't.
_zpu_attach() {
  if [[ -n $TUIOS_ENV ]]; then
    tuios switch-session "$1" >/dev/null
  else
    tuios attach "$1"
  fi
}

_zpu_current() {
  print -r -- "$TUIOS_SESSION"
}

_zpu_delete() {
  tuios kill-session "$1"
}

# Fails if the session only exists on disk (saved)
_zpu_busy() {
  local panes=$(tuios list-windows -s "$1" --json 2>/dev/null | jq -r '.windows[].pid')
  [[ -n $panes ]] || return
  _zp_busy_panes ${(f)panes}
}
