-- difftastic mode. Optional: if `difft` is missing or too old to output JSON
-- with aligned lines, the mode is simply unavailable.
--
-- Side-by-side layout: while the mode is on, 'diffexpr' points at
-- M.diffexpr(): Neovim hands it the two sides as temp files, we run
-- `difft --display json`, and turn its `aligned_lines` into the ed-style diff
-- Neovim expects. Neovim's diff mode then keeps doing filler lines,
-- scrollbind, ]c / [c and do / dp. The tokens difftastic marks as changed are
-- highlighted with extmarks on top.
--
-- Inline layout: uses M.diff_lines() + M.groups() + M.tokens() directly.

local M = {}

local ns = vim.api.nvim_create_namespace("review.difft")
local EXPR = "v:lua.require'review.view.difft'.diffexpr()"

local available
local saved_diffexpr
local tmpdir

local function null(v)
    return v == nil or v == vim.NIL
end

local function run(a, b)
    local res = vim.system({ "difft", "--display", "json", "--color", "never", a, b }, {
        env = { DFT_UNSTABLE = "yes" },
        text = true,
    }):wait()
    if res.code ~= 0 and (res.stdout or "") == "" then return nil end
    local ok, json = pcall(vim.json.decode, res.stdout)
    if not ok or type(json) ~= "table" then return nil end
    return json
end

function M.available()
    if available == nil then
        available = false
        if vim.fn.executable("difft") == 1 then
            local dir = vim.fn.tempname()
            vim.fn.mkdir(dir, "p")
            vim.fn.writefile({ "a" }, dir .. "/a.txt")
            vim.fn.writefile({ "b" }, dir .. "/b.txt")
            local json = run(dir .. "/a.txt", dir .. "/b.txt")
            available = json ~= nil and json.aligned_lines ~= nil
            vim.fn.delete(dir, "rf")
        end
    end
    return available
end

-- difftastic picks the language from the file name, so both sides are copied
-- (or written) under the reviewed file's name.
local function side_paths(name)
    tmpdir = tmpdir or vim.fn.tempname()
    vim.fn.mkdir(tmpdir .. "/a", "p")
    vim.fn.mkdir(tmpdir .. "/b", "p")
    return tmpdir .. "/a/" .. name, tmpdir .. "/b/" .. name
end

--- Run difftastic on two lists of lines. Returns the JSON table or nil.
function M.diff_lines(old, new, name)
    local pa, pb = side_paths(name)
    vim.fn.writefile(old, pa)
    vim.fn.writefile(new, pb)
    return run(pa, pb)
end

-- JSON helpers ---------------------------------------------------------------------------

--- Changed tokens per side: { lhs = { [0-based line] = changes }, rhs = {...} }.
function M.tokens(json)
    local t = { lhs = {}, rhs = {} }
    for _, chunk in ipairs(null(json.chunks) and {} or json.chunks) do
        for _, line in ipairs(chunk) do
            for _, key in ipairs({ "lhs", "rhs" }) do
                local l = line[key]
                if not null(l) then t[key][l.line_number] = l.changes or {} end
            end
        end
    end
    return t
end

--- Hunks from `aligned_lines`: { ls = {0-based old lines}, rs = {0-based new
--- lines}, pl, pr = last unchanged pair before the hunk (-1 at the top) }.
--- nil when difftastic gave no alignment.
function M.groups(json)
    if null(json.aligned_lines) then
        if json.status == "unchanged" then return {} end
        return nil
    end
    local tok = M.tokens(json)
    local groups = {}
    local pl, pr = -1, -1
    local ls, rs = {}, {}
    local function flush()
        if #ls > 0 or #rs > 0 then table.insert(groups, { ls = ls, rs = rs, pl = pl, pr = pr }) end
        ls, rs = {}, {}
    end
    for _, pair in ipairs(json.aligned_lines) do
        local l, r = pair[1], pair[2]
        l, r = (not null(l)) and l or nil, (not null(r)) and r or nil
        if l and r and not tok.lhs[l] and not tok.rhs[r] then
            flush()
            pl, pr = l, r
        else
            if l then table.insert(ls, l) end
            if r then table.insert(rs, r) end
        end
    end
    flush()
    return groups
end

local function range(a, b)
    return a == b and tostring(a) or (a .. "," .. b)
end

--- difft JSON -> ed-style diff ("3c3", "5a6,7", "8,9d7"), or nil.
function M.to_ed(json)
    local groups = M.groups(json)
    if not groups then return nil end
    local out = {}
    for _, g in ipairs(groups) do
        local ls, rs = g.ls, g.rs
        if #ls == 0 then
            table.insert(out, ("%da%s"):format(g.pl + 1, range(rs[1] + 1, rs[#rs] + 1)))
        elseif #rs == 0 then
            table.insert(out, ("%sd%d"):format(range(ls[1] + 1, ls[#ls] + 1), g.pr + 1))
        else
            table.insert(out, ("%sc%s"):format(range(ls[1] + 1, ls[#ls] + 1), range(rs[1] + 1, rs[#rs] + 1)))
        end
    end
    return out
end

-- side-by-side layout --------------------------------------------------------------------

local function highlight(v, json)
    for _, buf in ipairs({ v.base_buf, v.src_buf }) do
        if vim.api.nvim_buf_is_valid(buf) then vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1) end
    end
    local tok = M.tokens(json)
    local sides = { lhs = { v.base_buf, "ReviewDifftDelete" }, rhs = { v.src_buf, "ReviewDifftAdd" } }
    for key, side in pairs(sides) do
        if vim.api.nvim_buf_is_valid(side[1]) then
            for lnum, changes in pairs(tok[key]) do
                for _, ch in ipairs(changes) do
                    pcall(vim.api.nvim_buf_set_extmark, side[1], ns, lnum, ch.start, {
                        end_col = ch["end"],
                        hl_group = side[2],
                        priority = 200,
                    })
                end
            end
        end
    end
end

local function plain_diff(a, b, out)
    local res = vim.system({ "diff", "-a", "--", a, b }, { text = true }):wait()
    vim.fn.writefile(vim.split(res.stdout or "", "\n", { plain = true }), out)
end

function M.diffexpr()
    local a, b, out = vim.v.fname_in, vim.v.fname_new, vim.v.fname_out
    local v = require("review.view").state()

    local pa, pb = side_paths(v and vim.fs.basename(v.rel) or "file.txt")
    local ok = vim.uv.fs_copyfile(a, pa) and vim.uv.fs_copyfile(b, pb)

    local json = ok and run(pa, pb)
    local ed = json and M.to_ed(json)
    if not ed then return plain_diff(a, b, out) end
    vim.fn.writefile(ed, out)

    if v and v.mode == "difft" then
        vim.schedule(function()
            local cur = require("review.view").state()
            if cur and cur.mode == "difft" then highlight(cur, json) end
        end)
    end
end

function M.enable(v)
    if vim.o.diffexpr ~= EXPR then saved_diffexpr = vim.o.diffexpr end
    vim.o.diffexpr = EXPR
    -- difftastic's token highlights replace Neovim's character-level ones
    for _, win in ipairs({ v.base_win, v.src_win }) do
        if vim.api.nvim_win_is_valid(win) then
            vim.api.nvim_set_option_value("winhighlight", "DiffText:DiffChange", { win = win, scope = "local" })
        end
    end
end

function M.disable(v)
    if vim.o.diffexpr == EXPR then vim.o.diffexpr = saved_diffexpr or "" end
    for _, buf in ipairs({ v.base_buf, v.src_buf }) do
        if vim.api.nvim_buf_is_valid(buf) then vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1) end
    end
    for _, win in ipairs({ v.base_win, v.src_win }) do
        if vim.api.nvim_win_is_valid(win) then
            local restore = win == v.src_win and v.saved.winhighlight or ""
            vim.api.nvim_set_option_value("winhighlight", restore, { win = win, scope = "local" })
        end
    end
end

return M
