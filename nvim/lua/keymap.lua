vim.keymap.set('n', '<leader>r', '<cmd>Triad<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<leader>t', '<cmd>belowright split<CR>', { noremap = true, silent = true })
-- Note: <esc> -> :nohlsearch is now a default mapping in nvim 0.11

-- Navigate vim panes better
vim.keymap.set('n', '<c-k>', '<cmd>wincmd k<CR>')
vim.keymap.set('n', '<c-j>', '<cmd>wincmd j<CR>')
vim.keymap.set('n', '<c-h>', '<cmd>wincmd h<CR>')
vim.keymap.set('n', '<c-l>', '<cmd>wincmd l<CR>')

vim.keymap.set('n', '<Tab>', 'i')
