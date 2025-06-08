return {
  "folke/snacks.nvim",
  opts = {
    picker = {
      sources = {
        explorer = { win = { list = { wo = { relativenumber = true } } }, hidden = true },
        files = { hidden = true },
        grep = { hidden = true },
      },
    },
  },
}
