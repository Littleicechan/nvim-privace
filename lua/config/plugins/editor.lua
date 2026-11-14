return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "master",
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      -- parsers are compiled locally; skip auto-install when no usable C compiler exists
      local has_cc = false
      if vim.fn.has("win32") == 1 then
        -- On Windows, clang alone is not enough: it needs MSVC's C runtime headers
        -- (stdlib.h etc.) from the "Desktop development with C++" workload.
        -- zig bundles its own libc headers, so prefer it.
        require("nvim-treesitter.install").compilers = { "zig", "gcc", "clang", "cl" }
        local function has_msvc()
          local vswhere = "C:\\Program Files (x86)\\Microsoft Visual Studio\\Installer\\vswhere.exe"
          if vim.fn.executable(vswhere) == 0 then return false end
          local out = vim.fn.system({ vswhere, "-latest", "-products", "*",
            "-requires", "Microsoft.VisualStudio.Component.VC.Tools.x86.x64", "-property", "installationPath" })
          return vim.v.shell_error == 0 and vim.trim(out) ~= ""
        end
        has_cc = vim.fn.executable("zig") == 1 or vim.fn.executable("gcc") == 1
          or ((vim.fn.executable("clang") == 1 or vim.fn.executable("cl") == 1) and has_msvc())
      else
        for _, c in ipairs({ "cc", "gcc", "clang", "zig" }) do
          has_cc = has_cc or vim.fn.executable(c) == 1
        end
      end
      require("nvim-treesitter.configs").setup({
        ensure_installed = has_cc and {
          "asm", "bash", "c", "cpp", "go", "java", "javascript", "json", "kotlin",
          "lua", "python", "rust", "toml", "typescript", "vim", "yaml",
        } or {},
        highlight = { enable = true },
        indent = { enable = true },
      })
    end,
  },
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    cmd = "Telescope",
    keys = {
      { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find files" },
      { "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Live grep (needs ripgrep)" },
      { "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Buffers" },
      { "<leader>fr", "<cmd>Telescope oldfiles<cr>", desc = "Recent files" },
      { "<leader>fh", "<cmd>Telescope help_tags<cr>", desc = "Help" },
      { "<leader>fd", "<cmd>Telescope diagnostics<cr>", desc = "Diagnostics" },
    },
    opts = {},
  },
}
