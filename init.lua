-- Leader must be set before lazy.nvim loads plugins / keymaps
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- set to true if your terminal uses a Nerd Font (enables file icons)
vim.g.have_nerd_font = false

require("config.options")
require("config.keymaps")
require("config.autocmds")
require("config.lazy")
