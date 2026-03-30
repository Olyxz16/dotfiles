return {
    {
        "williamboman/mason.nvim",
        config = function()
            require("mason").setup()
        end,
    },
    {
        "neovim/nvim-lspconfig",
        dependencies = {
            "williamboman/mason.nvim",
            "hrsh7th/cmp-nvim-lsp",
        },
        config = function()
            local capabilities = require("cmp_nvim_lsp").default_capabilities()

            -- Define each server's config directly.
            -- vim.lsp.config sets the config; vim.lsp.enable activates it.
            -- 0.12: servers auto-attach when their filetype is opened.

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
                capabilities = capabilities,
            })

            vim.lsp.config("html", {
                filetypes = { "html", "templ" },
                capabilities = capabilities,
            })

            vim.lsp.config("cssls", {
                filetypes = { "css", "scss", "less" },
                settings = { css = { lint = { unknownAtRules = "ignore" } } },
                capabilities = capabilities,
            })

            vim.lsp.config("tailwindcss", {
                filetypes = { "css", "templ", "astro", "javascript", "typescript", "html" },
                init_options = { userLanguages = { templ = "html" } },
                capabilities = capabilities,
            })

            -- Enable all configured servers
            vim.lsp.enable({ "clangd", "html", "cssls", "tailwindcss" })

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
                end,
            })
        end,
    },
}
