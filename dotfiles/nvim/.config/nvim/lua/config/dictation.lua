-- ============================================================================
-- DICTATION FOR NEOVIM (LazyVim) — Speech-to-text via whisper.cpp
-- ============================================================================
--
-- A simple, integrated dictation workflow: hit a keymap, speak, hit it again,
-- and the transcribed text is inserted at the cursor. Runs entirely locally,
-- no cloud APIs. Tuned for German + English writing on macOS.
--
-- ----------------------------------------------------------------------------
-- INSTALLATION
-- ----------------------------------------------------------------------------
--
-- 1. Install the CLI tools via Homebrew:
--
--      brew install sox whisper-cpp
--
--    - sox          : records audio from the microphone
--    - whisper-cpp  : runs Whisper transcription locally
--                     (binary is installed as `whisper-cli`)
--
-- 2. Create the models directory and download the Whisper models:
--
--      mkdir -p ~/.local/share/whisper/models
--      cd ~/.local/share/whisper/models
--      bash "$(brew --prefix whisper-cpp)/share/whisper-cpp/download-ggml-model.sh" large-v3 .
--      bash "$(brew --prefix whisper-cpp)/share/whisper-cpp/download-ggml-model.sh" large-v3-turbo .
--
--    Result:
--      ~/.local/share/whisper/models/ggml-large-v3.bin        (~3.1 GB, best quality)
--      ~/.local/share/whisper/models/ggml-large-v3-turbo.bin  (~1.6 GB, ~4× faster, near-large quality)
--
--    Other sizes (tiny/base/small/medium) work too — just adjust the
--    `available_models` table below to match the filenames you downloaded.
--
-- 3. Smoke-test the toolchain from the command line BEFORE wiring up Neovim:
--
--      sox -d -r 16000 -c 1 /tmp/test.wav trim 0 5    # record 5s
--      whisper-cli -m ~/.local/share/whisper/models/ggml-large-v3-turbo.bin \
--                  -l de -f /tmp/test.wav
--
--    macOS will prompt for microphone permission for your terminal emulator
--    on first run. Grant it via System Settings → Privacy & Security → Microphone.
--    If you switch terminals later (e.g. iTerm2 → Ghostty), grant again.
--
-- 4. Save this file as:  ~/.config/nvim/lua/config/dictation.lua
--
-- 5. Load it once at startup. Add the following line to either
--    ~/.config/nvim/lua/config/init.lua  or  ~/.config/nvim/lua/config/keymaps.lua :
--
--      require("config.dictation")
--
-- 6. (Optional) Register the <leader>R prefix with which-key so the menu
--    shows a "dictation" label. Add to ~/.config/nvim/lua/plugins/which-key.lua :
--
--      return {
--        "folke/which-key.nvim",
--        opts = {
--          spec = { { "<leader>R", group = "dictation" } },
--        },
--      }
--
-- ----------------------------------------------------------------------------
-- USAGE
-- ----------------------------------------------------------------------------
--
--   <leader>Rr    Toggle recording (start / stop+transcribe+insert)
--   <leader>Rm    Pick Whisper model (large-v3 / large-v3-turbo)
--   <leader>Rl    Pick language (de / en / auto)
--   <leader>Rs    Show current status (model, language, recording state)
--
-- Default model:    large-v3-turbo  (fast, near-large quality)
-- Default language: de
--
-- Workflow:
--   1. Place cursor where text should appear (normal or insert mode both work).
--   2. <leader>Rr  → "🎙 Recording..." notification appears.
--   3. Speak. Punctuation is auto-inferred by Whisper — no need to say "Punkt".
--   4. <leader>Rr  → recording stops, transcription runs, text is inserted.
--
-- ----------------------------------------------------------------------------
-- TROUBLESHOOTING
-- ----------------------------------------------------------------------------
--
-- - "Model not found" error
--     → Check that filenames in `available_models` match what's actually in
--       ~/.local/share/whisper/models/  (use `ls` to verify).
--
-- - Silent / empty transcription
--     → macOS mic permission likely not granted to the terminal emulator.
--       Test with: sox -d -r 16000 -c 1 /tmp/test.wav trim 0 3 && afplay /tmp/test.wav
--
-- - "whisper-cli: command not found"
--     → Older whisper-cpp versions used `main` or `whisper-cpp` as the binary
--       name. Check with: ls "$(brew --prefix whisper-cpp)/bin/"
--       Then update the `whisper-cli` string in the M.toggle() function below.
--
-- - Recording won't stop
--     → `pkill -INT sox` is used to stop. If multiple sox processes are running
--       (e.g. from another app), this may interfere. Check with: pgrep -lf sox
--
-- - Conflicting keymap
--     → <leader>R is unused by LazyVim defaults at the time of writing. If a
--       future LazyVim update claims it, change the prefix in the keymap
--       section at the bottom of this file.
--
-- ----------------------------------------------------------------------------
-- DEPENDENCIES SUMMARY
-- ----------------------------------------------------------------------------
--
--   System  : macOS (tested), should also work on Linux with `arecord` swap
--   CLI     : sox, whisper-cli (from whisper-cpp Homebrew package)
--   Models  : ggml-large-v3.bin, ggml-large-v3-turbo.bin in
--             ~/.local/share/whisper/models/
--   Neovim  : 0.10+ (uses vim.ui.select, vim.notify, vim.fn.jobstart)
--   Plugins : none required; which-key integration optional
--
-- ============================================================================

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
