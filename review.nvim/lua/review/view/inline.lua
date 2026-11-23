-- Inline (unified) layout: one window, your real buffer. Lines added since the
-- review base are highlighted; deleted lines are shown in place as virtual
-- lines (with their old line number in the gutter). Changed parts of lines
-- are emphasized:
--   git   : vim.text.diff with your 'diffopt' algorithm/linematch, plus the
--           differing middle of each modified line pair
--   difft : difftastic's alignment and changed tokens
--
-- Like the split layout it is bound to a window and follows the buffers shown in it.

local util = require("review.util")
local config = require("review.config")
local difft = require("review.view.difft")

local M = {}

local ns = vim.api.nvim_create_namespace("review.inline")
local group = vim.api.nvim_create_augroup("review.inline", { clear = true })

local I -- { win, buf, rel, mode, base, saved_winbar, timer }

function M.is_open()
    return I ~= nil
end

function M.mode()
    return I and I.mode
end

local function available(mode)
    if mode == "git" then return true end
    if mode == "difft" then return difft.available() end
    return false
end

-- hunks --------------------------------------------------------------------------------
-- { old = {1-based lnums}, new = {1-based lnums}, anchor = new line after which
--   a pure deletion goes (0 = top), old_tok / new_tok = { [lnum] = {{s, e}, ...} } }

local function diffopt_algorithm()
    for _, item in ipairs(vim.opt.diffopt:get()) do
        local a = item:match("^algorithm:(%w+)")
        if a then return a end
    end
    return "myers"
end

local function diffopt_linematch()
    for _, item in ipairs(vim.opt.diffopt:get()) do
        local n = item:match("^linematch:(%d+)")
        if n then return tonumber(n) end
    end
end

-- Byte ranges where two lines differ: after their common prefix and suffix,
-- ignoring indentation (a reindented line only shows what really changed).
local function middle(a, b)
    local ia, ib = #(a:match("^%s*")), #(b:match("^%s*"))
    local p = 0
    local max = math.min(#a - ia, #b - ib)
    while p < max and a:byte(ia + p + 1) == b:byte(ib + p + 1) do p = p + 1 end
    local s = 0
    while s < max - p and a:byte(#a - s) == b:byte(#b - s) do s = s + 1 end
    return { ia + p, #a - s }, { ib + p, #b - s }
end

local function git_hunks(old, new)
    local function join(lines) return #lines == 0 and "" or table.concat(lines, "\n") .. "\n" end
    local indices = vim.text.diff(join(old), join(new), {
        result_type = "indices",
        algorithm = diffopt_algorithm(),
        indent_heuristic = true,
        linematch = diffopt_linematch(),
    })
    local hunks = {}
    for _, h in ipairs(indices) do
        local sa, ca, sb, cb = h[1], h[2], h[3], h[4]
        local hunk = { old = {}, new = {}, anchor = sb, old_tok = {}, new_tok = {} }
        for i = sa, sa + ca - 1 do if ca > 0 then table.insert(hunk.old, i) end end
        for i = sb, sb + cb - 1 do if cb > 0 then table.insert(hunk.new, i) end end
        if ca == cb then
            for k = 1, ca do
                local o, n = hunk.old[k], hunk.new[k]
                local ro, rn = middle(old[o], new[n])
                if ro[2] > ro[1] then hunk.old_tok[o] = { ro } end
                if rn[2] > rn[1] then hunk.new_tok[n] = { rn } end
            end
        end
        table.insert(hunks, hunk)
    end
    return hunks
end

local function difft_hunks(old, new, name)
    local json = difft.diff_lines(old, new, name)
    local groups = json and difft.groups(json)
    if not groups then return git_hunks(old, new) end
    local tok = difft.tokens(json)
    local function ranges(changes)
        local r = {}
        for _, ch in ipairs(changes or {}) do table.insert(r, { ch.start, ch["end"] }) end
        return r
    end
    local hunks = {}
    for _, g in ipairs(groups) do
        local hunk = { old = {}, new = {}, anchor = g.pr + 1, old_tok = {}, new_tok = {} }
        for _, l in ipairs(g.ls) do
            table.insert(hunk.old, l + 1)
            hunk.old_tok[l + 1] = ranges(tok.lhs[l])
        end
        for _, r in ipairs(g.rs) do
            table.insert(hunk.new, r + 1)
            hunk.new_tok[r + 1] = ranges(tok.rhs[r])
        end
        table.insert(hunks, hunk)
    end
    return hunks
end

-- rendering ------------------------------------------------------------------------------

-- Expand tabs relative to the display column `col`.
local function expand(s, col, ts)
    local out = {}
    for ch in s:gmatch("[^\t]*\t?") do
        if ch == "" then break end
        if ch:sub(-1) == "\t" then
            local text = ch:sub(1, -2)
            col = col + vim.fn.strdisplaywidth(text)
            local n = ts - (col % ts)
            table.insert(out, text .. string.rep(" ", n))
            col = col + n
        else
            table.insert(out, ch)
            col = col + vim.fn.strdisplaywidth(ch)
        end
    end
    return table.concat(out), col
end

local function virt_line(text, lnum, toks, textoff, width, ts)
    local chunks = {}
    if textoff > 0 then
        table.insert(chunks, { ("%" .. (textoff - 1) .. "d "):format(lnum):sub(-textoff), "ReviewInlineDeleteNr" })
    end
    -- split the line at token boundaries
    local marks = {}
    for _, t in ipairs(toks or {}) do table.insert(marks, t) end
    table.sort(marks, function(a, b) return a[1] < b[1] end)
    local col, pos = 0, 0
    local function push(s, hl)
        if s == "" then return end
        local e
        e, col = expand(s, col, ts)
        table.insert(chunks, { e, hl })
    end
    for _, t in ipairs(marks) do
        local s, e = math.max(t[1], pos), math.min(t[2], #text)
        if e > s then
            push(text:sub(pos + 1, s), "ReviewInlineDelete")
            push(text:sub(s + 1, e), "ReviewInlineDeleteText")
            pos = e
        end
    end
    push(text:sub(pos + 1), "ReviewInlineDelete")
    if width > col then table.insert(chunks, { string.rep(" ", width - col), "ReviewInlineDelete" }) end
    return chunks
end

local function render()
    if not I or not vim.api.nvim_buf_is_valid(I.buf) then return end
    local buf = I.buf
    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
    if not I.base then return end

    local new = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local hunks = I.mode == "difft" and difft_hunks(I.base, new, vim.fs.basename(I.rel)) or git_hunks(I.base, new)

    local info = vim.api.nvim_win_is_valid(I.win) and vim.fn.getwininfo(I.win)[1]
    local textoff = info and info.textoff or 0
    local width = (info and info.width or vim.o.columns) - textoff
    local ts = vim.bo[buf].tabstop
    local n = #new
    local top = 0

    for _, h in ipairs(hunks) do
        for _, l in ipairs(h.new) do
            pcall(vim.api.nvim_buf_set_extmark, buf, ns, l - 1, 0, { line_hl_group = "ReviewInlineAdd", priority = 50 })
            for _, t in ipairs(h.new_tok[l] or {}) do
                pcall(vim.api.nvim_buf_set_extmark, buf, ns, l - 1, t[1], {
                    end_col = t[2], hl_group = "ReviewInlineAddText", priority = 200,
                })
            end
        end
        if #h.old > 0 then
            local lines = {}
            for _, o in ipairs(h.old) do
                table.insert(lines, virt_line(I.base[o] or "", o, h.old_tok[o], textoff, width, ts))
            end
            local row, above
            if #h.new > 0 then
                row, above = h.new[1] - 1, true
            elseif h.anchor >= 1 then
                row, above = math.min(h.anchor, n) - 1, false
            else
                row, above = 0, true
            end
            pcall(vim.api.nvim_buf_set_extmark, buf, ns, math.max(row, 0), 0, {
                virt_lines = lines, virt_lines_above = above, virt_lines_leftcol = true,
            })
            if row <= 0 and above then top = top + #lines end
        end
    end

    -- Lines deleted at the very top hang above line 1: scroll them into view.
    if top > 0 and info and info.topline == 1 then
        vim.api.nvim_win_call(I.win, function() vim.fn.winrestview({ topfill = top }) end)
    end
end

local function schedule_render()
    if not I then return end
    I.timer = I.timer or vim.uv.new_timer()
    I.timer:stop()
    I.timer:start(150, 0, vim.schedule_wrap(render))
end

local function winbar()
    if not (I and vim.api.nvim_win_is_valid(I.win)) then return end
    local session = require("review.session")
    local label = (session.base_ref() and session.base) and session.base_ref() or "HEAD"
    local parts = {}
    for _, name in ipairs(config.get().view.modes) do
        if available(name) then
            local hl = name == I.mode and "ReviewModeActive" or "ReviewMode"
            table.insert(parts, ("%%#%s# %s %%*"):format(hl, name))
        end
    end
    local path = (label .. ":" .. I.rel .. " (inline)"):gsub("%%", "%%%%")
    vim.api.nvim_set_option_value("winbar", " " .. path .. "%=" .. table.concat(parts, " ") .. " ",
        { win = I.win, scope = "local" })
end

local function load_base()
    local session = require("review.session")
    I.base = util.git_show(session.rev(), I.rel, util.ctx().root) or {}
end

-- attach to a buffer: base content, re-render on edits
local function attach(buf)
    if I.buf and vim.api.nvim_buf_is_valid(I.buf) then
        vim.api.nvim_buf_clear_namespace(I.buf, ns, 0, -1)
    end
    vim.api.nvim_clear_autocmds({ group = group, event = { "TextChanged", "TextChangedI" } })
    I.buf = buf
    load_base()
    vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
        group = group, buffer = buf, callback = schedule_render,
    })
    winbar()
    render()
end

function M.close()
    if not I then return end
    local i = I
    I = nil
    vim.api.nvim_clear_autocmds({ group = group })
    if i.timer then i.timer:stop(); i.timer:close() end
    if vim.api.nvim_buf_is_valid(i.buf) then vim.api.nvim_buf_clear_namespace(i.buf, ns, 0, -1) end
    if vim.api.nvim_win_is_valid(i.win) then
        vim.api.nvim_set_option_value("winbar", i.saved_winbar, { win = i.win, scope = "local" })
    end
end

function M.open(mode)
    mode = mode or config.get().view.default_mode
    if not available(mode) then mode = "git" end
    local win, buf = vim.api.nvim_get_current_win(), vim.api.nvim_get_current_buf()
    local rel = util.relpath(buf)
    if not rel then
        return util.notify("buffer is not a file in this repository", vim.log.levels.WARN)
    end
    M.close()
    I = {
        win = win, rel = rel, mode = mode,
        saved_winbar = vim.api.nvim_get_option_value("winbar", { win = win, scope = "local" }),
    }
    attach(buf)

    vim.api.nvim_create_autocmd("BufWinEnter", {
        group = group,
        callback = function(a)
            if not I or vim.api.nvim_get_current_win() ~= I.win or a.buf == I.buf then return end
            local r = util.relpath(a.buf)
            if not r then return M.close() end
            I.rel = r
            attach(a.buf)
        end,
    })
    vim.api.nvim_create_autocmd("WinClosed", {
        group = group, pattern = tostring(win), callback = function() vim.schedule(M.close) end,
    })
    vim.api.nvim_create_autocmd("WinResized", { group = group, callback = schedule_render })
end

function M.set_mode(mode)
    if not I or not available(mode) or I.mode == mode then return end
    I.mode = mode
    winbar()
    render()
end

function M.cycle()
    if not I then return end
    local modes = config.get().view.modes
    local idx = 1
    for i, name in ipairs(modes) do
        if name == I.mode then idx = i end
    end
    for step = 1, #modes do
        local name = modes[(idx - 1 + step) % #modes + 1]
        if available(name) then return M.set_mode(name) end
    end
end

--- Reload the base (after the review base changed).
function M.refresh()
    if not I then return end
    load_base()
    winbar()
    render()
end

return M
