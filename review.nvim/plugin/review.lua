if vim.g.loaded_review then return end
vim.g.loaded_review = true

local cmd = vim.api.nvim_create_user_command

cmd("Review", function(o) require("review").start(o.args) end, {
    nargs = "?",
    desc = "Review the current branch against a base ref (merge-base)",
})
cmd("ReviewEnd", function() require("review").stop() end, { desc = "End the review session" })
cmd("ReviewFiles", function() require("review").files() end, { desc = "Changed files -> quickfix" })
cmd("ReviewComments", function(o) require("review").list(o.args) end, {
    nargs = "?",
    complete = function() return { "comment", "question" } end,
    desc = "Review comments -> quickfix",
})
cmd("ReviewNotes", function() require("review").notes() end, { desc = "Open the review notes file" })
cmd("ReviewView", function(o)
    local arg = o.args
    if arg == "" then return require("review").toggle_view() end
    if arg == "close" then return require("review").close_view() end
    if arg == "next" then return require("review").cycle_mode() end
    if arg == "inline" then return require("review").toggle_inline() end
    local layout, mode = arg:match("^(inline)%s+(%w+)$")
    if layout then return require("review").inline(mode) end
    require("review").view(arg)
end, {
    nargs = "?",
    complete = function() return { "git", "difft", "inline", "next", "close" } end,
    desc = "Side-by-side diff view against the review base",
})

local group = vim.api.nvim_create_augroup("review", { clear = true })

-- Comments are drawn on any repo file that has some.
vim.api.nvim_create_autocmd("BufReadPost", {
    group = group,
    callback = function(a) require("review.comments").render(a.buf) end,
})

-- Hand edits to the notes file are picked up on save.
vim.api.nvim_create_autocmd("BufWritePost", {
    group = group,
    pattern = "*.md",
    callback = function(a)
        local c = require("review.util").ctx()
        if c and vim.uv.fs_realpath(a.match) == vim.uv.fs_realpath(c.notes) then
            require("review.comments").reload()
        end
    end,
})
