-- AI agents, each in a floating terminal (toggleterm)
--
-- Keys (<leader>a…):
--   ac  Claude Code       official `claude` CLI
--   am  MiniMax3.1Flash   Codex CLI talking to MiniMax
--   (inside a terminal: <Esc><Esc> to normal mode, then the same key hides it)
--
-- Auth / model live with each CLI, not here:
--   Claude Code     -> its own login, or $ANTHROPIC_API_KEY
--   MiniMax3.1Flash -> ~/.codex/config.toml (model, provider, key)

local is_win = vim.fn.has("win32") == 1

-- npm global bin (claude CLI) may not be on PATH; make it visible to nvim
local npm_bin = is_win and (vim.env.APPDATA or "") .. "\\npm" or vim.fn.expand("~/.npm-global/bin")
if vim.fn.isdirectory(npm_bin) == 1 and not vim.env.PATH:find(npm_bin, 1, true) then
  vim.env.PATH = npm_bin .. (is_win and ";" or ":") .. vim.env.PATH
end

local function native(path)
  return is_win and (path:gsub("/", "\\")) or path
end

-- Codex: `codex` from PATH if installed (npm i -g @openai/codex), otherwise the
-- copy Codex keeps under ~/.codex/packages (`current` follows its auto-updates).
-- Like the npm launcher, also put its bundled tools (rg) on the terminal's PATH.
local function codex_spec()
  if vim.fn.executable("codex") == 1 then
    return { cmd = "codex" }
  end
  local home = vim.env.CODEX_HOME or vim.fn.expand("~/.codex")
  local root = home .. "/packages/app-server-daemon/current"
  if vim.fn.executable(root .. "/bin/codex" .. (is_win and ".exe" or "")) == 0 then
    return nil
  end
  local path = { native(root .. "/bin"), native(root .. "/codex-path"), vim.env.PATH }
  return { cmd = "codex", env = { PATH = table.concat(path, is_win and ";" or ":") } }
end

local agents = {
  claude = {
    name = "Claude Code",
    spec = function()
      return vim.fn.executable("claude") == 1 and { cmd = "claude" } or nil
    end,
    missing = "claude CLI not found: npm i -g @anthropic-ai/claude-code",
  },
  -- Codex CLI, named after the model ~/.codex/config.toml points it at
  codex = {
    name = "MiniMax3.1Flash",
    spec = codex_spec,
    missing = "MiniMax3.1Flash needs the codex CLI: npm i -g @openai/codex",
  },
}

local terms = {}

local function agent_term(kind)
  if terms[kind] then
    return terms[kind]
  end
  local agent = agents[kind]
  local spec = agent.spec()
  if not spec then
    vim.notify(agent.missing, vim.log.levels.ERROR)
    return nil
  end
  terms[kind] = require("toggleterm.terminal").Terminal:new({
    cmd = spec.cmd,
    env = spec.env,
    display_name = agent.name,
    direction = "float",
    float_opts = { border = "rounded", width = math.floor(vim.o.columns * 0.9), height = math.floor(vim.o.lines * 0.85) },
    hidden = true,
    close_on_exit = true,
    on_open = function(t)
      vim.keymap.set("t", "<Esc><Esc>", [[<C-\><C-n>]], { buffer = t.bufnr, desc = "Leave terminal mode" })
    end,
  })
  return terms[kind]
end

local function toggle_agent(kind)
  local t = agent_term(kind)
  if t then
    t:toggle()
  end
end

return {
  {
    "akinsho/toggleterm.nvim",
    keys = {
      { "<leader>ac", function() toggle_agent("claude") end, desc = "AI: " .. agents.claude.name },
      { "<leader>am", function() toggle_agent("codex") end, desc = "AI: " .. agents.codex.name },
    },
  },
}
