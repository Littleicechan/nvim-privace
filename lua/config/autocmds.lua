local group = vim.api.nvim_create_augroup("user_config", { clear = true })
local au = vim.api.nvim_create_autocmd

-- briefly highlight yanked text
au("TextYankPost", {
  group = group,
  callback = function()
    vim.hl.on_yank({ timeout = 200 })
  end,
})

-- reopen files at the last cursor position
au("BufReadPost", {
  group = group,
  callback = function(ev)
    local mark = vim.api.nvim_buf_get_mark(ev.buf, '"')
    local lines = vim.api.nvim_buf_line_count(ev.buf)
    if mark[1] > 0 and mark[1] <= lines and vim.bo[ev.buf].filetype ~= "gitcommit" then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- equalize splits when the terminal is resized
au("VimResized", { group = group, command = "tabdo wincmd =" })

-- close helper windows with q
au("FileType", {
  group = group,
  pattern = { "help", "qf", "man", "checkhealth", "lspinfo", "notify" },
  callback = function(ev)
    vim.bo[ev.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = ev.buf, silent = true })
  end,
})

-- reload files changed outside nvim (e.g. by an AI agent in the terminal)
au({ "FocusGained", "TermClose", "TermLeave", "BufEnter" }, {
  group = group,
  callback = function()
    if vim.o.buftype ~= "nofile" then
      pcall(vim.cmd, "checktime") -- errors inside the cmdline window
    end
  end,
})

-- 2-space indent for web/config filetypes
au("FileType", {
  group = group,
  pattern = { "lua", "javascript", "typescript", "json", "yaml", "html", "css" },
  callback = function()
    vim.opt_local.shiftwidth = 2
    vim.opt_local.tabstop = 2
  end,
})

-- <F5>: save the current file and run it in a terminal split at the bottom. Input works while it
-- runs; when it ends the output stays and the cursor goes back to the code. q in the output closes it.
local is_win = vim.fn.has("win32") == 1

-- quote a path for the shell that runs the command (cmd.exe on Windows, sh elsewhere)
local function q(s)
  return is_win and ('"' .. s .. '"') or ("'" .. s:gsub("'", [['\'']]) .. "'")
end

-- first of the given commands whose program is on PATH
local function pick(...)
  for _, c in ipairs({ ... }) do
    if vim.fn.executable(c:match("^%S+")) == 1 then return c end
  end
end

-- compile into stdpath("cache")/run (keeps exe files out of the source folder), then run it
local function build(cc, file, flags)
  local name = vim.fn.fnamemodify(file, ":t:r") .. (is_win and ".exe" or "")
  local out = vim.fs.joinpath(vim.fn.stdpath("cache"), "run", name)
  vim.fn.mkdir(vim.fs.dirname(out), "p")
  out = is_win and out:gsub("/", "\\") or out
  return ("%s %s -o %s%s && %s"):format(cc, q(file), q(out), flags or "", q(out))
end

-- filetype -> function(file) returning the shell command and optionally the working directory
-- (default: the file's folder), or nil and an error message
local runners = {
  lua = function(f) return "lua " .. q(f) end,
  -- on Windows `python3` is the Microsoft Store stub
  python = function(f) return (is_win and "python " or "python3 ") .. q(f) end,
  javascript = function(f) return "node " .. q(f) end,
  -- Node 22.18+ strips the types and runs .ts directly
  typescript = function(f) return "node " .. q(f) end,
  go = function(f) return "go run " .. q(f) end,
  -- JDK 11+ compiles and runs a .java file in one go
  java = function(f) return "java " .. q(f) end,
  -- .NET 10+ runs a single .cs file
  cs = function(f) return "dotnet run " .. q(f) end,
  zig = function(f) return "zig run " .. q(f) end,
  c = function(f)
    local cc = pick("gcc", "zig cc", "clang")
    if not cc then return nil, "No C compiler found (gcc / zig / clang)" end
    return build(cc, f, not is_win and " -lm" or nil)
  end,
  cpp = function(f)
    local cxx = pick("g++", "zig c++", "clang++")
    if not cxx then return nil, "No C++ compiler found (g++ / zig / clang++)" end
    return build(cxx, f)
  end,
  rust = function(f)
    local root = vim.fs.root(f, "Cargo.toml")
    if root then return "cargo run", root end
    return build("rustc", f)
  end,
  sh = function(f)
    if not is_win then return "bash " .. q(f) end
    -- `bash` on the Windows PATH is WSL's, which can't read Windows paths; use Git Bash
    local git = vim.fn.exepath("git")
    local bash = git ~= "" and vim.fs.joinpath(vim.fs.dirname(vim.fs.dirname(git)), "bin", "bash.exe") or ""
    if vim.fn.executable(bash) == 0 then return nil, "Git Bash not found" end
    return q((bash:gsub("/", "\\"))) .. " " .. q(f)
  end,
}
runners.bash = runners.sh

local run_buf
local function run_file()
  local file = vim.api.nvim_buf_get_name(0)
  if file == "" then
    return vim.notify("Save the file first", vim.log.levels.WARN)
  end
  local runner = runners[vim.bo.filetype]
  if not runner then
    return vim.notify("No runner for filetype " .. vim.bo.filetype, vim.log.levels.WARN)
  end
  local cmd, extra = runner(file) -- extra: working directory, or the error message
  if not cmd then
    return vim.notify(extra, vim.log.levels.ERROR)
  end
  local prog = cmd:match('^"(.-)"') or cmd:match("^%S+")
  if vim.fn.executable(prog) == 0 then
    return vim.notify(("`%s` is not on PATH (reopen the terminal after installing it)"):format(prog), vim.log.levels.ERROR)
  end
  vim.cmd("silent update")
  if run_buf and vim.api.nvim_buf_is_valid(run_buf) then
    vim.api.nvim_buf_delete(run_buf, { force = true }) -- replace the previous run (stops it if still running)
  end
  -- Windows: the console code page here is GBK (936); switch it to UTF-8 so Chinese output isn't garbled
  local argv = is_win and { "cmd.exe", "/s", "/c", '"chcp 65001 >nul && ' .. cmd .. '"' } or { "sh", "-c", cmd }
  vim.cmd("botright 12new")
  local buf = vim.api.nvim_get_current_buf()
  run_buf = buf
  vim.fn.jobstart(argv, {
    term = true,
    cwd = extra or vim.fs.dirname(file),
    on_exit = function()
      vim.schedule(function()
        -- still watching the run: leave terminal mode (a keypress would close the exited
        -- terminal and lose the output) and go back to the code
        if vim.api.nvim_get_current_buf() == buf and vim.api.nvim_get_mode().mode == "t" then
          vim.cmd.stopinsert()
          vim.cmd.wincmd("p")
        end
      end)
    end,
  })
  vim.bo[buf].buflisted = false
  vim.keymap.set("n", "q", "<cmd>bwipeout!<cr>", { buffer = buf, silent = true, desc = "Close run output" })
  vim.cmd.startinsert()
end

au("FileType", {
  group = group,
  pattern = vim.tbl_keys(runners),
  callback = function(ev)
    vim.keymap.set("n", "<F5>", run_file, { buffer = ev.buf, desc = "Run file" })
  end,
})
