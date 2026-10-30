# zpt: the tmux adapter of zp, see zp.zsh. One session per project.

zpt() { _zp_cli zpt "$@" }

ZPT_RESTORE=~/.local/share/tmux/plugins/tmux-resurrect/scripts/restore.sh

# After a reboot, bring back the state tmux-continuum saved. Session 0 is what
# tmux-resurrect replaces when it restores from scratch. Not after a kill, which
# may have ended the server, because -r wants a fresh session.
_zpt_server() {
  tmux list-sessions >/dev/null 2>&1 && return
  [[ -z $_zpt_killed && -x $ZPT_RESTORE && -e ~/.local/share/tmux/resurrect/last ]] || return 0
  tmux new-session -d -s 0 && tmux run-shell "$ZPT_RESTORE"
}

_zpt_sessions() {
  _zpt_server
  tmux list-sessions -F '#S' 2>/dev/null
}

_zpt_running() {
  _zpt_sessions
}

_zpt_open() {
  _zpt_server
  tmux has-session -t "=$1" 2>/dev/null || _zpt_start "$1" "$2"
  _zpt_attach "$1"
}

# The project's private layout if there is one, else nvim, a coding agent and a
# shell, each in its own window
_zpt_start() {
  if [[ -r $ZP_DIR/$1.tmux ]]; then
    source "$ZP_DIR/$1.tmux" "$1" "$2"
    return
  fi
  tmux new-session -d -s "$1" -c "$2" -n nvim "zsh -ic '_zp_run nvim .'"
  tmux new-window -d -t "=$1:" -c "$2" -n agent "zsh -ic '_zp_run _zp_agent'"
  tmux new-window -d -t "=$1:" -c "$2" -n shell
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
  typeset -g _zpt_killed=1
  tmux kill-session -t "=$1"
}

_zpt_busy() {
  local panes=$(tmux list-panes -s -t "=$1" -F '#{pane_pid}' 2>/dev/null)
  [[ -n $panes ]] || return
  _zp_busy_panes ${(f)panes}
}
