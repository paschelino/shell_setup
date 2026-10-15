# config.nu: loaded after env.nu. See env.nu for why this config is minimal.

$env.config.show_banner = false

[ nu_plugin_inc
  nu_plugin_polars
  nu_plugin_gstat
  nu_plugin_formats
  nu_plugin_query
] | each { plugin add (which $in | get path.0) } | ignore

mkdir ($nu.data-dir | path join "vendor/autoload")
starship init nu | save -f ($nu.data-dir | path join "vendor/autoload/starship.nu")

source ~/.cache/carapace/init.nu
