-- ~/.config/nvim/lua/plugins/core.lua
-- 常用插件配置

return {
    -- ======== 1. 视觉与界面增强 ========
    -- 配色主题
    {
        "folke/tokyonight.nvim",
        lazy = false,
        priority = 1000,
        opts = {
            style = "night",
            transparent = true,
        },
        config = function()
            -- require("tokyonight").setup(opts)
            vim.cmd([[colorscheme tokyonight]])
        end,
    },

    -- 透明插件（接管所有高亮组透明控制）
    {
        "xiyaowong/transparent.nvim",
        lazy = false,
        priority = 999,
        opts = {
            enable = true, -- 启动自动透明
            extra_groups = {
                "NormalFloat", "FloatBorder",
                "TelescopeNormal", "TelescopeBorder",
                "TelescopePromptNormal", "TelescopePromptBorder",
                "TelescopeResultsNormal", "TelescopePreviewNormal",
                "NvimTreeNormal", "NvimTreeNormalNC", "NvimTreeEndOfBuffer",
                "MasonNormal",
                "LspFloatWinNormal", "LspFloatWinBorder",
                "SignColumn",
                "DiagnosticSignError", "DiagnosticSignWarn",
                "DiagnosticSignInfo", "DiagnosticSignHint",
                "NvimTreeWinSeparator", "WinSeparator", "VertSplit",
                "CursorLine",
                "WhichKey", "WhichKeyBorder", "WhichKeyNormal", "WhichKeyFloat",
                "WhichKeyGroup", "WhichKeyDesc", "WhichKeySeparator", "WhichKeyValue",
                "WhichKeyTitle", "WhichKeyCursor",
                "Pmenu", "PmenuSel", "PmenuSbar", "PmenuThumb",
                "BlinkCmpMenu", "BlinkCmpMenuBorder",
                "BlinkCmpDoc", "BlinkCmpDocBorder",
                "BlinkCmpLabel", "BlinkCmpLabelDescription", "BlinkCmpLabelDetail",
                "BlinkCmpScrollBarThumb", "BlinkCmpScrollBarGutter",
                "BlinkCmpSource",
                "BlinkCmpSignatureHelp",
                "BlinkCmpSignatureHelpActiveParameter",
                "BlinkCmpSignatureHelpBorder",
                "BlinkCmpDocFrame",
                "BlinkCmpDocNormal",
                "ToggleTermNormal",
                "TabLine", "TabLineFill", "TabLineSel",
                -- nvim-notify 通知
                "NotifyBackground",
                "NotifyERRORBody", "NotifyWARNBody", "NotifyINFOBody",
                "NotifyDEBUGBody", "NotifyTRACEBody",
                "NotifyERRORBorder", "NotifyWARNBorder", "NotifyINFOBorder",
                "NotifyDEBUGBorder", "NotifyTRACEBorder",
                "NotifyERROR", "NotifyWARN", "NotifyINFO",
                "NotifyDEBUG", "NotifyTRACE",
                -- noice.nvim 命令行弹窗
                "NoiceCmdlinePopup", "NoiceCmdlinePopupBorder",
                "NoicePopup", "NoicePopupBorder",
                "NoicePopupmenu", "NoicePopupmenuBorder",
            },
        },
        config = function(_, opts)
            require("transparent").setup(opts)
        end,
    },

    {
        "nvim-lualine/lualine.nvim",
        event = "VeryLazy",
        dependencies = { "nvim-tree/nvim-web-devicons", lazy = true },
        config = function()
            local theme = require("lualine.themes.tokyonight")
            for _, mode in pairs(theme) do
                if type(mode) == "table" then
                    for _, section in pairs(mode) do
                        if type(section) == "table" and section.bg == "#1e2030" then
                            section.bg = "NONE"
                        end
                    end
                end
            end
            require("lualine").setup({
                options = { theme = theme },
                sections = {
                    lualine_c = { { "filename", path = 1 } }, -- 显示相对路径

                },
            })
        end,
    },

    -- 启动仪表板
    {
        "goolord/alpha-nvim",
        event = "VimEnter",
        enabled = true,
        init = false,
        opts = function()
            local dashboard = require("alpha.themes.dashboard")
            local logo = [[
      ██╗      █████╗ ███████╗██╗   ██╗██╗   ██╗██╗███╗   ███╗          Z
      ██║     ██╔══██╗╚══███╔╝╚██╗ ██╔╝██║   ██║██║████╗ ████║      Z
      ██║     ███████║  ███╔╝  ╚████╔╝ ██║   ██║██║██╔████╔██║   z
      ██║     ██╔══██║ ███╔╝    ╚██╔╝  ╚██╗ ██╔╝██║██║╚██╔╝██║ z
      ███████╗██║  ██║███████╗   ██║    ╚████╔╝ ██║██║ ╚═╝ ██║
      ╚══════╝╚═╝  ╚═╝╚══════╝   ╚═╝     ╚═══╝  ╚═╝╚═╝     ╚═╝
    ]]

            dashboard.section.header.val = vim.split(logo, "\n")
            -- stylua: ignore
            dashboard.section.buttons.val = {
                dashboard.button("f", " " .. " Find file", "<cmd>Telescope find_files<cr>"),
                dashboard.button("n", " " .. " New file", [[<cmd> ene <BAR> startinsert <cr>]]),
                dashboard.button("r", " " .. " Recent files", [[<cmd>Telescope oldfiles<cr>]]),
                dashboard.button("b", " " .. " Buffers", [[<cmd>Telescope buffers<cr>]]),
                dashboard.button("g", " " .. " Find text", [[<cmd>Telescope live_grep<cr>]]),
                dashboard.button("c", " " .. " Config", "<cmd>e ~/.config/nvim/init.lua<cr>"),
                dashboard.button("m", "󰏖 " .. " Mason", [[<cmd>Mason<cr>]]),
                dashboard.button("l", "󰒲 " .. " Lazy", "<cmd>Lazy<cr>"),
                dashboard.button("q", " " .. " Quit", "<cmd>qa<cr>"),
            }
            for _, button in ipairs(dashboard.section.buttons.val) do
                button.opts.hl = "AlphaButtons"
                button.opts.hl_shortcut = "AlphaShortcut"
            end
            dashboard.section.header.opts.hl = "AlphaHeader"
            dashboard.section.buttons.opts.hl = "AlphaButtons"
            dashboard.section.footer.opts.hl = "AlphaFooter"
            dashboard.opts.layout[1].val = 8
            return dashboard
        end,
        config = function(_, dashboard)
            -- close Lazy and re-open when the dashboard is ready
            if vim.o.filetype == "lazy" then
                vim.cmd.close()
                vim.api.nvim_create_autocmd("User", {
                    once = true,
                    pattern = "AlphaReady",
                    callback = function()
                        require("lazy").show()
                    end,
                })
            end

            require("alpha").setup(dashboard.opts)

            vim.api.nvim_create_autocmd("User", {
                once = true,
                pattern = "LazyVimStarted",
                callback = function()
                    local stats = require("lazy").stats()
                    local ms = (math.floor(stats.startuptime * 100 + 0.5) / 100)
                    dashboard.section.footer.val = "⚡ Neovim loaded "
                        .. stats.loaded
                        .. "/"
                        .. stats.count
                        .. " plugins in "
                        .. ms
                        .. "ms"
                    pcall(vim.cmd.AlphaRedraw)
                end,
            })
        end,
    },

    -- Buffer 标签栏（VSCode 风格）
    {
        "akinsho/bufferline.nvim",
        event = "VeryLazy",
        version = "*",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        opts = {
            options = {
                mode = "buffers",
                diagnostics = "nvim_lsp",
                offsets = {
                    { filetype = "NvimTree", text = "File Explorer", padding = 1 },
                },
                show_close_icon = false,
                separator_style = "thin",
                indicator = {
                    icon = "▎",
                    style = "underline",
                },
                -- 点击 ✕ / 右键关闭 buffer 时安全删除：
                -- 先把显示该 buffer 的窗口切换到其他 buffer，再删除，
                -- 避免 bdelete 把 nvim-tree 窗口挤掉
                close_command = function(buf)
                    require("config.bufops").close_buffer_safe(buf)
                end,
            },
        },
        config = function(_, opts)
            require("bufferline").setup(opts)
            -- 与透明主题配合：标签栏背景透明
            vim.api.nvim_set_hl(0, "BufferLineFill", { bg = "NONE" })
        end,
    },

    -- 缩进指示线
    {
        "lukas-reineke/indent-blankline.nvim",
        event = "VeryLazy",
        opts = {
            indent = { char = "│" },
            scope = { show_start = false },
        },
        main = "ibl",
    },

    -- Markdown 内联渲染（在 buffer 内直接渲染标题/代码块/列表等）
    -- 打开 .md 文件后无需任何操作，自动将 Markdown 语法渲染为美观的富文本显示
    -- 编辑时渲染实时更新，不影响源文件内容
    {
        "MeanderingProgrammer/render-markdown.nvim",
        -- 仅在打开 markdown / quarto 文件时加载
        ft = { "markdown", "quarto" },
        dependencies = {
            "nvim-tree/nvim-web-devicons", -- 语言/文件图标
        },
        opts = {
            -- ===== 渲染引擎 =====
            -- 默认使用 treesitter 解析 Markdown 语法树，精确渲染
            -- 如遇渲染问题可回退到 regex 模式
            -- parser = "mixed",  -- "tree-sitter" | "regex" | "mixed"

            -- ===== 标题渲染 =====
            heading = {
                -- 标题前显示图标（󰲡 󰲣 󰲥 󰲧 󰲩 󰲫）
                icons = { "󰲡", "󰲣", "󰲥", "󰲧", "󰲩", "󰲫" },
                -- 标题位置：左对齐（"overlay"）、行首（"icon"）、或与文本同位置
                position = "overlay",
                -- 标题行背景色高亮宽度
                -- "full" = 整行, "column" = 仅标题区域
                backgrounds = { "column", "column", "column", "column", "column", "column" },
                -- 标题左边框（竖线或圆点）
                left_pad = 2,
                right_pad = 2,
            },

            -- ===== 代码块渲染 =====
            code = {
                -- 代码块右上角显示语言名称（如 "lua", "python"）
                sign = true,
                -- 代码块左上角显示语言图标
                -- 需要 nvim-web-devicons 支持
                language_icon = true,
                -- 代码块背景色高亮
                highlight = "RenderMarkdownCode",
                -- 代码块左侧边框样式
                left_pad = 2,
                right_pad = 2,
                -- 代码块上方/下方空白行
                above = "▔",
                below = "▁",
                -- 禁用代码块的宽度限制（默认 0 = 不限制）
                width = "block", -- "block" | "full" | number
            },

            -- ===== 行内代码渲染 =====
            inline_code = {
                -- 行内代码使用 ` 包裹的文本高亮背景
                highlight = "RenderMarkdownCode",
            },

            -- ===== 列表符号 =====
            bullet = {
                -- 无序列表符号： - * + 分别映射为以下图标
                icons = { "●", "○", "◆" },
                -- 左侧内边距
                left_pad = 2,
                right_pad = 2,
            },

            -- ===== 复选框 =====
            checklist = {
                -- 未勾选 [ ] → 󰄱，已勾选 [x] → 󰱒
                unchecked = { icon = "󰄱", highlight = "RenderMarkdownUnchecked" },
                checked   = { icon = "󰱒", highlight = "RenderMarkdownChecked" },
                -- 复选框左侧内边距
                left_pad = 2,
                right_pad = 2,
            },

            -- ===== 引用块 =====
            quote = {
                -- 引用行左侧竖线颜色（跟随 tokyonight 配色）
                -- 设为空则使用默认高亮组
                icon = "▍",
                -- 左侧内边距
                left_pad = 2,
                right_pad = 2,
                -- 引用块是否重复图标行
                repeat_icon = false,
                -- 空引用行是否仍显示图标
                empty_line_icon = false,
            },

            -- ===== 表格渲染 =====
            pipe_table = {
                -- 表格对齐方式指示器（:--- | :--: | ---:）
                -- 渲染为对应方向的图标
                alignment_indicator = "▕",
                -- 表格左侧内边距
                left_pad = 2,
                right_pad = 2,
            },

            -- ===== LaTeX 数学公式 =====
            -- 需要安装 latex 相关工具，默认关闭
            -- latex = {
            --     enabled = false,
            -- },

            -- ===== 链接/图片渲染 =====
            link = {
                -- 超链接显示图标
                icon = "󰌹",
                -- 图片链接显示图标
                image_icon = "󰉋",
                -- 是否加下划线
                underline = true,
                -- 是否在链接后显示括号中的 URL
                -- show_url = false,
                -- 左侧内边距
                left_pad = 2,
                right_pad = 2,
            },

            -- ===== 分隔线 =====
            dash = {
                -- --- 分隔线渲染为图标
                icon = "─",
                -- 重复次数
                repeat_count = 3,
                -- 左侧内边距
                left_pad = 2,
                right_pad = 2,
            },

            -- ===== 折叠标记 =====
            fold = {
                -- 可折叠标题/列表的展开/收起图标
                enabled = true,
            },

            -- ===== 抗锯齿（性能相关） =====
            -- 使用双倍宽度的虚拟文本减少锯齿感
            anti_conceal = {
                enabled = true,
            },

            -- ===== 渲染延迟 =====
            -- 输入停止后等待多少毫秒再渲染（减少闪烁）
            render_priority = {
                -- 高优先级（输入停止后立即渲染）
                -- 低优先级（滚动/切换 buffer 时延迟）
            },
        },
        -- 可选：自定义高亮组覆盖（适配 tokyonight 主题）
        config = function(_, opts)
            require("render-markdown").setup(opts)

            -- 适配透明背景：将渲染高亮组背景设为 NONE
            -- 如果你使用了 transparent.nvim，推荐启用以下设置
            vim.api.nvim_set_hl(0, "RenderMarkdownCode",       { bg = "NONE" })
            vim.api.nvim_set_hl(0, "RenderMarkdownCodeInline", { bg = "NONE" })
        end,
    },

    -- 文件图标 (让文件树、状态栏等显示图标)
    { "nvim-tree/nvim-web-devicons", lazy = true },

    -- 快捷键提示（按 leader 后弹出，Helix 风格右下角）
    {
        "folke/which-key.nvim",
        event = "VeryLazy",
        opts = {
            preset = "helix", -- 右下角弹出，Helix 风格
            delay = 0,        -- 按下 leader 立即弹出，不等待
            buffer = true,
        },
    },

    -- 工作区会话管理（手动保存/恢复打开的缓冲区）
    {
        "folke/persistence.nvim",
        event = "VeryLazy",
        opts = {
            options = { "buffers", "tabpages", "curdir" },
        },
        config = function(_, opts)
            require("persistence").setup(opts)
            require("persistence").stop() -- 关闭自动保存
        end,
    },

    -- 终端管理器
    {
        "akinsho/toggleterm.nvim",
        cmd = { "ToggleTerm", "TermExec", "TermSelect" },
        opts = {
            size = 20,
            hide_numbers = true,
            shade_terminals = false,
            start_in_insert = true,
            direction = "float",
            float_opts = {
                border = "rounded",
                width = 90,
                height = 30,
            },
        },
    },

    -- 通知美化
    {
        "rcarriga/nvim-notify",
        opts = {
            background_colour = "#000000",
            timeout = 3000,
            position = "top-right",
            icons = {
                ERROR = "✖",
                WARN  = "⚠",
                INFO  = "ℹ",
            },
        },
        config = function(_, opts)
            require("notify").setup(opts)
            -- 通知体背景链接到 Normal（透明）
            vim.cmd([[highlight link NotifyERRORBody Normal]])
            vim.cmd([[highlight link NotifyWARNBody Normal]])
            vim.cmd([[highlight link NotifyINFOBody Normal]])
            vim.cmd([[highlight link NotifyDEBUGBody Normal]])
            vim.cmd([[highlight link NotifyTRACEBody Normal]])
            vim.cmd([[highlight link NotifyERRORBorder Normal]])
            vim.cmd([[highlight link NotifyWARNBorder Normal]])
            vim.cmd([[highlight link NotifyINFOBorder Normal]])
            vim.cmd([[highlight link NotifyDEBUGBorder Normal]])
            vim.cmd([[highlight link NotifyTRACEBorder Normal]])
        end,
    },

    -- 命令行弹窗 + 消息美化
    {
        "folke/noice.nvim",
        event = "VeryLazy",
        dependencies = { "rcarriga/nvim-notify" },
        opts = {
            cmdline = {
                view = "cmdline_popup",
            },
            views = {
                cmdline_popup = {
                    position = {
                        row = "25%", -- 稍微高一点
                        col = "50%",
                    },
                    size = {
                        width = 0.6,
                        height = "auto",
                    },
                    border = {
                        style = "rounded",
                        padding = { 0, 1 },
                    },
                },
            },
            messages = {
                view = "notify",
                view_error = "notify",
                view_warn = "notify",
            },
            notify = {
                view = "notify",
            },
            lsp = {
                progress = {
                    enabled = false,
                },
                override = {
                    "vim.lsp.util.convert_input_to_markdown",
                    "vim.lsp.util.stylify_markdown",
                    "vim.lsp.protocol.completion_item.__index",
                },
            },
            presets = {
                command_palette = true,
                long_message_to_split = true,
                inc_rename = true,
                lsp_doc_border = true,
            },
        },
        config = function(_, opts)
            require("noice").setup(opts)
        end,
    },

    -- ======== 2. 核心编辑增强 ========
    -- 模糊查找器 (文件、文本、历史等)
    {
        "nvim-telescope/telescope.nvim",
        cmd = "Telescope",
        lazy = true,
        dependencies = {
            "nvim-lua/plenary.nvim",                                        -- 必需依赖
            { "nvim-telescope/telescope-fzf-native.nvim", build = "make" }, -- 高性能排序
        },
        config = function()
            local telescope = require("telescope")
            telescope.setup({
                extensions = { fzf = {} },
            })
            pcall(telescope.load_extension, "fzf")
        end,
    },

    -- 路径模糊搜索文件（telescope-file-browser 扩展）
    -- 在 Telescope 中按路径模糊匹配，支持目录导航
    -- 快捷键 <leader>fp 打开
    -- 用法：
    --   - 输入 /usr/bin/pyt 可直接模糊匹配到 /usr/bin/python3
    --   - 回车进入文件夹，- 返回上级
    --   - H 切换隐藏文件显示
    --   - 支持文件创建/删除/重命名
    {
        "nvim-telescope/telescope-file-browser.nvim",
        dependencies = { "nvim-telescope/telescope.nvim" },
        cmd = "Telescope file_browser",
        config = function()
            require("telescope").load_extension("file_browser")
        end,
    },

    -- ======== 调试器 nvim-dap ========
    {
        "mfussenegger/nvim-dap",
        dependencies = {
            { "rcarriga/nvim-dap-ui", dependencies = { "nvim-neotest/nvim-nio" } },
        },
        config = function()
            local dap = require("dap")
            local dapui = require("dapui")
            dapui.setup()

            -- 调试时自动打开/关闭 UI
            dap.listeners.after.event_initialized["dapui_config"] = dapui.open
            dap.listeners.after.event_terminated["dapui_config"] = dapui.close
            dap.listeners.after.event_exited["dapui_config"] = dapui.close

            -- 语言适配器
            -- Python: 需要安装 debugpy
            dap.adapters.python = {
                type = "executable",
                command = "python3",
                args = { "-m", "debugpy.adapter" },
            }
            dap.configurations.python = {
                {
                    type = "python",
                    request = "launch",
                    name = "Launch file",
                    program = "${file}",
                },
            }

            -- C/C++: 通过 stdio 通信，绕开端口问题
            dap.adapters.lldb = {
                type = "executable",
                command = "/usr/bin/lldb-dap",
            }
            dap.configurations.c = {
                {
                    name = "Launch",
                    type = "lldb",
                    request = "launch",
                    program = function()
                        return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
                    end,
                    cwd = vim.fn.getcwd,
                },
            }
            dap.configurations.cpp = dap.configurations.c
            dap.configurations.rust = dap.configurations.c
        end,
    },

    -- 文件树浏览器
    {
        "nvim-tree/nvim-tree.lua",
        cmd = "NvimTreeToggle",
        opts = {
            sort = { sorter = "case_sensitive" },
            view = { width = 30 },
            renderer = { group_empty = true },
            filters = { dotfiles = false },
            sync_root_with_cwd = true,
        },
    },

    -- 代码注释
    -- 自动补全括号/引号
    { "windwp/nvim-autopairs",       event = "InsertEnter", opts = {} },

    -- 快速修改包围符号 (ys, cs, ds)
    {
        "kylechui/nvim-surround",
        keys = {
            { "ys", mode = { "n", "x" },     desc = "Add surround" },
            { "cs", desc = "Change surround" },
            { "ds", desc = "Delete surround" },
        },
        opts = {},
    },

    -- 重复上次插件操作 (配合 nvim-surround 等)
    { "tpope/vim-repeat", lazy = true },

    -- ======== 3. 代码分析与增强 ========
    -- Tree-sitter (语法高亮、代码折叠)
    {
        "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate",
        event = { "BufReadPost", "BufNewFile" },
        cmd = { "TSInstall", "TSUpdate" },
        ---@type TSConfig
        opts = {
            ensure_installed = {
                "lua", "vim", "vimdoc", "query", "markdown", "javascript", "typescript",
                "python", "go", "rust", "c", "cpp", "html", "css", "toml",
            },
            highlight = { enable = true },
            indent = { enable = true },
        },
        -- 新版配置方式：直接使用 opts，不需要手动调用 configs.setup
        config = function(_, opts)
            require("nvim-treesitter").setup(opts)
        end,
    },

    -- ======== 4. Git 集成 ========
    -- 行级 Git 变更标记
    {
        "lewis6991/gitsigns.nvim",
        event = "VeryLazy",
        opts = {
            signs = {
                add = { text = "│" },
                change = { text = "│" },
                delete = { text = "_" },
                topdelete = { text = "‾" },
                changedelete = { text = "~" },
            },
        },
    },

    -- ======== 5. 代码补全与 LSP (可选，新手可暂不配置) ========
    -- 补全引擎 - blink.cmp (现代化选择，详见 LazyVim 14 推荐[citation:4])
    -- 注意: 这部分配置较复杂，建议后续逐步添加
    -- 可参考: https://github.com/Saghen/

    -- ======== 6. 代码补全 (blink.cmp) ========
    {
        "saghen/blink.cmp",
        version = "1.*",    -- 锁定主版本，避免破坏性更新
        event = "VimEnter", -- Vim启动后加载
        build = function()
            -- 可选：启用 Rust fuzzy 匹配器需要构建
            -- 如果不想构建，保持 fuzzy.implementation = "lua" 即可
        end,
        dependencies = {
            -- 代码片段引擎
            {
                "L3MON4D3/LuaSnip",
                version = "2.*",
                build = "make install_jsregexp", -- 可选，提升正则性能
                opts = {},
            },
            -- LSP 能力扩展
            -- "hrsh7th/cmp-nvim-lsp",
            -- 代码片段源
            "rafamadriz/friendly-snippets",
            -- LazyDev 支持 (Lua 开发增强)
            { "folke/lazydev.nvim", ft = "lua" },
        },
        ---@module "blink.cmp"
        ---@type blink.cmp.Config
        opts = {
            -- ===== 快捷键配置 =====
            keymap = {
                -- preset = "default" 提供以下默认快捷键：
                -- <C-y>   确认补全 (y = yes)
                -- <C-e>   隐藏补全菜单
                -- <C-n>/<C-p>  选择下一项/上一项
                -- <C-space>  手动触发补全
                preset = "default",

                -- 如果你习惯用 Tab 键，可以使用 "super-tab" preset：
                -- preset = "super-tab",

                -- 覆盖 <C-space> 为 toggle 功能
                -- ["<C-space>"] = {
                --     function()
                --         local cmp = require("blink.cmp")
                --         if vim.fn.pumvisible() == 1 then
                --             cmp.hide()
                --         else
                --             cmp.show()
                --             -- 可选：同时显示文档
                --             -- vim.schedule(function() cmp.show_documentation() end)
                --         end
                --     end,
                --     -- 如果菜单打开时按 <C-space>，也关闭文档（可选）
                --     -- "hide_documentation",
                -- },

                -- 保留其他默认快捷键不变

                -- 自定义快捷键示例（如需自定义，注释掉上面的 preset）：
                -- ["<C-y>"] = { "accept", "fallback" },
                -- ["<C-n>"] = { "select_next", "fallback" },
                -- ["<C-p>"] = { "select_prev", "fallback" },
                -- ["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
            },

            -- ===== 外观设置 =====
            appearance = {
                -- 使用 nvim-cmp 的样式（兼容性好）
                use_nvim_cmp_as_default = true,
                -- Nerd Font 变体：mono（等宽）或 normal
                nerd_font_variant = "mono",
            },

            -- ===== 补全源配置 =====
            sources = {
                -- 补全源优先级（从左到右优先级递减）
                default = { "lsp", "path", "snippets", "buffer", "lazydev" },
                providers = {
                    -- LazyDev 专门为 Lua 开发优化
                    lazydev = {
                        module = "lazydev.integrations.blink",
                        -- 提高优先级，让 Lua 补全排在前面
                        score_offset = 100,
                    },
                    -- 可添加更多自定义源，如：
                    -- unreal = {
                    --   module = "blink-cmp-unreal",
                    --   score_offset = 15,
                    -- },
                },
            },

            -- ===== 代码片段配置 =====
            snippets = {
                preset = "luasnip", -- 使用 LuaSnip 作为片段引擎
            },

            -- ===== 补全行为 =====
            completion = {
                -- 自动显示文档窗口（默认手动按 <C-space> 显示）
                documentation = {
                    auto_show = false,        -- 设为 true 则自动显示
                    auto_show_delay_ms = 500, -- 延迟显示时间（毫秒）
                },
                -- 自动补全触发字符
                trigger = {
                    -- 阻止输入关键字时自动弹出补全菜单 [citation:3]
                    show_on_keyword = false,
                    -- 可选：阻止特定字符（如 `.`, `:`）触发补全
                    -- show_on_x_blocked_trigger_characters = { '.', ':', '>' } [citation:3]
                    -- 关闭按键自动触发补全，仅通过 <C-space> 等手动触发
                    -- show_on_insert_on_trigger_character = false, -- 输入 . : -> 等字符时不触发
                    -- 在输入这些字符时自动触发补全
                    -- 如 . : -> :: 等
                },
                --  关闭补全菜单的自动显示
                menu = {
                    -- 设为 false 后，菜单不会自动出现 [citation:2][citation:7]
                    auto_show = false,
                },
                --  (可选) 隐藏幽灵文本，让界面更干净
                ghost_text = {
                    enabled = false, -- 如果不想看到灰色的预览文本 [citation:7]
                },
            },

            -- ===== 模糊匹配 =====
            fuzzy = {
                -- 使用 Lua 实现（无需构建，开箱即用）
                -- 如需更好的性能，可设为 "prefer_rust"，需要 cargo 和 curl
                implementation = "lua",
            },

            -- ===== 函数签名帮助 =====
            signature = {
                enabled = true, -- 启用签名功能（供 <C-k> 快捷键使用）
                window = {
                    -- 可选：签名窗口样式配置
                    -- border = "rounded",
                },
            },

            -- ===== LSP 能力 =====
            -- 这些能力会自动合并到 LSP 配置中
            -- 如需手动配置 LSP capabilities，使用：
            -- require("blink.cmp").get_lsp_capabilities()
        },

        -- 可选：额外的 LSP 能力配置
        config = function(_, opts)
            require("blink.cmp").setup(opts)

            -- 如果你需要手动配置 LSP capabilities，可以在这里设置
            -- 示例：为你的 LSP 服务器添加 blink.cmp 的能力
            -- local lspconfig = require("lspconfig")
            -- local capabilities = require("blink.cmp").get_lsp_capabilities()
            -- lspconfig.clangd.setup { capabilities = capabilities }
            -- 其他 LSP 服务器同理...
        end,
    },

    {
        "stevearc/conform.nvim",
        event = { "BufWritePre" }, -- 保存时自动格式化
        cmd = "ConformInfo",
        opts = {
            -- 默认格式化选项
            default_format_opts = {
                timeout_ms = 3000,
                async = false,
                quiet = false,
                lsp_format = "fallback",
            },
            -- 按文件类型配置格式化工具
            formatters_by_ft = {
                -- C/C++ 配置：同时覆盖 .c 和 .cpp/.h 文件
                c = { "clang-format" },   -- .c 文件
                cpp = { "clang-format" }, -- .cpp/.hpp/.h 文件[citation:2]

                lua = { "stylua" },
                python = { "black", "isort" },
                javascript = { "prettier" },
                typescript = { "prettier" },
                json = { "prettier" },
                yaml = { "prettier" },
                markdown = { "prettier" },
                sh = { "shfmt" },
                bash = { "shfmt" },
                fish = { "fish_indent" },
            },
            -- 自定义格式化器配置
            formatters = {
                injected = { options = { ignore_errors = true } },
                -- 示例：配置 prettier 使用特定配置文件
                -- prettier = {
                --   prepend_args = { "--config", "/path/to/.prettierrc" },
                -- },
            },
            -- 保存时自动格式化
            format_on_save = {
                timeout_ms = 500,
                lsp_fallback = true,
            },
        },
        -- 需要提前安装这些格式化工具（通过 Mason）
        dependencies = {
            "williamboman/mason.nvim", -- 用于安装格式化工具
        },
        config = function(_, opts)
            require("conform").setup(opts)
        end,
    },

    -- ======== LSP 核心插件 ========

    -- ===== Layer 1: Mason =====
    {
        "williamboman/mason.nvim",
        cmd = "Mason",
        opts = {
            ui = {
                border = "rounded",
                icons = {
                    package_installed = "✓",
                    package_pending = "➜",
                    package_uninstalled = "✗",
                },
            },
            -- Mason 安装路径
            install_root_dir = vim.fn.stdpath("data") .. "/mason",
            -- 启动时自动更新注册表（确保能获取到最新的 LSP/格式化工具版本）
            registries = {
                github = {
                    update_on_startup = true,
                },
            },
        },
    },

    -- ===== Layer 2: mason-lspconfig =====
    {
        "williamboman/mason-lspconfig.nvim",
        dependencies = { "williamboman/mason.nvim" },
        config = function()
            require("mason-lspconfig").setup({})
            -- 改用 mason-registry API 直接安装（绕过 ensure_installed 的注册表缓存校验问题）
            local registry = require("mason-registry")
            local packages = {
                "clangd",                     -- C/C++
                "lua-language-server",        -- Lua
                "pyright",                    -- Python
                "typescript-language-server", -- TypeScript/JavaScript
            }
            for _, pkg_name in ipairs(packages) do
                local ok, pkg = pcall(registry.get_package, pkg_name)
                if ok and not pkg:is_installed() then
                    pkg:install()
                end
            end
        end,
    },

    -- ===== Layer 3: nvim-lspconfig =====
    {
        "neovim/nvim-lspconfig",
        dependencies = {
            "williamboman/mason.nvim",
            "williamboman/mason-lspconfig.nvim",
            "saghen/blink.cmp", -- 补全集成
        },
        event = { "BufReadPre", "BufNewFile" },
        config = function()
            -- 获取 blink.cmp 的 LSP 能力
            local capabilities = vim.lsp.protocol.make_client_capabilities()
            local has_blink, blink = pcall(require, "blink.cmp")
            if has_blink then
                capabilities = blink.get_lsp_capabilities()
            end

            -- ===== 1. clangd (C/C++) =====
            vim.lsp.config.clangd = {
                cmd = {
                    "clangd",
                    "--background-index",
                    "--clang-tidy",
                    "--header-insertion=iwyu",
                    "--completion-style=detailed",
                    "--function-arg-placeholders=true",
                },
                capabilities = capabilities,
                filetypes = { "c", "cpp", "objc", "objcpp", "cuda" },
            }

            -- ===== 2. lua_ls (Lua) =====
            vim.lsp.config.lua_ls = {
                cmd = { "lua-language-server" },
                capabilities = capabilities,
                filetypes = { "lua" },
                settings = {
                    Lua = {
                        runtime = { version = "LuaJIT" },
                        diagnostics = { globals = { "vim" } },
                        workspace = {
                            library = vim.api.nvim_get_runtime_file("", true),
                            checkThirdParty = false,
                        },
                        telemetry = { enable = false },
                    },
                },
            }

            -- ===== 3. pyright (Python) =====
            vim.lsp.config.pyright = {
                cmd = { "pyright-langserver", "--stdio" },
                capabilities = capabilities,
                filetypes = { "python" },
                settings = {
                    python = {
                        analysis = {
                            typeCheckingMode = "basic",
                            autoSearchPaths = true,
                            useLibraryCodeForTypes = true,
                        },
                    },
                },
            }

            -- ===== 4. ts_ls (TypeScript/JavaScript) =====
            vim.lsp.config.ts_ls = {
                cmd = { "typescript-language-server", "--stdio" },
                capabilities = capabilities,
                filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
            }

            -- ===== 启用所有 LSP 服务器 =====
            vim.lsp.enable("clangd")
            vim.lsp.enable("lua_ls")
            vim.lsp.enable("pyright")
            vim.lsp.enable("ts_ls")

            -- ===== 诊断显示配置 =====
            pcall(vim.diagnostic.config, {
                virtual_text = false,     -- 不显示行内文本
                signs = true,             -- 显示符号图标
                underline = true,         -- 错误处下划线
                update_in_insert = false, -- 插入模式不更新
                severity_sort = true,     -- 按严重性排序
                float = {
                    border = "rounded",
                    source = true,
                },
            })
        end,
    },

}
