return {
    {
        "nvim-treesitter/nvim-treesitter",
        lazy = false,
        build = ":TSUpdate",
        config = function()
            local function link_lang_hlgroups()
                local langs = vim.api.nvim_get_runtime_file("parser/*.so", true)
                if not langs then return end
                local seen = {}
                for _, path in ipairs(langs) do
                    local lang = path:match("parser/([^.]+)%.so$")
                    if lang and not seen[lang] then
                        seen[lang] = true
                        for _, cap in ipairs({
                            "attribute", "boolean", "character", "comment", "conditional",
                            "constant", "constructor", "debug", "define", "exception",
                            "field", "float", "function", "identifier", "include",
                            "keyword", "label", "macro", "method", "namespace",
                            "none", "number", "operator", "parameter", "preproc",
                            "punctuation", "repeat", "return", "section", "special",
                            "spell", "string", "symbol", "tag", "text", "type",
                            "underline", "variable",
                        }) do
                            local from = "@" .. cap .. "." .. lang
                            local to = "@" .. cap
                            pcall(vim.api.nvim_set_hl, 0, from, { link = to, default = true })
                        end
                    end
                end
            end
            link_lang_hlgroups()

            vim.api.nvim_create_autocmd("FileType", {
                callback = function(args)
                    local lang = vim.treesitter.language.get_lang(args.match)
                    if not lang then return end
                    if not pcall(vim.treesitter.language.add, lang) then return end
                    pcall(vim.treesitter.start, args.buf, lang, { highlight = { enable = true } })
                end,
            })
        end,
    },
}
