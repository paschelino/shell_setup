return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    opts = {
      latex = {
        enabled = true,
        render_modes = false,
        converter = { "utftex", "latex2text" },
        highlight = "RenderMarkdownMath",
        position = "center",
        top_pad = 0,
        bottom_pad = 0,
      },
      html = {
        tag = {
          u = { scope_highlight = "@markup.underline" },
          ins = { scope_highlight = "@markup.underline" },
          mark = { scope_highlight = "RenderMarkdownInlineHighlight" },
          abbr = { scope_highlight = "@markup.link.label" },
          kbd = {
            icon = "󰌌 ",
            highlight = "RenderMarkdownCodeInline",
            scope_highlight = "RenderMarkdownCodeInline",
          },
          small = { scope_highlight = "Comment" },
        },
      },
    },
  },
}
