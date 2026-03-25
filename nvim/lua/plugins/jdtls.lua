return {
    "mfussenegger/nvim-jdtls",
    dependencies = {
        "williamboman/mason.nvim",
        "hrsh7th/cmp-nvim-lsp",
    },
    ft = "java",
    config = function()
        local cmp_lsp = require("cmp_nvim_lsp")
        local capabilities = vim.tbl_deep_extend(
            "force",
            {},
            vim.lsp.protocol.make_client_capabilities(),
            cmp_lsp.default_capabilities()
        )

        -- Java 21+ is required to run jdtls itself (separate from project JDK)
        local java_21_home = os.getenv("JAVA_21_HOME")
        if not java_21_home then
            vim.notify("JAVA_21_HOME not set. jdtls requires Java 21+", vim.log.levels.WARN)
            return
        end

        -- Mason share paths
        local mason_share = vim.fn.stdpath("data") .. "/mason/share"
        local jdtls_dir = mason_share .. "/jdtls"
        local launcher_jar = jdtls_dir .. "/plugins/org.eclipse.equinox.launcher.jar"
        local config_dir = jdtls_dir .. "/config"
        local lombok_jar = jdtls_dir .. "/lombok.jar"

        if not vim.uv.fs_stat(launcher_jar) then
            vim.notify("jdtls not installed. Run :MasonInstall jdtls", vim.log.levels.WARN)
            return
        end

        -- Debug adapter bundles (computed once, reused across buffers)
        local bundles = {}
        local debug_jar_dir = mason_share .. "/java-debug-adapter"
        if vim.uv.fs_stat(debug_jar_dir) then
            local debug_jars = vim.fn.glob(debug_jar_dir .. "/com.microsoft.java.debug.plugin-*.jar", false, true)
            vim.list_extend(bundles, debug_jars)
        end
        local test_jar_dir = mason_share .. "/java-test"
        if vim.uv.fs_stat(test_jar_dir) then
            local test_jars = vim.fn.glob(test_jar_dir .. "/*.jar", false, true)
            vim.list_extend(bundles, test_jars)
        end

        --- Build a jdtls config for the given buffer, computing root_dir and
        --- workspace from the buffer's file path (not cwd).
        local function make_config(bufnr)
            local fname = vim.api.nvim_buf_get_name(bufnr)

            local root_dir = vim.fs.dirname(
                vim.fs.find(
                    { "gradlew", ".git", "mvnw", "pom.xml", "build.gradle", ".classpath" },
                    { path = fname, upward = true }
                )[1]
            )

            local project_name = root_dir and vim.fn.fnamemodify(root_dir, ":t") or "fallback"
            local workspace_dir = vim.fn.stdpath("cache") .. "/jdtls/" .. project_name .. "/workspace"

            return {
                cmd = {
                    java_21_home .. "/bin/java",

                    "-Declipse.application=org.eclipse.jdt.ls.core.id1",
                    "-Dosgi.bundles.defaultStartLevel=4",
                    "-Declipse.product=org.eclipse.jdt.ls.core.product",
                    "-Dlog.protocol=true",
                    "-Dlog.level=ALL",
                    "-Xms1g",
                    "--add-modules=ALL-SYSTEM",
                    "--add-opens", "java.base/java.util=ALL-UNNAMED",
                    "--add-opens", "java.base/java.lang=ALL-UNNAMED",
                    "-javaagent:" .. lombok_jar,

                    "-jar", launcher_jar,
                    "-configuration", config_dir,
                    "-data", workspace_dir,
                },
                capabilities = capabilities,
                root_dir = root_dir,

                settings = {
                    java = {
                        signatureHelp = { enabled = true },
                        configuration = {
                            runtimes = {
                                {
                                    name = "JavaSE-21",
                                    path = java_21_home,
                                    default = true,
                                },
                                {
                                    name = "JavaSE-1.8",
                                    path = os.getenv("JAVA_HOME"),
                                },
                            },
                        },
                    },
                },

                init_options = {
                    bundles = bundles,
                },
            }
        end

        --- Safely start/attach jdtls only on real Java file buffers.
        local function attach_jdtls(bufnr)
            bufnr = bufnr or vim.api.nvim_get_current_buf()
            -- Guard: only attach to named file buffers to avoid sending bare
            -- "file://" URIs to jdtls (which causes URISyntaxException).
            local fname = vim.api.nvim_buf_get_name(bufnr)
            if fname == "" then
                return
            end
            require("jdtls").start_or_attach(make_config(bufnr))
        end

        -- Attach to the current buffer immediately (the one that triggered ft=java loading)
        attach_jdtls()

        -- Register autocmd for future Java buffers
        vim.api.nvim_create_autocmd("FileType", {
            pattern = "java",
            callback = function(args)
                attach_jdtls(args.buf)
            end,
        })

        -- Re-attach after LspRestart
        vim.api.nvim_create_autocmd("LspDetach", {
            pattern = "*.java",
            callback = function(args)
                local client = vim.lsp.get_client_by_id(args.data.client_id)
                if client and client.name == "jdtls" then
                    vim.defer_fn(function()
                        if vim.api.nvim_buf_is_valid(args.buf) then
                            attach_jdtls(args.buf)
                        end
                    end, 100)
                end
            end,
        })
    end,
}
