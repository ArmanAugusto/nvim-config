-- ~/.config/nvim/init.lua
-- CachyOS / Arch-friendly Neovim config for:
-- C, C++, Python, Go, Rust, Packer(HCL), Ansible, Docker/Podman
--
-- Neovim: v0.11+
-- LSP: uses vim.lsp.config() + vim.lsp.enable() (no require("lspconfig") framework)
-- Plugins: lazy.nvim

------------------------------------------------------------
-- Basic settings
------------------------------------------------------------
vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.cursorline = true
vim.opt.termguicolors = true
vim.opt.signcolumn = "yes"
vim.opt.wrap = false
vim.opt.scrolloff = 8

vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.smartindent = true

vim.opt.ignorecase = true
vim.opt.smartcase = true

vim.opt.updatetime = 250
vim.opt.timeoutlen = 400
vim.opt.clipboard = "unnamedplus"

------------------------------------------------------------
-- Bootstrap lazy.nvim
------------------------------------------------------------
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

------------------------------------------------------------
-- Plugins
------------------------------------------------------------
require("lazy").setup({
	----------------------------------------------------------
	-- Theme
	----------------------------------------------------------
	{
		"catppuccin/nvim",
		name = "catppuccin",
		priority = 1000,
		config = function()
			vim.cmd.colorscheme("catppuccin-mocha")
		end,
	},

	----------------------------------------------------------
	-- QoL
	----------------------------------------------------------
	{
		"nvim-lualine/lualine.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			require("lualine").setup({ options = { globalstatus = true } })
		end,
	},
	{
		"lewis6991/gitsigns.nvim",
		config = function()
			require("gitsigns").setup({})
		end,
	},

	----------------------------------------------------------
	-- Telescope
	----------------------------------------------------------
	{
		"nvim-telescope/telescope.nvim",
		dependencies = { "nvim-lua/plenary.nvim" },
		config = function()
			require("telescope").setup({})
			local builtin = require("telescope.builtin")
			vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Find files" })
			vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Live grep" })
			vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Buffers" })
			vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Help" })
		end,
	},

	----------------------------------------------------------
	-- Treesitter (guarded so startup doesn't explode)
	----------------------------------------------------------
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		config = function()
			local ok, configs = pcall(require, "nvim-treesitter.configs")
			if not ok then
				vim.notify("nvim-treesitter not available yet (run :Lazy sync)", vim.log.levels.WARN)
				return
			end

			configs.setup({
				ensure_installed = {
					"c",
					"cpp",
					"python",
					"go",
					"rust",
					"lua",
					"vim",
					"vimdoc",
					"bash",
					"yaml",
					"json",
					"dockerfile",
					"hcl",
					"terraform",
					"regex",
					"markdown",
				},
				highlight = { enable = true },
				indent = { enable = true },
			})
		end,
	},

	----------------------------------------------------------
	-- LSP definitions (keep installed; don't require("lspconfig"))
	----------------------------------------------------------
	{ "neovim/nvim-lspconfig" },

	----------------------------------------------------------
	-- Mason (LSP server installer)
	----------------------------------------------------------
	{
		"williamboman/mason.nvim",
		config = function()
			require("mason").setup({})
		end,
	},
	{
		"williamboman/mason-lspconfig.nvim",
		dependencies = { "williamboman/mason.nvim", "neovim/nvim-lspconfig" },
		config = function()
			require("mason-lspconfig").setup({
				ensure_installed = {
					-- languages
					"clangd",
					"pyright",
					"gopls",
					"rust_analyzer",
					-- ops/iac
					"ansiblels",
					"yamlls",
					"jsonls",
					"dockerls",
					"terraformls", -- also useful for Packer HCL templates
					"bashls",
				},
				automatic_installation = true,
			})
		end,
	},

	----------------------------------------------------------
	-- Completion
	----------------------------------------------------------
	{
		"hrsh7th/nvim-cmp",
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-path",
			"L3MON4D3/LuaSnip",
			"saadparwaiz1/cmp_luasnip",
		},
		config = function()
			local cmp = require("cmp")
			local luasnip = require("luasnip")

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
					{ name = "path" },
					{ name = "buffer" },
				}),
			})
		end,
	},

	----------------------------------------------------------
	-- Diagnostics UI
	----------------------------------------------------------
	{
		"folke/trouble.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			require("trouble").setup({})
			vim.keymap.set("n", "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", { desc = "Diagnostics (Trouble)" })
		end,
	},

	----------------------------------------------------------
	-- Formatting
	----------------------------------------------------------
	{
		"stevearc/conform.nvim",
		config = function()
			require("conform").setup({
				format_on_save = function(bufnr)
					local max = 1024 * 1024
					local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(bufnr))
					if ok and stats and stats.size > max then
						return
					end
					return { timeout_ms = 1500, lsp_fallback = true }
				end,
				formatters_by_ft = {
					c = { "clang_format" },
					cpp = { "clang_format" },
					python = { "black" },
					go = { "gofmt" },
					rust = { "rustfmt" },
					lua = { "stylua" },
					yaml = { "prettier" },
					json = { "prettier" },
					terraform = { "terraform_fmt" },
					hcl = { "terraform_fmt" },
					dockerfile = { "prettier" },
					sh = { "shfmt" },
				},
			})

			vim.keymap.set({ "n", "v" }, "<leader>f", function()
				require("conform").format({ async = true, lsp_fallback = true })
			end, { desc = "Format" })
		end,
	},

	----------------------------------------------------------
	-- Extra HCL / Terraform syntax niceties
	----------------------------------------------------------
	{ "hashivim/vim-terraform" },
}, {
	checker = { enabled = true },
})

------------------------------------------------------------
-- LSP (Neovim 0.11+)
------------------------------------------------------------

-- Per-buffer LSP keymaps when a server attaches
vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("UserLspKeymaps", { clear = true }),
	callback = function(event)
		local map = function(mode, lhs, rhs, desc)
			vim.keymap.set(mode, lhs, rhs, { buffer = event.buf, desc = desc })
		end

		map("n", "gd", vim.lsp.buf.definition, "Go to definition")
		map("n", "gD", vim.lsp.buf.declaration, "Go to declaration")
		map("n", "gr", vim.lsp.buf.references, "References")
		map("n", "gi", vim.lsp.buf.implementation, "Implementation")
		map("n", "K", vim.lsp.buf.hover, "Hover")
		map("n", "<leader>rn", vim.lsp.buf.rename, "Rename")
		map("n", "<leader>ca", vim.lsp.buf.code_action, "Code action")
		map("n", "]d", vim.diagnostic.goto_next, "Next diagnostic")
		map("n", "[d", vim.diagnostic.goto_prev, "Prev diagnostic")
	end,
})

-- Add completion capabilities for LSP
local capabilities = vim.lsp.protocol.make_client_capabilities()
local ok_cmp, cmp_lsp = pcall(require, "cmp_nvim_lsp")
if ok_cmp then
	capabilities = cmp_lsp.default_capabilities(capabilities)
end

-- Configure servers (no require("lspconfig"))
vim.lsp.config("clangd", { capabilities = capabilities })
vim.lsp.config("pyright", { capabilities = capabilities })

vim.lsp.config("gopls", {
	capabilities = capabilities,
	settings = {
		gopls = {
			analyses = { unusedparams = true, nilness = true },
			staticcheck = true,
		},
	},
})

vim.lsp.config("rust_analyzer", {
	capabilities = capabilities,
	settings = {
		["rust-analyzer"] = {
			cargo = { allFeatures = true },
			checkOnSave = { command = "clippy" },
		},
	},
})

vim.lsp.config("ansiblels", {
	capabilities = capabilities,
	settings = {
		ansible = {
			ansible = { path = "ansible" },
			executionEnvironment = { enabled = false },
			validation = { enabled = true },
		},
	},
})

vim.lsp.config("yamlls", { capabilities = capabilities })
vim.lsp.config("jsonls", { capabilities = capabilities })
vim.lsp.config("dockerls", { capabilities = capabilities })
vim.lsp.config("terraformls", { capabilities = capabilities })
vim.lsp.config("bashls", { capabilities = capabilities })

vim.lsp.enable({
	"clangd",
	"pyright",
	"gopls",
	"rust_analyzer",
	"ansiblels",
	"yamlls",
	"jsonls",
	"dockerls",
	"terraformls",
	"bashls",
})

------------------------------------------------------------
-- Diagnostics UI polish
------------------------------------------------------------
vim.diagnostic.config({
	virtual_text = true,
	severity_sort = true,
	float = { border = "rounded" },
})

------------------------------------------------------------
-- Convenience keymaps (global)
------------------------------------------------------------
vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, { desc = "Line diagnostics" })
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Diagnostics list" })
