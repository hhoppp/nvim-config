-- markdown 专属：wikilink [[...]] 跳转 + 返回
-- 光标在 [[链接]] 上按 <CR> 打开目标文件；<BS> 用 jumplist 返回
--
-- 注意：gmatch 的第二个捕获是链接内容(字符串)不是位置；
-- nvim 的 win_get_cursor col 是 0-based 字节偏移，与 string.gmatch 的
-- 1-based 字节起始位置比较时需 +1。

local function vault_root()
    -- 从当前文件向上找 .obsidian 目录 = 库根；找不到则退回文件所在目录
    local dir = vim.fn.expand("%:p:h")
    while dir ~= "/" do
        if vim.fn.isdirectory(dir .. "/.obsidian") == 1 then return dir end
        dir = vim.fn.fnamemodify(dir, ":h")
    end
    return vim.fn.expand("%:p:h")
end

local function find_note(fname)
    fname = vim.trim(fname)
    if fname == "" then return nil end
    -- 0) 带扩展名的目标（如 .base）：直接按原样查
    if fname:match("%.[a-z]+$") then
        local hits = vim.fn.glob(vault_root() .. "/**/" .. fname, false, true)
        if #hits > 0 then return hits[1] end
    end
    -- 1) 相对当前文件目录
    local hits = vim.fn.glob(vim.fn.expand("%:p:h") .. "/" .. fname .. ".md", false, true)
    -- 2) 相对库根
    if #hits == 0 then
        hits = vim.fn.glob(vault_root() .. "/" .. fname .. ".md", false, true)
    end
    -- 3) 库根下递归模糊查找
    if #hits == 0 then
        hits = vim.fn.glob(vault_root() .. "/**/" .. fname .. ".md", false, true)
    end
    if #hits == 0 then return nil end
    -- basename 精确匹配优先
    for _, h in ipairs(hits) do
        if vim.fn.fnamemodify(h, ":t:r") == fname then return h end
    end
    return hits[1]
end

vim.keymap.set("n", "<CR>", function()
    local line = vim.api.nvim_get_current_line()
    local col1 = vim.api.nvim_win_get_cursor(0)[2] + 1  -- 0-based → 1-based 字节偏移
    for st, content in line:gmatch("()%[%[([^%]|#]*)") do
        local e = st + #content + 3  -- 链接结束位置（含 ]])
        if col1 >= st and col1 <= e then
            local target = content:match("^([^|#]*)") or ""
            local path = find_note(target)
            if not path then
                vim.notify("[md] 找不到笔记: " .. vim.trim(target), vim.log.levels.WARN)
                return
            end
            vim.cmd("edit " .. vim.fn.fnameescape(path))
            return
        end
    end
    -- 不在任何 wikilink 上：退回 LSP 定义跳转
    vim.lsp.buf.definition()
end, { buffer = true, silent = true, desc = "跳转到 wikilink 目标" })

vim.keymap.set("n", "<BS>", "<C-o>", { remap = true, buffer = true })
