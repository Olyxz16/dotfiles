vim.cmd("set expandtab")
vim.cmd("set tabstop=4")
vim.cmd("set softtabstop=4")
vim.cmd("set shiftwidth=4")
vim.cmd("set mouse=")
vim.g.mapleader = " "
vim.g.background = "light"

vim.wo.number = true
vim.wo.relativenumber = true

vim.opt.swapfile = false
vim.opt.encoding = 'utf8'

vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "nvim_treesitter#foldexpr()"
vim.opt.foldlevel = 1
vim.cmd("set nofoldenable")

vim.cmd('set shada="NONE"')

vim.cmd('autocmd InsertEnter * :let @/=""')

vim.api.nvim_create_user_command('Jq', function()
    vim.cmd("exec '%!jq .'")
end, {})

vim.keymap.set(
    'n', '<leader><F3>', '',
    {
        noremap = true,
        callback = function()
            local scheme = vim.api.nvim_get_var("background")
            print(scheme)
            if scheme == "light"
            then vim.api.nvim_set_var("background", "dark")
                 vim.cmd("set background=dark")
            else vim.api.nvim_set_var("background", "light")
                 vim.cmd("set background=light")
            end
        end
    }
)
