-- ftplugin/markdown.lua
-- Buffer-local settings applied to every Markdown file.
-- This file is sourced automatically by Neovim on the FileType event.

-- Enforce an 80-character line width and show the column ruler.
-- textwidth drives `gq` reflowing and auto-wrap (when fo+=t).
-- colorcolumn draws the visual guide at that column.
vim.opt_local.textwidth = 80
vim.opt_local.colorcolumn = "80"

-- Folding -----------------------------------------------------------------
--
-- Goal: fold the YAML frontmatter block (--- ... ---) automatically when a
-- Markdown file is opened, showing the note title in the fold label.
-- All other content (headings, code blocks, etc.) starts fully open.
--
-- Implementation overview:
--   1. frontmatter_range() scans the buffer once to locate the --- block and
--      caches the result in a global Lua table keyed by bufnr (vim.b cannot
--      store Lua tables or booleans, so we cannot use it here).
--   2. MarkdownFoldExpr() is the custom foldexpr. Neovim calls it for every
--      line whenever it needs to recompute folds. It returns fold-level
--      markers for the frontmatter lines and delegates everything else to
--      vim.treesitter.foldexpr(), which handles headings, code blocks, etc.
--   3. MarkdownFoldText() is the custom foldtext. It renders the closed
--      frontmatter fold as "[frontmatter: <title>]  ··  N lines". For all
--      other folds it falls back to Neovim's built-in foldtext().
--   4. apply_fold_settings() wires the options together and sets foldlevel:
--      - foldlevel=1  when frontmatter is present  → frontmatter fold closed,
--                                                     everything deeper open.
--      - foldlevel=99 when no frontmatter exists   → nothing starts closed.
--   5. We call apply_fold_settings() immediately (at FileType time) AND on
--      BufWinEnter, because LazyVim's treesitter and LSP autocmds run after
--      FileType and would otherwise overwrite our foldmethod/foldexpr.
--      On BufWinEnter we also issue a `zc` on line 1 to actually close the
--      fold visually — setting foldlevel alone does not close folds that are
--      already rendered open in the current window.

-- Global cache: maps bufnr → { start_lnum, end_lnum } (1-indexed, inclusive)
-- or false when the buffer has no frontmatter. Initialised once per session.
if not _G._md_fm_cache then _G._md_fm_cache = {} end

-- Returns the frontmatter line range for `bufnr`, or false if none exists.
-- Result is cached on first call and invalidated when the buffer is wiped.
local function frontmatter_range(bufnr)
  -- Return cached value if available (nil means "not yet computed").
  if _G._md_fm_cache[bufnr] ~= nil then return _G._md_fm_cache[bufnr] end

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local range = false  -- sentinel: no frontmatter found

  -- YAML frontmatter must start on the very first line with "---".
  if lines[1] == "---" then
    -- Scan forward for the closing delimiter ("---" or YAML's "...").
    for i = 2, #lines do
      if lines[i] == "---" or lines[i] == "..." then
        range = { 1, i }  -- both line numbers are 1-indexed and inclusive
        break
      end
    end
  end

  -- Store in cache and register a cleanup callback for when the buffer is
  -- unloaded so we don't leak memory across a long editing session.
  _G._md_fm_cache[bufnr] = range
  vim.api.nvim_buf_attach(bufnr, false, {
    on_detach = function() _G._md_fm_cache[bufnr] = nil end,
  })

  return range
end

-- foldexpr function — called by Neovim for every line to determine its fold
-- level. Must be a global so that `v:lua.MarkdownFoldExpr()` can reference it.
--
-- Return values follow Neovim's foldexpr contract:
--   ">1"  — this line starts a fold of level 1
--   "1"   — this line is inside a level-1 fold
--   "<1"  — this line ends a level-1 fold
--   (anything else is delegated to treesitter)
function MarkdownFoldExpr()
  local lnum = vim.v.lnum
  local bufnr = vim.api.nvim_get_current_buf()
  local fm = frontmatter_range(bufnr)

  if fm then
    if lnum == fm[1] then return ">1" end  -- opening "---" starts the fold
    if lnum == fm[2] then return "<1" end  -- closing "---" ends the fold
    if lnum > fm[1] and lnum < fm[2] then return "1" end  -- body is inside
  end

  -- Delegate all non-frontmatter lines to the treesitter foldexpr, which
  -- knows about Markdown sections, fenced code blocks, list nesting, etc.
  return vim.treesitter.foldexpr()
end

-- foldtext function — called by Neovim to render the label of a closed fold.
-- Must be a global so that `v:lua.MarkdownFoldText()` can reference it.
function MarkdownFoldText()
  local bufnr = vim.api.nvim_get_current_buf()
  local fm = frontmatter_range(bufnr)

  -- Only customise the label for the frontmatter fold.
  if fm and vim.v.foldstart == fm[1] then
    -- Scan the frontmatter lines for a `title:` field.
    -- Handles bare values as well as single- and double-quoted strings.
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, fm[2], false)
    local title = nil
    for _, line in ipairs(lines) do
      local t = line:match("^title:%s*['\"]?(.-)['\"?]?%s*$")
      if t and t ~= "" then
        title = t
        break
      end
    end

    local label = title and ("[frontmatter: " .. title .. "]") or "[frontmatter]"
    local line_count = fm[2] - fm[1] + 1
    return label .. "  ··  " .. line_count .. " lines"
  end

  -- For all other folds (headings, code blocks, …) use Neovim's default.
  return vim.fn.foldtext()
end

-- Sets foldmethod, foldexpr, foldtext, and foldlevel for the current buffer.
-- Called twice: once immediately and once on BufWinEnter (see below).
local function apply_fold_settings()
  local bufnr = vim.api.nvim_get_current_buf()
  if vim.bo[bufnr].filetype ~= "markdown" then return end

  vim.opt_local.foldmethod = "expr"
  vim.opt_local.foldexpr   = "v:lua.MarkdownFoldExpr()"
  vim.opt_local.foldtext   = "v:lua.MarkdownFoldText()"

  -- foldlevel controls which folds start closed:
  --   1  → level-1 folds (frontmatter) closed, everything deeper open
  --   99 → nothing closed (no frontmatter to hide)
  local fm = frontmatter_range(bufnr)
  vim.opt_local.foldlevel = fm and 1 or 99
end

-- First application at FileType time — establishes our settings early so
-- LazyVim's set_default() (called later in BufReadPost) sees a non-default
-- local value and skips overwriting foldmethod/foldexpr.
apply_fold_settings()

-- Capture bufnr now; the closure below must reference a stable value since
-- the autocmd fires asynchronously after the current file finishes loading.
local _bufnr = vim.api.nvim_get_current_buf()

-- Second application on BufWinEnter — runs after LazyVim's treesitter and
-- LSP autocmds to guarantee our settings are not overwritten. We also issue
-- a `zc` here to physically close the frontmatter fold, because changing
-- foldlevel after a window is already displayed does not retroactively close
-- folds that Neovim has already rendered open.
vim.api.nvim_create_autocmd("BufWinEnter", {
  buffer = _bufnr,
  once = true,  -- only needed once per buffer lifetime
  callback = function()
    apply_fold_settings()

    local fm = frontmatter_range(_bufnr)
    if not fm then return end  -- no frontmatter, nothing to close

    local win = vim.fn.bufwinid(_bufnr)
    if win == -1 then return end  -- buffer not visible in any window

    -- Save the cursor position, jump to the frontmatter opening line,
    -- close the fold with zc, then restore the cursor.
    local cursor = vim.api.nvim_win_get_cursor(win)
    vim.api.nvim_win_set_cursor(win, { fm[1], 0 })
    vim.cmd("silent! normal! zc")  -- silent! avoids "no fold" errors
    vim.api.nvim_win_set_cursor(win, cursor)
  end,
})

-- Zettelkasten keymaps (zk-nvim) ------------------------------------------
--
-- These buffer-local mappings are only registered when the current file lives
-- inside a zk notebook (identified by an ancestor .zk directory).

if require("zk.util").notebook_root(vim.fn.expand("%:p")) ~= nil then
  local function map(...)
    vim.api.nvim_buf_set_keymap(0, ...)
  end
  local opts = { noremap = true, silent = false }

  -- Follow the wiki-link under the cursor (delegates to the zk LSP server).
  map("n", "<CR>", "<Cmd>lua vim.lsp.buf.definition()<CR>", opts)

  -- Create a new note in the same directory as the current buffer.
  -- Overrides the global <leader>zn mapping defined in lua/config/keymaps.lua.
  map("n", "<leader>zn", "<Cmd>ZkNew { dir = vim.fn.expand('%:p:h'), title = vim.fn.input('Title: ') }<CR>", opts)

  -- Create a new note using the current visual selection as the title.
  map("v", "<leader>znt", ":'<,'>ZkNewFromTitleSelection { dir = vim.fn.expand('%:p:h') }<CR>", opts)

  -- Create a new note using the current visual selection as the body,
  -- prompting separately for a title.
  map(
    "v",
    "<leader>znc",
    ":'<,'>ZkNewFromContentSelection { dir = vim.fn.expand('%:p:h'), title = vim.fn.input('Title: ') }<CR>",
    opts
  )

  -- Open a picker of all notes that link to the current buffer (backlinks).
  map("n", "<leader>zb", "<Cmd>ZkBacklinks<CR>", opts)

  -- Open a picker of all notes linked from the current buffer (outgoing links).
  map("n", "<leader>zl", "<Cmd>ZkLinks<CR>", opts)

  -- Show a hover preview of the note under the cursor via the LSP server.
  map("n", "K", "<Cmd>lua vim.lsp.buf.hover()<CR>", opts)

  -- Run LSP code actions on the current visual selection (e.g. extract to note).
  map("v", "<leader>za", ":'<,'>lua vim.lsp.buf.range_code_action()<CR>", opts)
end
