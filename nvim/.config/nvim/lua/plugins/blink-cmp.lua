return {
    "saghen/blink.cmp",
    event = "InsertEnter",
    version = "1.*",
    dependencies = {
        "rafamadriz/friendly-snippets",
    },
    opts = {
        keymap = {
            preset = "enter",
            ['<C-k>'] = { 'show_documentation', 'hide_documentation' },
        },
        appearance = {
            use_nvim_cmp_as_default = false,
            nerd_font_variant = "mono",
        },
        completion = {
            menu = {
                border = "none",
                draw = {
                    columns = { { "label", "label_description", gap = 1 }, { "kind" } },
                },
            },
            documentation = {
                auto_show = false,
            },
            ghost_text = {
                enabled = false,
            },
        },
        sources = {
            default = { "lsp", "path", "buffer" },
        },
        fuzzy = {
            implementation = "prefer_rust_with_warning",
        },
    },
    opts_extend = { "sources.default" },
}
