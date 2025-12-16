return {
    {
        "Olyxz16/triad.nvim",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-tree/nvim-web-devicons",
        },
        config = function()
            require("triad").setup()
        end,
        cmd = "Triad",
    },
    {
        "mikavilpas/yazi.nvim",
        version = "*", -- use the latest stable version
        event = "VeryLazy",
        dependencies = {
            { "nvim-lua/plenary.nvim", lazy = true },
        },
        keys = {
            -- 👇 in this section, choose your own keymappings!
            {
                "<leader>e",
                mode = { "n", "v" },
                "<cmd>Yazi<cr>",
                desc = "Open yazi at the current file",
            },
        },
        ---@type YaziConfig | {}
        opts = {
            -- if you want to open yazi instead of netrw, see below for more info
            open_for_directories = false,
            keymaps = {
                show_help = "<f1>",
            },
        },
        -- 👇 if you use `open_for_directories=true`, this is recommended
        init = function()
            -- mark netrw as loaded so it's not loaded at all.
            --
            -- More details: https://github.com/mikavilpas/yazi.nvim/issues/802
            vim.g.loaded_netrwPlugin = 1
        end,
    },
    {
        "ThePrimeagen/harpoon",
        dependencies = {
            "nvim-lua/plenary.nvim"
        },
        vim.keymap.set('n', '<leader><Tab>', ':lua require("harpoon.ui").toggle_quick_menu()<CR>', { noremap = true, silent = true }),
        vim.keymap.set('n', '<leader>²', ':lua require("harpoon.mark").add_file()<CR>', { noremap = true, silent = true }), 
        vim.api.nvim_create_user_command('Mark', function ()
            require("harpoon.mark").add_file()
        end, {})
    }
    
}
