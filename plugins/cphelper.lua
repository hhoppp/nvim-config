return {
  "cphelper",
  url = "https://git.sr.ht/~chinmay/cphelper.nvim",
  dependencies = { "MunifTanjim/nui.nvim" },
  lazy = false,
  init = function()
    vim.g["cph#dir"] = vim.fn.expand("~/Documents/code/codeforces")
    vim.g["cph#lang"] = "cpp"
    vim.g["cph#timeout"] = 2000
    vim.g["cph#border"] = "rounded"
    vim.g["cph#vsplit"] = true
    vim.g["cph#cpp#compile_command"] = { "g++", "solution.cpp", "-o", "cpp.out", "-std=c++17" }
  end,
}
