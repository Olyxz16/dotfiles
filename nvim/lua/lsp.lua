local M = {}

-- ============================================================
-- Add/remove servers here. Key = lspconfig/mason server name.
-- Leave the value as {} if you don't need custom config.
-- ============================================================
M.servers = {
  clangd = {
    cmd = { "clangd", "--background-index", "--clang-tidy", "--query-driver=**/*gcc*,**/*g++*" },
    filetypes = { "c", "cpp", "objc", "objcpp", "cuda", "proto" },
    init_options = { fallbackFlags = { "-I" .. vim.fn.getcwd() .. "/include" } },
  },

  html = {
    filetypes = { "html", "templ" },
  },

  cssls = {
    filetypes = { "css", "scss", "less" },
    settings = { css = { lint = { unknownAtRules = "ignore" } } },
  },

  tailwindcss = {
    filetypes = { "css", "templ", "astro", "javascript", "typescript", "html" },
    init_options = { userLanguages = { templ = "html" } },
  },

  jdtls = {
    cmd = { "jdtls", "--java-executable", (vim.env.JAVA_21_HOME or "/usr/lib/jvm/default") .. "/bin/java" },
    root_markers = { ".git", "mvnw", "pom.xml", "build.gradle", ".classpath" },
    filetypes = { "java" },
    settings = {
      java = {
        configuration = {
          runtimes = {
            { name = "JavaSE-1.8", path = vim.env.JAVA_8_HOME or "/usr/lib/jvm/default", default = true },
            { name = "JavaSE-21", path = vim.env.JAVA_21_HOME or "/usr/lib/jvm/default" },
          },
        },
      },
    },
  },

  csharp_ls = {
    filetypes = { "cs" },
  },

  svelte = {
    filetypes = { "svelte" },
    init_options = { configurationSection = { "css", "svelte" } },
  },

  ts_ls = {
    filetypes = {
      "typescript", "typescriptreact", "typescript.tsx",
      "javascript", "javascriptreact", "javascript.jsx",
    },
    settings = { completions = { completeFunctionCalls = true } },
  },

  gopls = {},
}

function M.setup()
  -- Custom filetype associations
  vim.filetype.add({
    extension = {
      axaml = "xml",
      svelte = "svelte",
    },
  })

  -- Register any custom config for each server with the native LSP client
  for name, cfg in pairs(M.servers) do
    if next(cfg) ~= nil then
      vim.lsp.config(name, cfg)
    end
  end

  -- mason-lspconfig bridges mason.nvim <-> vim.lsp:
  --  * ensure_installed  -> installs any of these servers that are missing
  --  * automatic_enable  -> calls vim.lsp.enable() for every installed one,
  --                         which is what makes it attach automatically
  --                         when you open a matching filetype
  require("mason-lspconfig").setup({
    ensure_installed = vim.tbl_keys(M.servers),
    automatic_enable = true,
  })

  -- Buffer-local setup once a server attaches
  vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
      local opts = { buffer = args.buf }
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      if not client then return end

      -- Detach LSP from non-file buffers (e.g., diffview, oil)
      local bufname = vim.api.nvim_buf_get_name(args.buf)
      if bufname:match("^%a+://") then
        vim.lsp.buf_detach_client(args.buf, client.id)
        return
      end

      -- Disable semantic tokens to avoid highlight conflicts
      client.server_capabilities.semanticTokensProvider = nil

      vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
      vim.keymap.set("n", "<leader>gd", vim.lsp.buf.definition, opts)
      vim.keymap.set("n", "<leader>gr", vim.lsp.buf.references, opts)
      vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
    end,
  })
end

return M
