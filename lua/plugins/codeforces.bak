-- Codeforces 直连抓题：不经过 Competitive Companion 浏览器扩展
-- 仓库: https://github.com/yunusey/codeforces-nvim
-- 外部依赖（不在插件内）：codeforces-extractor (cargo) + Chromium
-- 抓题目录结构: <cf_path>/contests/{test,solutions,templates}/<contest-id>
return {
  "yunusey/codeforces-nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    -- 不用 toggleterm：本插件自己管理运行窗口，见下方 run_in_window
  },
  -- 不用 cmd/event 懒加载，保证命令一定被注册
  config = function()
    require("codeforces-nvim").setup({
      -- 绝对路径（插件要求）
      cf_path = vim.fn.expand("~/Documents/code/codeforces"),

      -- Xvfb 已安装（xorg-server-xvfb），用虚拟显示抓题，不再弹出 Chromium 窗口
      use_native_display = false,

      extension = "cpp",
      timeout = 15000,

      -- 已不用 toggleterm
      use_term_toggle = false,

      compiler = { cpp = { "g++", "@.cpp", "-o", "@", "-std=c++17" } },
      run = { cpp = { "@" } },

      -- 打开模板后光标落点：对应 template.cpp 中 solve() 的空行
      -- 若你以后改模板，需要同步这个行号
      lines = { cpp = 5 },

      -- 插件默认把 success 也当成 WARN 发，导致"编译成功/样例通过"也弹警告
      -- 这里改成：success -> INFO，error -> ERROR
      notify = function(title, message, type)
        local level = type == "success" and vim.log.levels.INFO or vim.log.levels.ERROR
        vim.notify(message and (title .. "\n" .. message) or title, level)
      end,
    })

    -- ============================================================
    -- 个性化覆盖。放在 config 里覆盖而非改插件源码，
    -- 这样 :Lazy update 不会丢失。
    -- 原理：插件的命令回调是"调用时查表"（codeforces.enter_contest /
    -- M.next_question / commands.run_normally），替换模块表上的函数即可生效。
    -- ============================================================
    local cf = require("codeforces-nvim.codeforces")
    local uc = require("codeforces-nvim.user_commands")
    local cmds = require("codeforces-nvim.commands")

    --- 把 path 打开到当前窗口并聚焦。
    --- 若该文件已显示在某个窗口，则直接聚焦那个窗口（不重复打开）。
    --- @param path string
    local function focus_file(path)
      local abs = vim.fn.fnamemodify(path, ":p")
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        local buf = vim.api.nvim_win_get_buf(win)
        local name = vim.api.nvim_buf_get_name(buf)
        if name ~= "" and vim.fn.fnamemodify(name, ":p") == abs then
          vim.api.nvim_set_current_win(win)
          return buf
        end
      end
      -- bufadd 会复用已存在的 buffer，不会重复创建
      local buf = vim.fn.bufadd(abs)
      vim.fn.bufload(buf)
      vim.api.nvim_set_current_buf(buf)
      return buf
    end

    --- 覆盖 :EnterContest
    --- 顺带修插件 bug：原实现调用 fetch_problems 时漏传 use_native_display，
    --- 导致 exit_function 被当成该参数、结束时调用 nil 报错。
    cf.enter_contest = function(cont)
      cf.current_contest = cont
      if cf.current_contest == nil or cf.current_contest == "" then
        cf.current_contest = vim.fn.input({
          prompt = "Please enter the contest: ",
          default = "17",
        })
      end

      local test_directory = vim.fs.joinpath(cf.paths.tests, cf.current_contest)
      local found_contest = vim.fn.isdirectory(test_directory) == 1

      local exit_function = function()
        cf.create_contest(cf.current_contest)
        cf.current_problem = 1

        if #cf.problems == 0 then return end

        local solution_file = cf.get_solution_file(cf.problems[cf.current_problem], cf.options.extension)
        vim.fn.chdir(vim.fs.joinpath(cf.paths.solutions, cf.current_contest))
        focus_file(solution_file)
        vim.api.nvim_win_set_cursor(0, { cf.options.lines[cf.options.extension], 0 })
      end

      if found_contest == false then
        cf.fetch_problems(cf.current_contest, test_directory, cf.options.use_native_display, exit_function)
      else
        exit_function()
      end
    end

    --- 覆盖 :QNext
    uc.next_question = function(jump)
      if #cf.problems == 0 then
        vim.notify("codeforces-nvim: 还没有加载题目，请先 :EnterContest", vim.log.levels.WARN)
        return
      end
      cf.current_problem = (cf.current_problem + jump - 1) % #cf.problems + 1
      local solution_file = cf.get_solution_file(cf.problems[cf.current_problem], cf.options.extension)
      focus_file(solution_file)
      vim.api.nvim_win_set_cursor(0, { cf.options.lines[cf.options.extension], 0 })
    end

    -- ============================================================
    -- 运行窗口：不用 toggleterm。
    -- 一个固定窗口 + 每次新建的终端 buffer，不开新 tab、不弹浮窗。
    -- 在窗口里按 q 关闭；按 Esc 从终端模式回到普通模式。
    -- ============================================================
    local run_win = nil

    --- @param cmd string 要在终端里执行的 shell 命令
    local function run_in_window(cmd)
      if run_win and vim.api.nvim_win_is_valid(run_win) then
        vim.api.nvim_set_current_win(run_win)
      else
        -- 在当前 tab 底部开一个窗口（绝不是新 tab）
        vim.cmd("botright split")
        run_win = vim.api.nvim_get_current_win()
      end

      -- 用全新 scratch buffer，避免 enew 在文件有未保存改动时报 E37
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_win_set_buf(run_win, buf)
      -- 切走时自动 wipe，顺带结束上一个终端进程
      vim.bo[buf].bufhidden = "wipe"
      vim.fn.termopen(cmd)
      vim.cmd("startinsert")

      -- q 关闭运行窗口
      vim.keymap.set("n", "q", function()
        if run_win and vim.api.nvim_win_is_valid(run_win) then
          vim.api.nvim_win_close(run_win, true)
        end
      end, { buffer = true, desc = "Close run window" })

      -- 终端模式下 Esc 回到普通模式（否则 Esc 会被送给程序）
      vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], { buffer = true, desc = "Terminal normal mode" })
    end

    --- 把插件里的 @（当前题目）展开成实际路径
    --- @param problem string
    --- @param t string[]
    local function expand_at(problem, t)
      local exe = cf.get_solution_file(problem, nil)
      return vim.tbl_map(function(s)
        return (s:gsub("@", exe))
      end, t)
    end

    --- 覆盖 :RunCurrent
    cmds.run_normally = function(problem)
      local compiler = expand_at(problem, cf.options.compiler[cf.options.extension] or {})
      local function run()
        run_in_window(table.concat(expand_at(problem, cf.options.run[cf.options.extension] or {}), " "))
      end

      if #compiler > 0 then
        cmds.compile(compiler, run)
      else
        run()
      end
    end

    --- 覆盖 :RetrieveLastTestCase（以及 :CreateTestCase 里回车触发的运行）
    cmds.run_custom_test = function(problem)
      local input = vim.fs.joinpath(
        cf.paths.solutions,
        cf.get_current_contest(),
        string.format("custom-%s.in", problem)
      )
      run_in_window(
        table.concat(expand_at(problem, cf.options.run[cf.options.extension] or {}), " ") .. " < " .. input
      )
    end

    -- ============================================================
    -- 覆盖样例失败时的 diff：用当前 tab 的窗口，而不是 :tabnew
    -- 两个窗口都绑定 q 关闭
    -- ============================================================
    cmds.handle_differences = function(errors)
      local user_output_content = {}
      local expected_output_content = {}
      for _, i in pairs(errors) do
        local test_case = i[1]
        table.insert(user_output_content, "Test Case: " .. test_case)
        table.insert(expected_output_content, "Test Case: " .. test_case)
        for _, j in pairs(i[2] or {}) do
          table.insert(user_output_content, j)
        end
        for _, j in pairs(i[3] or {}) do
          table.insert(expected_output_content, j)
        end
      end

      local user_file = vim.fn.tempname()
      local expected_file = vim.fn.tempname()
      vim.fn.writefile(user_output_content, user_file)
      vim.fn.writefile(expected_output_content, expected_file)

      -- 在当前 tab 底部开窗口（不是新 tab），再纵向 diff
      vim.cmd("botright split " .. vim.fn.fnameescape(user_file))
      vim.cmd("vert diffsplit " .. vim.fn.fnameescape(expected_file))

      --- 关闭当前窗口；若是本 tab 最后一个窗口则留一个空 buffer
      local function close_win()
        if #vim.api.nvim_tabpage_list_wins(0) > 1 then
          vim.api.nvim_win_close(0, false)
        else
          vim.cmd("enew")
        end
      end

      for _, b in ipairs({ vim.fn.bufnr(user_file), vim.fn.bufnr(expected_file) }) do
        if b > 0 then
          vim.keymap.set("n", "q", close_win, { buffer = b, desc = "Close diff window" })
        end
      end
    end
  end,
}
