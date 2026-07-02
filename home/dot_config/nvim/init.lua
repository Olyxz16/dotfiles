local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable",
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

-- Filter out the stale leap.nvim Codeberg migration nag.
do
    local orig = vim.notify
    vim.notify = function(msg, level, opts)
        if type(msg) == "string" and msg:match("leap.nvim: the repository has been moved to Codeberg") then
            return
        end
        return orig(msg, level, opts)
    end
end

-- Enable the experimental Neovim 0.12 UI
require('vim._core.ui2').enable({})

require("vim-options")
require("keymap")
require("lazy").setup("plugins")
