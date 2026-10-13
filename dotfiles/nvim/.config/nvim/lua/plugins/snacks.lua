return {
  "folke/snacks.nvim",
  opts = {
    image = {
      enabled = true,
      -- LaTeX is rendered by render-markdown (see render-markdown.lua).
      -- Rendering it here as well would draw every formula twice.
      math = {
        enabled = false,
      },
    },
  },
}
