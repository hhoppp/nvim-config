-- ============================================================================
--  transparent.lua —— 透明模式开关
--  <leader>t  切换透明/不透明
--  lualine 状态栏始终保持透明，不受开关影响
-- ============================================================================

local M = {}

-- ============================================================================
--  参与切换的高亮组（lualine 除外，由 core.lua 独立管理，永远透明）
-- ============================================================================

local others = {
    -- 编辑器主体
    "Normal", "NormalNC", "NormalFloat", "FloatBorder",
    -- Telescope
    "TelescopeNormal", "TelescopeBorder",
    "TelescopePromptNormal", "TelescopePromptBorder",
    "TelescopeResultsNormal", "TelescopePreviewNormal",
    -- NvimTree
    "NvimTreeNormal", "NvimTreeNormalNC", "NvimTreeEndOfBuffer",
    -- Mason
    "MasonNormal",
    -- LSP 浮窗
    "LspFloatWinNormal", "LspFloatWinBorder",
    -- 诊断符号
    "SignColumn",
    "DiagnosticSignError", "DiagnosticSignWarn",
    "DiagnosticSignInfo", "DiagnosticSignHint",
    -- 窗口分隔线
    "NvimTreeWinSeparator", "WinSeparator", "VertSplit",
    -- 光标行
    "CursorLine",
    -- 补全菜单
    "Pmenu", "PmenuSel", "PmenuSbar", "PmenuThumb",
    -- blink.cmp 补全浮窗
    "BlinkCmpMenu", "BlinkCmpMenuBorder",
    "BlinkCmpDoc", "BlinkCmpDocBorder",
    "BlinkCmpLabel", "BlinkCmpLabelDescription", "BlinkCmpLabelDetail",
    "BlinkCmpScrollBarThumb", "BlinkCmpScrollBarGutter",
    "BlinkCmpSource",
}

-- which-key 群组（分离出来，因为其群组在弹窗打开时才创建）
local wk_groups = {
    "WhichKey", "WhichKeyBorder", "WhichKeyNormal", "WhichKeyFloat",
    "WhichKeyGroup", "WhichKeyDesc", "WhichKeySeparator", "WhichKeyValue",
    "WhichKeyTitle", "WhichKeyCursor",
}

-- ============================================================================
--  核心逻辑
-- ============================================================================

local function apply()
    for _, g in ipairs(others) do
        pcall(vim.api.nvim_set_hl, 0, g, { bg = "NONE" })
    end
    -- which-key 群组也一并涂（<leader>t 时 which-key 已打开）
    for _, g in ipairs(wk_groups) do
        pcall(vim.api.nvim_set_hl, 0, g, { bg = "NONE" })
    end
    -- 分隔线需要同时清除前景色
    pcall(vim.api.nvim_set_hl, 0, "NvimTreeWinSeparator", { bg = "NONE", fg = "NONE" })
    pcall(vim.api.nvim_set_hl, 0, "WinSeparator", { bg = "NONE", fg = "NONE" })
    pcall(vim.api.nvim_set_hl, 0, "VertSplit", { bg = "NONE", fg = "NONE" })
    pcall(vim.cmd("highlight! StatusLine guibg=NONE"))
    pcall(vim.cmd("highlight! StatusLineNC guibg=NONE"))
end

---<leader>t 切换透明/不透明
function M.toggle()
    vim.g.transparent = not vim.g.transparent
    if vim.g.transparent then
        apply()
    else
        vim.cmd("colorscheme tokyonight")
    end
end

-- ============================================================================
--  初始化
-- ============================================================================

-- 从 options.lua 读取默认值
vim.g.transparent = vim.g.transparent == nil and true or vim.g.transparent

-- 每次主题重载后，若透明开启则自动重涂（含启动时首加载）
vim.api.nvim_create_autocmd("ColorScheme", {
    callback = function()
        if vim.g.transparent then
            vim.schedule(apply)
        end
    end,
})

-- which-key 等 VeryLazy 插件加载完成后重涂一次
vim.api.nvim_create_autocmd("User", {
    pattern = "VeryLazy",
    once = true,
    callback = function()
        if vim.g.transparent then
            vim.schedule(apply)
        end
    end,
})

-- which-key 弹窗打开时实时涂透明
vim.api.nvim_create_autocmd("User", {
    pattern = "WhichKey",
    callback = function()
        if vim.g.transparent then
            for _, g in ipairs(wk_groups) do
                pcall(vim.api.nvim_set_hl, 0, g, { bg = "NONE" })
            end
        end
    end,
})

return M
