# env.nu
#
# Installed by:
# version = "0.103.0"
#
# Previously, environment variables were typically configured in `env.nu`.
# In general, most configuration can and should be performed in `config.nu`
# or one of the autoload directories.
#
# This file is generated for backwards compatibility for now.
# It is loaded before config.nu and login.nu
#
# See https://www.nushell.sh/book/configuration.html
#
# Also see `help config env` for more options.
#
# You can remove these comments if you want or leave
# them for future reference.
## ~/.config/nushell/env.nu
$env.CARAPACE_BRIDGES = 'zsh,fish,bash,inshellisense' # optional
mkdir ~/.cache/carapace
carapace _carapace nushell | save --force ~/.cache/carapace/init.nu

# ~/.config/nushell/env.nu

# 1) Ensure rbenv/bin + shims are always on PATH
$env.PATH = [
  $"($env.HOME)/.rbenv/bin"
  $"($env.HOME)/.rbenv/shims"
] ++ $env.PATH
$env.RBENV_SHELL = "nu"


# pnpm
$env.PNPM_HOME = "/Users/paschelino/Library/pnpm"
$env.PATH = ($env.PATH | split row (char esep) | prepend $env.PNPM_HOME )
# pnpm end
