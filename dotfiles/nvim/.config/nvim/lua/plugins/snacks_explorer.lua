return {
  "folke/snacks.nvim",
  opts = function(_, opts)
    opts.explorer = opts.explorer or {}
    opts.explorer.win = opts.explorer.win or {}
    opts.explorer.win.wo = opts.explorer.win.wo or {}
    opts.explorer.win.wo.relativenumber = true
    opts.explorer.hidden = true
    
    opts.picker = opts.picker or {}
    opts.picker.sources = opts.picker.sources or {}
    opts.picker.sources.files = opts.picker.sources.files or {}
    opts.picker.sources.files.hidden = true
    opts.picker.sources.grep = opts.picker.sources.grep or {}
    opts.picker.sources.grep.hidden = true
    
    return opts
  end,
}
