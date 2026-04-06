-- Override conform.nvim's markdown formatter to preserve YAML frontmatter.
--
-- When a markdown file starts with a `---` block (YAML frontmatter, as used
-- by zk and many static-site generators), this formatter:
--   1. Splits the buffer into frontmatter lines and body lines.
--   2. Runs prettierd only on the body.
--   3. Re-prepends the original frontmatter verbatim.
--
-- Files without frontmatter are passed directly to prettierd unchanged.
return {
  "stevearc/conform.nvim",
  opts = function(_, opts)
    opts.formatters_by_ft = opts.formatters_by_ft or {}
    opts.formatters_by_ft.markdown = { "markdown_prettier" }

    opts.formatters = opts.formatters or {}
    opts.formatters.markdown_prettier = {
      ---@param self conform.FormatterConfig
      ---@param ctx conform.Context
      ---@param lines string[]
      ---@param callback fun(err: string|nil, new_lines: string[]|nil)
      format = function(self, ctx, lines, callback)
        -- Detect YAML frontmatter: file must start with "---" on line 1,
        -- followed by a closing "---" somewhere further down.
        local front_end = nil
        if lines[1] == "---" then
          for i = 2, #lines do
            if lines[i] == "---" then
              front_end = i
              break
            end
          end
        end

        -- No frontmatter — run prettierd on the whole buffer as normal.
        if not front_end then
          require("conform").format_lines({ "prettierd" }, lines, { bufnr = ctx.buf, async = true }, callback)
          return
        end

        -- Split: keep frontmatter verbatim, format only the body.
        local frontmatter = vim.list_slice(lines, 1, front_end)
        local body = vim.list_slice(lines, front_end + 1, #lines)

        -- If the body is empty (nothing after frontmatter), nothing to format.
        if #body == 0 then
          callback(nil, lines)
          return
        end

        require("conform").format_lines(
          { "prettierd" },
          body,
          { bufnr = ctx.buf, async = true },
          function(err, new_body)
            if err then
              callback(err, nil)
              return
            end
            -- Reassemble: original frontmatter + formatted body.
            local result = vim.list_extend(vim.list_slice(frontmatter, 1, #frontmatter), new_body)
            callback(nil, result)
          end
        )
      end,
    }

    return opts
  end,
}
