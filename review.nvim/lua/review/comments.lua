-- Persistent review comments, stored per branch in a markdown notes file:
--
--   ## [question] src/foo.ts:42-45
--
--   ```ts
--   <the code the comment was written on>
--   ```
--
--   body...
--
-- [comment] = meant for the PR, [question] = open question for later.

local util = require("review.util")

local M = {}

local ns = vim.api.nvim_create_namespace("review.comments")

M.kinds = {
    comment = { sign = "C", sign_hl = "ReviewCommentSign", text_hl = "ReviewCommentText", qf = "I" },
    question = { sign = "?", sign_hl = "ReviewQuestionSign", text_hl = "ReviewQuestionText", qf = "W" },
}

M.entries = {}
M.base_ref = nil -- remembered in the notes header
local loaded_file

local function first_line(s)
    return s:match("^[^\n]*") or ""
end

-- (de)serialization ------------------------------------------------------------------

local function parse(path)
    local entries, base = {}, nil
    local f = io.open(path, "r")
    if not f then return entries, nil end
    local lines = vim.split(f:read("a"), "\n", { plain = true })
    f:close()

    local cur, in_code
    local function finish()
        if not cur then return end
        cur.body = vim.trim(table.concat(cur.body_lines, "\n"))
        cur.body_lines = nil
        table.insert(entries, cur)
    end

    for _, l in ipairs(lines) do
        local kind, file, s, e = l:match("^## %[(%a+)%] (.+):(%d+)%-?(%d*)%s*$")
        if kind and M.kinds[kind] then
            finish()
            s = tonumber(s)
            cur = { kind = kind, file = file, lnum = s, end_lnum = tonumber(e) or s, body_lines = {}, code = {} }
            in_code = nil
        elseif not cur then
            base = base or l:match("^# Review: .- vs (%S+)")
        elseif in_code == nil and l:match("^%s*$") then
            -- blank lines between heading and snippet
        elseif in_code == nil and l:match("^```") then
            in_code = true
            cur.lang = l:match("^```(%S*)")
        elseif in_code then
            if l:match("^```%s*$") then in_code = false else table.insert(cur.code, l) end
        else
            in_code = false
            table.insert(cur.body_lines, l)
        end
    end
    finish()
    return entries, (base ~= "?" and base or nil)
end

local function serialize(c)
    local out = {
        ("# Review: %s vs %s"):format(c.branch, M.base_ref or "?"),
        "",
        "<!-- [comment] = for the PR, [question] = open question for later.",
        "     Free to edit by hand; keep the `## [kind] path:line[-end]` headings. -->",
        "",
    }
    local sorted = vim.list_slice(M.entries)
    table.sort(sorted, function(a, b)
        if a.file ~= b.file then return a.file < b.file end
        return a.lnum < b.lnum
    end)
    for _, e in ipairs(sorted) do
        local range = e.end_lnum > e.lnum and (e.lnum .. "-" .. e.end_lnum) or tostring(e.lnum)
        table.insert(out, ("## [%s] %s:%s"):format(e.kind, e.file, range))
        table.insert(out, "")
        if e.code and #e.code > 0 then
            table.insert(out, "```" .. (e.lang or ""))
            vim.list_extend(out, e.code)
            table.insert(out, "```")
            table.insert(out, "")
        end
        vim.list_extend(out, vim.split(e.body, "\n", { plain = true }))
        table.insert(out, "")
    end
    return out
end

--- Load the notes file of the current branch (once). Returns the repo ctx.
function M.load(force)
    local c = util.ctx()
    if not c then return nil end
    if force or loaded_file ~= c.notes then
        M.entries, M.base_ref = parse(c.notes)
        loaded_file = c.notes
    end
    return c
end

-- Pull positions back from extmarks (they follow edits in the buffer).
local function sync_marks()
    for _, e in ipairs(M.entries) do
        local m = e.mark
        if m then
            local pos = vim.api.nvim_buf_is_loaded(m.buf)
                and vim.api.nvim_buf_get_extmark_by_id(m.buf, ns, m.id, { details = true })
            if pos and pos[1] then
                e.lnum = pos[1] + 1
                e.end_lnum = math.max(e.lnum, (pos[3].end_row or pos[1]) + 1)
            else
                e.mark = nil
            end
        end
    end
end

function M.save()
    local c = M.load()
    if not c then return end
    sync_marks()
    vim.fn.mkdir(vim.fs.dirname(c.notes), "p")
    vim.fn.writefile(serialize(c), c.notes)
    local nb = vim.fn.bufnr(c.notes)
    if nb ~= -1 and vim.api.nvim_buf_is_loaded(nb) and not vim.bo[nb].modified then
        vim.cmd("checktime " .. nb)
    end
end

-- rendering --------------------------------------------------------------------------

-- If the file changed since the comment was written, move it to the nearest
-- line matching the first line of its snippet.
local function relocate(e, buf)
    local anchor = e.code and e.code[1] and vim.trim(e.code[1])
    if not anchor or anchor == "" then return end
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    if lines[e.lnum] and vim.trim(lines[e.lnum]) == anchor then return end
    local best
    for i, l in ipairs(lines) do
        if vim.trim(l) == anchor and (not best or math.abs(i - e.lnum) < math.abs(best - e.lnum)) then
            best = i
        end
    end
    if best then
        local span = e.end_lnum - e.lnum
        e.lnum, e.end_lnum = best, best + span
    end
end

function M.render(buf)
    if not M.load() then return end
    local rel = util.relpath(buf)
    if not rel then return end
    sync_marks()
    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
    local n = vim.api.nvim_buf_line_count(buf)
    for _, e in ipairs(M.entries) do
        if e.file == rel then
            if not (e.mark and e.mark.buf == buf) then relocate(e, buf) end
            local k = M.kinds[e.kind]
            local ok, id = pcall(vim.api.nvim_buf_set_extmark, buf, ns, math.min(e.lnum, n) - 1, 0, {
                end_row = math.min(e.end_lnum, n) - 1,
                sign_text = k.sign,
                sign_hl_group = k.sign_hl,
                virt_text = { { " " .. k.sign .. " " .. first_line(e.body) .. " ", k.text_hl } },
                virt_text_pos = "eol",
            })
            e.mark = ok and { buf = buf, id = id } or nil
        end
    end
end

function M.render_all()
    for _, b in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(b) then M.render(b) end
    end
end

--- Re-read the notes file (after a hand edit) and redraw everything.
function M.reload()
    for _, b in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(b) then vim.api.nvim_buf_clear_namespace(b, ns, 0, -1) end
    end
    M.load(true)
    M.render_all()
end

-- editing ----------------------------------------------------------------------------

local function entry_at(rel, lnum)
    for i, e in ipairs(M.entries) do
        if e.file == rel and lnum >= e.lnum and lnum <= e.end_lnum then return e, i end
    end
end

local function open_editor(e, on_save)
    local buf = vim.api.nvim_create_buf(false, true)
    vim.bo[buf].buftype = "acwrite"
    vim.bo[buf].bufhidden = "wipe"
    vim.api.nvim_buf_set_name(buf, ("review://comment/%s:%d#%d"):format(e.file, e.lnum, buf))
    vim.bo[buf].filetype = "markdown"
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(e.body or "", "\n", { plain = true }))
    vim.bo[buf].modified = false

    local w = math.min(90, math.floor(vim.o.columns * 0.6))
    local h = 10
    local row = (vim.fn.screenrow() + h + 3 > vim.o.lines) and -(h + 2) or 1
    local win = vim.api.nvim_open_win(buf, true, {
        relative = "cursor", row = row, col = 0, width = w, height = h,
        border = "rounded", style = "minimal",
        title = (" %s · %s:%d "):format(e.kind, e.file, e.lnum), title_pos = "center",
        footer = " :w save · q cancel · empty = delete ", footer_pos = "center",
    })
    vim.wo[win].wrap = true

    local function close()
        if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
    end
    vim.api.nvim_create_autocmd("BufWriteCmd", {
        buffer = buf,
        callback = function()
            on_save(vim.trim(table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")))
            vim.bo[buf].modified = false
            vim.schedule(close)
        end,
    })
    vim.keymap.set("n", "q", close, { buffer = buf, nowait = true })
    if (e.body or "") == "" then vim.cmd.startinsert() end
end

--- Add or edit the comment at the cursor (or on lines s..en).
function M.comment(kind, s, en)
    if not M.load() then return util.notify("not in a git repository", vim.log.levels.WARN) end
    local buf = vim.api.nvim_get_current_buf()
    local rel = util.relpath(buf)
    if not rel then return util.notify("buffer is not a file in this repository", vim.log.levels.WARN) end
    sync_marks()

    s = s or vim.fn.line(".")
    en = en or s
    if s > en then s, en = en, s end

    local e = entry_at(rel, s)
    local is_new = e == nil
    if is_new then
        e = {
            kind = kind, file = rel, lnum = s, end_lnum = en, body = "",
            code = vim.api.nvim_buf_get_lines(buf, s - 1, en, false),
            lang = vim.fn.fnamemodify(rel, ":e"),
        }
    end

    open_editor(vim.tbl_extend("force", e, { kind = kind }), function(body)
        if body == "" then
            if not is_new then
                for i, x in ipairs(M.entries) do
                    if x == e then table.remove(M.entries, i) break end
                end
            end
        else
            e.body, e.kind = body, kind
            if is_new then table.insert(M.entries, e) end
        end
        M.save()
        M.render(buf)
    end)
end

function M.delete()
    if not M.load() then return end
    sync_marks()
    local rel = util.relpath(0)
    local e, i = rel and entry_at(rel, vim.fn.line("."))
    if not e then return util.notify("no review comment on this line") end
    table.remove(M.entries, i)
    M.save()
    M.render(vim.api.nvim_get_current_buf())
end

--- All comments (optionally of one kind) into the quickfix list.
function M.list(kind)
    local c = M.load()
    if not c then return end
    sync_marks()
    local items = {}
    for _, e in ipairs(M.entries) do
        if not kind or kind == "" or e.kind == kind then
            table.insert(items, {
                filename = c.root .. "/" .. e.file,
                lnum = e.lnum,
                end_lnum = e.end_lnum,
                type = M.kinds[e.kind].qf,
                text = ("[%s] %s"):format(e.kind, first_line(e.body)),
            })
        end
    end
    table.sort(items, function(a, b)
        if a.filename ~= b.filename then return a.filename < b.filename end
        return a.lnum < b.lnum
    end)
    vim.fn.setqflist({}, " ", { title = "Review comments (" .. c.branch .. ")", items = items })
    util.open_qf()
end

--- Open the notes file in a split and copy its path to the clipboard.
function M.open_notes()
    local c = M.load()
    if not c then return util.notify("not in a git repository", vim.log.levels.WARN) end
    if not vim.uv.fs_stat(c.notes) then M.save() end
    pcall(vim.fn.setreg, "+", c.notes)
    vim.cmd("botright split " .. vim.fn.fnameescape(c.notes))
    util.notify("notes path copied to clipboard: " .. c.notes)
end

return M
