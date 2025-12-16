return {
    "neovim/nvim-lspconfig",
    dependencies = {
        "williamboman/mason.nvim",
        "williamboman/mason-lspconfig.nvim",
        "hrsh7th/cmp-nvim-lsp",
        "hrsh7th/nvim-cmp"
    },
    config = function()
        require("mason").setup()
        require("mason-lspconfig").setup({
            ensure_installed = { "cssls", "html", "tailwindcss" },
            automatic_installation = true,
        })

        local capabilities = require("cmp_nvim_lsp").default_capabilities()

        local function get_raw_config(server_name)
            local ok, config = pcall(require, "lspconfig.server_configurations." .. server_name)
            if ok then return config.default_config end
            return {} -- Return empty table instead of erroring
        end

        local function get_clangd_config()
            local includeDir = vim.fn.getcwd() .. '/include'
            return {
                cmd = { 
                    "clangd", 
                    "--background-index", 
                    "--clang-tidy",
                    "--query-driver=**/*gcc*,**/*g++*" 
                },
                -- Explicitly set filetypes so we don't depend on the plugin
                filetypes = { "c", "cpp", "objc", "objcpp", "cuda", "proto" },
                init_options = { fallbackFlags = { '-I'..includeDir } },
                on_new_config = function(new_config, new_root_dir)
                    local build_file = new_root_dir .. "/build/compile_commands.json"
                    if vim.loop.fs_stat(build_file) then
                        local found = false
                        for _, v in ipairs(new_config.cmd) do
                            if v == "--compile-commands-dir=build" then found = true; break end
                        end
                        if not found then
                            table.insert(new_config.cmd, "--compile-commands-dir=build")
                        end
                    end
                end
            }
        end

        local servers = {
            clangd = get_clangd_config(),
            
            html = { 
                filetypes = { "html", "templ" } 
            },
            
            cssls = { 
                filetypes = { "css", "scss", "less" },
                settings = { css = { lint = { unknowAtRules = "ignore" } } } 
            },
            
            tailwindcss = {
                filetypes = { "css", "templ", "astro", "javascript", "typescript", "html" },
                init_options = { userLanguages = { templ = { "html" } } },
            },
            
        }

        for name, user_opts in pairs(servers) do
            local defaults = get_raw_config(name)
            
            local final_config = vim.tbl_deep_extend("force", defaults, user_opts)
            final_config.capabilities = vim.tbl_deep_extend("force", final_config.capabilities or {}, capabilities)

            vim.lsp.config[name] = final_config

            local filetypes = user_opts.filetypes or defaults.filetypes
            
            if filetypes then
                vim.api.nvim_create_autocmd("FileType", {
                    pattern = filetypes,
                    callback = function(args)
                        vim.lsp.enable(name)
                    end,
                })
            end
        end

        vim.api.nvim_create_autocmd("LspAttach", {
            callback = function(args)
                local opts = { buffer = args.buf }
                vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
                vim.keymap.set("n", "<leader>gd", vim.lsp.buf.definition, opts)
                vim.keymap.set("n", "<leader>gr", vim.lsp.buf.references, opts)
                vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
            end,
        })
    end,
}
