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
      use_native_display = true,

      extension = "cpp",
      timeout = 15000,
      use_term_toggle = true,

      compiler = { cpp = { "g++", "@.cpp", "-o", "@", "-std=c++17" } },
      run = { cpp = { "@" } },

      -- 打开模板后光标落点：对应 template.cpp 中 solve() 的空行
      -- 若你以后改模板，需要同步这个行号
      lines = { cpp = 17 },
    })
  end,
}
