return {
  "b0o/blender.nvim",
  config = function()
    require("blender").setup()
  end,
  dependencies = {
    "MunifTanjim/nui.nvim",
    "grapp-dev/nui-components.nvim",
    "mfussenegger/nvim-dap", -- Optional, for debugging with DAP
    "LiadOz/nvim-dap-repl-highlights", -- Optional, for syntax highlighting in the DAP REPL
  },
}
