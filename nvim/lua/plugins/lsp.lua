return {
    "neovim/nvim-lspconfig",
    dependencies = {
        "williamboman/mason.nvim",
        "williamboman/mason-lspconfig.nvim",
        "hrsh7th/cmp-nvim-lsp",
        "hrsh7th/nvim-cmp",
        { "imroc/kubeschema.nvim", opts = {} },
    },
    config = function()
        require("mason").setup()
        require("mason-lspconfig").setup({
            ensure_installed = { "cssls", "html", "tailwindcss", "lua_ls" },
            automatic_installation = true,
        })

        local capabilities = require("cmp_nvim_lsp").default_capabilities()

        -- Clangd --
        -- Build the clangd cmd: if build/compile_commands.json exists, add --compile-commands-dir=build
        local clangd_cmd = {
            "clangd",
            "--background-index",
            "--clang-tidy",
            "--query-driver=**/*gcc*,**/*g++*",
        }
        local build_ccjson = vim.fn.getcwd() .. "/build/compile_commands.json"
        if vim.uv.fs_stat(build_ccjson) then
            table.insert(clangd_cmd, "--compile-commands-dir=build")
        end

        vim.lsp.config.clangd = {
            cmd = clangd_cmd,
            filetypes = { "c", "cpp", "objc", "objcpp", "cuda", "proto" },
            root_markers = { "compile_commands.json", "compile_flags.txt", ".clangd", ".git" },
            init_options = {
                fallbackFlags = { '-I' .. vim.fn.getcwd() .. '/include' },
            },
            capabilities = capabilities,
        }

        -- HTML --
        vim.lsp.config.html = {
            filetypes = { "html", "templ" },
            root_markers = { "package.json", ".git" },
            capabilities = capabilities,
        }

        -- CSS --
        vim.lsp.config.cssls = {
            filetypes = { "css", "scss", "less" },
            root_markers = { "package.json", ".git" },
            settings = {
                css = { lint = { unknownAtRules = "ignore" } },
            },
            capabilities = capabilities,
        }

        -- Tailwind CSS --
        vim.lsp.config.tailwindcss = {
            filetypes = { "css", "templ", "astro", "javascript", "typescript", "html" },
            root_markers = { "tailwind.config.js", "tailwind.config.ts", "package.json", ".git" },
            init_options = { userLanguages = { templ = "html" } },
            capabilities = capabilities,
        }

        -- YAML (with kubeschema for Kubernetes support) --
        vim.lsp.config.yamlls = {
            filetypes = { "yaml", "yaml.docker-compose" },
            root_markers = { ".git" },
            capabilities = vim.tbl_deep_extend("force", capabilities, {
                workspace = { didChangeConfiguration = { dynamicRegistration = true } },
            }),
            on_attach = require("kubeschema").on_attach,
            on_new_config = function(new_config)
                new_config.settings.yaml = vim.tbl_deep_extend("force", new_config.settings.yaml or {}, {
                    validate = true,
                    hover = true,
                    completion = true,
                    schemaStore = { enable = false, url = "" },
                })
            end,
        }

        -- Lua LS (for Neovim config development) --
        vim.lsp.config.lua_ls = {
            filetypes = { "lua" },
            root_markers = { ".luarc.json", ".luarc.jsonc", ".git" },
            settings = {
                Lua = {
                    runtime = { version = "LuaJIT" },
                    diagnostics = { globals = { "vim" } },
                    workspace = {
                        library = { vim.env.VIMRUNTIME },
                        checkThirdParty = false,
                    },
                    telemetry = { enable = false },
                },
            },
            capabilities = capabilities,
        }

        -- Enable all configured servers
        vim.lsp.enable({ 'clangd', 'html', 'cssls', 'tailwindcss', 'lua_ls', 'yamlls' })

        -- Disable auto-discovered jdtls (nvim-jdtls ships lsp/jdtls.lua which Neovim
        -- 0.11 picks up automatically). We manage jdtls ourselves via start_or_attach.
        vim.lsp.enable('jdtls', false)

        -- LSP keymaps on attach
        -- Note: 0.11 provides defaults for K (hover), grr (references), gra (code_action),
        -- grn (rename), gri (implementation). We keep format and definition keymaps.
        vim.api.nvim_create_autocmd("LspAttach", {
            callback = function(args)
                local opts = { buffer = args.buf }
                vim.keymap.set("n", "<leader>gd", vim.lsp.buf.definition, opts)
                vim.keymap.set("n", "<leader>gf", function()
                    vim.lsp.buf.format({ async = true })
                end, opts)
            end,
        })
    end,
}
