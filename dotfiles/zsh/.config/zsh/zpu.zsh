# zpu: the TUIOS adapter of zp, see zp.zsh. One session per project.

zpu() { _zp_cli zpu "$@" }

# With no daemon running, `tuios ls` lists the saved sessions, marked "saved"
_zpu_sessions() {
  tuios ls --json 2>/dev/null | jq -r '.[]?.name'
}

_zpu_running() {
  tuios ls --json 2>/dev/null | jq -r '.[]? | select(.saved != true) | .name'
}

# `tuios attach` inside a pane would nest; switch-session doesn't.
_zpu_open() {
  if [[ -n $TUIOS_ENV ]]; then
    tuios switch-session "$1" --create --cwd "$2" >/dev/null
  else
    # An attached `tuios new` opens an empty desktop, a detached one a shell.
    _zpu_sessions | grep -qxF -- "$1" || _zpu_start "$1" "$2"
    _zpu_attach "$1"
  fi
}

_zpu_start() {
  tuios new "$1" --detach --cwd "$2" >/dev/null
}

_zpu_attach() {
  tuios attach "$1"
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
