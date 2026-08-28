return {
    {
        "rose-pine/neovim",
        name = "rose-pine",
        lazy = false,
        priority = 1000,
        config = function()
            require("rose-pine").setup({
                variant = "auto",
                dark_variant = "main",
            })
        end
    },
    {
        "ellisonleao/gruvbox.nvim",
        name = "gruvbox",
        priority = 1000,
        config = function ()
            require("gruvbox").setup({
                variant = "auto",
                dark_variant = "main",
            })
            vim.cmd("colorscheme gruvbox")
        end, opts = {}
    }
}
