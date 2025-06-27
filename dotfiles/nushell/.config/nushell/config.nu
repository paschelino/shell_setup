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
$env.config.edit_mode = 'vi'

#~/.config/nushell/config.nu
source ~/.cache/carapace/init.nu

# asdf
$env.ASDF_DATA_DIR = $"($env.XDG_CONFIG_HOME)/asdf"
source "~/.config/asdf/completions/nushell.nu"
$env.PATH = [ $"($env.ASDF_DATA_DIR)/shims" ] ++ $env.PATH

# erlang / elixir
$env.KERL_CONFIGURE_OPTIONS = "--disable-debug --without-javac"
$env.ERL_AFLAGS = "-kernel shell_history enabled"

# psql:
$env.PATH = [ "/opt/homebrew/opt/libpq/bin" ] ++ $env.PATH

$env.LDFLAGS = "-L/opt/homebrew/opt/libpq/lib"
$env.CPPFLAGS = "-I/opt/homebrew/opt/libpq/include"

$env.PKG_CONFIG_PATH = "/opt/homebrew/opt/libpq/lib/pkgconfig"

# saml2aws
$env.SAML2AWS_SESSION_DURATION=43200

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

