vim.opt_local.textwidth = 80
vim.opt_local.colorcolumn = "80"

-- Folding -----------------------------------------------------------------

-- Cache frontmatter ranges in a plain Lua table keyed by bufnr.
-- vim.b cannot store tables or booleans, so we use a module-level cache.
if not _G._md_fm_cache then _G._md_fm_cache = {} end

local function frontmatter_range(bufnr)
  if _G._md_fm_cache[bufnr] ~= nil then return _G._md_fm_cache[bufnr] end
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local range = false  -- false = "file has no frontmatter"
  if lines[1] == "---" then
    for i = 2, #lines do
      if lines[i] == "---" or lines[i] == "..." then
        range = { 1, i }  -- 1-indexed start and end, both inclusive
        break
      end
    end
  end
  _G._md_fm_cache[bufnr] = range
  -- Invalidate cache when the buffer is wiped.
  vim.api.nvim_buf_attach(bufnr, false, {
    on_detach = function() _G._md_fm_cache[bufnr] = nil end,
  })
  return range
end

-- Custom foldexpr: level 1 fold for frontmatter, treesitter for everything else.
function MarkdownFoldExpr()
  local lnum = vim.v.lnum
  local bufnr = vim.api.nvim_get_current_buf()
  local fm = frontmatter_range(bufnr)
  if fm then
    if lnum == fm[1] then return ">1" end  -- start fold at opening "---"
    if lnum == fm[2] then return "<1" end  -- end fold at closing "---"
    if lnum > fm[1] and lnum < fm[2] then return "1" end
  end
  return vim.treesitter.foldexpr()
end

-- Custom foldtext: show [frontmatter: title] for the frontmatter fold.
function MarkdownFoldText()
  local bufnr = vim.api.nvim_get_current_buf()
  local fm = frontmatter_range(bufnr)
  if fm and vim.v.foldstart == fm[1] then
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, fm[2], false)
    local title = nil
    for _, line in ipairs(lines) do
      local t = line:match("^title:%s*['\"]?(.-)['\"?]?%s*$")
      if t and t ~= "" then title = t break end
    end
    local label = title and ("[frontmatter: " .. title .. "]") or "[frontmatter]"
    return label .. "  ··  " .. (fm[2] - fm[1] + 1) .. " lines"
  end
  return vim.fn.foldtext()
end

local function apply_fold_settings()
  local bufnr = vim.api.nvim_get_current_buf()
  if vim.bo[bufnr].filetype ~= "markdown" then return end
  vim.opt_local.foldmethod = "expr"
  vim.opt_local.foldexpr = "v:lua.MarkdownFoldExpr()"
  vim.opt_local.foldtext = "v:lua.MarkdownFoldText()"
  -- Only close foldlevel 1 (frontmatter) if the file actually has frontmatter.
  -- Otherwise keep everything open so headings don't start collapsed.
  local fm = frontmatter_range(bufnr)
  vim.opt_local.foldlevel = fm and 1 or 99
end

-- Apply immediately (for FileType event) and again after BufWinEnter
-- so that LazyVim's treesitter/LSP autocmds cannot overwrite our values.
-- On BufWinEnter we also explicitly close the frontmatter fold, because
-- setting foldlevel alone does not close folds that are already open.
apply_fold_settings()
local _bufnr = vim.api.nvim_get_current_buf()
vim.api.nvim_create_autocmd("BufWinEnter", {
  buffer = _bufnr,
  once = true,
  callback = function()
    apply_fold_settings()
    local fm = frontmatter_range(_bufnr)
    if not fm then return end
    local win = vim.fn.bufwinid(_bufnr)
    if win == -1 then return end
    local cursor = vim.api.nvim_win_get_cursor(win)
    vim.api.nvim_win_set_cursor(win, { fm[1], 0 })
    vim.cmd("silent! normal! zc")
    vim.api.nvim_win_set_cursor(win, cursor)
  end,
})

-- Add the key mappings only for Markdown files in a zk notebook.
if require("zk.util").notebook_root(vim.fn.expand("%:p")) ~= nil then
  local function map(...)
    vim.api.nvim_buf_set_keymap(0, ...)
  end
  local opts = { noremap = true, silent = false }

  -- Open the link under the caret.
  map("n", "<CR>", "<Cmd>lua vim.lsp.buf.definition()<CR>", opts)

  -- Create a new note after asking for its title.
  -- This overrides the global `<leader>zn` mapping to create the note in the same directory as the current buffer.
  map("n", "<leader>zn", "<Cmd>ZkNew { dir = vim.fn.expand('%:p:h'), title = vim.fn.input('Title: ') }<CR>", opts)
  -- Create a new note in the same directory as the current buffer, using the current selection for title.
  map("v", "<leader>znt", ":'<,'>ZkNewFromTitleSelection { dir = vim.fn.expand('%:p:h') }<CR>", opts)
  -- Create a new note in the same directory as the current buffer, using the current selection for note content and asking for its title.
  map(
    "v",
    "<leader>znc",
    ":'<,'>ZkNewFromContentSelection { dir = vim.fn.expand('%:p:h'), title = vim.fn.input('Title: ') }<CR>",
    opts
  )

  -- Open notes linking to the current buffer.
  map("n", "<leader>zb", "<Cmd>ZkBacklinks<CR>", opts)
  -- Alternative for backlinks using pure LSP and showing the source context.
  --map('n', '<leader>zb', '<Cmd>lua vim.lsp.buf.references()<CR>', opts)
  -- Open notes linked by the current buffer.
  map("n", "<leader>zl", "<Cmd>ZkLinks<CR>", opts)

  -- Preview a linked note.
  map("n", "K", "<Cmd>lua vim.lsp.buf.hover()<CR>", opts)
  -- Open the code actions for a visual selection.
  map("v", "<leader>za", ":'<,'>lua vim.lsp.buf.range_code_action()<CR>", opts)
end
