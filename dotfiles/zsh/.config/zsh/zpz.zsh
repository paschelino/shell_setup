# zp, zpz: the Zellij adapter of zp, see zp.zsh.

zp() { _zp_cli zpz "$@" }
alias zpz=zp

_zpz_sessions() {
  zellij list-sessions --short --no-formatting 2>/dev/null
}

_zpz_running() {
  zellij list-sessions --no-formatting 2>/dev/null | grep -v EXITED | cut -d' ' -f1
}

_zpz_open() {
  local layout=$(_zpz_layout "$1")
  if _zpz_sessions | grep -qxF -- "$1"; then
    if [[ -n $ZELLIJ ]]; then
      zellij action switch-session "$1"
    else
      zellij attach "$1"
    fi
  elif [[ -n $ZELLIJ ]]; then
    zellij action switch-session "$1" --cwd "$2" --layout "$layout"
  else
    (cd "$2" && zellij --session "$1" --new-session-with-layout "$layout")
  fi
}

_zpz_start() {
  (cd "$2" && zellij attach --create-background "$1" options --default-layout "$(_zpz_layout "$1")")
}

_zpz_attach() {
  zellij attach "$1"
}

_zpz_current() {
  print -r -- "$ZELLIJ_SESSION_NAME"
}

_zpz_delete() {
  zellij delete-session --force "$1"
}

# Fails if the session has no server (exited)
_zpz_busy() {
  local server=$(ps -axo pid=,args= | awk -v s="$1" '$3 == "--server" && $2 ~ /zellij$/ { n = split($4, p, "/"); if (p[n] == s) { print $1; exit } }')
  [[ -n $server ]] || return
  _zp_busy_panes $(pgrep -P $server)
}

# The project's private layout if there is one, else the generic one
_zpz_layout() {
  if [[ -r $ZP_DIR/$1.kdl ]]; then
    print -r -- "$ZP_DIR/$1.kdl"
  else
    print project
  fi
}
