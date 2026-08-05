return {
	{
		"catppuccin/nvim",
		name = "catppuccin",
		opts = {
			flavour = "mocha", -- latte, frappe, macchiato, or mocha
			transparent_background = false,

			styles = {
				comments = { "italic" },
				conditionals = { "italic" },
			},

			integrations = {
				treesitter = true,
				native_lsp = {
					enabled = true,
				},
			},
		},
	},

	{
		"LazyVim/LazyVim",
		opts = {
			colorscheme = "catppuccin",
		},
	},
}
