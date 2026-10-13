-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")
local zk = require("util.zk")

vim.api.nvim_create_autocmd("BufReadPost", {
  group = vim.api.nvim_create_augroup("zk_spellfile", { clear = true }),
  pattern = "*.md",
  callback = function(args)
    local root = zk.notebook_root(args.buf)
    if root then
      local spell_dir = root .. "/spell"
      -- Ensure the directory exists so zg / :spellgood doesn't throw E484
      vim.fn.mkdir(spell_dir, "p")
      local global_spell = vim.fn.stdpath("config") .. "/spell/custom.utf-8.add"
      vim.opt_local.spellfile = spell_dir .. "/custom.utf-8.add," .. global_spell
    end
  end,
})

vim.api.nvim_create_autocmd("BufReadPost", {
  group = vim.api.nvim_create_augroup("journal_nospell", { clear = true }),
  pattern = "*.md",
  callback = function(args)
    if zk.is_journal(args.buf) then
      vim.opt_local.spell = false
      vim.diagnostic.enable(false, { bufnr = args.buf })
      vim.fn.system({ "tmux", "set", "status", "off" })
      vim.schedule(function()
        vim.cmd("$")
        vim.cmd("startinsert")
        require("lualine").hide({})
      end)
    end
  end,
})

vim.api.nvim_create_autocmd("BufLeave", {
  group = vim.api.nvim_create_augroup("journal_restore", { clear = true }),
  pattern = "*.md",
  callback = function(args)
    if zk.is_journal(args.buf) then
      vim.fn.system({ "tmux", "set", "status", "on" })
      require("lualine").hide({ unhide = true })
    end
  end,
})
