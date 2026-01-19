return {
    {
        "nvim-treesitter/nvim-treesitter",
        tag = "v0.9.2",
        build = ":TSUpdate",
        config = function()
            local config = require("nvim-treesitter.configs")
            vim.filetype.add({extension = { templ = "templ" }})
            config.setup({
                auto_install = true,
                highlight = {
                    enable = true,
                    disable = { "vimdoc" }
                },
                indent = { enable = true },
                install = {
                    compilers = { "clang", "gcc" },
                },
            })
        end,
        dependencies = {
            'vrischmann/tree-sitter-templ'
        }
    }
}
