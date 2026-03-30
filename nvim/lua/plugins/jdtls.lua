return {
    "mfussenegger/nvim-jdtls",
    dependencies = { "williamboman/mason.nvim" },
    ft = "java",
    config = function()
        local capabilities = require("cmp_nvim_lsp").default_capabilities()

        local install_path = require("mason-registry").get_package("jdtls"):get_install_path()
        local debug_install_path = require("mason-registry").get_package("java-debug-adapter"):get_install_path()

        local bundles = {
            vim.fn.glob(
                debug_install_path .. "/extension/server/com.microsoft.java.debug.plugin-*.jar",
                true
            ),
        }

        local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t")
        local workspace_dir = vim.fn.stdpath("data") .. "/site/java/workspace-root/" .. project_name

        local jdtls_config = {
            cmd = {
                install_path .. "/bin/jdtls",
                "--jvm-arg=-javaagent:" .. install_path .. "/lombok.jar",
                "-data", workspace_dir,
            },
            capabilities = capabilities,
            root_dir = vim.fs.dirname(
                vim.fs.find(
                    { ".gradlew", ".git", "mvnw", "pom.xml", "build.gradle", ".classpath" },
                    { upward = true }
                )[1]
            ),
            settings = {
                java = {
                    signatureHelp = { enabled = true },
                    configuration = {
                        runtimes = {
                            {
                                name = "JavaSE-21",
                                path = os.getenv("JAVA_HOME"),
                                default = true,
                            },
                        },
                    },
                    project = {
                        sourcePaths = { "src/main" },
                        referencedLibraries = { "**/lib/*.jar", "lib/**/*.jar" },
                    },
                },
            },
            init_options = {
                bundles = bundles,
            },
        }

        -- nvim-jdtls recommends attaching via FileType, which is correct —
        -- but the autocmd must live here, after jdtls_config is defined.
        vim.api.nvim_create_autocmd("FileType", {
            pattern = "java",
            callback = function()
                require("jdtls").start_or_attach(jdtls_config)
            end,
        })
    end,
}
