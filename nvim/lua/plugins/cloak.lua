return {
    "laytan/cloak.nvim",
    config = function()
        require("cloak").setup({
            enabled = true,
            cloak_character = "*",
            pattern = {
                {
                    file_pattern = ".env*",
                    cloak_pattern = "=.+",
                    replace = nil
                }
            }
        })
    end
}
