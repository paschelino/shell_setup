# ~/.zprofile: read by login shells (terminal windows, tmux panes) after
# macOS's /etc/zprofile. Everything started from such a shell inherits PATH.

# Homebrew: PATH, MANPATH, INFOPATH, fpath and HOMEBREW_PREFIX
eval "$(/opt/homebrew/bin/brew shellenv)"

# Keep only the first occurrence of each entry.
typeset -U path

# Highest priority first.
path=(
  "$HOME/.local/bin" # local binaries (git-wt, pipx, ...)
  /opt/homebrew/opt/openjdk@25/bin
  "$HOME/go/bin"
  /opt/homebrew/opt/libpq/bin # psql
  "$HOME/bin"                 # personal scripts
  "$PNPM_HOME"
  "$HOME/.local/share/mise/shims" # non-interactive use; .zshrc activates mise
  $path
  "$HOME/.cargo/bin"
)

# JetBrains Toolbox command-line launchers, if installed
if [[ -d "$HOME/Library/Application Support/JetBrains/Toolbox/scripts" ]]; then
  path+=("$HOME/Library/Application Support/JetBrains/Toolbox/scripts")
fi
