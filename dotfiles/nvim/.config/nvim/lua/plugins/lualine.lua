-- Source: https://nickjanetakis.com/blog/modify-lualine-in-neovim-to-show-word-count-and-reading-time
-- wordcount() scans the whole buffer and lualine redraws on every cursor move,
-- so the buffer's word count is cached until the buffer changes.
local function get_wordcount()
  if vim.fn.mode():find("[vV\22]") then
    return vim.fn.wordcount().visual_words or 0
  end

  local cache = vim.b.wordcount_cache
  if not cache or cache.tick ~= vim.b.changedtick then
    cache = { tick = vim.b.changedtick, words = vim.fn.wordcount().words }
    vim.b.wordcount_cache = cache
  end

  return cache.words
end

local function wordcount()
  local label = "word"
  local word_count = get_wordcount()

  if word_count > 1 then
    label = label .. "s"
  end

  return word_count .. " " .. label
end

local function readingtime()
  -- 200 is about the average words read per minute.
  return tostring(math.ceil(get_wordcount() / 200.0)) .. " min"
end

local function is_prose()
  return vim.bo.filetype == "markdown" or vim.bo.filetype == "text"
end

return {
  {
    "nvim-lualine/lualine.nvim",
    opts = {
      sections = {
        -- Disable the default clock and replace it with word stats.
        lualine_z = {
          { wordcount, cond = is_prose },
          { readingtime, cond = is_prose },
        },
      },
    },
  },
}
