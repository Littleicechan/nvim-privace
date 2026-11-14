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
