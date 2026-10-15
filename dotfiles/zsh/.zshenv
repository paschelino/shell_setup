# ~/.zshenv: read by every zsh process (interactive shells, scripts, editors).
# Keep it to plain exports: no output, no slow commands. PATH is set in
# .zprofile, because macOS's /etc/zprofile (path_helper) would reorder it.

export XDG_CONFIG_HOME="$HOME/.config"
export EDITOR=nvim
export VISUAL=nvim

# zk
export ZK_NOTEBOOK_DIR="$HOME/z"
export ZK_SHELL=/bin/bash

# version managers
export PNPM_HOME="$HOME/Library/pnpm"

# erlang / elixir
export KERL_CONFIGURE_OPTIONS="--disable-debug --without-javac"
export ERL_AFLAGS="-kernel shell_history enabled"

# libpq (psql) for compilers and pkg-config
export LDFLAGS="-L/opt/homebrew/opt/libpq/lib"
export CPPFLAGS="-I/opt/homebrew/opt/libpq/include"
export PKG_CONFIG_PATH="/opt/homebrew/opt/libpq/lib/pkgconfig"

# saml2aws
export SAML2AWS_SESSION_DURATION=43200
