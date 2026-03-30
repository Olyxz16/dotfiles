return {
    "laytan/cloak.nvim",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
        require("cloak").setup({
            enabled = true,
            cloak_character = "*",
            patterns = {
                {
                    file_pattern = ".env*",
                    cloak_pattern = "=.+",
                    replace = nil
                }
            }
        })
    end
}
