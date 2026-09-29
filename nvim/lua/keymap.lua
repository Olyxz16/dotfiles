local map = vim.keymap.set

map('n', '<leader>tt', '<cmd>belowright split<CR>', { noremap = true, silent = true })

-- Navigate vim panes better
map('n', '<c-k>', '<cmd>wincmd k<CR>')
map('n', '<c-j>', '<cmd>wincmd j<CR>')
map('n', '<c-h>', '<cmd>wincmd h<CR>')
map('n', '<c-l>', '<cmd>wincmd l<CR>')


-- Trouble / lsp
map("n", "K", vim.lsp.buf.hover, opts)
map("n", "<leader>gd", vim.lsp.buf.definition, opts)
map("n", "<leader>gr", vim.lsp.buf.references, opts)
map("n", "<leader>ca", vim.lsp.buf.code_action, opts)
map('n', '<leader>tr', function() require("trouble").toggle("diagnostics") end, { desc = "Trouble diagnostics" })
map("n", "<leader>gi", "<cmd>Trouble lsp_incoming_calls toggle<cr>", { desc = "Incoming calls" })
map("n", "<leader>go", "<cmd>Trouble lsp_outgoing_calls toggle<cr>", { desc = "Outgoing calls" })
map("n", "<leader>gm", "<cmd>Trouble lsp_implementations toggle<cr>", { desc = "Implementations" })
map("n", "<leader>gl", "<cmd>Trouble lsp toggle<cr>", { desc = "All LSP info for symbol" })

map('n', '<Tab>', function()
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

map('n', '<leader>fd', function() 
    vim.cmd("silent !firefox %")
end, {})

-- Auto-center navigation
map('n', '<C-u>', '<C-u>zz')
map('n', '<C-d>', '<C-d>zz')
map('n', '{', '{zz')
map('n', '}', '}zz')
map('n', 'n', 'nzzzv')
map('n', 'N', 'Nzzzv')
map('n', 'G', 'Gzz')
map('n', 'gg', 'ggzz')
map('n', 'gd', 'gdzz')
map('n', '<C-i>', '<C-i>zz')
map('n', '<C-o>', '<C-o>zz')
map('n', '%', '%zz')
map('n', '*', '*zz')
map('n', '#', '#zz')

-- Format buffer
map('n', '<leader>gf', function()
    require("conform").format({ async = true, lsp_fallback = true })
end, { desc = "Format buffer" })

-- Diffview
map('n', '<leader>gd', '<cmd>DiffviewOpen<CR>', { desc = "Diffview open" })
map('n', '<leader>gc', '<cmd>DiffviewClose<CR>', { desc = "Diffview close" })
map('n', '<leader>gh', '<cmd>DiffviewFileHistory %<CR>', { desc = "Diffview file history" })
map('n', '<leader>gH', '<cmd>DiffviewFileHistory<CR>', { desc = "Diffview repo history" })

-- Toggle relative line numbers
map('n', '<leader>ln', function()
    vim.opt.relativenumber = not vim.opt.relativenumber:get()
end, { desc = "Toggle relative line numbers" })

-- Run the .NET app pinned to the non-windows TFM. This box is Linux, so
-- `net10.0-windows10.0.19041.0` (UWP toast notifications) is never testable
-- here; -f keeps that true even if TargetFrameworks gets reordered.
vim.api.nvim_create_user_command('DotnetRun', function()
    local bufdir = vim.fs.dirname(vim.api.nvim_buf_get_name(0))
    local csproj = vim.fs.find(function(name)
        return name:match('%.csproj$')
    end, { upward = true, path = bufdir })[1]
    local target = csproj and vim.fs.dirname(csproj) or vim.fn.getcwd()
    vim.cmd('belowright 15split | terminal dotnet run --project ' .. vim.fn.shellescape(target) .. ' -f net10.0')
end, { desc = 'Run dotnet app (net10.0)' })
vim.keymap.set('n', '<leader>rr', '<cmd>DotnetRun<CR>', { desc = 'Run dotnet app (net10.0)' })
