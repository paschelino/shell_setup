-- Leave insert mode with jj or jk without delaying typed j/k characters.
-- Unlike a regular `imap jj <Esc>`, better-escape inserts the first key
-- immediately and only removes it again if the second key follows in time.
return {
  "max397574/better-escape.nvim",
  event = "InsertEnter",
  opts = {
    default_mappings = false,
    mappings = {
      i = {
        j = {
          j = "<Esc>",
          k = "<Esc>",
        },
      },
    },
  },
}
