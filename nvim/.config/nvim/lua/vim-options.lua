vim.opt.expandtab = true
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.mouse = "a"
vim.g.mapleader = " "


vim.opt.number = true
vim.opt.relativenumber = true

vim.opt.swapfile = false

vim.opt.shada = ""

vim.opt.completeopt = { "menu", "menuone", "noselect" }

vim.opt.statusline = "%#StatusLine# %m %f %= %y %l:%c"

-- Set winborder for floating windows (replaces old vim.lsp.handlers border hacks)
vim.o.winborder = 'rounded'

-- Enable diagnostic virtual text (disabled by default in 0.11)
vim.diagnostic.config({
    virtual_text = { current_line = true },
})

vim.api.nvim_create_user_command('Jq', function()
    vim.cmd("exec '%!jq .'")
end, {})

vim.keymap.set(
    'n', '<leader><F3>', '',
    {
        noremap = true,
        callback = function()
            local scheme = vim.g.background
            if scheme == "light" then
                vim.g.background = "dark"
                vim.o.background = "dark"
            else
                vim.g.background = "light"
                vim.o.background = "light"
            end
        end
    }
)
