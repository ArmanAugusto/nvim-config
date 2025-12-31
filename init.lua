-----------------------------------------------------------
-- Bootstrap lazy.nvim
-----------------------------------------------------------
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-----------------------------------------------------------
-- Basic options
-----------------------------------------------------------
vim.o.termguicolors = true

vim.o.number = true
vim.o.relativenumber = true
vim.o.cursorline = true
vim.o.signcolumn = "yes"

vim.o.updatetime = 300
vim.o.completeopt = "menu,menuone,noselect"

vim.o.expandtab = true
vim.o.shiftwidth = 2
vim.o.tabstop = 2
vim.o.smartindent = true

-----------------------------------------------------------
-- Plugins (lazy.nvim)
-----------------------------------------------------------
require("lazy").setup({
  ---------------------------------------------------------
  -- Catppuccin theme
  ---------------------------------------------------------
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    config = function()
      require("catppuccin").setup({
        flavour = "mocha",
        integrations = {
          treesitter = true,
          native_lsp = {
            enabled = true,
            virtual_text = {
              errors = { "italic" },
              hints = { "italic" },
              warnings = { "italic" },
              information = { "italic" },
            },
            underlines = {
              errors = { "underline" },
              hints = { "underline" },
              warnings = { "underline" },
              information = { "underline" },
            },
          },
          cmp = true,
          gitsigns = true,
          mason = true,
          telescope = true,
        },
      })
      vim.cmd.colorscheme("catppuccin-mocha")
    end,
  },

  ---------------------------------------------------------
  -- Treesitter
  ---------------------------------------------------------
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      local ok, configs = pcall(require, "nvim-treesitter.configs")
      if not ok then
        vim.notify("nvim-treesitter not found; skipping Treesitter setup", vim.log.levels.WARN)
        return
      end

      configs.setup({
        ensure_installed = {
          "c",
          "cpp",
          "rust",
          "go",
          "python",
          "lua",
          "vim",
          "vimdoc",
          "bash",
        },
        highlight = { enable = true },
        indent    = { enable = true },
      })
    end,
  },

  ---------------------------------------------------------
  -- Mason & mason-lspconfig
  ---------------------------------------------------------
  {
    "williamboman/mason.nvim",
    config = function()
      require("mason").setup()
    end,
  },

  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim" },
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = {
          "clangd",        -- C/C++
          "rust_analyzer", -- Rust
          "gopls",         -- Go
          "pyright",       -- Python (needs nodejs/npm on system)
        },
        automatic_installation = true,
      })
    end,
  },

  ---------------------------------------------------------
  -- nvim-cmp (completion) + LuaSnip
  ---------------------------------------------------------
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
      "rafamadriz/friendly-snippets",
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")

      require("luasnip.loaders.from_vscode").lazy_load()

      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { "i", "s" }),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
        }, {
          { name = "buffer" },
          { name = "path" },
        }),
        formatting = {
          fields = { "abbr", "kind", "menu" },
        },
      })
    end,
  },

  ---------------------------------------------------------
  -- nvim-lspconfig (server definitions only)
  ---------------------------------------------------------
  {
    "neovim/nvim-lspconfig",
  },

  ---------------------------------------------------------
  -- Telescope (optional but nice)
  ---------------------------------------------------------
  {
    "nvim-lua/plenary.nvim",
  },
  {
    "nvim-telescope/telescope.nvim",
    branch = "0.1.x",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("telescope").setup({})
    end,
  },

  ---------------------------------------------------------
  -- Formatter: conform.nvim
  ---------------------------------------------------------
  {
    "stevearc/conform.nvim",
    config = function()
      require("conform").setup({
        formatters_by_ft = {
          c = { "clang_format" },
          cpp = { "clang_format" },
          rust = { "rustfmt" },
          go = { "gofumpt", "gofmt" }, -- prefer gofumpt; fall back to gofmt
          python = { "black" },
        },
        format_on_save = {
          lsp_fallback = true,
          timeout_ms = 1000,
        },
      })
    end,
  },
})

-----------------------------------------------------------
-- LSP configuration (Neovim 0.11+ style)
-----------------------------------------------------------

local cmp_capabilities = require("cmp_nvim_lsp").default_capabilities()

local on_attach = function(_, bufnr)
  local map = function(mode, lhs, rhs)
    vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, silent = true, noremap = true })
  end

  -- Go-to
  map("n", "gd", vim.lsp.buf.definition)
  map("n", "gr", vim.lsp.buf.references)
  map("n", "gi", vim.lsp.buf.implementation)

  -- Hover docs
  map("n", "K", vim.lsp.buf.hover)

  -- Rename symbol
  map("n", "<leader>rn", vim.lsp.buf.rename)

  -- Diagnostics
  map("n", "<leader>e", vim.diagnostic.open_float)
  map("n", "[d", vim.diagnostic.goto_prev)
  map("n", "]d", vim.diagnostic.goto_next)
end

local servers = { "clangd", "rust_analyzer", "gopls", "pyright" }

for _, server in ipairs(servers) do
  vim.lsp.config(server, {
    on_attach = on_attach,
    capabilities = cmp_capabilities,
  })
end

vim.lsp.enable(servers)

-----------------------------------------------------------
-- UI / behavior tweaks
-----------------------------------------------------------

vim.diagnostic.config({
  virtual_text = true,
  float = {
    border = "rounded",
  },
})

vim.g.mapleader = " "

-- Telescope keymaps
vim.keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<CR>")
vim.keymap.set("n", "<leader>fg", "<cmd>Telescope live_grep<CR>")
vim.keymap.set("n", "<leader>fb", "<cmd>Telescope buffers<CR>")
vim.keymap.set("n", "<leader>fh", "<cmd>Telescope help_tags<CR>")

-- Manual format keymap
vim.keymap.set("n", "<leader>f", function()
  require("conform").format({ async = true })
end)
