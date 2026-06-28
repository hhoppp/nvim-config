-- ============================================================================
--  other.lua —— 零散工具函数集
--  被 keymaps.lua 引用，保持快捷键文件的整洁
-- ============================================================================

local M = {}

---热刷新 Neovim 配置
---清空 config.* 模块缓存后重新加载 init.lua
function M.reload_config()
    local modules = {
        "config.options", "config.keymaps", "config.modlock",
        "config.bufops", "config.transparent",
    }
    for _, mod in ipairs(modules) do
        package.loaded[mod] = nil
    end
    vim.cmd("luafile /home/alise/.config/nvim/init.lua")
    -- 重载后关闭搜索高亮
    vim.cmd("noh")
    vim.notify("配置已热加载", vim.log.levels.INFO)
end

---切换终端（互斥模式：先关其他终端，再打开指定终端）
---@param id number 终端 ID
---@param direction string 方向：float / horizontal / vertical
---@param size number|nil 尺寸
function M.toggle_term(id, direction, size)
    -- 先关闭其他打开的 toggleterm 终端
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buftype == "terminal" then
            local ok, num = pcall(vim.api.nvim_buf_get_var, buf, "toggle_number")
            if ok and num and num ~= id then
                local win = vim.fn.bufwinnr(buf)
                if win ~= -1 then
                    vim.cmd(string.format("%dToggleTerm", num))
                end
            end
        end
    end
    -- 打开目标终端（存在则 toggle，不存在则创建）
    vim.cmd(string.format("%dToggleTerm direction=%s%s", id, direction, size and (" size=" .. size) or ""))
end

---用 Telescope 列出并选择会话
---@param scroll_to string|nil 删除后恢复光标位置的文件名
function M.select_session(scroll_to)
    local session_dir = vim.fn.stdpath("state") .. "/sessions/"
    if vim.fn.isdirectory(session_dir) == 0 then
        vim.notify("没有保存的会话", vim.log.levels.INFO)
        return
    end
    require("telescope.builtin").find_files({
        prompt_title = " Sessions",
        cwd = session_dir,
        attach_mappings = function(prompt_bufnr, _)
            local actions = require("telescope.actions")
            local state = require("telescope.actions.state")

            -- Alt+d 永久删除会话文件
            vim.api.nvim_buf_set_keymap(prompt_bufnr, "i", "<A-d>", "", {
                noremap = true,
                callback = function()
                    local selection = state.get_selected_entry()
                    if selection then
                        local filename = selection.value or selection[1] or ""
                        if filename ~= "" then
                            os.remove(session_dir .. filename)
                            actions.close(prompt_bufnr)
                            vim.defer_fn(function()
                                M.select_session(filename)
                            end, 0)
                        end
                    end
                end,
            })

            vim.defer_fn(function()
                if scroll_to and scroll_to ~= "" then
                    pcall(vim.api.nvim_buf_set_lines, prompt_bufnr, 0, 1, false, { scroll_to })
                end
            end, 0)

            actions.select_default:replace(function()
                local selection = state.get_selected_entry()
                actions.close(prompt_bufnr)
                if selection then
                    local filename = selection.value or selection[1] or ""
                    if filename ~= "" then
                        local file = session_dir .. filename
                        local lines = vim.fn.readfile(file)
                        if lines then
                            pcall(vim.cmd, table.concat(lines, "\n"))
                        end
                    end
                end
            end)

            -- 恢复光标位置：设置输入框内容过滤到目标文件
            if scroll_to and scroll_to ~= "" then
                vim.defer_fn(function()
                    pcall(vim.api.nvim_buf_set_lines, prompt_bufnr, 0, 1, false, { scroll_to })
                end, 0)
            end

            return true
        end,
    })
end

---在 Telescope buffers 中用 Alt+d 关闭选中缓冲区，滚动恢复光标
---@param scroll_to string|nil 删除后恢复的文件名
function M.select_buffer(scroll_to)
    require("telescope.builtin").buffers({
        attach_mappings = function(prompt_bufnr, _)
            local actions = require("telescope.actions")
            local state = require("telescope.actions.state")

            -- Alt+d 关闭选中缓冲区
            vim.api.nvim_buf_set_keymap(prompt_bufnr, "i", "<A-d>", "", {
                noremap = true,
                callback = function()
                    local selection = state.get_selected_entry()
                    if selection and selection.bufnr then
                        local saved = selection.filename or selection.value or selection[1] or ""
                        vim.api.nvim_buf_delete(selection.bufnr, { force = true })
                        if saved ~= "" then
                            actions.close(prompt_bufnr)
                            vim.defer_fn(function()
                                M.select_buffer(saved)
                            end, 0)
                        end
                    end
                end,
            })

            -- 恢复光标位置
            if scroll_to and scroll_to ~= "" then
                vim.defer_fn(function()
                    pcall(vim.api.nvim_buf_set_lines, prompt_bufnr, 0, 1, false, { scroll_to })
                end, 0)
            end

            -- 恢复光标位置
            if scroll_to and scroll_to ~= "" then
                vim.defer_fn(function()
                    pcall(vim.api.nvim_buf_set_lines, prompt_bufnr, 0, 1, false, { scroll_to })
                end, 0)
            end

            return true
        end,
    })
end

return M
