# Changelog

Todas as alterações notáveis neste repositório de dotfiles serão documentadas neste arquivo.

O formato segue o padrão [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/) e respeita o [Versionamento Semântico](https://semver.org/lang/pt-BR/).

---

## [2.1.0] - 2026-11-07

### Added
- Pipeline de integração contínua (CI) em `.github/workflows/ci.yml` com validação de sintaxe POSIX, ShellCheck, Zsh e escaneamento Gitleaks.
- Modelos estruturados de Pull Request (`.github/PULL_REQUEST_TEMPLATE.md`) e Issues (`.github/ISSUE_TEMPLATE/`).
- Documentação formal de governança em `CONTRIBUTING.md`, `SECURITY.md` e licença MIT em `LICENSE`.
- Makefile com atalhos de automação para testes locais (`make check`, `make lint`, `make test`, `make doctor`).
- Wrapper executável `local-bin/.local/bin/agy` para integração nativa com o CLI do Antigravity no Windows.
- Modelo de reprodutibilidade em 4 camadas documentado em `docs/ARCHITECTURE.md`.

### Fixed
- Cobertura estrita de sintaxe no CI e Makefile: corrigido `find -exec sh -n {} \;` e loop individual `zsh -n` para validação real de 100% dos arquivos; incluído `zsh/.profile` e removida referência ao `.zlogin` inexistente.
- Renderização visual do README: substituídos glifos Nerd Font incompatíveis com navegadores web por logotipos SVG oficiais do Alpine Linux e Catppuccin Mocha.
- Inicialização do OpenRC no WSL 2: ativado `[boot] command = "/sbin/openrc default"` em `wsl-system/wsl.conf` e `/etc/wsl.conf`.
- Modo `--dry-run` do `install.sh`: agora executa a simulação real `stow --simulate --restow --no-folding` e roda a suíte de diagnósticos em modo somente-leitura.
- Diagnóstico de repositório no `alpine-maint`: corrigido para consultar `DOTFILES_DIR` em `~/dotfiles` via `git -C`.
- Curadoria do PATH: configurado `appendWindowsPath = false` e limpos diretórios NTFS redundantes (`Wbem`, `WindowsApps`, `.gemini/.../bin`).
- Procedimento de restauração de backup em `README.md` e `docs/INSTALLATION.md`: adicionadas validações defensivas contra caminhos nulos, links simbólicos e diff seletivo restrito ao snapshot.

---

## [2.0.0] - 2026-11-07

### Added
- Reestruturação integral dos dotfiles para arquitetura modular gerenciada pelo GNU Stow (`--no-folding`).
- Bootstrap POSIX idempotente `install.sh` com suporte a flags (`--dry-run`, `--with-optional`, `--skip-packages`, `--skip-openrc`, `--skip-doctor`).
- Manifestos declarativos de pacotes APK em `packages/alpine/` (`base.txt`, `tui.txt`, `dev.txt`, `security.txt`, `optional.txt`).
- Configurações do Neovim 0.11 com arquitetura LazyVim Hybrid e Language Servers nativos `musl` (`clangd`, `gopls`, `rust-analyzer`, `ruff`, `lua-ls`, `taplo`), eliminando dependência do Mason.
- Configuração modular do Zsh com Starship prompt, hooks cacheados (`zcompdump`, `zoxide`, `direnv`) e tempo de inicialização `< 25 ms`.
- Configuração do Tmux 3.6 com popups flutuantes em 92% para LazyGit, LazyDocker, Yazi e Btop.
- Guia abrangente de personalização do Windows 11 Host em `docs/WINDOWS_RICE.md` (WezTerm, GlazeWM v3, Zebar, Flow Launcher e Catppuccin Mocha).
- Suíte de diagnóstico de saúde da workstation em `local-bin/.local/bin/devdoctor`.
