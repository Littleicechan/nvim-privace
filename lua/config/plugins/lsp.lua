-- clangd (C/C++) is enabled below if found on PATH; mason needs `unzip` to install it
local servers = { "bashls", "jdtls", "lua_ls", "pyright", "rust_analyzer", "ts_ls" }
-- mason builds gopls with `go install`, so only request it when Go is installed
if vim.fn.executable("go") == 1 then
  table.insert(servers, "gopls")
end

return {
  {
    "williamboman/mason.nvim",
    cmd = "Mason",
    opts = { ui = { border = "rounded" } },
  },
  {
    "williamboman/mason-lspconfig.nvim",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = { "williamboman/mason.nvim", "neovim/nvim-lspconfig", "hrsh7th/cmp-nvim-lsp" },
    config = function()
      -- shared settings for every server (nvim 0.11+ vim.lsp.config API)
      vim.lsp.config("*", {
        capabilities = require("cmp_nvim_lsp").default_capabilities(),
      })
      -- lua_ls serves two kinds of Lua, chosen by the project root:
      --   nvim config / plugins (stdpath config or data) -> LuaJIT + the vim API
      --   anything else -> plain Lua 5.5, like the `lua` on PATH (G:\Language\Lua\5.5.1 on Windows)
      local function inside(path, dir)
        local function norm(p)
          p = vim.fs.normalize(vim.uv.fs_realpath(p) or p)
          return vim.fn.has("win32") == 1 and p:lower() or p
        end
        path, dir = norm(path), norm(dir)
        return path == dir or vim.startswith(path, dir .. "/")
      end
      vim.lsp.config("lua_ls", {
        -- ~ is a git repo, so ".git" alone would make /home/y the root; prefer nearer markers
        root_markers = { { ".luarc.json", ".luarc.jsonc", "stylua.toml", ".stylua.toml" }, "init.lua", ".git" },
        before_init = function(_, config)
          local root = config.root_dir
          local nvim = root and (inside(root, vim.fn.stdpath("config")) or inside(root, vim.fn.stdpath("data")))
          config.settings.Lua = vim.tbl_deep_extend("force", config.settings.Lua, nvim and {
            runtime = { version = "LuaJIT" },
            diagnostics = { globals = { "vim" } },
            workspace = { library = { vim.env.VIMRUNTIME } },
          } or {
            runtime = { version = "Lua 5.5" },
          })
        end,
        settings = {
          Lua = { workspace = { checkThirdParty = false } },
        },
      })

      -- mason.setup() already runs via lazy's `opts` above; calling it again duplicates registries
      require("mason-lspconfig").setup({
        ensure_installed = servers,
        automatic_enable = true,
      })

      -- servers installed outside mason (e.g. `sudo apt install clangd`)
      for _, s in ipairs({ { "clangd", "clangd" } }) do
        if vim.fn.executable(s[2]) == 1 then
          vim.lsp.enable(s[1])
        end
      end

      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(ev)
          local function map(lhs, rhs, desc)
            vim.keymap.set("n", lhs, rhs, { buffer = ev.buf, desc = desc })
          end
          -- built-in: K hover, grn rename, gra code action, grr references, gri implementation
          map("gd", vim.lsp.buf.definition, "Go to definition")
          map("gD", vim.lsp.buf.declaration, "Go to declaration")
          map("<leader>rn", vim.lsp.buf.rename, "Rename")
          map("<leader>ca", vim.lsp.buf.code_action, "Code action")
          map("<leader>lf", function() vim.lsp.buf.format({ async = true }) end, "Format")
        end,
      })
    end,
  },
}
