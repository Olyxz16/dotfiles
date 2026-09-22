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

-- Map framework filetypes to their tree-sitter parser names (Neovim 0.12 has no
-- defaults for these). A parser for each target must exist under stdpath/site/parser.
vim.treesitter.language.register("tsx", "typescriptreact")
vim.treesitter.language.register("javascript", "javascriptreact")


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

vim.api.nvim_create_autocmd("FileType", {
    pattern = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
    callback = function()
        vim.bo.tabstop = 2
        vim.bo.shiftwidth = 2
        vim.bo.expandtab = true
        vim.bo.softtabstop = 2
    end,
})
