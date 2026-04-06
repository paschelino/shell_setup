-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")
vim.api.nvim_create_autocmd("BufReadPost", {
  group = vim.api.nvim_create_augroup("zk_spellfile", { clear = true }),
  pattern = "*.md",
  callback = function(args)
    local zk_dir = vim.fs.find(".zk", {
      upward = true,
      path = vim.fn.fnamemodify(args.file, ":h"),
    })[1]
    if zk_dir then
      local spell_dir = vim.fn.fnamemodify(zk_dir, ":h") .. "/spell"
      -- Ensure the directory exists so zg / :spellgood doesn't throw E484
      vim.fn.mkdir(spell_dir, "p")
      local global_spell = vim.fn.stdpath("config") .. "/spell/custom.utf-8.add"
      vim.opt_local.spellfile = spell_dir .. "/custom.utf-8.add," .. global_spell
    end
  end,
})
