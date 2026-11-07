-- ============================================================================
-- ~/.config/nvim/lua/plugins/coding.lua — Completion, Formatting & Editing
-- ============================================================================
return {
  -- Blink.cmp: Ultra-fast completion engine (Pure Lua fallback safe on Alpine musl)
  {
    "saghen/blink.cmp",
    event = "InsertEnter",
    version = "1.*",
    opts = {
      keymap = {
        preset = "enter",
        ["<C-y>"] = { "select_and_accept" },
        ["<Tab>"] = { "select_next", "snippet_forward", "fallback" },
        ["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
      },
      appearance = {
        nerd_font_variant = "mono",
      },
      completion = {
        accept = { auto_brackets = { enabled = true } },
        documentation = { auto_show = true, auto_show_delay_ms = 150 },
        ghost_text = { enabled = false },
      },
      sources = {
        default = { "lsp", "path", "snippets", "buffer" },
      },
      fuzzy = {
        implementation = "lua",
      },
      signature = { enabled = true },
    },
  },

  -- Conform.nvim: Fast format-on-save using native Alpine musl formatters
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    keys = {
      {
        "<leader>cf",
        function()
          require("conform").format({ async = true, lsp_format = "fallback" })
        end,
        mode = { "n", "v" },
        desc = "Format Buffer (Conform)",
      },
      {
        "<leader>f",
        function()
          require("conform").format({ async = true, lsp_format = "fallback" })
        end,
        mode = { "n", "v" },
        desc = "Format Buffer",
      },
    },
    opts = {
      formatters_by_ft = {
        lua = { "stylua" },
        python = { "ruff_organize_imports", "ruff_format" },
        go = { "gofmt" },
        rust = { "rustfmt" },
        c = { "clang-format" },
        cpp = { "clang-format" },
        sh = { "shfmt" },
        bash = { "shfmt" },
        zsh = { "shfmt" },
        toml = { "taplo" },
        json = { "jq" },
      },
      format_on_save = function(bufnr)
        if not vim.g.autoformat or vim.b[bufnr].disable_autoformat then
          return
        end
        return { timeout_ms = 1500, lsp_format = "fallback" }
      end,
    },
  },

  -- Mini.pairs: Automatic bracket pairing
  {
    "echasnovski/mini.pairs",
    event = "VeryLazy",
    opts = {
      modes = { insert = true, command = false, terminal = false },
    },
  },

  -- Mini.surround: Fast surround actions (gsa, gsd, gsr)
  {
    "echasnovski/mini.surround",
    keys = {
      { "gsa", desc = "Add Surrounding", mode = { "n", "v" } },
      { "gsd", desc = "Delete Surrounding" },
      { "gsf", desc = "Find Right Surrounding" },
      { "gsF", desc = "Find Left Surrounding" },
      { "gsh", desc = "Highlight Surrounding" },
      { "gsr", desc = "Replace Surrounding" },
    },
    opts = {
      mappings = {
        add = "gsa",
        delete = "gsd",
        find = "gsf",
        find_left = "gsF",
        highlight = "gsh",
        replace = "gsr",
        update_n_lines = "gsn",
      },
    },
  },
}
