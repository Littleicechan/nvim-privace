-- VS Code-style completion: the first suggestion is highlighted and Enter/Tab accept it,
-- <Up>/<Down> move through the list, parameter hints pop up while typing a call,
-- and friendly-snippets provides VS Code's snippet library (for, if, def, ...).
return {
  {
    "hrsh7th/nvim-cmp",
    event = { "InsertEnter", "CmdlineEnter" },
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-cmdline",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
      "rafamadriz/friendly-snippets",
      "onsails/lspkind.nvim",
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")
      require("luasnip.loaders.from_vscode").lazy_load() -- friendly-snippets uses VS Code's snippet format

      cmp.setup({
        -- "noinsert" without "noselect": the first item is highlighted, but nothing is typed until you accept
        completion = { completeopt = "menu,menuone,noinsert" },
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        window = {
          completion = cmp.config.window.bordered(),
          documentation = cmp.config.window.bordered(),
        },
        -- VS Code's kind icons (codicons) need a Nerd Font; without one, kinds stay as text ("Method", "Function")
        formatting = vim.g.have_nerd_font and {
          fields = { "kind", "abbr", "menu" },
          format = function(_, item)
            -- lspkind's cmp_format() no longer swaps the kind for an icon, so use its codicons table directly
            item.menu = item.kind -- kind name on the right
            item.kind = require("lspkind").presets.codicons[item.kind] or "" -- icon on the left
            return item
          end,
        } or nil,
        -- the insert preset also maps <Up>/<Down> and <C-n>/<C-p> to move through the list
        mapping = cmp.mapping.preset.insert({
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<C-e>"] = cmp.mapping.abort(),
          ["<C-b>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.confirm({ select = true })
            elseif luasnip.locally_jumpable(1) then
              luasnip.jump(1)
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if luasnip.locally_jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { "i", "s" }),
        }),
        sources = cmp.config.sources(
          { { name = "nvim_lsp" }, { name = "luasnip" }, { name = "path" } },
          { { name = "buffer" } }
        ),
      })

      cmp.setup.cmdline({ "/", "?" }, {
        mapping = cmp.mapping.preset.cmdline(),
        sources = { { name = "buffer" } },
      })
      cmp.setup.cmdline(":", {
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources({ { name = "path" } }, { { name = "cmdline" } }),
      })
    end,
  },
  {
    -- parameter hints while typing a call, like VS Code (the built-in one is manual: <C-s>)
    "ray-x/lsp_signature.nvim",
    event = "InsertEnter",
    opts = {
      hint_enable = false, -- floating window only, no virtual-text hint
      handler_opts = { border = "rounded" },
    },
    config = function(_, opts)
      require("lsp_signature").setup(opts)
    end,
  },
}
