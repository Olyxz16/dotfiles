vim.keymap.set('n', '<leader>r', '<cmd>Triad<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<leader>tt', '<cmd>belowright split<CR>', { noremap = true, silent = true })

-- Navigate vim panes better
vim.keymap.set('n', '<c-k>', '<cmd>wincmd k<CR>')
vim.keymap.set('n', '<c-j>', '<cmd>wincmd j<CR>')
vim.keymap.set('n', '<c-h>', '<cmd>wincmd h<CR>')
vim.keymap.set('n', '<c-l>', '<cmd>wincmd l<CR>')

vim.keymap.set('n', '<leader>tr', function() require("trouble").toggle("diagnostics") end, { desc = "Trouble diagnostics" })

vim.keymap.set('n', '<Tab>', function()
    local line = vim.api.nvim_get_current_line()
    local col = vim.api.nvim_win_get_cursor(0)[2] 
    local first_non_blank = line:find("[^%s]") 

    if not first_non_blank then
        return '"_cc'
    elseif col < (first_non_blank - 1) then
        return 'I'
    else
        return 'i'
    end
end, { expr = true, noremap = true, desc = "Smart context-aware insert" })

vim.keymap.set('n', '<leader>fd', function() 
    vim.cmd("silent !firefox %")
end, {})

-- Auto-center navigation
vim.keymap.set('n', '<C-u>', '<C-u>zz')
vim.keymap.set('n', '<C-d>', '<C-d>zz')
vim.keymap.set('n', '{', '{zz')
vim.keymap.set('n', '}', '}zz')
vim.keymap.set('n', 'n', 'nzzzv')
vim.keymap.set('n', 'N', 'Nzzzv')
vim.keymap.set('n', 'G', 'Gzz')
vim.keymap.set('n', 'gg', 'ggzz')
vim.keymap.set('n', 'gd', 'gdzz')
vim.keymap.set('n', '<C-i>', '<C-i>zz')
vim.keymap.set('n', '<C-o>', '<C-o>zz')
vim.keymap.set('n', '%', '%zz')
vim.keymap.set('n', '*', '*zz')
vim.keymap.set('n', '#', '#zz')

-- Format buffer
vim.keymap.set('n', '<leader>gf', function()
    require("conform").format({ async = true, lsp_fallback = true })
end, { desc = "Format buffer" })

-- Undotree
vim.keymap.set('n', '<leader>ut', '<cmd>UndotreeToggle<CR>', { desc = "Toggle undotree" })

-- Spectre
vim.keymap.set('n', '<leader>S', '<cmd>Spectre<CR>', { desc = "Toggle Spectre" })
vim.keymap.set('n', '<leader>sw', function()
    require("spectre").open_visual({ select_word = true })
end, { desc = "Spectre search word" })

-- Diffview
vim.keymap.set('n', '<leader>gd', '<cmd>DiffviewOpen<CR>', { desc = "Diffview open" })
vim.keymap.set('n', '<leader>gc', '<cmd>DiffviewClose<CR>', { desc = "Diffview close" })
vim.keymap.set('n', '<leader>gh', '<cmd>DiffviewFileHistory %<CR>', { desc = "Diffview file history" })
vim.keymap.set('n', '<leader>gH', '<cmd>DiffviewFileHistory<CR>', { desc = "Diffview repo history" })

-- Toggle relative line numbers
vim.keymap.set('n', '<leader>ln', function()
    vim.opt.relativenumber = not vim.opt.relativenumber:get()
end, { desc = "Toggle relative line numbers" })
