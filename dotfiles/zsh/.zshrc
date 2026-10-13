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

# Must be sourced last, after all widgets are defined.
source "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
