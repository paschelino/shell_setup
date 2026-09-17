# config.nu
#
# Installed by:
# version = "0.103.0"
#
# This file is used to override default Nushell settings, define
# (or import) custom commands, or run any other startup tasks.
# See https://www.nushell.sh/book/configuration.html
#
# This file is loaded after env.nu and before login.nu
#
# You can open this file in your default editor using:
# config nu
#
# See `help config nu` for more options
#
# You can remove these comments if you want or leave
# them for future reference.

$env.config.show_banner = false
$env.xdg_config_home = $"($env.home)/.config"
$env.path ++= [ $"($env.home)/.cargo/bin" ]

[ nu_plugin_inc
  nu_plugin_polars
  nu_plugin_gstat
  nu_plugin_formats
  nu_plugin_query
] | each { plugin add $"($env.home)/.cargo/bin/($in)" } | ignore

mkdir ($nu.data-dir | path join "vendor/autoload")
starship init nu | save -f ($nu.data-dir | path join "vendor/autoload/starship.nu")
# $env.config.edit_mode = 'vi'

#~/.config/nushell/config.nu
source ~/.cache/carapace/init.nu

# homebrew:
$env.PATH = [ "/opt/homebrew/sbin" ] ++ $env.PATH

# pipx:
$env.PATH = [ $"($env.HOME)/.local/bin" ] ++ ( $env.PATH | uniq )

# asdf
$env.ASDF_DATA_DIR = $"($env.XDG_CONFIG_HOME)/asdf"
source "~/.config/asdf/completions/nushell.nu"
$env.PATH = [ $"($env.ASDF_DATA_DIR)/shims" ] ++ $env.PATH

# node version manager n:
$env.N_PREFIX = $"($env.HOME)"
$env.PATH = [ $"($env.HOME)/bin" ] ++ $env.PATH

# erlang / elixir
$env.KERL_CONFIGURE_OPTIONS = "--disable-debug --without-javac"
$env.ERL_AFLAGS = "-kernel shell_history enabled"

# psql:
$env.PATH = [ "/opt/homebrew/opt/libpq/bin" ] ++ $env.PATH

# go:
$env.PATH = [ $"($env.HOME)/go/bin" ] ++ $env.PATH

$env.LDFLAGS = "-L/opt/homebrew/opt/libpq/lib"
$env.CPPFLAGS = "-I/opt/homebrew/opt/libpq/include"

$env.PKG_CONFIG_PATH = "/opt/homebrew/opt/libpq/lib/pkgconfig"

# saml2aws
$env.SAML2AWS_SESSION_DURATION = 43200

# direnv
$env.config = {
  hooks: {
    pre_prompt: [{ ||
      if (which direnv | is-empty) {
        return
      }

      direnv export json | from json | default {} | load-env
      if 'ENV_CONVERSIONS' in $env and 'PATH' in $env.ENV_CONVERSIONS {
        $env.PATH = do $env.ENV_CONVERSIONS.PATH.from_string $env.PATH
      }
    }]
  }
}

# zk
$env.ZK_NOTEBOOK_DIR = $"($env.HOME)/z"
$env.ZK_SHELL = "/bin/bash"

# openjdk / java
$env.PATH = [ "/opt/homebrew/opt/openjdk@25/bin" ] ++ $env.PATH

# local binaries (git-wt, etc.)
$env.PATH = [ $"($env.HOME)/.local/bin" ] ++ $env.PATH

$env.PATH = $env.PATH | uniq

# =============================================================================
# Git Worktree Helper (git-wt)
# =============================================================================
# Requires: git-wt binary in ~/.local/bin (or PATH)
# Install:  https://github.com/k1LoW/git-wt/releases
# Config:   git config --global wt.basedir "../{gitroot}-worktrees"
#           git config --global wt.copyignored true

# List worktrees (excluding main) for fzf selection
def _wt-list [] {
    git wt --json
    | from json
    | where current == false
    | get branch
    | str replace "refs/heads/" ""
}

# Create worktree + open in tmux window, or select existing
def wt [
    branch?: string  # Branch name; omit to select existing via fzf
    --delete (-d)    # Delete worktree (safe: keeps unmerged branch)
    --force (-D)     # Force delete (removes branch even if unmerged)
] {
    if $delete or $force {
        let target = if ($branch | is-empty) {
            git branch --show-current
        } else {
            $branch
        }
        if $force {
            git wt -D $target
        } else {
            git wt -d $target
        }
        return
    }

    if ($branch | is-empty) {
        # Interactive: select existing worktree
        let selected = (_wt-list | str join "\n" | fzf --height 40% --reverse --prompt="worktree> ")
        if ($selected | is-not-empty) {
            let path = (git wt --nocd $selected | tail -1)
            cd $path
        }
    } else {
        # Create new worktree in tmux window
        let path = (git wt --nocd $branch | tail -1)
        let repo_name = (git rev-parse --show-toplevel | path basename)
        let window_name = $"($repo_name)/($branch)"

        if ($env.TMUX? | is-not-empty) {
            tmux neww -c $path -n $window_name
        } else {
            # Fallback: just cd
            cd $path
        }
    }
}

# Alias for quick cleanup
alias wt-rm = wt --delete
alias wt-rm! = wt --force

