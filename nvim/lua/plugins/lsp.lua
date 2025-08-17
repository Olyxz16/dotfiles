return {
    "neovim/nvim-lspconfig",
    dependencies = {
        "williamboman/mason.nvim",
        "williamboman/mason-lspconfig.nvim",
        "hrsh7th/cmp-nvim-lsp",
        "hrsh7th/nvim-cmp"
    },

    config = function()
        local cmd = require("cmp")
        local cmp_lsp = require("cmp_nvim_lsp")
        local capabilities = vim.tbl_deep_extend(
            "force",
            {},
            vim.lsp.protocol.make_client_capabilities(),
            cmp_lsp.default_capabilities()
        )

        vim.keymap.set("n", "K", vim.lsp.buf.hover, {})
        vim.keymap.set("n", "<leader>gd", vim.lsp.buf.definition, {})
        vim.keymap.set("n", "<leader>gr", vim.lsp.buf.references, {})
        vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, {})

        local lspconfig = require("lspconfig")
        local templConf = { capabilities = capabilities, filetypes = { "html", "templ" } }
        require("mason").setup()
        require("mason-lspconfig").setup({
            handlers = {
                function(server_name)
                    lspconfig[server_name].setup {
                        capabilities = capabilities
                    }
                end,
                ["clangd"] = function()
                    local includeDir = vim.fn.getcwd() .. '/include'
                    lspconfig.clangd.setup {
                        capabilities = capabilities,
                        cmd={ 'clangd' },
                        init_options = {
                            fallbackFlags = { '-I'..includeDir }
                        }
                    }
                end,
                ["cssls"] = function()
                    lspconfig.cssls.setup {
                        capabilities = capabilities,
                        settings = { css = { valid = true,
                            lint = { unknowAtRules = "ignore", }, }, },
                    }
                end,
                ["tailwindcss"] = function()
                    lspconfig.tailwindcss.setup {
                        capabilities = capabilities,
                        filetype = { "css", "templ", "astro", "javascript", "typescript", "html" },
                        init_options = { userLanguages = { templ = { "html" } } },
                    }
                end,
                ["volar"] = function()
                    lspconfig.volar.setup {
                        capabilities = capabilities,
                        filetypes = { 'typescript', 'javascript', 'vue' },
                        init_options = {
                            vue = {
                                hybridMode = false,
                            }
                        }
                    }
                end,
                ["html"] = function()
                    lspconfig.html.setup(templConf)
                end,
                ["htmx"] = function()
                    lspconfig.htmx.setup(templConf)
                end,
                ["jdtls"] = function()
                end,
            },
        })
    end,
}
