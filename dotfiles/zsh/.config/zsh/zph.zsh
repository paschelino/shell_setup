# zph: the herdr adapter of zp, see zp.zsh. One workspace per project in the
# default server, not one named session each: herdr can't switch between
# sessions from inside one, and its agent overview covers a single server.

zph() { _zp_cli zph "$@" }

# Start the server if it isn't running. It restores its workspaces by itself.
_zph_server() {
  _zph_up && return
  (cd && herdr server >/dev/null 2>&1 &!)
  repeat 50 {
    _zph_up && return
    sleep 0.1
  }
  print -u2 "$prog: herdr server didn't start"
  return 1
}

_zph_up() {
  [[ $(herdr status server --json 2>/dev/null | jq -r .running) == true ]]
}

# _zph_id <name>   print the ID of the project's workspace, if it has one
_zph_id() {
  herdr workspace list | jq -r --arg name "$1" 'first(.result.workspaces[] | select(.label == $name) | .workspace_id) // empty'
}

_zph_sessions() {
  _zph_server || return
  herdr workspace list | jq -r '.result.workspaces[].label'
}

_zph_running() {
  _zph_sessions
}

_zph_open() {
  _zph_server || return
  [[ -n $(_zph_id "$1") ]] || _zph_start "$1" "$2"
  _zph_attach "$1"
}

# The project's private layout if there is one, else nvim, a coding agent and a
# shell, each in its own tab
_zph_start() {
  _zph_server || return
  if [[ -r $ZP_DIR/$1.herdr ]]; then
    source "$ZP_DIR/$1.herdr" "$1" "$2"
    return
  fi
  local id=$(_zph_workspace "$1" "$2" nvim "_zp_run nvim .")
  _zph_tab "$id" "$2" agent "_zp_run _zp_agent"
  _zph_tab "$id" "$2" shell
}

# _zph_workspace <name> <dir> <tab> [command]   create the workspace with its
# first tab and print the workspace's ID
_zph_workspace() {
  local created=$(herdr workspace create --cwd "$2" --label "$1" --no-focus)
  herdr tab rename "$(jq -r .result.tab.tab_id <<<$created)" "$3" >/dev/null
  [[ -z $4 ]] || herdr pane run "$(jq -r .result.root_pane.pane_id <<<$created)" "$4" >/dev/null
  jq -r .result.workspace.workspace_id <<<$created
}

# _zph_tab <workspace> <dir> <tab> [command]   add a tab to the workspace
_zph_tab() {
  local created=$(herdr tab create --workspace "$1" --cwd "$2" --label "$3" --no-focus)
  [[ -z $4 ]] || herdr pane run "$(jq -r .result.root_pane.pane_id <<<$created)" "$4" >/dev/null
}

# Inside herdr, focusing is all it takes: the client follows.
_zph_attach() {
  herdr workspace focus "$(_zph_id "$1")" >/dev/null
  [[ -n $HERDR_ENV ]] || herdr
}

_zph_current() {
  [[ -n $HERDR_ENV ]] && herdr workspace get "$HERDR_WORKSPACE_ID" | jq -r '.result.workspace.label'
}

_zph_delete() {
  herdr workspace close "$(_zph_id "$1")"
}

_zph_busy() {
  local id=$(_zph_id "$1") pane
  [[ -n $id ]] || return
  local -a pids
  for pane in ${(f)"$(herdr pane list --workspace "$id" | jq -r '.result.panes[].pane_id')"}; do
    pids+=($(herdr pane process-info --pane "$pane" | jq -r '.result.process_info.shell_pid'))
  done
  _zp_busy_panes $pids
}
