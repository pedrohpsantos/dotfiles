-- ============================================================================
-- ~/.config/nvim/lua/plugins/ui.lua — Catppuccin Mocha, Lualine, Snacks & UI
-- ============================================================================
return {
  -- Icons
  {
    "nvim-tree/nvim-web-devicons",
    lazy = true,
  },

  -- Colorscheme: Catppuccin Mocha
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    priority = 1000,
    opts = {
      flavour = "mocha",
      transparent_background = true,
      integrations = {
        blink_cmp = true,
        flash = true,
        gitsigns = true,
        indent_blankline = { enabled = true },
        mini = { enabled = true },
        native_lsp = {
          enabled = true,
          underlines = {
            errors = { "undercurl" },
            hints = { "undercurl" },
            warnings = { "undercurl" },
            information = { "undercurl" },
          },
        },
        snacks = true,
        telescope = { enabled = true },
        treesitter = true,
        trouble = true,
        which_key = true,
      },
    },
    config = function(_, opts)
      require("catppuccin").setup(opts)
      vim.cmd.colorscheme("catppuccin")
    end,
  },

  -- Statusline: Lualine (Fixed theme = "catppuccin-mocha" to eliminate LualineNotices)
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      options = {
        theme = "catppuccin-mocha",
        globalstatus = true,
        icons_enabled = true,
        component_separators = { left = "│", right = "│" },
        section_separators = { left = "", right = "" },
        disabled_filetypes = { statusline = { "dashboard", "snacks_dashboard" } },
      },
      sections = {
        lualine_a = { { "mode", separator = { left = "", right = "" }, right_padding = 2 } },
        lualine_b = { "branch", "diff", "diagnostics" },
        lualine_c = { { "filename", path = 1 } },
        lualine_x = {
          {
            function()
              local clients = vim.lsp.get_clients({ bufnr = 0 })
              if #clients == 0 then
                return ""
              end
              local names = {}
              for _, c in ipairs(clients) do
                table.insert(names, c.name)
              end
              return " " .. table.concat(names, ",")
            end,
          },
          "encoding",
          "fileformat",
          "filetype",
        },
        lualine_y = { "progress" },
        lualine_z = { { "location", separator = { left = "", right = "" }, left_padding = 2 } },
      },
    },
  },

  -- Bufferline: LazyVim tab/buffer bar
  {
    "akinsho/bufferline.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    keys = {
      { "<leader>bp", "<Cmd>BufferLineTogglePin<CR>", desc = "Toggle Pin" },
      { "<leader>bP", "<Cmd>BufferLineGroupClose ungrouped<CR>", desc = "Delete Non-Pinned Buffers" },
      { "<leader>bo", "<Cmd>BufferLineCloseOthers<CR>", desc = "Delete Other Buffers" },
      { "<leader>br", "<Cmd>BufferLineCloseRight<CR>", desc = "Delete Buffers to the Right" },
      { "<leader>bl", "<Cmd>BufferLineCloseLeft<CR>", desc = "Delete Buffers to the Left" },
    },
    opts = {
      options = {
        diagnostics = "nvim_lsp",
        always_show_bufferline = false,
        show_buffer_close_icons = false,
        show_close_icon = false,
        separator_style = "thin",
      },
    },
  },

  -- Snacks.nvim: LazyVim's modern Swiss-army knife (LazyGit, LazyDocker, Btop, Terminal, Dashboard, Notifier)
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    opts = {
      bigfile = { enabled = true },
      dashboard = {
        enabled = true,
        preset = {
          header = [[
   █████╗ ██╗     ██████╗ ██╗███╗   ██╗███████╗    ███╗   ██╗██╗   ██╗██╗███╗   ███╗
  ██╔══██╗██║     ██╔══██╗██║████╗  ██║██╔════╝    ████╗  ██║██║   ██║██║████╗ ████║
  ███████║██║     ██████╔╝██║██╔██╗ ██║█████╗      ██╔██╗ ██║██║   ██║██║██╔████╔██║
  ██╔══██║██║     ██╔═══╝ ██║██║╚██╗██║██╔══╝      ██║╚██╗██║╚██╗ ██╔╝██║██║╚██╔╝██║
  ██║  ██║███████╗██║     ██║██║ ╚████║███████╗    ██║ ╚████║ ╚████╔╝ ██║██║ ╚═╝ ██║
  ╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚═╝  ╚═══╝╚══════╝    ╚═╝  ╚═══╝  ╚═══╝  ╚═╝╚═╝     ╚═╝
          Alpine WSL 2 · Native musl LSP · LazyGit · LazyDocker · Yazi]],
          keys = {
            { icon = " ", key = "f", desc = "Find File", action = ":Telescope find_files" },
            { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
            { icon = " ", key = "g", desc = "Find Text (Ripgrep)", action = ":Telescope live_grep" },
            { icon = " ", key = "r", desc = "Recent Files", action = ":Telescope oldfiles" },
            { icon = " ", key = "l", desc = "LazyGit", action = function() Snacks.lazygit() end },
            { icon = " ", key = "d", desc = "LazyDocker", action = function() Snacks.terminal("lazydocker") end },
            { icon = " ", key = "c", desc = "Config", action = ":Telescope find_files cwd=" .. vim.fn.stdpath("config") },
            { icon = "󰒲 ", key = "L", desc = "Lazy Plugins", action = ":Lazy" },
            { icon = " ", key = "q", desc = "Quit", action = ":qa" },
          },
        },
      },
      indent = { enabled = true },
      input = { enabled = true },
      lazygit = { enabled = true },
      notifier = { enabled = true, timeout = 3000 },
      quickfile = { enabled = true },
      statuscolumn = { enabled = true },
      terminal = { enabled = true },
      words = { enabled = true },
    },
    keys = {
      { "<leader>gg", function() Snacks.lazygit() end, desc = "Lazygit (Root Dir)" },
      { "<leader>gf", function() Snacks.lazygit.log_file() end, desc = "Lazygit Current File History" },
      { "<leader>gl", function() Snacks.lazygit.log() end, desc = "Lazygit Log (CWD)" },
      { "<leader>gB", function() Snacks.git.blame_line() end, desc = "Git Blame Line" },
      { "<leader>dd", function() Snacks.terminal("lazydocker", { win = { style = "float", width = 0.92, height = 0.92, border = "rounded" } }) end, desc = "LazyDocker Floating TUI" },
      { "<leader>ob", function() Snacks.terminal("btop", { win = { style = "float", width = 0.92, height = 0.92, border = "rounded" } }) end, desc = "Btop System Monitor" },
      { "<leader>fy", function() Snacks.terminal("yazi", { win = { style = "float", width = 0.92, height = 0.92, border = "rounded" } }) end, desc = "Yazi File Manager" },
      { "<leader>ft", function() Snacks.terminal() end, desc = "Toggle Terminal" },
      { "<C-/>",      function() Snacks.terminal() end, desc = "Toggle Terminal", mode = { "n", "t" } },
      { "<C-_>",      function() Snacks.terminal() end, desc = "which_key_ignore", mode = { "n", "t" } },
      { "<leader>un", function() Snacks.notifier.hide() end, desc = "Dismiss All Notifications" },
      { "<leader>nh", function() Snacks.notifier.show_history() end, desc = "Notification History" },
      { "<leader>cR", function() Snacks.rename.rename_file() end, desc = "Rename File" },
      { "]]",         function() Snacks.words.jump(vim.v.count1) end, desc = "Next Reference", mode = { "n", "t" } },
      { "[[",         function() Snacks.words.jump(-vim.v.count1) end, desc = "Prev Reference", mode = { "n", "t" } },
    },
  },

  -- Which-Key: LazyVim group labels & keybind hints
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      preset = "helix",
      spec = {
        { "<leader>b", group = "buffer" },
        { "<leader>c", group = "code" },
        { "<leader>d", group = "docker / diagnostics" },
        { "<leader>f", group = "file / find" },
        { "<leader>g", group = "git (lazygit)" },
        { "<leader>gh", group = "hunks" },
        { "<leader>n", group = "notifications" },
        { "<leader>o", group = "ops / btop" },
        { "<leader>q", group = "quit / session" },
        { "<leader>s", group = "search" },
        { "<leader>u", group = "ui / toggles" },
        { "<leader>w", group = "windows / save" },
        { "<leader>x", group = "diagnostics / quickfix" },
        { "[", group = "prev" },
        { "]", group = "next" },
        { "g", group = "goto" },
      },
    },
  },
}
