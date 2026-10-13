-- Classify buffers by their location in a zk notebook (a directory that
-- contains a .zk folder). Journal notes live in <notebook>/0-journals/,
-- matching the `journal` group in the notebook's .zk/config.toml.
local M = {}

-- Notebook root per directory; false when the directory is in no notebook.
local roots = {}

---@param buf? integer
---@return string? root directory of the notebook containing the buffer's file
function M.notebook_root(buf)
  local path = vim.api.nvim_buf_get_name(buf or 0)
  if path == "" then
    return nil
  end
  local dir = vim.fs.dirname(path)
  if roots[dir] == nil then
    local zk_dir = vim.fs.find(".zk", { upward = true, path = dir, type = "directory" })[1]
    roots[dir] = zk_dir and vim.fs.dirname(zk_dir) or false
  end
  return roots[dir] or nil
end

---@param buf? integer
---@return boolean
function M.is_journal(buf)
  local root = M.notebook_root(buf)
  return root ~= nil and vim.api.nvim_buf_get_name(buf or 0):find(root .. "/0-journals/", 1, true) ~= nil
end

return M
