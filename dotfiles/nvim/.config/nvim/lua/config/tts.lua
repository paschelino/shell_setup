-- ============================================================================
-- TEXT-TO-SPEECH FOR NEOVIM (LazyVim)
-- ============================================================================
--
-- Reads text from the buffer aloud — selection, paragraph, or whole buffer.
-- Supports two backends:
--   - macOS `say` (built-in, Premium voices via Accessibility settings)
--   - Piper (local neural TTS, higher quality)
--
-- INSTALLATION
--   1. Optional Piper:  pipx install piper-tts
--   2. Voices: macOS Premium via System Settings → Accessibility
--              → Spoken Content → Manage Voices
--      Download Piper voices to ~/.local/share/piper/voices/
--   3. Load this file: require("config.tts") in keymaps.lua
--
-- KEYMAPS (prefix <leader>R for "Voice")
--   <leader>Rv    Speak selection (visual mode)
--   <leader>Rc    Speak current paragraph
--   <leader>Rb    Speak entire buffer
--   <leader>Rx    Stop playback
--   <leader>Re    Switch backend (say ↔ piper)
--   <leader>Rv    Switch voice
-- ============================================================================

local M = {}

local job_id = nil

-- Configuration -------------------------------------------------------------

local piper_voices_dir = vim.fn.expand("~/.local/share/piper/voices")

local backends = {
  say = {
    name = "macOS say",
    voices = { "Anna", "Markus", "Petra", "Anna (Premium)", "Markus (Premium)" },
    default_voice = "Anna",
    rate = "180", -- words per minute
  },
  piper = {
    name = "Piper",
    voices = {
      ["thorsten-high"] = piper_voices_dir .. "/de_DE-thorsten-high.onnx",
      -- add more as needed:
      -- ["thorsten-medium"] = piper_voices_dir .. "/de_DE-thorsten-medium.onnx",
      -- ["eva_k"]           = piper_voices_dir .. "/de_DE-eva_k-x_low.onnx",
    },
    default_voice = "thorsten-high",
  },
}

local state = {
  backend = "piper", -- "say" or "piper"
  voice = backends.piper.default_voice,
  tmp_wav = "/tmp/nvim_tts.wav",
}

-- Playback ------------------------------------------------------------------

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = "TTS" })
end

function M.stop()
  if job_id then
    vim.fn.jobstop(job_id)
    job_id = nil
  end
  vim.fn.system("pkill say 2>/dev/null; pkill afplay 2>/dev/null; pkill piper 2>/dev/null")
end

local function speak_with_say(text)
  job_id = vim.fn.jobstart({ "say", "-v", state.voice, "-r", backends.say.rate, text }, {
    on_exit = function()
      job_id = nil
    end,
  })
end

local function speak_with_piper(text)
  local model = backends.piper.voices[state.voice]
  if not model or vim.fn.filereadable(model) == 0 then
    notify("Piper voice not found: " .. (model or "?"), vim.log.levels.ERROR)
    return
  end

  -- Pipeline: echo → piper → afplay
  -- Render first, then play, so that Stop works cleanly
  local cmd = string.format(
    "%s --model %s --output_file %s 2>/dev/null && afplay %s",
    vim.fn.shellescape(vim.fn.expand("~/.local/bin/piper")),
    vim.fn.shellescape(model),
    vim.fn.shellescape(state.tmp_wav),
    vim.fn.shellescape(state.tmp_wav)
  )

  job_id = vim.fn.jobstart({ "sh", "-c", cmd }, {
    stdin = "pipe",
    on_exit = function()
      job_id = nil
    end,
  })
  vim.fn.chansend(job_id, text)
  vim.fn.chanclose(job_id, "stdin")
end

function M.speak(text)
  if not text or text == "" then
    notify("No text to speak", vim.log.levels.WARN)
    return
  end
  M.stop()
  notify("🔊 " .. backends[state.backend].name .. " (" .. state.voice .. ")")
  if state.backend == "say" then
    speak_with_say(text)
  else
    speak_with_piper(text)
  end
end

-- Text sources -------------------------------------------------------------

function M.speak_selection()
  local s_start = vim.fn.getpos("'<")
  local s_end = vim.fn.getpos("'>")
  local lines = vim.fn.getline(s_start[2], s_end[2])
  if #lines == 0 then
    return
  end
  lines[#lines] = string.sub(lines[#lines], 1, s_end[3])
  lines[1] = string.sub(lines[1], s_start[3])
  M.speak(table.concat(lines, "\n"))
end

function M.speak_paragraph()
  local cur = vim.api.nvim_win_get_cursor(0)[1]
  local total = vim.api.nvim_buf_line_count(0)
  local start_l, end_l = cur, cur
  while start_l > 1 and vim.fn.getline(start_l - 1) ~= "" do
    start_l = start_l - 1
  end
  while end_l < total and vim.fn.getline(end_l + 1) ~= "" do
    end_l = end_l + 1
  end
  M.speak(table.concat(vim.fn.getline(start_l, end_l), "\n"))
end

function M.speak_buffer()
  M.speak(table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n"))
end

-- Switch backend / voice ---------------------------------------------------

function M.pick_backend()
  vim.ui.select({ "say", "piper" }, {
    prompt = "TTS backend:",
    format_item = function(item)
      return backends[item].name .. (item == state.backend and "  ← active" or "")
    end,
  }, function(choice)
    if choice then
      state.backend = choice
      state.voice = backends[choice].default_voice
      notify("Backend: " .. backends[choice].name)
    end
  end)
end

function M.pick_voice()
  local b = backends[state.backend]
  local choices
  if state.backend == "say" then
    choices = b.voices
  else
    choices = vim.tbl_keys(b.voices)
    table.sort(choices)
  end
  vim.ui.select(choices, {
    prompt = "Voice (" .. b.name .. "):",
    format_item = function(item)
      return item .. (item == state.voice and "  ← active" or "")
    end,
  }, function(choice)
    if choice then
      state.voice = choice
      notify("Voice: " .. choice)
    end
  end)
end

-- Cleanup on exit ----------------------------------------------------------

vim.api.nvim_create_autocmd("VimLeavePre", {
  group = vim.api.nvim_create_augroup("tts_cleanup", { clear = true }),
  callback = function()
    M.stop()
    vim.fn.delete(state.tmp_wav)
  end,
})

-- Keymaps ------------------------------------------------------------------

vim.keymap.set("v", "<leader>Rv", M.speak_selection, { desc = "TTS: speak selection" })
vim.keymap.set("n", "<leader>Rn", M.speak_paragraph, { desc = "TTS: speak paragraph" })
vim.keymap.set("n", "<leader>RN", M.speak_buffer, { desc = "TTS: speak whole buffer" })
vim.keymap.set("n", "<leader>Rx", M.stop, { desc = "TTS: stop" })
vim.keymap.set("n", "<leader>RA", M.pick_backend, { desc = "TTS: switch backend" })
vim.keymap.set("n", "<leader>RL", M.pick_voice, { desc = "TTS: switch voice" })

return M
