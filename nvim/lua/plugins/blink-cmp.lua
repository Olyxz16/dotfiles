return {
    "saghen/blink.cmp",
    event = "InsertEnter",
    version = "1.*",
    opts = {
        keymap = {
            preset = "enter",
            ['<C-k>'] = { 'show_documentation', 'hide_documentation' },
        },
        appearance = {
            use_nvim_cmp_as_default = false,
            nerd_font_variant = "mono",
        },
        sources = {
            default = { "lsp", "path", "buffer" },
            providers = {
                lsp = {
                    score_offset = 1000,
                },
            },
        },
        fuzzy = {
            implementation = "prefer_rust_with_warning",
        },
    },
    opts_extend = { "sources.default" },
}
