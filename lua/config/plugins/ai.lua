-- AI agents: Claude + MiniMax
--   codecompanion.nvim : in-editor chat / inline edits / agent tools
--   toggleterm         : Claude Code CLI (official) and Claude Code on MiniMax
--
-- Keys (<leader>a…):
--   aa  toggle chat (Claude)          an  new chat (MiniMax)
--   ap  action palette                ai  inline edit (n/v)
--   ad  add selection to chat (v)
--   ac  Claude Code terminal          am  Claude Code on MiniMax terminal
--   (inside a terminal: <Esc><Esc> to normal mode, then the same key hides it)
-- In the chat buffer press `ga` to switch adapter/model.
--
-- Auth:
--   Claude  -> export ANTHROPIC_API_KEY=sk-ant-...   (e.g. in ~/.bashrc)
--   MiniMax -> $MINIMAX_API_KEY, else read from ~/.mmx/config.json (mmx CLI)

local is_win = vim.fn.has("win32") == 1

-- npm global bin (claude CLI) may not be on PATH; make it visible to nvim
local npm_bin = is_win and (vim.env.APPDATA or "") .. "\\npm" or vim.fn.expand("~/.npm-global/bin")
if vim.fn.isdirectory(npm_bin) == 1 and not vim.env.PATH:find(npm_bin, 1, true) then
  vim.env.PATH = npm_bin .. (is_win and ";" or ":") .. vim.env.PATH
end

local CLAUDE_MODEL = "claude-opus-5-5"
local MINIMAX_MODEL = "MiniMax-M3.1-Flash"

---------------------------------------------------------------------------
-- MiniMax credentials / endpoint
---------------------------------------------------------------------------
local function minimax_env()
  local region = vim.env.MINIMAX_REGION
  if not vim.env.MINIMAX_API_KEY or not region then
    local path = vim.fn.expand("~/.mmx/config.json")
    local ok, cfg = pcall(function()
      return vim.json.decode(table.concat(vim.fn.readfile(path), "\n"))
    end)
    if ok and type(cfg) == "table" then
      vim.env.MINIMAX_API_KEY = vim.env.MINIMAX_API_KEY or cfg.api_key
      region = region or cfg.region
    end
  end
  local host = (region or "cn") == "cn" and "https://api.minimaxi.com" or "https://api.minimax.io"
  return host, vim.env.MINIMAX_API_KEY
end

local MINIMAX_HOST = minimax_env()

---------------------------------------------------------------------------
-- Claude Opus 5.5 rejects sampling params (temperature/top_p/top_k) and
-- budget_tokens thinking; strip them from whatever the adapter builds.
---------------------------------------------------------------------------
local function sanitize_claude(params)
  if type(params) == "table" then
    params.temperature, params.top_p, params.top_k = nil, nil, nil
    if type(params.thinking) == "table" and params.thinking.type == "enabled" then
      params.thinking = { type = "adaptive" }
    end
  end
  return params
end

local function wrap_param_builder(adapter)
  local h = adapter.handlers or {}
  local function wrap(tbl, key)
    local orig = tbl and tbl[key]
    if type(orig) == "function" then
      tbl[key] = function(...)
        return sanitize_claude(orig(...))
      end
    end
  end
  wrap(h, "form_parameters") -- codecompanion <= v17
  wrap(h.request, "build_parameters") -- newer handler layout
  return adapter
end

---------------------------------------------------------------------------
-- Claude Code terminals
---------------------------------------------------------------------------
local terms = {}

local function claude_term(kind)
  if terms[kind] then
    return terms[kind]
  end
  if vim.fn.executable("claude") == 0 then
    vim.notify("claude CLI not found: npm i -g @anthropic-ai/claude-code", vim.log.levels.ERROR)
    return nil
  end
  local Terminal = require("toggleterm.terminal").Terminal
  local opts = {
    cmd = "claude",
    direction = "float",
    float_opts = { border = "rounded", width = math.floor(vim.o.columns * 0.9), height = math.floor(vim.o.lines * 0.85) },
    hidden = true,
    close_on_exit = true,
    on_open = function(t)
      vim.keymap.set("t", "<Esc><Esc>", [[<C-\><C-n>]], { buffer = t.bufnr, desc = "Leave terminal mode" })
    end,
  }
  if kind == "minimax" then
    local host, key = minimax_env()
    if not key then
      vim.notify("MiniMax API key not found ($MINIMAX_API_KEY or ~/.mmx/config.json)", vim.log.levels.ERROR)
      return nil
    end
    -- don't let an Anthropic key override the MiniMax token (no `env` binary on Windows)
    opts.cmd = is_win and "claude" or "env -u ANTHROPIC_API_KEY claude"
    opts.display_name = "Claude Code (MiniMax)"
    opts.env = {
      ANTHROPIC_API_KEY = is_win and "" or nil,
      ANTHROPIC_BASE_URL = host .. "/anthropic",
      ANTHROPIC_AUTH_TOKEN = key,
      ANTHROPIC_MODEL = MINIMAX_MODEL,
      ANTHROPIC_SMALL_FAST_MODEL = MINIMAX_MODEL,
      ANTHROPIC_DEFAULT_OPUS_MODEL = MINIMAX_MODEL,
      ANTHROPIC_DEFAULT_SONNET_MODEL = MINIMAX_MODEL,
      ANTHROPIC_DEFAULT_HAIKU_MODEL = MINIMAX_MODEL,
      API_TIMEOUT_MS = "3000000",
      CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = "1",
    }
  else
    opts.display_name = "Claude Code"
  end
  terms[kind] = Terminal:new(opts)
  return terms[kind]
end

local function toggle_claude(kind)
  local t = claude_term(kind)
  if t then
    t:toggle()
  end
end

---------------------------------------------------------------------------
-- Specs
---------------------------------------------------------------------------
return {
  {
    "olimorris/codecompanion.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    cmd = { "CodeCompanion", "CodeCompanionChat", "CodeCompanionActions", "CodeCompanionCmd" },
    keys = {
      { "<leader>aa", "<cmd>CodeCompanionChat Toggle<cr>", mode = { "n", "v" }, desc = "AI: toggle chat" },
      { "<leader>an", "<cmd>CodeCompanionChat minimax<cr>", mode = { "n", "v" }, desc = "AI: new chat (MiniMax)" },
      { "<leader>ap", "<cmd>CodeCompanionActions<cr>", mode = { "n", "v" }, desc = "AI: actions" },
      { "<leader>ai", ":CodeCompanion ", mode = { "n", "v" }, desc = "AI: inline prompt" },
      { "<leader>ad", "<cmd>CodeCompanionChat Add<cr>", mode = "v", desc = "AI: add selection to chat" },
    },
    opts = function()
      local adapters = require("codecompanion.adapters")
      return {
        adapters = {
          http = {
            opts = { show_presets = false }, -- only list our adapters in `ga`
            claude = function()
              return wrap_param_builder(adapters.extend("anthropic", {
                name = "claude",
                formatted_name = "Claude",
                env = { api_key = "ANTHROPIC_API_KEY" },
                schema = {
                  model = { default = CLAUDE_MODEL },
                },
              }))
            end,
            -- MiniMax via its Anthropic-compatible endpoint (keeps thinking blocks + tool calls)
            minimax = function()
              return adapters.extend("anthropic", {
                name = "minimax",
                formatted_name = "MiniMax",
                url = MINIMAX_HOST .. "/anthropic/v1/messages",
                env = { api_key = "MINIMAX_API_KEY" },
                schema = {
                  model = {
                    default = MINIMAX_MODEL,
                    -- static list: MiniMax has no /v1/models endpoint
                    choices = {
                      [MINIMAX_MODEL] = { formatted_name = "MiniMax M3.1 Flash", opts = { can_reason = true } },
                      ["MiniMax-M3"] = { formatted_name = "MiniMax M3", opts = { can_reason = true } },
                    },
                  },
                },
              })
            end,
          },
        },
        interactions = {
          chat = { adapter = "claude" },
          inline = { adapter = "claude" },
          cmd = { adapter = "claude" },
        },
        display = {
          chat = { window = { layout = "vertical", position = "right", width = 0.38 } },
        },
        opts = { language = "Chinese" },
      }
    end,
  },
  {
    "akinsho/toggleterm.nvim",
    keys = {
      { "<leader>ac", function() toggle_claude("anthropic") end, desc = "AI: Claude Code" },
      { "<leader>am", function() toggle_claude("minimax") end, desc = "AI: Claude Code (MiniMax)" },
    },
  },
}
