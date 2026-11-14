-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", "https://github.com/folke/lazy.nvim.git", lazypath })
end
vim.opt.rtp:prepend(lazypath)

-- Every file in lua/config/plugins/*.lua returns a spec (ai.lua, lsp.lua, ...)
require("lazy").setup({ { import = "config.plugins" } }, {
  install = { colorscheme = { "tokyonight" } },
  checker = { enabled = false },
  change_detection = { notify = false },
})
