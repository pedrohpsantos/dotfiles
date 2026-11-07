#  Alpine Linux WSL 2 & Windows 11 Catppuccin Mocha Dotfiles (2026)

Infraestrutura pessoal de desenvolvimento declarativa, modular e reproduzível para **Alpine Linux 3.23 (`musl` / BusyBox / OpenRC)** no **WSL 2**, gerenciada via **GNU Stow** com bootstrap automatizado POSIX (`install.sh`), **Neovim 0.11.7 (LazyVim Hybrid + Native `musl` LSP)**, **Zsh + Starship (< 30 ms)**, **Tmux 3.6**, suíte TUI completa e guia de personalização **Windows 11 Rice (WezTerm + GlazeWM v3 + Zebar + Flow Launcher)**.

---

## 1. Apresentação

Este repositório transforma o ambiente de engenharia em uma plataforma versionada, auditável e idempotente, guiada por quatro princípios:

- **Performance Nativa `musl`:** Zero dependência de binários `glibc` do Mason no Neovim; todos os compiladores, Language Servers (`clangd`, `gopls`, `rust-analyzer`, `ruff`, `lua-language-server`, `taplo`), formatadores (`stylua`, `shfmt`) e gramáticas Tree-sitter (`/usr/lib/tree-sitter/*.so`) são nativos do Alpine Linux.
- **Modularidade GNU Stow:** Cada ferramenta reside em seu próprio pacote isolado (`zsh`, `starship`, `tmux`, `nvim`, `lazygit`, `lazydocker`, `yazi`, `btop`, `fastfetch`, `git`, `local-bin`), aplicado com `--no-folding`.
- **Interoperabilidade Híbrida WSL 2 ↔ Windows 11:** `PATH` estritamente curado para eliminar lentidão de I/O em `/mnt/c`, clipboard integrado (`clip.exe` / `Get-Clipboard`) e wrappers inteligentes para GPU NVIDIA CUDA (`/dev/dxg` + `/usr/lib/wsl` no Docker), `nvidia-smi` e `ollama`.
- **Identidade Visual Unificada:** Paleta **Catppuccin Mocha** com acentos **Sapphire (`#74c7ec`)**, **Teal (`#94e2d5`)** e **Lavender (`#b4befe`)** em todas as ferramentas CLI/TUI e no Windows 11 Host.

---

## 2. Ambiente de Referência

| Camada | Componente | Especificação Real Auditada |
| :--- | :--- | :--- |
| **Host OS** | Windows 11 Pro | Build `26300` · WSL `2.7.14.0` · Kernel `6.18.33.2-microsoft-standard-WSL2` |
| **Hardware & GPU** | Acer Nitro V15 (`ANV15-51`) | Intel Core i5-13420H (12 threads) · 16 GB RAM (10 GB WSL) · NVIDIA RTX 3050 6 GB (`CUDA 13.5`) |
| **Linux Guest** | Alpine Linux `3.23.8` | `x86_64` · `musl` libc · BusyBox · OpenRC (`systemd = false`) |
| **Shell & Prompt** | Zsh `5.9` + Starship `1.24.2` | Bytecode `.zwc` compilado + hooks em cache (`zoxide`, `direnv`, `fzf`, `compinit`) |
| **Multiplexador** | Tmux `3.6` | Prefixo `Ctrl+b`, splits `\|` e `-`, copy-mode Vi (`clip.exe`), popups TUI em `92%` |
| **Editor Principal** | Neovim `0.11.7` | Arquitetura LazyVim Hybrid (18 plugins, startup `~33 ms`), `vim.lsp.config` nativo + Tree-sitter `.so` |
| **Suíte TUI** | CLI & Diagnóstico | `lazygit 0.48`, `lazydocker 0.24`, `yazi 25.5`, `btop 1.4`, `fastfetch 2.56`, `delta`, `eza`, `bat`, `ripgrep`, `fd` |
| **Windows Rice** | Desktop & Terminal | WezTerm / Windows Terminal + GlazeWM v3 + Zebar + Flow Launcher (`JetBrainsMono Nerd Font`) |

---

## 3. Arquitetura

Consulte [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) para o detalhamento completo do mapeamento GNU Stow, fronteiras de sistema (`/etc/wsl.conf` vs. `$HOME` vs. Windows Host) e decisões técnicas para `musl`.

---

## 4. Stack & Atalhos Essenciais

### 4.1. Zsh, Tmux & TUIs
| Atalho / Comando | Contexto | Ação |
| :--- | :--- | :--- |
| `Ctrl+b` `\|` / `Ctrl+b` `-` | Tmux | Split horizontal / vertical preservando o diretório atual |
| `Ctrl+b` `g` | Tmux Popup (92%) | Abre **LazyGit** flutuante no repositório atual |
| `Ctrl+b` `d` | Tmux Popup (92%) | Abre **LazyDocker** flutuante |
| `Ctrl+b` `y` | Tmux Popup (92%) | Abre **Yazi** flutuante |
| `Ctrl+b` `b` | Tmux Popup (92%) | Abre **Btop** flutuante |
| `wb` / `workbench [categoria]` | Zsh / PowerShell | Seleciona projeto via `fzf` + preview `eza` e abre sessão Tmux (`code`, `run`, `ops`) |
| `y` | Zsh | Abre o **Yazi** e muda o `CWD` automaticamente ao sair com `q` (`Q` mantém o diretório) |
| `devdoctor` | Zsh / PowerShell | Executa a suíte de 19 verificações de saúde da workstation |
| `alpine-maint` | Zsh | Auditoria read-only de pacotes APK, OpenRC, caches, dotfiles e backups |

### 4.2. Neovim 0.11.7 (`Leader = Space`)
| Atalho | Função |
| :--- | :--- |
| `<Space><Space>` / `<Space>ff` | Buscar arquivos no projeto (`telescope.nvim`) |
| `<Space>/` / `<Space>fg` | Busca textual em tempo real com Ripgrep (`live_grep`) |
| `<Space>e` / `<Space>E` | Explorador de arquivos em colunas (`mini.files`) |
| `<Space>gg` / `<Space>gf` | **LazyGit** flutuante (`Snacks.lazygit`) / Histórico do arquivo atual |
| `<Space>dd` | **LazyDocker** flutuante (`Snacks.terminal`) |
| `<Space>fy` / `<Space>ob` | **Yazi** / **Btop** flutuante dentro do Neovim |
| `<C-/>` / `<Space>ft` | Alternar terminal flutuante |
| `gd` / `gr` / `gI` / `K` | Go to Definition / References / Implementation / Hover (LSP nativo `musl`) |
| `<Space>cf` / `<Space>f` | Formatar buffer (`conform.nvim`: `stylua`, `ruff`, `gofmt`, `rustfmt`, `clang-format`, `shfmt`, `taplo`) |
| `<Space>xx` / `<Space>cs` | Diagnósticos e símbolos estruturados (`trouble.nvim` v3) |
| `<Space>uf` / `<Space>uh` | Alternar Format-on-Save / Inlay Hints |

---

## 5. Estrutura de Diretórios

```text
dotfiles/
├── .gitignore                        # Governança estrita contra segredos, caches, .zwc e binários
├── README.md                         # Documentação principal do projeto
├── install.sh                        # Bootstrap POSIX idempotente (pre-flight, APK, backup, Stow, OpenRC, devdoctor)
│
├── packages/
│   └── alpine/
│       ├── base.txt                  # Pacotes essenciais (git, zsh, starship, tmux, neovim, stow, doas)
│       ├── tui.txt                   # Ferramentas TUI/CLI (lazygit, lazydocker, yazi, btop, fastfetch, fzf, fd, rg, eza, bat, delta)
│       ├── dev.txt                   # Toolchains e LSPs musl (clang21-extra-tools, gopls, rust-analyzer, ruff, lua-ls, stylua, shfmt, taplo, tree-sitter-grammars)
│       ├── security.txt              # Scanners APK (actionlint, osv-scanner, shellcheck, gnupg)
│       └── optional.txt              # Cloud, HDL, Embarcados e referência de ferramentas estáticas/uv
│
├── zsh/                              # ~/.zshenv, ~/.zprofile, ~/.zshrc, ~/.profile, ~/.config/zsh/aliases.zsh
├── starship/                         # ~/.config/starship.toml
├── tmux/                             # ~/.config/tmux/tmux.conf
├── nvim/                             # ~/.config/nvim/{init.lua,lazy-lock.json,lua/{config,plugins}/*.lua}
├── lazygit/                          # ~/.config/lazygit/config.yml
├── lazydocker/                       # ~/.config/lazydocker/config.yml
├── yazi/                             # ~/.config/yazi/{yazi.toml,keymap.toml}
├── btop/                             # ~/.config/btop/{btop.conf,themes/catppuccin_mocha.theme}
├── fastfetch/                        # ~/.config/fastfetch/config.jsonc
├── git/                              # ~/.gitconfig, ~/.editorconfig, ~/.config/git/ignore
├── local-bin/                        # ~/.local/bin/{devdoctor,workbench,wb,alpine-maint,docker,nvidia-smi,ollama,rasp32-*}
│
├── wsl-system/
│   └── wsl.conf                      # Configuração de sistema (/etc/wsl.conf — não gerenciada via stow -t $HOME)
│
└── docs/
    ├── INSTALLATION.md               # Guia passo a passo de instalação, flags, remoção e restauração
    ├── ARCHITECTURE.md               # Arquitetura modular GNU Stow e decisões de engenharia
    └── WINDOWS_RICE.md               # Guia completo Windows 11 Rice (WezTerm, GlazeWM v3, Zebar, Flow Launcher, .wslconfig)
```

---

## 6. Instalação

Consulte [`docs/INSTALLATION.md`](docs/INSTALLATION.md) para detalhes completos. Resumo rápido:

```sh
# 1. Clonar o repositório no filesystem nativo do Alpine
git clone https://github.com/pedrohpsantos/dotfiles.git ~/dotfiles
cd ~/dotfiles

# 2. Simular a instalação (Dry-Run)
./install.sh --dry-run

# 3. Executar o bootstrap completo e idempotente
./install.sh
```

---

## 7. Atualização

Como as configurações em `$HOME` são links simbólicos diretos para `~/dotfiles`:

```sh
cd ~/dotfiles

# Verificar alterações locais
git status -sb

# Reaplicar um pacote específico ou todos os pacotes após adicionar novos arquivos
stow --restow --no-folding --target="$HOME" nvim
./install.sh --skip-packages
```

---

## 8. Restauração de Backups

O script `install.sh` cria automaticamente um diretório `~/.dotfiles_backup_YYYYMMDD_HHMMSS` sempre que encontra arquivos reais antes de aplicar os symlinks do Stow:

```sh
cd ~/dotfiles
# 1. Inspecione diferenças antes de reverter para evitar sobrescrever edições recentes
BACKUP_DIR="$(find "$HOME" -maxdepth 1 -type d -name '.dotfiles_backup_*' | sort | tail -n 1)"
diff -ru "$BACKUP_DIR" "$HOME" 2>/dev/null || true

# 2. Remova os links simbólicos do Stow ANTES de restaurar os arquivos
stow --delete --target="$HOME" zsh starship tmux nvim lazygit lazydocker yazi btop fastfetch git local-bin
cp -a "$BACKUP_DIR"/. "$HOME"/
```

---

## 9. Diagnóstico e Troubleshooting

- **Painel Completo (`devdoctor`):**
  ```sh
  ~/.local/bin/devdoctor
  ```
- **Auditoria de Manutenção (`alpine-maint`):**
  ```sh
  ~/.local/bin/alpine-maint status
  ```
- **Recompilar Bytecode Zsh:**
  ```sh
  zsh -c 'for f in ~/.zshenv ~/.zprofile ~/.zshrc; do zcompile "$f"; done'
  ```
- **Serviços OpenRC no WSL 2:**
  No WSL 2, o init primário é `/init` da Microsoft. Caso `rc-service` reclame de `softlevel`, o `install.sh` garante `/run/openrc/softlevel` e inicia `syslog` e `crond` com `rc-service --nodeps <serviço> start`.

---

## 10. Windows 11 Rice

Toda a documentação e os arquivos prontos para copiar e colar para o **Windows 11 Host** (**WezTerm**, **Windows Terminal**, **GlazeWM v3**, **Zebar**, **Flow Launcher** e **`%USERPROFILE%\.wslconfig`**) estão em:

👉 **[`docs/WINDOWS_RICE.md`](docs/WINDOWS_RICE.md)**

---

## 11. Segurança e Governança

- `.gitignore` bloqueia estritamente chaves privadas (`*.pem`, `*.key`, `.ssh/`, `.gnupg/`), variáveis de ambiente (`.env*`), tokens/credenciais (`**/hosts.yml`, `**/*secret*`, `**/*token*`), históricos de shell e binários ELF.
- Nenhum script remoto (`curl | sh`) é executado pelo bootstrap.
- Nenhum pacote de repositório instável (`edge`/`testing`) é adicionado automaticamente.

---

## 12. Referências Oficiais

- [Alpine Linux Wiki — WSL](https://wiki.alpinelinux.org/wiki/Windows_Subsystem_for_Linux)
- [GNU Stow Manual](https://www.gnu.org/software/stow/manual/stow.html)
- [Neovim 0.11 LSP Configuration (`vim.lsp.config`)](https://neovim.io/doc/user/lsp.html)
- [Catppuccin Palette & Ports](https://github.com/catppuccin/catppuccin)
- [WezTerm Documentation](https://wezfurlong.org/wezterm/)
- [GlazeWM v3](https://github.com/glzr-io/glazewm) & [Zebar](https://github.com/glzr-io/zebar)
- [Flow Launcher](https://github.com/Flow-Launcher/Flow.Launcher) & [Catppuccin for Flow Launcher](https://github.com/catppuccin/flow-launcher)
