local M = {}

function M.check()
    local h = vim.health
    h.start("review.nvim")

    if vim.fn.has("nvim-0.11") == 1 then h.ok("Neovim " .. tostring(vim.version())) else h.error("Neovim >= 0.11 required") end

    if vim.fn.executable("git") == 1 then h.ok("git found") else h.error("git not found") end

    local c = require("review.util").ctx()
    if c then
        h.ok(("repository %s, branch %s"):format(c.root, c.branch))
        h.info("notes file: " .. c.notes)
    else
        h.info("cwd is not inside a git repository")
    end

    if pcall(require, "gitsigns") then
        h.ok("gitsigns.nvim found: signs and hunk actions follow the review base")
    else
        h.info("gitsigns.nvim not found (optional): no gutter signs against the review base")
    end

    if vim.fn.executable("difft") == 0 then
        h.info("difftastic not found (optional): the difft view mode is disabled")
    elseif require("review.view.difft").available() then
        h.ok("difftastic found: difft view mode enabled (" .. vim.trim(vim.fn.system({ "difft", "--version" })):match("^[^\n]*") .. ")")
    else
        h.warn("difftastic found but its JSON output lacks aligned_lines; the difft view mode is disabled",
            { "Upgrade difftastic to a recent release" })
    end
end

return M
