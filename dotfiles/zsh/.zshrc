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

# carapace: completions for hundreds of CLIs, falling back to other shells'
export CARAPACE_BRIDGES='zsh,fish,bash,inshellisense'
source <(carapace _carapace zsh)

# --- Integrations ------------------------------------------------------------
source "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
source <(fzf --zsh) # Ctrl-r: history search, Ctrl-t: files, Alt-c: cd
eval "$(starship init zsh)"
eval "$(direnv hook zsh)"

# --- Git worktree helper (git-wt) --------------------------------------------
# Requires: git-wt binary in ~/.local/bin (or PATH)
# Install:  https://github.com/k1LoW/git-wt/releases
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
    if [[ -n $TMUX ]]; then
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

# Must be sourced last, after all widgets are defined.
source "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
