return {
    "mfussenegger/nvim-jdtls",
    ft = "java",
    config = function()
        local on_attach = function(client, bufnr)
            require("lspconfig").on_attach(client, bufnr)
        end

        local cmp_lsp = require("cmp_nvim_lsp")
        local capabilities = vim.tbl_deep_extend(
            "force",
            {},
            vim.lsp.protocol.make_client_capabilities(),
            cmp_lsp.default_capabilities()
        )
        local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t")
        -- calculate workspace dir
        local workspace_dir = vim.fn.stdpath "data" .. "/site/java/workspace-root/" .. project_name
        -- get the mason install path
        local install_path = require("mason-registry").get_package("jdtls"):get_install_path()
        -- get the debug adapter install path
        local debug_install_path = require("mason-registry").get_package("java-debug-adapter"):get_install_path()
        local bundles = {
            vim.fn.glob(debug_install_path .. "/extension/server/com.microsoft.java.debug.plugin-*.jar", 1),
        }

        -- Comment out these lines if you have 'java-test' installed
        -- local java_test_path = require("mason-registry").get_package("java-test"):get_install_path()
        -- vim.list_extend(bundles, vim.split(vim.fn.glob(java_test_path .. "/extension/server/*.jar", 1), "\n"))

        local config = {
            cmd = {
                install_path .. "/bin/jdtls",
                "--jvm-arg=-javaagent:" .. install_path .. "/lombok.jar",
                "-Declipse.application=org.eclipse.jdt.ls.core.id1",
                "-Dosgi.bundles.defaultStartLevel=4",
                "-Declipse.product=org.eclipse.jdt.ls.core.product",
                "-Dlog.protocol=true",
                "-Dlog.level=ALL",
                "-Xms1g",
                "--add-modules=ALL-SYSTEM",
                "--add-opens",
                "java.base/java.util=ALL-UNNAMED",
                "--add-opens",
                "java.base/java.lang=ALL-UNNAMED",
                "-data",
                workspace_dir,
            },
            --on_attach = on_attach,
            capabilities = capabilities,
            root_dir = vim.fs.dirname(
                vim.fs.find({ ".gradlew", ".git", "mvnw", "pom.xml", "build.gradle" }, { upward = true })[1]
            ),

            settings = {
                java = {
                    signatureHelp = { enabled = true },
                    configuration = {
                        runtimes = {
                            {
                                name="JavaSE-21",
                                path=os.getenv("JAVA_HOME"),
                                default=true,
                            }
                        },
                    },
                    project = {
                        sourcePaths = { "src/main" },
                        referencedLibraries = {
                            '**/lib/*.jar',
                            'lib/**/*.jar',
                        }
                    }
                },
            },

            init_options = {
                bundles = bundles,
            },
        }
        vim.api.nvim_create_autocmd("FileType", {
            pattern = "java",
            callback = function()
                require("jdtls").start_or_attach(config)
            end,
        })
    end,
}
