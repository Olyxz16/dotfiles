return {
    {
        "nvim-treesitter/nvim-treesitter",
        lazy = false,
        build = ":TSUpdate",
        config = function()
            vim.filetype.add({ extension = { templ = "templ" } })

            require("nvim-treesitter").setup()

            -- Enable treesitter highlighting for any buffer with an installed parser
            vim.api.nvim_create_autocmd("FileType", {
                callback = function(args)
                    local lang = vim.treesitter.language.get_lang(args.match)
                    if lang and vim.treesitter.language.add(lang) then
                        vim.treesitter.start(args.buf, lang)
                    end
                end,
            })
        end,
    }
}
