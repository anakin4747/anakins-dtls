vim.lsp.set_log_level("debug")
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
    pattern = { "*.dts", "*.dtsi" },
    callback = function()
        vim.lsp.start({
            name = "anakins-dtls",
            cmd = { "anakins-dtls" },
            root_dir = vim.fn.getcwd(),
            filetypes = { "dts" },
        })
    end,
})
