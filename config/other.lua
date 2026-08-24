-- ============================================================================
--  other.lua —— 零散工具函数集
--  被 keymaps.lua 引用，保持快捷键文件的整洁
-- ============================================================================

local M = {}

-- toggleterm 打开前的主窗口视图（供 on_open 恢复，消除闪烁/偏移）
M._main_view = nil
M._main_win = nil

---记录当前主窗口视图（toggle_term 打开 split 终端前调用）
---原理：split 终端打开时 Vim 会重置主窗口视图（光标回顶、滚动丢失），
---产生可见的闪烁/偏移。打开前用 winsaveview 记录，on_open 时再恢复。
---仅记录普通文件窗口（跳过终端窗口自身），且仅 split 方向需要
---（float 终端不影响布局，无需恢复）。
function M.record_main_view()
    local win = vim.api.nvim_get_current_win()
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].buftype ~= "terminal" and vim.fn.win_gettype(win) == "" then
        M._main_view = vim.fn.winsaveview()
        M._main_win = win
    end
end

---恢复主窗口视图（toggleterm 配置的 on_open 回调中调用）
---用 nvim_win_call 在目标窗口上下文执行，避免切换当前窗口触发额外重绘。
---每次打开后清空记录，确保只恢复本次打开前的视图。
function M.restore_main_view()
    if M._main_win and vim.api.nvim_win_is_valid(M._main_win) and M._main_view then
        vim.api.nvim_win_call(M._main_win, function()
            vim.fn.winrestview(M._main_view)
        end)
    end
    -- 用完即清，避免下次误恢复
    M._main_view = nil
    M._main_win = nil
end

---热刷新 Neovim 配置
---清空 config.* 模块缓存后重新加载 init.lua
function M.reload_config()
    local modules = {
        "config.options", "config.keymaps", "config.modlock",
        "config.bufops", "config.transparent", "config.other",
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
---打开 split 终端前记录主窗口视图，恢复动作由 toggleterm 的
---on_open 回调（见 plugins/core.lua）完成，避免内容晃动/偏移。
---@param id number 终端 ID
---@param direction string 方向：float / horizontal / vertical
---@param size number|nil 尺寸
function M.toggle_term(id, direction, size)
    -- 记录主窗口视图（split 方向才需要；float 不影响布局）
    if direction ~= "float" then
        M.record_main_view()
    end

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
---保存 nvim-tree 状态到会话伴随文件（会话名.tree.json）
---@param session_file string 会话 .vim 文件路径
function M.save_tree_state(session_file)
    local ok, api = pcall(require, "nvim-tree.api")
    if not ok then
        return
    end
    local state = {
        visible = api.tree.is_visible(),
        cwd = vim.fn.getcwd(),
        focused = "",
        expanded = {},   -- 展开的目录列表
        filters = nil,   -- 过滤状态（dotfiles / git_ignored 等）
    }
    if state.visible then
        -- 记录过滤开关状态（H: dotfiles, I: git_ignored 等）
        local explorer = require("nvim-tree.core").get_explorer()
        if explorer and explorer.filters and explorer.filters.state then
            state.filters = vim.deepcopy(explorer.filters.state)
        end
        -- 遍历树节点，收集所有展开的目录
        local explorer = require("nvim-tree.core").get_explorer()
        local function collect(node, acc)
            if node.type == "directory" and node.open and node.absolute_path then
                acc[#acc + 1] = node.absolute_path
            end
            for _, child in ipairs(node.nodes or {}) do
                collect(child, acc)
            end
        end
        if explorer then
            for _, node in ipairs(explorer.nodes or {}) do
                collect(node, state.expanded)
            end
        end
    end
    -- 从"非树窗口"中取正在编辑的文件作为树聚焦点
    local function file_in_win(win)
        local buf = vim.api.nvim_win_get_buf(win)
        if vim.bo[buf].buftype ~= "" then
            return ""
        end
        local name = vim.api.nvim_buf_get_name(buf)
        return (name ~= "" and vim.fn.fnamemodify(name, ":p")) or ""
    end
    -- 优先当前窗口的文件，否则取任一普通窗口的文件
    local current_file = file_in_win(vim.api.nvim_get_current_win())
    if current_file == "" then
        for _, win in ipairs(vim.api.nvim_list_wins()) do
            local n = file_in_win(win)
            if n ~= "" then
                current_file = n
                break
            end
        end
    end
    state.focused = current_file
    local state_file = session_file:gsub("%.vim$", "") .. ".tree.json"
    local f = io.open(state_file, "w")
    if f then
        f:write(vim.json.encode(state))
        f:close()
    end
end

---保存整个工作区：记录树状态，mksession 时保留树窗口
---（恢复时会由 restore_tree_state 清理残留树窗口）
---@param session_file string 会话 .vim 文件路径
function M.save_workspace(session_file)
    -- 记录树状态（树保持原样，不关闭、不重开）
    M.save_tree_state(session_file)

    vim.cmd("mksession! " .. vim.fn.fnameescape(session_file))
end

---恢复 nvim-tree 状态（打开/关闭、cwd、聚焦节点）
---@param session_file string 会话 .vim 文件路径
function M.restore_tree_state(session_file)
    local state_file = session_file:gsub("%.vim$", "") .. ".tree.json"
    local f = io.open(state_file, "r")
    if not f then
        return
    end
    local content = f:read("*a")
    f:close()
    local ok, state = pcall(vim.json.decode, content)
    if not ok or not state or not state.visible then
        return
    end
    vim.schedule(function()
        local ok2, api = pcall(require, "nvim-tree.api")
        if not ok2 then
            vim.notify("nvim-tree API 加载失败: " .. tostring(api), vim.log.levels.ERROR)
            return
        end

        -- 内部：应用树状态（过滤 + 展开 + 聚焦）
        local applied = false
        local in_progress = false
        local attempts = 0
        local function apply_state()
            if applied or in_progress then
                return
            end
            in_progress = true
            attempts = attempts + 1
            local explorer = require("nvim-tree.core").get_explorer()
            if not explorer then
                if attempts < 40 then
                    in_progress = false
                    vim.defer_fn(apply_state, 50)
                end
                return
            end
            -- 恢复过滤状态（H: dotfiles / I: git_ignored 等）
            if type(state.filters) == "table" then
                if explorer.filters then
                    local cur = explorer.filters.state
                    for k, v in pairs(state.filters) do
                        if cur[k] ~= nil and cur[k] ~= v then
                            pcall(function()
                                explorer.filters:toggle(k)
                            end)
                        end
                    end
                end
            end

            -- 逐个展开保存时展开的目录（先浅后深，保持层级）
            if type(state.expanded) == "table" and #state.expanded > 0 then
                local dirs = vim.deepcopy(state.expanded)
                table.sort(dirs, function(a, b)
                    local da = select(2, a:gsub("/", ""))
                    local db = select(2, b:gsub("/", ""))
                    return da < db
                end)
                local all_done = true
                for _, dir in ipairs(dirs) do
                    local node = explorer:get_node_from_path(dir)
                    if node then
                        node.open = true
                        explorer:expand_dir_node(node)
                    else
                        all_done = false
                    end
                end
                -- 关键：展开后必须重绘，否则 GUI 显示不刷新
                if all_done and explorer.renderer then
                    explorer.renderer:draw()
                end
                -- 目录还没就绪则稍后重试
                if not all_done then
                    if attempts < 40 then
                        in_progress = false
                        vim.defer_fn(apply_state, 100)
                        return
                    end
                end
            end

            applied = true
            in_progress = false

            -- 在树中定位保存时的文件（不抢焦点）
            if state.focused and state.focused ~= "" then
                pcall(function()
                    api.tree.find_file({ path = state.focused, open = true, focus = false })
                end)
            end
            -- 最后把焦点放回显示该文件的窗口，保留 mksession 恢复的光标行
            if state.focused and state.focused ~= "" then
                local target_win = vim.fn.bufwinid(vim.fn.bufnr(state.focused))
                if target_win and target_win > 0 then
                    pcall(vim.api.nvim_set_current_win, target_win)
                end
            end
        end

        -- 清理老会话可能残留的树空窗口（mksession 保存的 enew+NvimTree_x）
        for _, win in ipairs(vim.api.nvim_list_wins()) do
            local buf = vim.api.nvim_win_get_buf(win)
            local name = vim.api.nvim_buf_get_name(buf)
            if name:match("NvimTree_") and vim.bo[buf].buftype == "" then
                pcall(vim.api.nvim_win_close, win, false)
            end
        end

        -- 检查是否有"真正的"树窗口（filetype=NvimTree），而非 nvim-tree 内部状态
        local has_real_tree = false
        for _, win in ipairs(vim.api.nvim_list_wins()) do
            local buf = vim.api.nvim_win_get_buf(win)
            if vim.bo[buf].filetype == "NvimTree" then
                has_real_tree = true
                break
            end
        end

        if has_real_tree then
            -- 树已真实打开：目录不同则切换根目录
            local explorer = require("nvim-tree.core").get_explorer()
            local cur_cwd = explorer and explorer.absolute_path or nil
            if cur_cwd ~= state.cwd then
                pcall(function()
                    require("nvim-tree.api").tree.change_root(state.cwd)
                end)
            end
        else
            -- 无真实树窗口：直接打开（source 会话后 nvim-tree 内部状态不可信）
            api.tree.open({ path = state.cwd })
        end

        -- 树渲染完成后应用状态（TreeRendered 事件驱动，时序最可靠）
        local ok_sub, _ = pcall(function()
            api.events.subscribe(api.events.Event.TreeRendered, function()
                apply_state()
            end)
        end)
        -- 兜底：事件未触发时也尝试（open 后 300ms 起，最多 40 次重试）
        if ok_sub then
            vim.defer_fn(apply_state, 300)
        else
            vim.defer_fn(apply_state, 100)
        end
    end)
end

---清理失效会话（会话文件对应的目录已不存在则删除）
function M.cleanup_stale_sessions()
    local session_dir = vim.fn.stdpath("state") .. "/sessions/"
    if vim.fn.isdirectory(session_dir) == 0 then
        return
    end
    local files = vim.fn.glob(session_dir .. "*.vim", false, true)
    local removed = 0
    for _, file in ipairs(files) do
        local name = vim.fn.fnamemodify(file, ":t"):gsub("%.vim$", "")
        -- 解码会话文件名：%home%alise%a → /home/alise/a
        local dir = name:gsub("%%", "/")
        if dir ~= "" and vim.fn.isdirectory(dir) == 0 then
            os.remove(file)
            -- 连带删除树状态伴随文件
            os.remove(file:gsub("%.vim$", "") .. ".tree.json")
            removed = removed + 1
        end
    end
    if removed > 0 then
        vim.notify(("已清理 %d 个失效会话"):format(removed), vim.log.levels.INFO)
    end
end

---用 Telescope 列出并选择会话
---@param scroll_to string|nil 删除后恢复光标位置的文件名
function M.select_session(scroll_to)
    -- 先清理失效会话
    M.cleanup_stale_sessions()
    local session_dir = vim.fn.stdpath("state") .. "/sessions/"
    if vim.fn.isdirectory(session_dir) == 0 then
        vim.notify("没有保存的会话", vim.log.levels.INFO)
        return
    end
    -- 只列出 .vim 会话文件（过滤掉 .tree.json 伴随文件等）
    require("telescope.builtin").find_files({
        prompt_title = " Sessions",
        cwd = session_dir,
        file_ignore_patterns = { "%.tree%.json$" },
        attach_mappings = function(prompt_bufnr, _)
            local actions = require("telescope.actions")
            local state = require("telescope.actions.state")

            -- Alt+d 永久删除会话文件：用 Telescope 官方的 delete_selection，
            -- 删除后自动从结果中移除该条目并刷新，picker 不关闭、无闪烁
            vim.api.nvim_buf_set_keymap(prompt_bufnr, "i", "<A-d>", "", {
                noremap = true,
                callback = function()
                    local picker = state.get_current_picker(prompt_bufnr)
                    if not picker then
                        return
                    end
                    picker:delete_selection(function(selection)
                        local filename = selection.value or selection[1] or ""
                        if filename ~= "" then
                            -- 删除会话文件及其树状态伴随文件
                            os.remove(session_dir .. filename)
                            os.remove(session_dir .. filename:gsub("%.vim$", "") .. ".tree.json")
                        end
                        return true -- 从结果列表中移除该条目
                    end)
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
                            M.restore_tree_state(file)
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
