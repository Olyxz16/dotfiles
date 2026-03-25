return {
    {
        "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate",
        config = function()
            local config = require("nvim-treesitter.config")
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
        -- tree-sitter-templ is now bundled in nvim-treesitter; no external dependency needed
    }
}
