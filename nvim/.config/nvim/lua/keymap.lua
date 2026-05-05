vim.keymap.set('n', '<leader>r', '<cmd>Triad<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<leader>tt', '<cmd>belowright split<CR>', { noremap = true, silent = true })

-- Navigate vim panes better
vim.keymap.set('n', '<c-k>', '<cmd>wincmd k<CR>')
vim.keymap.set('n', '<c-j>', '<cmd>wincmd j<CR>')
vim.keymap.set('n', '<c-h>', '<cmd>wincmd h<CR>')
vim.keymap.set('n', '<c-l>', '<cmd>wincmd l<CR>')

vim.keymap.set('n', '<leader>tr', vim.diagnostic.setqflist, { desc = "Diagnostic Quickfix" })

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
