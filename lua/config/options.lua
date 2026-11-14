local o = vim.opt

o.number = true
o.relativenumber = true
o.signcolumn = "yes"
o.cursorline = true
o.termguicolors = true
o.scrolloff = 8
o.wrap = false

o.expandtab = true
o.shiftwidth = 4
o.tabstop = 4
o.smartindent = true

o.ignorecase = true
o.smartcase = true

o.splitright = true
o.splitbelow = true
o.mouse = "a"
o.updatetime = 250
o.timeoutlen = 400
o.undofile = true
o.completeopt = { "menu", "menuone", "noselect" }

-- Windows: LLVM's installer doesn't add itself to PATH; expose clang/clangd to nvim
if vim.fn.has("win32") == 1 then
  local llvm = "C:\\Program Files\\LLVM\\bin"
  if vim.fn.isdirectory(llvm) == 1 and not vim.env.PATH:find(llvm, 1, true) then
    vim.env.PATH = llvm .. ";" .. vim.env.PATH
  end
  -- proxy.golang.org can time out on this network, which breaks mason's `go install gopls`;
  -- "|" falls through to the next proxy on any error (a "," only falls through on 404/410)
  if not vim.env.GOPROXY then
    vim.env.GOPROXY = "https://proxy.golang.org|https://goproxy.cn|direct"
  end
end

o.clipboard = "unnamedplus" -- share yank/paste with the system clipboard (xclip on Linux, native on Windows)
o.inccommand = "split" -- live preview of :s substitutions
o.list = true
o.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
o.confirm = true -- ask to save instead of failing on :q
o.laststatus = 3 -- single global statusline
o.showmode = false -- mode is shown in lualine
o.sidescrolloff = 8
o.pumheight = 12
o.foldmethod = "expr"
o.foldexpr = "v:lua.vim.treesitter.foldexpr()"
o.foldlevel = 99 -- start with everything unfolded

vim.diagnostic.config({
  virtual_text = true,
  severity_sort = true,
  float = { border = "rounded" },
})
