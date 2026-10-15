# env.nu: loaded before config.nu.
#
# Nushell is kept for occasional structured-data work; the interactive shell
# is zsh (see dotfiles/zsh). Started from zsh, nu inherits the environment
# (PATH, version managers, ...), so only nushell's own setup lives here.

$env.CARAPACE_BRIDGES = 'zsh,fish,bash,inshellisense' # optional
mkdir ~/.cache/carapace
carapace _carapace nushell | save --force ~/.cache/carapace/init.nu
