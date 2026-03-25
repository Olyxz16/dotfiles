return {
    {
        "lowitea/aw-watcher.nvim",
        event = "VeryLazy",
        config = function()
            require("aw_watcher").setup({
                -- Ensure these match your ActivityWatch settings
                aw_server = {
                    host = "127.0.0.1",
                    port = 5600,
                }
            })
        end
    },
    {
        "andweeb/presence.nvim",
        event = "VeryLazy", -- Loads after startup to prevent lag
        config = function()
            require("presence").setup({
                -- Minimal config for performance
                auto_update         = true,
                neovim_image_text   = "Neovim", 
                main_image          = "file", -- Shows the language icon (e.g., Lua icon)

                -- Rich Presence Text (Customizable)
                editing_text        = "Editing %s", -- "Editing main.lua"
                workspace_text      = "Working on %s", -- "Working on MyProject"
            })
        end
    }
}

