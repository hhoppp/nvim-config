-- ============================================================================
--  bufops.lua —— 缓冲区批量操作
--  被 keymaps.lua 引用，保持快捷键配置文件的简洁
-- ============================================================================

local M = {}

---关闭当前缓冲区，如果是最后一个则打开欢迎界面
function M.close_current()
    local listed = vim.tbl_filter(function(b)
        return vim.api.nvim_buf_is_valid(b) and vim.bo[b].buflisted
    end, vim.api.nvim_list_bufs())
    if #listed <= 1 then
        vim.api.nvim_buf_delete(vim.api.nvim_get_current_buf(), { force = true })
        vim.schedule(function()
            pcall(vim.cmd, "Alpha")
        end)
    else
        vim.cmd("bdelete")
    end
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
