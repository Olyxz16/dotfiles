local M = {}

function M.notify(msg, level)
    vim.notify("review: " .. msg, level or vim.log.levels.INFO)
end

--- Run git synchronously. Returns trimmed stdout, or nil + stderr on failure.
function M.git(args, cwd)
    local cmd = { "git" }
    vim.list_extend(cmd, args)
    local res = vim.system(cmd, { cwd = cwd, text = true }):wait()
    if res.code ~= 0 then return nil, vim.trim(res.stderr or "") end
    return vim.trim(res.stdout or "")
end

--- File content at a revision as a list of lines (untrimmed); nil if absent.
function M.git_show(rev, rel, cwd)
    local res = vim.system({ "git", "show", rev .. ":" .. rel }, { cwd = cwd, text = true }):wait()
    if res.code ~= 0 then return nil end
    local lines = vim.split(res.stdout, "\n", { plain = true })
    if lines[#lines] == "" then table.remove(lines) end
    return lines
end

-- Repo context, cached for the session (false = not in a repo).
local ctx_cache

function M.reset_ctx()
    ctx_cache = nil
end

--- { root, branch, notes } for the repo of the cwd, or nil.
function M.ctx()
    if ctx_cache ~= nil then return ctx_cache or nil end
    local root = M.git({ "rev-parse", "--show-toplevel" })
    local common = root and M.git({ "rev-parse", "--path-format=absolute", "--git-common-dir" })
    if not root or not common then
        ctx_cache = false
        return nil
    end
    local branch = M.git({ "branch", "--show-current" })
    if not branch or branch == "" then
        branch = "detached-" .. (M.git({ "rev-parse", "--short", "HEAD" }) or "unknown")
    end
    local dir = require("review.config").get().notes_dir or (common .. "/review")
    ctx_cache = {
        root = vim.uv.fs_realpath(root) or root,
        branch = branch,
        notes = dir .. "/" .. branch:gsub("[^%w%._-]", "_") .. ".md",
    }
    return ctx_cache
end

--- Path of a buffer relative to the repo root, or nil if it isn't a repo file.
function M.relpath(buf)
    local c = M.ctx()
    buf = buf == 0 and vim.api.nvim_get_current_buf() or buf
    local name = vim.api.nvim_buf_get_name(buf)
    if not c or name == "" or vim.bo[buf].buftype ~= "" then return nil end
    local real = vim.uv.fs_realpath(name) or vim.fn.fnamemodify(name, ":p")
    if real:sub(1, #c.root + 1) ~= c.root .. "/" then return nil end
    return real:sub(#c.root + 2)
end

function M.open_qf()
    local open = require("review.config").get().open_qf
    if type(open) == "function" then open() else vim.cmd(open) end
end

return M
