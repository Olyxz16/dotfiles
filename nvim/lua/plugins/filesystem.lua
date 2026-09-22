return {
    {
        "mikavilpas/yazi.nvim",
        version = "*",
        event = "VeryLazy",
        dependencies = {
            { "nvim-lua/plenary.nvim", lazy = true },
        },
        keys = {
            {
                "<leader>e",
                mode = { "n", "v" },
                "<cmd>Yazi<cr>",
                desc = "Open yazi at the current file",
            },
        },
        ---@type YaziConfig | {}
        opts = {
            open_for_directories = true,
            keymaps = {
                show_help = "<f1>",
            },
        },
        init = function()
            vim.g.loaded_netrwPlugin = 1
        end,
    },
    {
        "ThePrimeagen/harpoon",
        dependencies = {
            "nvim-lua/plenary.nvim"
        },
        keys = {
            { "<leader><Tab>", function() require("harpoon.ui").toggle_quick_menu() end, desc = "Harpoon quick menu" },
            { "<leader>²", function() require("harpoon.mark").add_file() end, desc = "Harpoon add file" },
            { "<leader>@", function() require("harpoon.mark").add_file() end, desc = "Harpoon add file" },
        },
    }
}
