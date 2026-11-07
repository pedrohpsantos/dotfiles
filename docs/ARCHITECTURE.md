# Arquitetura do Repositório e Governança GNU Stow (`docs/ARCHITECTURE.md`)

Este documento detalha a arquitetura de diretórios, as decisões de engenharia para **Alpine Linux (`musl`) no WSL 2**, o mapeamento declarativo do **GNU Stow** e o fluxo de ciclo de vida das configurações.

---

## 1. Visão Geral da Arquitetura

O ambiente opera em um modelo híbrido estritamente separado por responsabilidade:

```mermaid
flowchart TD
    subgraph WinHost["Windows 11 Pro Host (GUI & GPU Driver)"]
        WT["WezTerm / Windows Terminal"]
        WM["GlazeWM v3 + Zebar + Flow Launcher"]
        VSC["VS Code (Remote-WSL) / Antigravity"]
        DD["Docker Desktop 4.98 + NVIDIA CUDA 13.5 + Ollama Host"]
    end

    subgraph AlpineWSL["Alpine Linux 3.23 WSL 2 (musl · OpenRC · Stow)"]
        Stow["~/dotfiles (GNU Stow Repository)"]
        Zsh["Zsh 5.9 + Starship + Tmux 3.6"]
        Nvim["Neovim 0.11.7 (LazyVim Hybrid + Native musl LSP)"]
        TUIs["LazyGit · LazyDocker · Yazi · Btop · Fastfetch"]
        Wrappers["~/.local/bin (docker GPU hook · nvidia-smi · ollama · workbench · devdoctor)"]
    end

    WT --> Zsh
    VSC --> AlpineWSL
    Wrappers --> DD
    Stow -->|"stow --no-folding -t $HOME"| Zsh
    Stow -->|"stow --no-folding -t $HOME"| Nvim
    Stow -->|"stow --no-folding -t $HOME"| TUIs
    Stow -->|"stow --no-folding -t $HOME"| Wrappers
```

---

## 2. Organização dos Pacotes GNU Stow

Cada diretório de primeiro nível representa um **pacote Stow autônomo** cuja estrutura interna espelha exatamente o caminho relativo a `$HOME` (`/home/pedrohpsantos`):

| Pacote Stow | Caminho no Repositório | Destino em `$HOME` | Descrição |
| :--- | :--- | :--- | :--- |
| **`zsh`** | `zsh/.zshenv`, `.zprofile`, `.zshrc`, `.profile`, `.config/zsh/aliases.zsh` | `~/.zshenv`, `~/.zprofile`, `~/.zshrc`, `~/.profile`, `~/.config/zsh/aliases.zsh` | Shell principal (< 50 ms), PATH curado, hooks em cache e aliases |
| **`starship`** | `starship/.config/starship.toml` | `~/.config/starship.toml` | Prompt Catppuccin Mocha com cápsula ` alpine` |
| **`tmux`** | `tmux/.config/tmux/tmux.conf` | `~/.config/tmux/tmux.conf` | Multiplexador Tmux 3.6 (Prefixo `Ctrl+b`, splits `\|`/`-`, popups 92%) |
| **`nvim`** | `nvim/.config/nvim/{init.lua,lazy-lock.json,lua/**}` | `~/.config/nvim/**` | Neovim 0.11.7 LazyVim Hybrid + LSP nativo `musl` + Tree-sitter `.so` |
| **`lazygit`** | `lazygit/.config/lazygit/config.yml` | `~/.config/lazygit/config.yml` | TUI Git com Catppuccin Mocha, Delta pager e atalhos VS Code/GitHub |
| **`lazydocker`** | `lazydocker/.config/lazydocker/config.yml` | `~/.config/lazydocker/config.yml` | TUI Docker Compose v2 com shell `sh`/`bash` e inspect via `bat` |
| **`yazi`** | `yazi/.config/yazi/{yazi.toml,keymap.toml}` | `~/.config/yazi/**` | File manager TUI com bookmarks (`gp`, `gc`, `gd`, `gw`) e `cd-on-exit` |
| **`btop`** | `btop/.config/btop/{btop.conf,themes/catppuccin_mocha.theme}` | `~/.config/btop/**` | Monitor de recursos com gráficos Braille e navegação Vim |
| **`fastfetch`** | `fastfetch/.config/fastfetch/config.jsonc` | `~/.config/fastfetch/config.jsonc` | Resumo de sistema Alpine WSL 2 com acentos Sapphire/Teal |
| **`git`** | `git/{.gitconfig,.editorconfig,.config/git/ignore}` | `~/.gitconfig`, `~/.editorconfig`, `~/.config/git/ignore` | Configuração global do Git, Delta, Git LFS, GH CLI credential helper |
| **`local-bin`** | `local-bin/.local/bin/*` | `~/.local/bin/*` | Scripts e wrappers (`devdoctor`, `workbench`, `wb`, `alpine-maint`, `docker`, `nvidia-smi`, `ollama`, `rasp32-*`) |

---

## 3. Separação entre Usuário, Sistema (`/etc`) e Windows Host

### 3.1. Configurações de Usuário (`$HOME`)
Gerenciadas pelo GNU Stow com `--no-folding --target="$HOME"`. O uso de `--no-folding` impede que o Stow substitua diretórios inteiros (como `~/.config` ou `~/.local/bin`) por um único symlink de diretório, permitindo que ferramentas como `uv`, `gh` ou binários estáticos coexistam sem poluir o repositório Git.

### 3.2. Configurações de Sistema (`wsl-system/wsl.conf`)
O arquivo `wsl-system/wsl.conf` corresponde a `/etc/wsl.conf`.
- **Regra Crítica:** Nunca execute `stow -t "$HOME" wsl-system`.
- O `install.sh` compara `wsl-system/wsl.conf` com `/etc/wsl.conf` usando `cmp -s`. Somente se houver divergência, ele cria um backup `/etc/wsl.conf.bak.<timestamp>` e aplica o arquivo com `doas`/`sudo`.

### 3.3. Configurações do Windows Host (`docs/WINDOWS_RICE.md`)
Arquivos como `%USERPROFILE%\.wslconfig`, `%USERPROFILE%\.wezterm.lua`, `%USERPROFILE%\.glzr\glazewm\config.yaml` e `%USERPROFILE%\.glzr\zebar\*` pertencem ao sistema de arquivos NTFS do Windows Host e são documentados em [`docs/WINDOWS_RICE.md`](WINDOWS_RICE.md).

---

## 4. Decisões Técnicas para Alpine Linux (`musl`)

1. **Proibição de Mason no Neovim:** O `mason.nvim` baixa binários pré-compilados para `glibc` que falham ou exigem gambiarras no Alpine. Em vez disso, `nvim/.config/nvim/lua/config/lsp.lua` utiliza a API nativa `vim.lsp.config` do Neovim 0.11 conectada aos binários `musl` do APK (`clangd`, `gopls`, `rust-analyzer`, `ruff`, `lua-language-server`, `taplo`).
2. **Tree-sitter Nativo (`/usr/lib/tree-sitter`):** As gramáticas `.so` são providas pelo pacote `tree-sitter-grammars` do Alpine e carregadas sob demanda via `vim.treesitter.start`.
3. **Curadoria de `PATH` WSL 2:** Em vez de importar dezenas de diretórios do Windows via `/mnt/c` (que degradam a latência de `stat()` no barramento Plan9/9p), `.zshenv` e `.zprofile` definem uma allowlist enxuta contendo apenas os caminhos Linux e as pontes essenciais do Windows (`system32`, `WindowsPowerShell`, `VS Code`, `Antigravity`).
4. **GPU CUDA em Containers `glibc`:** O wrapper `local-bin/.local/bin/docker` intercepta `--gpus=all` em `docker run` / `docker container run` e injeta `--device=/dev/dxg -v /usr/lib/wsl:/usr/lib/wsl:ro` com `LD_LIBRARY_PATH` configurado, permitindo treinar e rodar cargas PyTorch/CUDA em containers a partir do Alpine.

---

## 5. Fluxo de Bootstrap, Atualização e Política de Backups

1. **Idempotência Real:** Na primeira execução sobre arquivos regulares, `install.sh` move cada arquivo conflitante para `~/.dotfiles_backup_YYYYMMDD_HHMMSS/<caminho-relativo>`, valida a cópia com `cmp -s` e aplica os symlinks do Stow. Nas execuções seguintes, `resolve_stow_conflicts` detecta que todos os links já apontam para o repositório e **não cria diretórios de backup vazios ou redundantes**.
2. **Fluxo de Edição Contínua:** Como os arquivos em `$HOME` são symlinks diretos para `~/dotfiles/<pacote>/...`, qualquer ajuste feito em `~/.config/nvim/init.lua` ou `~/.zshrc` reflete imediatamente no `git status` de `~/dotfiles`.
