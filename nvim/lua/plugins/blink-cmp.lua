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
        },
        appearance = {
            use_nvim_cmp_as_default = false,
            nerd_font_variant = "mono",
        },
        completion = {
            menu = {
                border = "rounded",
            },
            documentation = {
                auto_show = true,
                auto_show_delay_ms = 200,
            },
        },
        sources = {
            default = { "lsp", "path", "snippets", "buffer" },
        },
        snippets = {
            preset = "default",
        },
        fuzzy = {
            implementation = "prefer_rust_with_warning",
        },
    },
    opts_extend = { "sources.default" },
}
