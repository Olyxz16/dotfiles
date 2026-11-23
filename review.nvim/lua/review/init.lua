local config = require("review.config")

local M = {}

local function highlights()
    local set = function(name, link) vim.api.nvim_set_hl(0, name, { link = link, default = true }) end
    set("ReviewCommentSign", "DiagnosticSignInfo")
    set("ReviewCommentText", "DiagnosticVirtualTextInfo")
    set("ReviewQuestionSign", "DiagnosticSignWarn")
    set("ReviewQuestionText", "DiagnosticVirtualTextWarn")
    set("ReviewDifftAdd", "DiffText")
    set("ReviewDifftDelete", "DiffText")
    set("ReviewInlineAdd", "DiffAdd")
    set("ReviewInlineAddText", "DiffText")
    set("ReviewInlineDelete", "DiffDelete")
    set("ReviewInlineDeleteText", "DiffText")
    set("ReviewInlineDeleteNr", "DiffDelete")
    set("ReviewMode", "Comment")
    set("ReviewModeActive", "PmenuSel")
end

highlights()
vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("review.highlights", { clear = true }),
    callback = highlights,
})

-- Public API
function M.start(base) require("review.session").start(base) end
function M.stop() require("review.session").stop() end
function M.files() require("review.session").files() end
function M.comment(kind, s, e) require("review.comments").comment(kind, s, e) end
function M.delete() require("review.comments").delete() end
function M.list(kind) require("review.comments").list(kind) end
function M.notes() require("review.comments").open_notes() end
function M.view(mode) require("review.view").open(mode) end
function M.toggle_view() require("review.view").toggle() end
function M.toggle_inline() require("review.view").toggle_inline() end
function M.inline(mode) require("review.view").open_inline(mode) end
function M.toggle_view_mode(mode) require("review.view").toggle_mode(mode) end
function M.cycle_mode() require("review.view").cycle() end
function M.close_view() require("review.view").close_all() end

local function keymaps(km)
    if not km then return end
    local function map(mode, name, rhs, desc)
        if km[name] then vim.keymap.set(mode, km[name], rhs, { desc = "Review: " .. desc }) end
    end
    local function visual(kind)
        return function()
            local s, e = vim.fn.line("v"), vim.fn.line(".")
            vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "nx", false)
            M.comment(kind, s, e)
        end
    end
    map("n", "comment", function() M.comment("comment") end, "comment")
    map("x", "comment", visual("comment"), "comment on range")
    map("n", "question", function() M.comment("question") end, "question")
    map("x", "question", visual("question"), "question on range")
    map("n", "delete", M.delete, "delete comment")
    map("n", "list", function() M.list() end, "list comments")
    map("n", "files", M.files, "changed files")
    map("n", "notes", M.notes, "open notes file")
    map("n", "view", M.toggle_view, "toggle side-by-side view")
    map("n", "inline", M.toggle_inline, "toggle inline view")
    map("n", "view_difft", function() M.toggle_view_mode("difft") end, "toggle difftastic mode")
    map("n", "cycle_mode", M.cycle_mode, "next diff view mode")
end

function M.setup(opts)
    local c = config.set(opts)
    keymaps(c.keymaps)
end

return M
