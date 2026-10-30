# zpt: the tmux adapter of zp, see zp.zsh. One session per project.

zpt() { _zp_cli zpt "$@" }

_zpt_sessions() {
  tmux list-sessions -F '#S' 2>/dev/null
}

_zpt_running() {
  _zpt_sessions
}

_zpt_open() {
  tmux has-session -t "=$1" 2>/dev/null || _zpt_start "$1" "$2"
  _zpt_attach "$1"
}

_zpt_start() {
  tmux new-session -d -s "$1" -c "$2"
}

_zpt_attach() {
  if [[ -n $TMUX ]]; then
    tmux switch-client -t "=$1"
  else
    tmux attach-session -t "=$1"
  fi
}

_zpt_current() {
  [[ -n $TMUX ]] && tmux display-message -p '#S'
}

_zpt_delete() {
  tmux kill-session -t "=$1"
}

_zpt_busy() {
  local panes=$(tmux list-panes -s -t "=$1" -F '#{pane_pid}' 2>/dev/null)
  [[ -n $panes ]] || return
  _zp_busy_panes ${(f)panes}
}
