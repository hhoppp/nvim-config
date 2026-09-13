-- Codeforces 直连抓题：不经过 Competitive Companion 浏览器扩展
-- 仓库: https://github.com/yunusey/codeforces-nvim
-- 外部依赖（不在插件内）：codeforces-extractor (cargo) + Chromium
-- 抓题目录结构: <cf_path>/contests/{test,solutions,templates}/<contest-id>
return {
  "yunusey/codeforces-nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "akinsho/toggleterm.nvim",
  },
  -- 不用 cmd/event 懒加载，保证命令一定被注册
  config = function()
    require("codeforces-nvim").setup({
      -- 绝对路径（插件要求）
      cf_path = vim.fn.expand("~/Documents/code/codeforces"),

      -- 没装 Xvfb 时保持 true：抓题会短暂弹出 Chromium 窗口（更可靠）
      -- 装了 Xvfb 后改成 false：改用虚拟显示，不再弹窗
      use_native_display = true ,

      extension = "cpp",
      timeout = 15000,
      use_term_toggle = true,

      compiler = { cpp = { "g++", "@.cpp", "-o", "@", "-std=c++17" } },
      run = { cpp = { "@" } },

      -- 打开模板后光标落点：对应 template.cpp 中 solve() 的空行
      -- 若你以后改模板，需要同步这个行号
      lines = { cpp = 5 },
    })

    -- ============================================================
    -- 个性化覆盖：:EnterContest / :QNext 不再新开 tab，
    -- 而是在当前窗口打开并聚焦 buffer。
    -- 放在这里覆盖而非改插件源码 —— :Lazy update 不会丢失。
    -- 原理：插件的命令回调是"调用时查表"（codeforces.enter_contest /
    -- M.next_question），所以替换模块表上的函数即可生效。
    -- ============================================================
    local cf = require("codeforces-nvim.codeforces")
    local uc = require("codeforces-nvim.user_commands")

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
  end,
}
