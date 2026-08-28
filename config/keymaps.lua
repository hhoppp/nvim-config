-- ~/.config/nvim/lua/config/keymaps.lua
-- 快捷键集中管理
-- 修改此文件后重启 Neovim 或执行 :luafile % 生效

local map = vim.keymap.set
local opts = { noremap = true, silent = true }

-- 辅助：快速创建带 desc 的映射
local function desc(description)
    return vim.tbl_extend("force", opts, { desc = description })
end

-- ============================================================================
--  文件导航
-- ============================================================================

map("n", "<leader>e", "<cmd>NvimTreeToggle<cr>", desc("Toggle file explorer"))

-- 终端（互斥模式：每次只显示一个窗口）
-- 高度/宽度为原始值的 2/3：
--   th 高度 20 → 13（水平终端），tv 宽度 75 → 50（垂直终端）
-- Alt+d 默认打开水平终端（th），而非 toggleterm 默认的居中 float 终端
map("n", "<leader>tf", function()
    require("config.other").toggle_term(1, "float")
end, desc("Terminal float"))
map("n", "<leader>th", function()
    require("config.other").toggle_term(2, "horizontal", 13)
end, desc("Terminal horizontal"))
map("n", "<leader>tv", function()
    require("config.other").toggle_term(3, "vertical", 50)
end, desc("Terminal vertical"))
map("n", "<A-d>", function()
    require("config.other").toggle_term(2, "horizontal", 13)
end, desc("Toggle horizontal terminal"))
map("n", "<leader>tl", "<cmd>TermSelect<cr>", desc("List terminals"))
map("t", "<A-d>", function()
    require("config.other").toggle_term(2, "horizontal", 13)
end, desc("Toggle horizontal terminal"))
-- 终端模式：Esc 退出到普通模式
map("t", "<Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

map("t", "<C-[>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- ============================================================================
--  会话管理
-- ============================================================================

-- 列出所有保存的会话，回车恢复
map("n", "<leader>fs", function()
    require("config.other").select_session()
end, desc("Select session"))
map("n", "<leader>fq", function()
    local dir = vim.fn.getcwd()
    -- 把绝对路径编码为会话文件名：/home/xxx/yyy → %home%xxx%yyy.vim
    local encoded = dir:gsub("/", "%%")
    local file = vim.fn.stdpath("state") .. "/sessions/" .. encoded .. ".vim"
    vim.fn.mkdir(vim.fn.stdpath("state") .. "/sessions", "p")
    require("config.other").save_workspace(file)
    vim.notify("工作区已保存", vim.log.levels.INFO)
end, desc("Save workspace"))

-- ============================================================================
--  标签页
-- ============================================================================

map("n", "<leader>tn", "<cmd>tabn<cr>", desc("Next tab"))
map("n", "<leader>tp", "<cmd>tabp<cr>", desc("Previous tab"))
map("n", "<leader>tc", "<cmd>tabnew<cr>", desc("Create tab"))
map("n", "<leader>td", "<cmd>tabclose<cr>", desc("Close tab"))
map("n", "<leader>to", "<cmd>tabonly<cr>", desc("Close other tabs"))

-- ============================================================================
--  模糊查找 (Telescope)
-- ============================================================================

map("n", "<leader>ff", "<cmd>Telescope find_files<cr>", desc("Find files"))
map("n", "<leader>fg", "<cmd>Telescope live_grep<cr>", desc("Live grep"))
map("n", "<leader>fb", function()
    require("config.other").select_buffer()
end, desc("Find buffers"))
map("n", "<leader>fh", "<cmd>Telescope help_tags<cr>", desc("Help tags"))
map("n", "<leader>fr", "<cmd>Telescope resume<cr>", desc("Resume last picker"))
map("n", "<leader>fo", "<cmd>Telescope oldfiles<cr>", desc("Recent files"))
map("n", "<leader>fw", "<cmd>Telescope grep_string<cr>", desc("Grep word under cursor"))
map("n", "<leader>fk", "<cmd>Telescope keymaps<cr>", desc("Find keyword"))
-- 查看消息历史（noice）
-- 查看/跳转标记
map("n", "<leader>fm", function()
    require("telescope.builtin").marks({
        attach_mappings = function(prompt_bufnr, _)
            local actions = require("telescope.actions")
            local state = require("telescope.actions.state")
            vim.api.nvim_buf_set_keymap(prompt_bufnr, "i", "<A-d>", "", {
                noremap = true,
                callback = function()
                    local selection = state.get_selected_entry()
                    if selection then
                        -- 从显示文本提取标记名：如 "'a"
                        local value = selection.value or selection[1] or ""
                        local mark = value:match("'(%w)")
                        if mark then
                            vim.fn.delmark("'" .. mark)
                            local picker = state.get_current_picker(prompt_bufnr)
                            if picker then
                                picker:refresh(picker.finder, {})
                            end
                        end
                    end
                end,
            })
            return true
        end,
    })
end, desc("Find marks"))
-- 按路径模糊搜索文件（telescope-file-browser）
-- 插入模式快捷键：
--   Alt+d  删除（移到回收站）   Alt+r  重命名
--   Alt+c  创建                Alt+m  移动
--   Alt+y  复制                Ctrl+h 切换隐藏文件
--   Ctrl+g 上级目录             Ctrl+e home 目录
--   Ctrl+s 切换全选             Ctrl+o 系统打开
map("n", "<leader>fp", "<cmd>Telescope file_browser hidden=true<cr>", desc("File browser (path)"))

-- ============================================================================
--  搜索体验优化
-- ============================================================================

-- 搜索结果居中显示（zz = 居中，zv = 展开折叠）
map("n", "n", "nzzzv", desc("Next search result (center)"))
map("n", "N", "Nzzzv", desc("Prev search result (center)"))
map("n", "*", "*zzzv", desc("Search word under cursor (center)"))
map("n", "#", "#zzzv", desc("Search word backward (center)"))


-- <leader>br: 将标签栏重排为 buffer 实际顺序（nvim_list_bufs 的 ID 顺序）
map("n", "<leader>br", function()
    local ok, cmds = pcall(require, "bufferline.commands")
    if ok then cmds.sort_by("id") end
end, desc("Reorder tabs to buffer ID order"))

-- ============================================================================
--  窗口管理
-- ============================================================================

-- 分屏
map("n", "<leader>sv", "<cmd>vsplit<cr>", desc("Vertical split"))
map("n", "<leader>sh", "<cmd>split<cr>", desc("Horizontal split"))
map("n", "<leader>sc", "<cmd>close<cr>", desc("Close window"))

-- 窗口导航 (Ctrl + hjkl，免去先按 C-w)
map({ "n", "t" }, "<C-h>", "<C-w>h", desc("Go to left window"))
map({ "n", "t" }, "<C-j>", "<C-w>j", desc("Go to down window"))
map({ "n", "t" }, "<C-k>", "<C-w>k", desc("Go to up window"))
map({ "n", "t" }, "<C-l>", "<C-w>l", desc("Go to right window"))

-- 窗口大小调整（niri 风格：Alt + hjkl）
map("n", "<A-S-h>", "<C-w><", desc("Decrease width ×5"))
map("n", "<A-S-l>", "<C-w>>", desc("Increase width ×5"))
map("n", "<A-S-j>", "<C-w>-", desc("Decrease height ×5"))
map("n", "<A-S-k>", "<C-w>+", desc("Increase height ×5"))
-- 等分
map("n", "<leader>s=", "<C-w>=", desc("Equalize windows"))
-- 最大化
map("n", "<leader>s_", "<C-w>_", desc("Maximize height"))
map("n", "<leader>s|", "<C-w>|", desc("Maximize width"))

-- ============================================================================
--  刷新相关
-- ============================================================================

-- ============================================================================
--  缓冲区管理
-- ============================================================================

-- bn/bp 跟 bufferline 的视觉顺序（与 bh/bl 移动后的标签顺序一致）
map("n", "<leader>bn", function()
    local ok, bl = pcall(require, "bufferline")
    if ok then bl.cycle(1) else vim.cmd("bnext") end
end, desc("Next buffer (follows tab order)"))
map("n", "<leader>bp", function()
    local ok, bl = pcall(require, "bufferline")
    if ok then bl.cycle(-1) else vim.cmd("bprevious") end
end, desc("Previous buffer (follows tab order)"))
map("n", "<leader>bh", "<cmd>BufferLineMovePrev<cr>", desc("Move buffer left"))
map("n", "<leader>bl", "<cmd>BufferLineMoveNext<cr>", desc("Move buffer right"))
map("n", "<leader>bo", "<cmd>BufferLineCloseOthers<cr>", desc("Close other buffer"))
map("n", "<leader>bd", function()
    require("config.bufops").close_current()
end, desc("Close buffer"))
map("n", "<leader>bD", function()
    require("config.bufops").close_all()
end, desc("Close all buffers"))

-- ============================================================================
--  快速保存 / 退出
-- ============================================================================
map("n", "<leader>w", "<cmd>write<cr>", desc("Save"))
map("n", "<leader>q", "<cmd>quit<cr>", desc("Quit"))
map("n", "<leader>Q", "<cmd>qa<cr>", desc("Quit all"))
-- map("n", "<leader>x", "<cmd>x<cr>", desc("Save and quit"))

-- ============================================================================
--  编辑增强
-- ============================================================================

-- Ctrl+S 保存（插入模式）
-- map("i", "<C-s>", function()
--     if vim.bo.modified then vim.cmd.write() end
-- end, desc("Save"))

-- Ctrl+V 粘贴（插入模式，从系统剪贴板）
-- map("i", "<C-v>", "<C-r>+", desc("Paste"))

-- Ctrl+Z 撤销（插入模式，退出插入模式执行撤销）
-- map("i", "<C-z>", "<Esc>ui", desc("Undo"))

-- Ctrl+E 关闭（插入模式）
-- map("i", "<C-e>", "<Esc>a", desc("Hide"))

-- 注释切换 (gc/gcc) — Neovim 内置注释（详见 :help gcc）
-- 包围符号 (ys/cs/ds) — 定义在 plugins/core.lua nvim-surround 中（同上）

-- 自动补全菜单 (blink.cmp)
-- <C-y>    确认补全
-- <C-e>    取消补全
-- <C-n/p>  上下选择
-- <C-space> 手动触发
-- 以上由 blink.cmp 的 preset = "default" 管理，见 plugins/core.lua

-- ============================================================================
--  格式化 (conform.nvim)
-- ============================================================================

-- Shift+Alt+F 格式化（通用快捷键）
map({ "n", "v", "i" }, "<A-S-f>", function()
    require("conform").format({ async = true, lsp_fallback = true })
end, desc("Format code"))

-- ============================================================================
--  调试 (nvim-dap)
-- ============================================================================

map("n", "<F5>", function()
    require("dap").continue()
end, desc("Debug continue"))
map("n", "<F10>", function()
    require("dap").step_over()
end, desc("Debug step over"))
map("n", "<F11>", function()
    require("dap").step_into()
end, desc("Debug step into"))
map("n", "<F12>", function()
    require("dap").step_out()
end, desc("Debug step out"))
map("n", "<leader>db", function()
    require("dap").toggle_breakpoint()
end, desc("Toggle breakpoint"))
map("n", "<leader>dB", function()
    require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
end, desc("Set conditional breakpoint"))
map("n", "<leader>dc", function()
    require("dap").continue()
end, desc("Start/continue"))
map("n", "<leader>di", function()
    require("dapui").toggle()
end, desc("Toggle debug UI"))
map("n", "<leader>dE", function()
    require("dap").terminate()
end, desc("Debug terminate"))
map("n", "<leader>dr", function()
    require("dap").restart()
end, desc("Debug restart"))

-- ============================================================================
--  LSP / 代码导航
-- ============================================================================

-- 跳转
map("n", "gd", vim.lsp.buf.definition, desc("Go to definition"))
map("n", "gr", vim.lsp.buf.references, desc("Find references"))
map("n", "gI", vim.lsp.buf.implementation, desc("Go to implementation"))

-- 文档
map("n", "K", vim.lsp.buf.hover, desc("Hover documentation"))

-- ============================================================================
--  诊断
-- ============================================================================

map("n", "[d", function()
    vim.diagnostic.jump({ count = -1 })
end, desc("Previous diagnostic"))

map("n", "]d", function()
    vim.diagnostic.jump({ count = 1 })
end, desc("Next diagnostic"))

map("n", "<leader>de", function()
    vim.diagnostic.open_float({ border = "rounded", source = true })
end, desc("Show diagnostic"))

map("n", "<leader>dl", function()
    vim.diagnostic.setloclist({ open = true })
end, desc("List all diagnostics"))

map("n", "<leader>dp", function()
    vim.diagnostic.jump({ count = -1, severity = { min = vim.diagnostic.severity.WARN } })
end, desc("Previous (warn/error)"))

map("n", "<leader>dn", function()
    vim.diagnostic.jump({ count = 1, severity = { min = vim.diagnostic.severity.WARN } })
end, desc("Next (warn/error)"))

-- ============================================================================
--  工具
-- ============================================================================

--  map("n", "<leader>m", "<cmd>Mason<CR>", desc("Mason (LSP Manager)"))

-- ============================================================================
--  透明开关（由 xiyaowong/transparent.nvim 接管）
-- ============================================================================

-- map("n", "<leader>TT", "<cmd>TransparentToggle<cr>", desc("Toggle transparent"))

-- ============================================================================
--  Markdown 渲染开关
-- ============================================================================

-- render-markdown.nvim 内联渲染开关，在 Markdown 文件中切换是否显示渲染效果
-- 关闭后恢复纯文本显示，不影响源文件
-- map("n", "<leader>rdm", function()
--     require("render-markdown").toggle()
-- end, desc("Toggle markdown render"))

-- ============================================================================
--  自定义快捷键可追加在此 ↓
-- ====================================================================================

--  输入模式下光标移动
-- map("i", "<A-h>", "<Left>", desc("Left"))
-- map("i", "<A-l>", "<Right>", desc("Right"))
-- map("i", "<A-j>", "<Down>", desc("Down"))
-- map("i", "<A-k>", "<Up>", desc("Up"))

--  输入模式下退格与删除快捷键
-- map("i", "<C-x>", "<C-h>", desc("Delete char before cursor"))
-- map("i", "<C-b>", "<Del>", desc("Delete char after cursor"))
