return {
    "stevearc/dressing.nvim",
    event = "VeryLazy",
    opts = {
        input = {
            enabled = true,
            default_prompt = "Input:",
            title_pos = "left",
            insert_only = false,
            start_in_insert = true,
            border = "rounded",
            relative = "cursor",
            prefer_width = 40,
            width = nil,
            max_width = { 140, 0.9 },
            min_width = { 20, 0.2 },
            buf_options = {},
            win_options = {
                wrap = false,
                list = true,
                listchars = "precedes:…,extends:…",
                sidescrolloff = 0,
            },
            mappings = {
                n = {
                    ["<Esc>"] = "Close",
                    ["<CR>"] = "Confirm",
                },
                i = {
                    ["<C-c>"] = "Close",
                    ["<CR>"] = "Confirm",
                    ["<Up>"] = "HistoryPrev",
                    ["<Down>"] = "HistoryNext",
                },
            },
            override = function(conf)
                return conf
            end,
            get_config = nil,
        },
        select = {
            enabled = true,
            backend = { "telescope", "fzf_lua", "fzf", "builtin", "nui" },
            trim_prompt = true,
            builtin = {
                show_numbers = true,
                border = "rounded",
                relative = "editor",
                buf_options = {},
                win_options = {
                    cursorline = true,
                    cursorlineopt = "both",
                    number = true,
                },
                max_width = { 140, 0.8 },
                min_width = { 40, 0.2 },
                height = nil,
                max_height = 0.9,
                min_height = { 10, 0.2 },
                mappings = {
                    ["<Esc>"] = "Close",
                    ["<C-c>"] = "Close",
                    ["<CR>"] = "Confirm",
                },
            },
            format_item_override = {},
            get_config = function(opts)
                if opts.kind == "codeaction" then
                    return {
                        backend = "builtin",
                        nui = {
                            relative = "cursor",
                            max_width = 80,
                            min_width = 40,
                            max_height = 15,
                        },
                    }
                end
            end,
        },
    },
}
