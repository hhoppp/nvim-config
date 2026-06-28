-- ============================================================================
--  modlock.lua —— 全局编辑锁定
--  <leader>ll  切换锁定/解锁
--  锁定后：禁止一切文件修改操作，静默拦截，无弹窗无通知
--  解锁后：恢复所有编辑功能
--  状态栏图标：🔒 锁定中 | 无图标 = 已解锁
--  使用: require("config.modlock") 即可启用
-- ============================================================================

local M = {}

-- 独立 autocmd group，方便重载时清理
local augroup = vim.api.nvim_create_augroup("ModLock", { clear = true })

-- ============================================================================
--  锁定状态（全局）
-- ============================================================================

---切换锁定/解锁，锁定后禁止一切修改操作
function M.toggle()
    vim.g.mod_locked = not vim.g.mod_locked
    -- 触发事件刷新状态栏
    vim.cmd("doautocmd User ModLockChanged")
    return vim.g.mod_locked
end

---是否处于锁定状态
function M.is_locked()
    return vim.g.mod_locked or false
end

-- ============================================================================
--  内部工具函数
-- ============================================================================

---静默检查锁定状态，锁定则返回 true（不弹任何通知）
local function locked()
    return vim.g.mod_locked or false
end

---通过 feedkeys 放行按键（等映射函数退出后再执行，避免上下文问题）
---@param cmd string 正常模式命令，如 "i", "x", "dd"
local function pass_through(cmd)
    vim.api.nvim_feedkeys(
        vim.api.nvim_replace_termcodes(cmd, true, false, true),
        "n", false
    )
end

---operator 类按键的透传（吃一个 motion 字符）
---如 d, c, g~, gu, gU, gq, gw, =, <, >
---@param op string 操作符，如 "d", "g~"
local function operator_pass(op)
    local char = vim.fn.getchar()
    vim.api.nvim_feedkeys(
        vim.api.nvim_replace_termcodes(op .. vim.fn.nr2char(char), true, false, true),
        "n", false
    )
end

-- ============================================================================
--  映射生成器
-- ============================================================================

---封装一组按键为锁定感知映射
---@param mode string "n" 普通模式 / "x" 可视模式
---@param keys table 按键列表
---@param use_operator boolean 是否为 operator（需吃 motion）
---@param custom_cmd string|nil 透传时的自定义命令（nil 则用按键本身）
local function setup_keys(mode, keys, use_operator, custom_cmd)
    for _, key in ipairs(keys) do
        vim.keymap.set(mode, key, function()
            if locked() then return end
            if use_operator then
                operator_pass(custom_cmd or key)
            else
                pass_through(custom_cmd or key)
            end
        end, { desc = key })
    end
end

-- ============================================================================
--  安装所有拦截映射
-- ============================================================================

local function setup_mappings()
    -- ── 普通模式：进入编辑/替换模式的键 ──
    setup_keys("n", { "i", "I", "a", "A", "o", "O" })
    setup_keys("n", { "s", "S" })
    setup_keys("n", { "c" }, true)
    setup_keys("n", { "C" })
    setup_keys("n", { "gi", "gI", "gR" })
    setup_keys("n", { "R" })
    setup_keys("n", { "r" }, true)
    setup_keys("n", { "gr" }, true)

    -- ── 普通模式：直接修改文件的键 ──
    setup_keys("n", { "x", "X" })        -- 删除字符
    setup_keys("n", { "d" }, true)       -- delete 操作符（dw, dd, diw 等）
    setup_keys("n", { "D" })             -- 删除到行尾
    setup_keys("n", { "p", "P" })        -- 粘贴
    setup_keys("n", { "J", "gJ" })       -- 合并行
    setup_keys("n", { "u", "<C-r>" })    -- 撤销 / 重做
    setup_keys("n", { "." })             -- 重复上次修改
    setup_keys("n", { "~", "g~" }, true) -- 切换大小写（~ 单字符, g~ 操作符）
    setup_keys("n", { "gu" }, true)      -- 转为小写
    setup_keys("n", { "gU" }, true)      -- 转为大写
    setup_keys("n", { "gq" }, true)      -- 格式化（操作符）
    setup_keys("n", { "gw" }, true)      -- 格式化 + 保持光标
    setup_keys("n", { "g@" }, true)      -- operatorfunc
    setup_keys("n", { "<", ">" }, true)  -- 缩进
    setup_keys("n", { "=" }, true)       -- 自动缩进

    -- ── 可视模式：拦截所有会改文件的键 ──
    setup_keys("x", { "x", "X", "d", "D", "c", "C", "s", "S" })
    setup_keys("x", { "p", "P" })
    setup_keys("x", { "J" })
    setup_keys("x", { "~", "gu", "gU", "gq", "g@" })
    setup_keys("x", { "<", ">", "=" })
end

-- ============================================================================
--  初始化
-- ============================================================================

M.setup_done = false

function M.setup()
    M.setup_done = true

    -- 默认解锁
    if vim.g.mod_locked == nil then
        vim.g.mod_locked = false
    end

    -- 安装拦截映射
    setup_mappings()

    -- 锁定状态下意外进入插入模式 → 静默退出（无通知）
    vim.api.nvim_create_autocmd("InsertEnter", {
        group = augroup,
        callback = function()
            if vim.g.mod_locked then
                vim.schedule(function()
                    vim.cmd("stopinsert")
                end)
            end
        end,
    })
end

-- ============================================================================
--  lualine 组件
-- ============================================================================

---供 lualine 使用的状态栏组件函数
---锁定显示 🔒，解锁不显示任何内容
function M.indicator()
    if vim.g.mod_locked then
        return " 🔒"
    end
    return ""
end

---在 lazy.nvim 和 lualine 初始化完成后注入组件
local function inject_lualine_indicator()
    vim.api.nvim_create_autocmd("UIEnter", {
        once = true,
        group = augroup,
        callback = function()
            vim.schedule(function()
                vim.defer_fn(function()
                    pcall(function()
                        require("lualine").setup({
                            sections = {
                                lualine_c = {
                                    {
                                        function()
                                            return require("config.modlock").indicator()
                                        end,
                                    },
                                    { "filename", path = 1 },
                                },
                            },
                        })
                    end)
                end, 100)
            end)
        end,
    })
end

-- 自动初始化
M.setup()
inject_lualine_indicator()

return M
