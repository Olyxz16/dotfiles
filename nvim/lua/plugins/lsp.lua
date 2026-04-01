return {
    {
        "williamboman/mason.nvim",
        config = function()
            require("mason").setup()
        end,
    },
    {
        "neovim/nvim-lspconfig",
        event = { "BufReadPre", "BufNewFile" }, -- Lazy load LSP
        dependencies = {
            "williamboman/mason.nvim",
            "saghen/blink.cmp",
        },
        config = function()
            -- 1. Setup Java Paths (Reads from OS Environment Variables)
            local java_21 = vim.env.JAVA_21_HOME or "/usr/lib/jvm/default"
            local java_8  = vim.env.JAVA_8_HOME or "/usr/lib/jvm/default"

            -- 2. Configure Servers
            vim.lsp.config("clangd", {
                cmd = { "clangd", "--background-index", "--clang-tidy", "--query-driver=**/*gcc*,**/*g++*" },
                filetypes = { "c", "cpp", "objc", "objcpp", "cuda", "proto" },
                init_options = { fallbackFlags = { "-I" .. vim.fn.getcwd() .. "/include" } },
            })

            vim.lsp.config("html", { filetypes = { "html", "templ" } })

            vim.lsp.config("cssls", {
                filetypes = { "css", "scss", "less" },
                settings = { css = { lint = { unknownAtRules = "ignore" } } },
            })

            vim.lsp.config("tailwindcss", {
                filetypes = { "css", "templ", "astro", "javascript", "typescript", "html" },
                init_options = { userLanguages = { templ = "html" } },
            })

            vim.lsp.config("jdtls", {
                cmd = { "jdtls", "--java-executable", java_21 .. "/bin/java" },
                root_markers = { ".git", "mvnw", "pom.xml", "build.gradle", ".classpath" },
                filetypes = { "java" },
                settings = {
                    java = {
                        configuration = {
                            runtimes = {
                                { name = "JavaSE-1.8", path = java_8, default = true },
                                { name = "JavaSE-21", path = java_21 }
                            }
                        }
                    }
                }
            })

            -- 3. Enable Servers Natively
            vim.lsp.enable({ "clangd", "html", "cssls", "tailwindcss", "jdtls" })

            -- 4. Handle Attachments (Keymaps, Completion, Formatting)
            vim.api.nvim_create_autocmd("LspAttach", {
                callback = function(args)
                    local opts = { buffer = args.buf }
                    
                    -- FIX: Safely extract the client from args.data.client_id
                    local client = vim.lsp.get_client_by_id(args.data.client_id)
                    if not client then return end

                    -- Keymaps
                    vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
                    vim.keymap.set("n", "<leader>gd", vim.lsp.buf.definition, opts)
                    vim.keymap.set("n", "<leader>gr", vim.lsp.buf.references, opts)
                    vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
                    
                    -- Native Format on Save
                    if client:supports_method("textDocument/formatting") then
                        vim.api.nvim_create_autocmd("BufWritePre", {
                            buffer = args.buf,
                            callback = function()
                                vim.lsp.buf.format({ bufnr = args.buf, id = client.id })
                            end,
                        })
                    end
                end,
            })
        end,
    },
}
