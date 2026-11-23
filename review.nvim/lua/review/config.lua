local M = {}

M.defaults = {
    -- Ref to review against when :Review gets no argument and none is remembered.
    default_base = "develop",
    -- Where notes files go. nil = <git-common-dir>/review/<branch>.md
    notes_dir = nil,
    -- What opens a filled quickfix list: an Ex command or a function.
    open_qf = "botright copen",
    view = {
        -- Mode used by :ReviewView without argument: "git" or "difft".
        default_mode = "git",
        -- Mode order when cycling.
        modes = { "git", "difft" },
    },
    -- Set to false to define no keymaps, or override any entry (false disables it).
    keymaps = {
        comment = "<leader>rc",
        question = "<leader>rq",
        delete = "<leader>rx",
        list = "<leader>rl",
        files = "<leader>rf",
        notes = "<leader>rn",
        view = "<leader>rs",
        inline = "<leader>ri",
        view_difft = "<leader>rd",
        cycle_mode = "<leader>rm",
    },
}

local config = vim.deepcopy(M.defaults)

function M.get()
    return config
end

function M.set(opts)
    config = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), opts or {})
    -- lists are replaced, not merged
    if opts and opts.view and opts.view.modes then config.view.modes = opts.view.modes end
    return config
end

return M
