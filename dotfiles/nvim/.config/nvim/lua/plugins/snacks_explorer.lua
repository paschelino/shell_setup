return {
  "folke/snacks.nvim",
  opts = {
    picker = {
      sources = {
        explorer = { win = { list = { wo = { relativenumber = true } } }, hidden = true, ignored = true },
        files = { hidden = true },
        grep = { hidden = true },
      },
    },
  },
}
