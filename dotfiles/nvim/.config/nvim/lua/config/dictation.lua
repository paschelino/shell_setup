local M = {}

local models_dir = vim.fn.expand("~/.local/share/whisper/models")
local available_models = {
  ["large-v3"] = models_dir .. "/ggml-large-v3.bin",
  ["large-v3-turbo"] = models_dir .. "/ggml-large-v3-turbo.bin",
}

local state = {
  recording = false,
  rec_file = "/tmp/nvim_dictation.wav",
  current_model = "large-v3-turbo", -- default
  language = "de",
}

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = "Dictation" })
end

function M.toggle()
  if not state.recording then
    -- Verify model file exists before starting
    local model_path = available_models[state.current_model]
    if vim.fn.filereadable(model_path) == 0 then
      notify("Model not found: " .. model_path, vim.log.levels.ERROR)
      return
    end

    vim.fn.jobstart({ "sox", "-d", "-r", "16000", "-c", "1", state.rec_file }, { detach = true })
    state.recording = true
    notify("🎙  Recording (" .. state.current_model .. ", " .. state.language .. ")")
  else
    vim.fn.system("pkill -INT sox")
    state.recording = false
    notify("Transcribing with " .. state.current_model .. "...")

    local model_path = available_models[state.current_model]
    vim.fn.jobstart({
      "whisper-cli",
      "-m",
      model_path,
      "-l",
      state.language,
      "-f",
      state.rec_file,
      "--no-timestamps",
      "-otxt",
      "-of",
      state.rec_file,
    }, {
      on_exit = function(_, code)
        if code ~= 0 then
          vim.schedule(function()
            notify("Transcription failed (exit " .. code .. ")", vim.log.levels.ERROR)
          end)
          return
        end
        local out = state.rec_file .. ".txt"
        if vim.fn.filereadable(out) == 1 then
          local text = vim.fn.readfile(out)
          while #text > 0 and text[1] == "" do
            table.remove(text, 1)
          end
          while #text > 0 and text[#text] == "" do
            table.remove(text)
          end
          vim.schedule(function()
            vim.api.nvim_put(text, "c", true, true)
            notify("✓ Inserted (" .. #text .. " line" .. (#text == 1 and "" or "s") .. ")")
          end)
        end
      end,
    })
  end
end

function M.pick_model()
  local choices = vim.tbl_keys(available_models)
  table.sort(choices)
  vim.ui.select(choices, {
    prompt = "Whisper model:",
    format_item = function(item)
      return item .. (item == state.current_model and "  ← current" or "")
    end,
  }, function(choice)
    if choice then
      state.current_model = choice
      notify("Model: " .. choice)
    end
  end)
end

function M.pick_language()
  vim.ui.select({ "de", "en", "auto" }, {
    prompt = "Language:",
    format_item = function(item)
      return item .. (item == state.language and "  ← current" or "")
    end,
  }, function(choice)
    if choice then
      state.language = choice
      notify("Language: " .. choice)
    end
  end)
end

function M.status()
  notify(
    string.format(
      "Model: %s | Language: %s | %s",
      state.current_model,
      state.language,
      state.recording and "🎙 RECORDING" or "idle"
    )
  )
end

-- Keymaps under <leader>R (Record) prefix
vim.keymap.set({ "n", "i" }, "<leader>Rr", function()
  if vim.fn.mode() == "i" then
    vim.cmd("stopinsert")
  end
  M.toggle()
end, { desc = "Dictation: toggle recording" })

vim.keymap.set("n", "<leader>Rm", M.pick_model, { desc = "Dictation: pick model" })
vim.keymap.set("n", "<leader>Rl", M.pick_language, { desc = "Dictation: pick language" })
vim.keymap.set("n", "<leader>Rs", M.status, { desc = "Dictation: show status" })

return M
