-- ============================================================================
-- ~/.config/nvim/lua/config/lsp.lua — Native musl LSPs (Neovim 0.11)
-- No Mason / no glibc binaries. Uses system APK musl binaries directly.
-- ============================================================================
local map = vim.keymap.set

local servers = {
  clangd = {
    cmd = {
      "clangd",
      "--background-index",
      "--clang-tidy",
      "--header-insertion=iwyu",
      "--completion-style=detailed",
      "--function-arg-placeholders",
      "--fallback-style=llvm",
    },
    filetypes = { "c", "cpp", "objc", "objcpp", "cuda" },
    root_markers = { "compile_commands.json", ".clangd", "CMakeLists.txt", "Makefile", ".git" },
  },
  gopls = {
    cmd = { "gopls" },
    filetypes = { "go", "gomod", "gowork", "gotmpl" },
    root_markers = { "go.work", "go.mod", ".git" },
    settings = {
      gopls = {
        analyses = { unusedparams = true, shadow = true },
        staticcheck = true,
        gofumpt = true,
        hints = {
          assignVariableTypes = true,
          compositeLiteralFields = true,
          constantValues = true,
          functionTypeParameters = true,
          parameterNames = true,
          rangeVariableTypes = true,
        },
      },
    },
  },
  rust_analyzer = {
    cmd = { "rust-analyzer" },
    filetypes = { "rust" },
    root_markers = { "Cargo.toml", "rust-project.json", ".git" },
    settings = {
      ["rust-analyzer"] = {
        cargo = { allFeatures = true },
        checkOnSave = { command = "clippy" },
      },
    },
  },
  ruff = {
    cmd = { "ruff", "server" },
    filetypes = { "python" },
    root_markers = { "pyproject.toml", "ruff.toml", ".ruff.toml", "setup.py", ".git" },
  },
  lua_ls = {
    cmd = { "lua-language-server" },
    filetypes = { "lua" },
    root_markers = { ".luarc.json", ".luarc.jsonc", ".stylua.toml", "stylua.toml", ".git" },
    settings = {
      Lua = {
        runtime = { version = "LuaJIT" },
        workspace = {
          checkThirdParty = false,
          library = { vim.env.VIMRUNTIME },
        },
        diagnostics = { globals = { "vim" } },
        completion = { callSnippet = "Replace" },
        hint = { enable = true, setType = false, paramType = true, paramName = "Disable" },
      },
    },
  },
  taplo = {
    cmd = { "taplo", "lsp", "stdio" },
    filetypes = { "toml" },
    root_markers = { ".taplo.toml", "taplo.toml", "Cargo.toml", "pyproject.toml", ".git" },
  },
}

if vim.lsp and vim.lsp.config then
  for name, cfg in pairs(servers) do
    if vim.fn.executable(cfg.cmd[1]) == 1 then
      vim.lsp.config[name] = cfg
      vim.lsp.enable(name)
    end
  end
end

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    local bmap = function(mode, lhs, rhs, desc)
      map(mode, lhs, rhs, { buffer = ev.buf, desc = desc })
    end

    bmap("n", "gd", vim.lsp.buf.definition, "Goto Definition")
    bmap("n", "gD", vim.lsp.buf.declaration, "Goto Declaration")
    bmap("n", "gr", vim.lsp.buf.references, "References")
    bmap("n", "gI", vim.lsp.buf.implementation, "Goto Implementation")
    bmap("n", "gy", vim.lsp.buf.type_definition, "Goto Type Definition")
    bmap("n", "K", vim.lsp.buf.hover, "Hover Documentation")
    bmap("n", "gK", vim.lsp.buf.signature_help, "Signature Help")
    bmap("i", "<C-k>", vim.lsp.buf.signature_help, "Signature Help")
    bmap("n", "<leader>cr", vim.lsp.buf.rename, "Rename Symbol (LazyVim)")
    bmap("n", "<leader>rn", vim.lsp.buf.rename, "Rename Symbol")
    bmap({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, "Code Action")

    -- Toggle Inlay Hints (<leader>uh) if supported by server
    if client and client:supports_method("textDocument/inlayHint") then
      bmap("n", "<leader>uh", function()
        local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = ev.buf })
        vim.lsp.inlay_hint.enable(not enabled, { bufnr = ev.buf })
        vim.notify("Inlay Hints: " .. (not enabled and "ON" or "OFF"), vim.log.levels.INFO)
      end, "Toggle Inlay Hints")
    end
  end,
})
