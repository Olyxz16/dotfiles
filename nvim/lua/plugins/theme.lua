return {
    {
        'f4z3r/gruvbox-material.nvim',
        name = 'gruvbox-material',
        lazy = false,
        priority = 1000,
        opts = {},
        config = function()
            require("gruvbox-material").setup({
                contrast="soft",
                comments={
                    italics = true,
                },
            })
        end
    },
    {
        "rose-pine/neovim",
        name = "rose-pine",
        config = function()
            vim.cmd("colorscheme rose-pine")
        end
    }
}
