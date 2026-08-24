-- ============================================================================
--  bufops.lua —— 缓冲区批量操作
--  被 keymaps.lua 引用，保持快捷键配置文件的简洁
-- ============================================================================

local M = {}

---关闭当前缓冲区，如果是最后一个则打开欢迎界面
function M.close_current()
    local buf = vim.api.nvim_get_current_buf()
    local win = vim.api.nvim_get_current_win()

    -- 收集其他可列出的 buffer（排除当前）
    local others = vim.tbl_filter(function(b)
        return vim.api.nvim_buf_is_valid(b) and b ~= buf and vim.bo[b].buflisted
    end, vim.api.nvim_list_bufs())

    if #others == 0 then
        -- 最后一个 buffer：删除后打开欢迎界面
        vim.api.nvim_buf_delete(buf, { force = true })
        vim.schedule(function()
            pcall(vim.cmd, "Alpha")
        end)
    else
        -- 先让当前窗口显示下一个 buffer，再删除当前 buffer，
        -- 避免 bdelete 时 Vim 关掉当前窗口
        vim.api.nvim_win_set_buf(win, others[1])
        vim.api.nvim_buf_delete(buf, { force = false })
    end
end

---安全关闭指定 buffer：先把显示它的窗口切换到其他 buffer，再删除。
---用于 bufferline 点击 ✕ 等场景，避免 bdelete 把 nvim-tree 窗口挤掉。
---@param buf number buffer 编号
function M.close_buffer_safe(buf)
    if not vim.api.nvim_buf_is_valid(buf) then
        return
    end
    -- 如果该 buffer 显示在某个窗口，先把窗口切到其他 buffer
    local wins = vim.fn.win_findbuf(buf)
    if #wins > 0 then
        local win = wins[1]
        -- 找其他可显示的 listed buffer（排除当前要删的）
        local others = vim.tbl_filter(function(b)
            return vim.api.nvim_buf_is_valid(b) and b ~= buf and vim.bo[b].buflisted
        end, vim.api.nvim_list_bufs())
        if #others > 0 then
            vim.api.nvim_win_set_buf(win, others[1])
        end
    end
    vim.api.nvim_buf_delete(buf, { force = false })
end

---强制关闭所有缓冲区，然后打开欢迎界面
function M.close_all()
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buflisted then
            vim.api.nvim_buf_delete(buf, { force = true })
        end
    end
    vim.schedule(function()
        pcall(vim.cmd, "Alpha")
    end)
end

return M
