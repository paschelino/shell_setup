cargo install nu --locked

for crate in nu_plugin_inc nu_plugin_polars nu_plugin_gstat nu_plugin_formats nu_plugin_query
do
  cargo install "$crate" --locked 
done

