-- The markdown highlight query uses `conceal_lines` to hide code fence lines.
-- That makes Neovim's highlighter re-parse every visible line on every redraw,
-- which costs time proportional to the file size: ~70 ms of input lag per
-- keystroke in a 4500-line note. render-markdown already hides fence lines
-- itself (code.border = "hide"), so the query directive is dropped here.
local function drop_markdown_conceal_lines()
  local src = {}
  for _, file in ipairs(vim.treesitter.query.get_files("markdown", "highlights")) do
    table.insert(src, table.concat(vim.fn.readfile(file), "\n"))
  end
  local query = table.concat(src, "\n"):gsub('%(#set!%s+conceal_lines%s+""%s*%)', "")
  vim.treesitter.query.set("markdown", "highlights", query)
end

return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      drop_markdown_conceal_lines()
      vim.list_extend(opts.ensure_installed, {
        "latex",
        "html",
      })
    end,
  },
}
