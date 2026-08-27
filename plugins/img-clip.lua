-- img-clip.nvim —— 剪贴板图片粘贴进 markdown（参考 patricorgi/dotfiles，适配本机知识库）
-- 用法：复制截图后，在 md 文件里按 <leader>P，图片存到 attachments/ 并插入引用
return {
    "HakonHarnes/img-clip.nvim",
    ft = { "markdown" },
    keys = {
        { "<leader>P", function() require("img-clip").pasteImage() end, desc = "粘贴剪贴板图片", ft = "markdown" },
    },
    opts = {
        default = {
            -- 图片统一放库根的 attachments/（Obsidian 也能识别）
            dir_path = "attachments",
            use_absolute_path = false,
            copy_images = true,
            prompt_for_file_name = false,
            file_name = "%Y%m%d-%H%M%S",
            extension = "png",
            -- 不依赖 ImageMagick（视频作者用 avif+magick，本机从简）
            process_cmd = "",
        },
        filetypes = {
            markdown = {
                template = "![$CURSOR]($FILE_PATH)",
            },
        },
    },
}
