-- The review view: the file at the review base (left, read-only scratch buffer)
-- next to the real buffer (right), using Neovim's diff mode. How lines are
-- aligned and what gets highlighted depends on the mode:
--   git   : Neovim's own diff (your 'diffopt': histogram, linematch, ...)
--   difft : difftastic's structural alignment + changed-token highlights
--
-- Only one view at a time. It follows the right window: open another file
-- there (e.g. :cnext) and the left side switches to that file's base version.

local util = require("review.util")
local config = require("review.config")

local M = {}

M.modes = {
    git = require("review.view.git"),
    difft = require("review.view.difft"),
}

local inline = require("review.view.inline")

local V -- { src_win, src_buf, base_win, base_buf, rel, mode, saved }
local group = vim.api.nvim_create_augroup("review.view", { clear = true })

function M.state()
    return V
end

local function available(mode)
    local m = M.modes[mode]
    return m ~= nil and m.available()
end

local function set_local(win, name, value)
    vim.api.nvim_set_option_value(name, value, { win = win, scope = "local" })
end

local function get_local(win, name)
    return vim.api.nvim_get_option_value(name, { win = win, scope = "local" })
end

-- Filler lines (the side with no counterpart) are left blank instead of "-".
local function blank_filler(win)
    local fc = get_local(win, "fillchars")
    set_local(win, "fillchars", (fc ~= "" and fc .. "," or "") .. "diff: ")
end

local function winbar()
    if not (V and vim.api.nvim_win_is_valid(V.base_win)) then return end
    local session = require("review.session")
    local label = (session.base_ref() and session.base) and session.base_ref() or "HEAD"
    local parts = {}
    for _, name in ipairs(config.get().view.modes) do
        if available(name) then
            local hl = name == V.mode and "ReviewModeActive" or "ReviewMode"
            table.insert(parts, ("%%#%s# %s %%*"):format(hl, name))
        end
    end
    local rel = V.rel:gsub("%%", "%%%%")
    vim.wo[V.base_win].winbar = " " .. label:gsub("%%", "%%%%") .. ":" .. rel .. "%=" .. table.concat(parts, " ") .. " "
    -- Both sides need a winbar, or the right one starts a line higher.
    if vim.api.nvim_win_is_valid(V.src_win) then
        set_local(V.src_win, "winbar", " working tree:" .. rel)
    end
end

local function load_base()
    local session = require("review.session")
    local c = util.ctx()
    local lines = util.git_show(session.rev(), V.rel, c.root) or {}
    local buf = V.base_buf
    vim.bo[buf].modifiable = true
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].modifiable = false
    vim.bo[buf].modified = false
    pcall(vim.api.nvim_buf_set_name, buf, ("review://%s/%s"):format(session.rev():sub(1, 12), V.rel))
    local ft = vim.bo[V.src_buf].filetype
    if vim.bo[buf].filetype ~= ft then vim.bo[buf].filetype = ft end
end

local function diffupdate()
    if V and vim.api.nvim_win_is_valid(V.src_win) then
        vim.api.nvim_win_call(V.src_win, function() vim.cmd("diffupdate") end)
    end
end

local function teardown()
    local v = V
    if not v then return end
    V = nil
    vim.api.nvim_clear_autocmds({ group = group })
    pcall(M.modes[v.mode].disable, v)
    vim.schedule(function()
        if vim.api.nvim_win_is_valid(v.src_win) then
            vim.api.nvim_win_call(v.src_win, function() vim.cmd("diffoff") end)
            for name, value in pairs(v.saved) do pcall(set_local, v.src_win, name, value) end
        end
    end)
end

function M.close()
    if not V then return end
    local win = V.base_win
    teardown()
    if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
end

local function set_mode(mode)
    if V.mode == mode then return end
    if V.mode then M.modes[V.mode].disable(V) end
    V.mode = mode
    M.modes[mode].enable(V)
    winbar()
    diffupdate()
end

-- The right window now shows another buffer: follow it.
local function retarget(buf)
    local rel = util.relpath(buf)
    if not rel then return M.close() end
    if V.mode then M.modes[V.mode].disable(V) end
    V.src_buf, V.rel = buf, rel
    load_base()
    -- The previous buffer stays in the diff once hidden: reset the tab's diff
    -- and add both sides again, base first (see create()).
    vim.api.nvim_win_call(V.src_win, function() vim.cmd("diffoff!") end)
    vim.api.nvim_win_call(V.base_win, function() vim.cmd("diffthis") end)
    vim.api.nvim_win_call(V.src_win, function() vim.cmd("diffthis") end)
    M.modes[V.mode].enable(V)
    winbar()
    diffupdate()
end

local function create(mode)
    local src_win, src_buf = vim.api.nvim_get_current_win(), vim.api.nvim_get_current_buf()
    local rel = util.relpath(src_buf)
    if not rel then
        return util.notify("buffer is not a file in this repository", vim.log.levels.WARN)
    end

    vim.cmd("leftabove vnew")
    local base_win, base_buf = vim.api.nvim_get_current_win(), vim.api.nvim_get_current_buf()
    vim.bo[base_buf].buftype = "nofile"
    vim.bo[base_buf].bufhidden = "wipe"
    vim.bo[base_buf].swapfile = false

    V = {
        src_win = src_win, src_buf = src_buf, base_win = base_win, base_buf = base_buf, rel = rel,
        saved = {
            fillchars = get_local(src_win, "fillchars"),
            winhighlight = get_local(src_win, "winhighlight"),
            winbar = get_local(src_win, "winbar"),
        },
    }
    load_base()

    -- The left side must enter diff mode first: it is then the "original" that
    -- 'diffexpr' receives as v:fname_in.
    vim.cmd("diffthis")
    vim.api.nvim_win_call(src_win, function() vim.cmd("diffthis") end)
    blank_filler(base_win)
    blank_filler(src_win)
    vim.keymap.set("n", "q", M.close, { buffer = base_buf, nowait = true, desc = "Close review view" })

    vim.api.nvim_create_autocmd("BufWipeout", { group = group, buffer = base_buf, callback = teardown })
    vim.api.nvim_create_autocmd("WinClosed", {
        group = group,
        pattern = tostring(src_win),
        callback = function() vim.schedule(M.close) end,
    })
    vim.api.nvim_create_autocmd("BufWinEnter", {
        group = group,
        callback = function(a)
            if V and vim.api.nvim_get_current_win() == V.src_win and a.buf ~= V.src_buf then
                retarget(a.buf)
            end
        end,
    })

    vim.api.nvim_set_current_win(src_win)
    set_mode(mode)
end

--- Open the side-by-side view in `mode` (or switch the open view to it). A
--- mode that isn't available (e.g. difft not installed) is silently ignored.
function M.open(mode)
    if inline.is_open() then
        mode = mode or inline.mode()
        inline.close()
    end
    mode = mode or (V and V.mode) or config.get().view.default_mode
    if not available(mode) then
        if V then return end
        mode = "git"
    end
    if V and vim.api.nvim_win_is_valid(V.base_win) then
        if vim.api.nvim_get_current_win() ~= V.base_win and vim.api.nvim_get_current_buf() ~= V.src_buf then
            -- invoked from another window: move the view there
            M.close()
            return vim.schedule(function() create(mode) end)
        end
        return set_mode(mode)
    end
    create(mode)
end

--- Open the inline layout (switching from side-by-side if needed).
function M.open_inline(mode)
    if not V then return inline.open(mode) end
    mode = mode or V.mode
    local win = V.src_win
    M.close()
    -- after the split's teardown (scheduled) has restored the window
    vim.schedule(function()
        if vim.api.nvim_win_is_valid(win) then vim.api.nvim_set_current_win(win) end
        inline.open(mode)
    end)
end

--- Side-by-side: close if open, otherwise open (switching from inline).
function M.toggle()
    if V then return M.close() end
    M.open()
end

--- Inline: close if open, otherwise open (switching from side-by-side).
function M.toggle_inline()
    if inline.is_open() then return inline.close() end
    M.open_inline()
end

--- Show `mode` in the current layout (side-by-side if none is open); if that
--- mode is already shown, close the layout.
function M.toggle_mode(mode)
    if not available(mode) then return end
    if inline.is_open() then
        if inline.mode() == mode then return inline.close() end
        return inline.set_mode(mode)
    end
    if V and V.mode == mode then return M.close() end
    M.open(mode)
end

--- Next available mode in the current layout (opens side-by-side if none).
function M.cycle()
    if inline.is_open() then return inline.cycle() end
    if not V then return M.open() end
    local modes = config.get().view.modes
    local idx = 1
    for i, name in ipairs(modes) do
        if name == V.mode then idx = i end
    end
    for step = 1, #modes do
        local name = modes[(idx - 1 + step) % #modes + 1]
        if available(name) then return set_mode(name) end
    end
end

--- Close whichever layout is open.
function M.close_all()
    inline.close()
    M.close()
end

--- Reload the base side (after the review base changed).
function M.refresh()
    inline.refresh()
    if not V then return end
    load_base()
    winbar()
    diffupdate()
end

return M
