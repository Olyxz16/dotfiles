return {
    {
        "williamboman/mason.nvim",
        config = function()
            require("mason").setup()
        end,
    },
    {
        "neovim/nvim-lspconfig",
        event = { "BufReadPre", "BufNewFile" },
        dependencies = {
            "williamboman/mason.nvim",
        },
        config = function()
            vim.lsp.config("clangd", {
                cmd = {
                    "clangd",
                    "--background-index",
                    "--clang-tidy",
                    "--query-driver=**/*gcc*,**/*g++*",
                },
                filetypes = { "c", "cpp", "objc", "objcpp", "cuda", "proto" },
                init_options = {
                    fallbackFlags = { "-I" .. vim.fn.getcwd() .. "/include" },
                },
            })

            vim.lsp.config("html", {
                filetypes = { "html", "templ" },
            })

            vim.lsp.config("cssls", {
                filetypes = { "css", "scss", "less" },
                settings = { css = { lint = { unknownAtRules = "ignore" } } },
            })

            vim.lsp.config("tailwindcss", {
                filetypes = { "css", "templ", "astro", "javascript", "typescript", "html" },
                init_options = { userLanguages = { templ = "html" } },
            })

            vim.lsp.config("jdtls", {
                cmd = { "jdtls" },
                root_markers = { ".git", "mvnw", "pom.xml", "build.gradle", ".classpath" },
                filetypes = { "java" },
            })

            -- Enable all configured servers
            vim.lsp.enable({ "clangd", "html", "cssls", "tailwindcss", "jdtls" })

            vim.api.nvim_create_autocmd("LspAttach", {
                callback = function(args)
                    local opts = { buffer = args.buf }
                    vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
                    vim.keymap.set("n", "<leader>gd", vim.lsp.buf.definition, opts)
                    vim.keymap.set("n", "<leader>gr", vim.lsp.buf.references, opts)
                    vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
                    vim.keymap.set("n", "<leader>gf", function()
                        vim.lsp.buf.format({ async = true })
                    end, opts)

                    vim.lsp.completion.enable(ture, args.client.id, args.buf, { autotrigger = true })
                end,
            })
        end,
    },
}
