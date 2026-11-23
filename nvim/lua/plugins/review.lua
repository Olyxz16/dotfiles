-- Local plugin, developed in ~/dotfiles/review.nvim (resolved through the
-- stow symlink so the path isn't hardcoded).
local dotfiles = vim.fs.dirname(vim.fs.dirname(vim.fn.resolve(vim.fn.stdpath("config") .. "/init.lua")))

return {
    dir = dotfiles .. "/review.nvim",
    name = "review.nvim",
    lazy = false,
    opts = {
        default_base = "develop",
    },
}
