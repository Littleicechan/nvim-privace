local icons = vim.g.have_nerd_font

return {
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    opts = { style = "night" },
    config = function(_, opts)
      require("tokyonight").setup(opts)
      vim.cmd.colorscheme("tokyonight")
    end,
  },
  {
    "akinsho/toggleterm.nvim",
    keys = { { "<C-\\>", desc = "Toggle terminal" } },
    opts = {
      open_mapping = [[<C-\>]],
      direction = "float",
      float_opts = { border = "rounded" },
    },
  },
  -- popup that shows available keys after <leader>
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      preset = "modern",
      icons = { mappings = icons },
      spec = {
        { "<leader>a", group = "AI" },
        { "<leader>b", group = "buffer" },
        { "<leader>c", group = "code" },
        { "<leader>f", group = "find" },
        { "<leader>g", group = "git" },
        { "<leader>l", group = "lsp" },
        { "<leader>x", group = "diagnostics" },
      },
    },
  },
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    opts = {
      options = {
        theme = "tokyonight",
        globalstatus = true,
        icons_enabled = icons,
        component_separators = icons and { left = "", right = "" } or "|",
        section_separators = icons and { left = "", right = "" } or "",
      },
      sections = {
        lualine_c = { { "filename", path = 1 } },
      },
    },
  },
  {
    "akinsho/bufferline.nvim",
    event = "VeryLazy",
    opts = {
      options = {
        show_buffer_icons = icons,
        show_buffer_close_icons = false,
        diagnostics = "nvim_lsp",
        offsets = { { filetype = "NvimTree", text = "Explorer", separator = true } },
      },
    },
  },
  -- indent guides
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    event = { "BufReadPost", "BufNewFile" },
    opts = { indent = { char = "│" }, scope = { enabled = true } },
  },
}
