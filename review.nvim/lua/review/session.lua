-- A review session: the merge-base of HEAD with a base ref, applied to gitsigns
-- (when installed) and used by the changed-files list and the diff view.

local util = require("review.util")
local comments = require("review.comments")

local M = {}

M.base = nil -- merge-base sha while a review is active

--- The ref shown to the user ("develop"), or nil.
function M.base_ref()
    return comments.base_ref
end

--- Revision the view diffs against: the merge-base, or HEAD outside a review.
function M.rev()
    return M.base or "HEAD"
end

local function gitsigns()
    local ok, gs = pcall(require, "gitsigns")
    return ok and gs or nil
end

function M.start(ref)
    util.reset_ctx() -- pick up branch switches
    local c = comments.load(true)
    if not c then return util.notify("not in a git repository", vim.log.levels.WARN) end
    ref = (ref and ref ~= "") and ref or comments.base_ref or require("review.config").get().default_base
    local mb, err = util.git({ "merge-base", ref, "HEAD" }, c.root)
    if not mb then
        return util.notify(err ~= "" and err or ("no merge-base with " .. ref), vim.log.levels.ERROR)
    end

    comments.base_ref, M.base = ref, mb
    vim.g.review_base = mb
    local gs = gitsigns()
    if gs then gs.change_base(mb, true) end
    comments.save() -- remembers the base ref in the notes header
    comments.render_all()
    require("review.view").refresh()
    M.files()
end

function M.stop()
    local gs = gitsigns()
    if gs then gs.reset_base(true) end
    M.base, vim.g.review_base = nil, nil
    require("review.view").refresh()
    local c = util.ctx()
    util.notify("review ended" .. (c and ("; comments kept in " .. c.notes) or ""))
end

local function test_key(p)
    local k = p:gsub("/__tests__/", "/")
        :gsub("%.test%.", ".")
        :gsub("%.spec%.", ".")
        :gsub("_test%.", ".")
        :gsub("_spec%.", ".")
    return k, k ~= p
end

--- Changed files vs the merge-base into the quickfix list, sorted by path with
--- tests right after their source file; each entry jumps to the first hunk.
function M.files()
    local c = util.ctx()
    if not c or not M.base then
        return util.notify("no active review, run :Review [base]", vim.log.levels.WARN)
    end

    local first_hunk, cur = {}, nil
    local diff = util.git({ "diff", "-U0", "--no-renames", "--diff-filter=d", "--no-color", M.base, "HEAD" }, c.root) or ""
    for l in vim.gsplit(diff, "\n", { plain = true }) do
        local f = l:match("^%+%+%+ b/(.*)$")
        if f then
            cur = f
        elseif cur and not first_hunk[cur] then
            local n = l:match("^@@ %-%S+ %+(%d+)")
            if n then first_hunk[cur] = math.max(1, tonumber(n)) end
        end
    end

    local items = {}
    local stat = util.git({ "diff", "--numstat", "--no-renames", "--diff-filter=d", M.base, "HEAD" }, c.root) or ""
    for l in vim.gsplit(stat, "\n", { plain = true }) do
        local add, del, f = l:match("^(%S+)\t(%S+)\t(.+)$")
        if f then
            local key, is_test = test_key(f)
            table.insert(items, {
                filename = c.root .. "/" .. f,
                lnum = first_hunk[f] or 1,
                text = ("+%s -%s"):format(add, del),
                user_data = { key = key, is_test = is_test, path = f },
            })
        end
    end
    table.sort(items, function(a, b)
        local x, y = a.user_data, b.user_data
        if x.key ~= y.key then return x.key < y.key end
        if x.is_test ~= y.is_test then return not x.is_test end
        return x.path < y.path
    end)

    vim.fn.setqflist({}, " ", {
        title = ("Review: %s vs %s (%d files)"):format(c.branch, M.base_ref(), #items),
        items = items,
    })
    util.open_qf()
end

return M
