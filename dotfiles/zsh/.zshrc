# ~/.zshrc: read by interactive shells.

HOMEBREW_PREFIX=${HOMEBREW_PREFIX:-/opt/homebrew}

# --- History -----------------------------------------------------------------
HISTSIZE=100000
SAVEHIST=100000
setopt EXTENDED_HISTORY  # store timestamps
setopt SHARE_HISTORY     # write each command immediately, share across sessions
setopt HIST_IGNORE_SPACE # commands starting with a space are not recorded
setopt HIST_IGNORE_DUPS  # skip consecutive duplicates
setopt HIST_REDUCE_BLANKS

# Typing a directory name changes into it.
setopt AUTO_CD

# --- Vi mode -----------------------------------------------------------------
bindkey -v
KEYTIMEOUT=1 # Esc switches to normal mode after 10 ms instead of 400 ms

# Backspace, Ctrl-w and Ctrl-u keep working past the point where insert mode
# was entered (vi's default stops there).
bindkey -M viins '^?' backward-delete-char
bindkey -M viins '^H' backward-delete-char
bindkey -M viins '^W' backward-kill-word
bindkey -M viins '^U' backward-kill-line

# `v` in normal mode edits the command line in $EDITOR.
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey -M vicmd v edit-command-line

# Beam cursor in insert mode, block cursor in normal mode.
_vi_cursor_shape() {
  if [[ $KEYMAP == vicmd ]]; then
    print -n '\e[2 q'
  else
    print -n '\e[6 q'
  fi
}
autoload -Uz add-zle-hook-widget
add-zle-hook-widget keymap-select _vi_cursor_shape
add-zle-hook-widget line-init _vi_cursor_shape

# --- Completion --------------------------------------------------------------
[[ -d ~/.cache/zsh ]] || mkdir -p ~/.cache/zsh
autoload -Uz compinit
compinit -d ~/.cache/zsh/zcompdump

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}' # case-insensitive
zstyle ':completion:*' format $'\e[2;37mCompleting %d\e[m'

# carapace: completions for hundreds of CLIs, falling back to bash's. No zsh
# bridge: zsh already completes those commands natively.
export CARAPACE_BRIDGES='bash'
source <(carapace _carapace zsh)

# --- Integrations ------------------------------------------------------------
source "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
source <(fzf --zsh) # Ctrl-r: history search, Ctrl-t: files, Alt-c: cd
eval "$(starship init zsh)"
eval "$(direnv hook zsh)"
eval "$(mise activate zsh)"

# --- Git worktree helper (git-wt) --------------------------------------------
# Requires: git-wt (Brewfile: k1LoW/tap/git-wt) and jq
# Config:   git config --global wt.basedir "../{gitroot}-worktrees"
#           git config --global wt.copyignored true

# List worktrees (excluding the current one) for fzf selection
_wt_list() {
  git wt --json | jq -r '.[] | select(.current == false) | .branch | sub("^refs/heads/"; "")'
}

# wt [branch]        create worktree + open it in a tmux window, or select an
#                    existing one via fzf when no branch is given
# wt -d|--delete [b] delete worktree (safe: keeps unmerged branch)
# wt -D|--force [b]  force delete (removes branch even if unmerged)
wt() {
  local delete= force= branch=
  while (( $# )); do
    case $1 in
      -d | --delete) delete=1 ;;
      -D | --force) force=1 ;;
      *) branch=$1 ;;
    esac
    shift
  done

  if [[ -n $delete || -n $force ]]; then
    local target=${branch:-$(git branch --show-current)}
    if [[ -n $force ]]; then
      git wt -D "$target"
    else
      git wt -d "$target"
    fi
    return
  fi

  if [[ -z $branch ]]; then
    local selected
    selected=$(_wt_list | fzf --height 40% --reverse --prompt="worktree> ")
    if [[ -n $selected ]]; then
      cd "$(git wt --nocd "$selected" | tail -1)"
    fi
  else
    # Not `path`: in zsh that is tied to $PATH.
    local wt_path repo_name
    wt_path=$(git wt --nocd "$branch" | tail -1)
    repo_name=$(basename "$(git rev-parse --show-toplevel)")
    if [[ -n $ZELLIJ ]]; then
      zellij action new-tab --cwd "$wt_path" --name "$repo_name/$branch" >/dev/null
    elif [[ -n $TMUX ]]; then
      tmux neww -c "$wt_path" -n "$repo_name/$branch"
    else
      cd "$wt_path"
    fi
  fi
}

# Completion for wt; replaces carapace's completer for an unrelated `wt` tool.
_wt() {
  _arguments \
    '(-d --delete -D --force)'{-d,--delete}'[delete worktree, keep unmerged branch]' \
    '(-d --delete -D --force)'{-D,--force}'[force delete, also removes unmerged branch]' \
    '1:branch:->branch'
  if [[ $state == branch ]]; then
    compadd -- ${(f)"$(git for-each-ref --format='%(refname:short)' refs/heads 2>/dev/null)"}
  fi
}
compdef _wt wt

alias wt-rm='wt --delete'
alias 'wt-rm!'='wt --force'

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
zp() {
  if [[ ! -r $ZP_DIR/projects ]]; then
    print -u2 "zp: no project list, create $ZP_DIR/projects with lines like: <name> <path> [<agent>]"
    return 1
  fi
  if [[ $1 == (-a|--all) ]]; then
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

_zp() {
  _arguments \
    '(-a --all 1)'{-a,--all}'[start all projects in the background]' \
    '1:project:->project'
  if [[ $state == project ]]; then
    compadd -- ${(f)"$(_zp_projects | cut -f1)"}
  fi
}
compdef _zp zp

# Must be sourced last, after all widgets are defined.
source "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
