# Guia de Instalação, Bootstrap e Recuperação (`docs/INSTALLATION.md`)

Este guia descreve o processo completo de provisionamento, atualização, desinstalação segura e restauração de backups do repositório de dotfiles para **Alpine Linux 3.23 (`musl`) no WSL 2**.

---

## 1. Requisitos do Sistema

| Requisito | Especificação |
| :--- | :--- |
| **Sistema Operacional** | Alpine Linux `3.23.x` (`/etc/alpine-release`) |
| **Arquitetura & Libc** | `x86_64` · `musl` libc (`/lib/ld-musl-x86_64.so.1`) |
| **Subsistema** | Windows 11 WSL 2 (`/dev/dxg`, `WSLInterop`, kernel `*-microsoft-standard-WSL2`) |
| **Gerenciador de Pacotes** | `apk` (repositórios oficiais `main` e `community` v3.23) |
| **Init System** | OpenRC (`busybox-openrc`), `systemd = false` |
| **Privilégios** | Usuário pertencente ao grupo `wheel` com `doas` ou `sudo` (ou execução como `root`) |

---

## 2. Verificações Pre-flight (`./install.sh`)

Antes de realizar qualquer modificação, o script `install.sh` executa 8 verificações bloqueantes:

1. Confirma a presença de `/etc/alpine-release` e valida a série `3.23.*`.
2. Valida a arquitetura `x86_64` (`uname -m`).
3. Confirma a execução em WSL 2 verificando `/proc/sys/fs/binfmt_misc/WSLInterop`, `/dev/dxg` ou assinatura `microsoft` no kernel.
4. Valida a presença da `musl` libc (`ldd --version` / `/lib/ld-musl-x86_64.so.1`).
5. Confirma a disponibilidade do gerenciador `apk`.
6. Verifica se o repositório está clonado no filesystem Linux (`ext4`) e emite alerta caso esteja em `/mnt/c`.
7. Detecta o mecanismo de elevação de privilégios (`doas`, `sudo` ou `root`).
8. Verifica a disponibilidade do GNU Stow (`stow`) após a etapa de pacotes.

---

## 3. Clonagem e Execução do Bootstrap

### 3.1. Clonar o Repositório
Sempre clone o repositório dentro do filesystem nativo do Alpine (`$HOME`), nunca em `/mnt/c`:

```sh
git clone https://github.com/pedrohpsantos/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

### 3.2. Simulação Segura (`--dry-run`)
Inspecione todas as ações planejadas (pacotes faltantes, backups de conflitos, comandos Stow, `zcompile`, serviços OpenRC) sem alterar nenhum arquivo no sistema:

```sh
./install.sh --dry-run
```

### 3.3. Execução Completa (Padrão)
Executa a instalação de pacotes base/TUI/dev/security ausentes, faz backup de arquivos conflitantes, aplica todos os pacotes GNU Stow, valida permissões, compila os arquivos Zsh, ajusta os serviços OpenRC e executa o `devdoctor`:

```sh
./install.sh
```

### 3.4. Flags Disponíveis
```sh
./install.sh --help            # Exibe ajuda completa
./install.sh --dry-run         # Simula todas as etapas sem alterar o sistema
./install.sh --with-optional   # Instala também os pacotes de packages/alpine/optional.txt
./install.sh --skip-packages   # Pula a verificação/instalação de pacotes APK
./install.sh --skip-openrc     # Pula a verificação de serviços OpenRC
./install.sh --skip-doctor     # Pula a execução final do devdoctor
```

---

## 4. Gerenciamento de Pacotes APK

Os pacotes estão divididos em manifestos declarativos em `packages/alpine/`:

- [`packages/alpine/base.txt`](../packages/alpine/base.txt): `git`, `zsh`, `starship`, `tmux`, `neovim`, `stow`, `doas`, `busybox-openrc`, etc.
- [`packages/alpine/tui.txt`](../packages/alpine/tui.txt): `lazygit`, `lazydocker`, `yazi`, `btop`, `fastfetch`, `fzf`, `fd`, `ripgrep`, `eza`, `bat`, `delta`, `zoxide`, `direnv`.
- [`packages/alpine/dev.txt`](../packages/alpine/dev.txt): `clang21-extra-tools` (`clangd`, `clang-format`), `ruff`, `gopls`, `rust-analyzer`, `lua-language-server`, `stylua`, `shfmt`, `shellcheck`, `taplo`, `yamllint`, `tree-sitter-grammars`.
- [`packages/alpine/security.txt`](../packages/alpine/security.txt): `actionlint`, `osv-scanner`, `shellcheck`, `gnupg`, `openssh-client`.
- [`packages/alpine/optional.txt`](../packages/alpine/optional.txt): Ferramentas de Cloud/IaC (`opentofu`, `ansible`, `helm`), Acadêmicas/HDL (`iverilog`, `verilator`, `typst`, `pandoc-cli`), Embarcados (`gcc-arm-none-eabi`, `openocd`) e documentação das ferramentas estáticas/uv (`gitleaks`, `trivy`, `hadolint`, `bandit`, `pip-audit`, `esptool`).

> **Política de Segurança APK:** O `install.sh` **nunca** altera `/etc/apk/repositories`, **nunca** ativa repositórios `edge`/`testing`, **nunca** executa `apk upgrade` automático e **nunca** reinstala pacotes já presentes (`apk info -e`).

---

## 5. Aplicação Modular com GNU Stow

Você pode aplicar todos os pacotes de uma só vez ou gerenciar módulos individuais:

```sh
cd ~/dotfiles

# Aplicar todos os pacotes de usuário
stow --restow --no-folding --target="$HOME" \
  zsh starship tmux nvim lazygit lazydocker yazi btop fastfetch git local-bin

# Aplicar apenas um módulo específico
stow --restow --no-folding --target="$HOME" zsh
stow --restow --no-folding --target="$HOME" tmux
stow --restow --no-folding --target="$HOME" nvim
```

A flag `--no-folding` garante que diretórios compartilhados como `~/.config` e `~/.local/bin` permaneçam diretórios reais, criando symlinks apenas para os arquivos versionados e preservando binários ou estados locais não gerenciados pelo Stow.

---

## 6. Permissões, `zcompile` e OpenRC

### 6.1. Permissões (`~/.local/bin`)
O `install.sh` garante permissão `0755` (`rwxr-xr-x`) apenas nos scripts utilitários versionados em `local-bin/.local/bin/`:
`devdoctor`, `workbench`, `wb`, `alpine-maint`, `nvidia-smi`, `docker`, `ollama`, `rasp32-check`, `rasp32-info`, `rasp32-sync`.

### 6.2. Compilação Zsh (`zcompile`)
Para manter o tempo de inicialização do Zsh abaixo de **50 ms**, o bootstrap valida a sintaxe com `zsh -n` e gera bytecode compilado (`.zwc`) apenas quando o arquivo-fonte é mais novo que o cache:
- `~/.zshenv` → `~/.zshenv.zwc`
- `~/.zprofile` → `~/.zprofile.zwc`
- `~/.zshrc` → `~/.zshrc.zwc`

Os arquivos `.zwc` são ignorados pelo `.gitignore`.

### 6.3. Governança OpenRC no WSL 2
O bootstrap verifica e aplica de forma não-destrutiva:
- **`redis`:** Removido dos runlevels `boot` e `default` (evita ocupar a porta `6379` no boot sem matar instâncias manuais em execução).
- **`syslog`:** Habilitado no runlevel `boot` e iniciado com `rc-service --nodeps syslog start`.
- **`crond`:** Habilitado no runlevel `default` e iniciado com `rc-service --nodeps crond start`.

---

## 7. Desinstalação Segura e Restauração de Backups

### 7.1. Remover Links Simbólicos de um Pacote Stow
Para desativar um pacote sem apagar os arquivos do repositório:

```sh
cd ~/dotfiles
stow --delete --target="$HOME" nvim
```

### 7.2. Procedimento de Recuperação Segura a partir de Backup (`~/.dotfiles_backup_*`)
Sempre que o `install.sh` encontra um arquivo real no `$HOME` antes de criar um symlink, ele copia o arquivo preservando permissões e timestamps (`cp -a`) para `~/.dotfiles_backup_YYYYMMDD_HHMMSS/`.

Para restaurar os arquivos originais com verificação rigorosa de integridade, falha segura e sem sobrescrever a árvore do repositório:

```sh
# 1. Localizar o backup mais recente no $HOME
BACKUP_DIR="$(find "$HOME" -maxdepth 1 -type d -name '.dotfiles_backup_*' 2>/dev/null | sort | tail -n 1)"

# 2. Validações rigorosas de segurança antes de qualquer ação
if [ -z "${BACKUP_DIR:-}" ]; then
    printf "ERRO: Nenhum diretorio de backup encontrado em %s\n" "$HOME" >&2
    return 1 2>/dev/null || exit 1
fi

case "$BACKUP_DIR" in
    "$HOME"/.dotfiles_backup_*) ;;
    *)
        printf "ERRO: Caminho de backup invalido ou fora do padrao: %s\n" "$BACKUP_DIR" >&2
        return 1 2>/dev/null || exit 1
        ;;
esac

if [ -L "$BACKUP_DIR" ]; then
    printf "ERRO: O backup selecionado e um link simbolico; abortando: %s\n" "$BACKUP_DIR" >&2
    return 1 2>/dev/null || exit 1
fi

if [ ! -d "$BACKUP_DIR" ]; then
    printf "ERRO: Diretorio de backup nao existe ou inacessivel: %s\n" "$BACKUP_DIR" >&2
    return 1 2>/dev/null || exit 1
fi

printf "Backup validado: %s\n" "$BACKUP_DIR"

# 3. Comparar estritamente os arquivos relevantes contidos no snapshot (evita varrer todo o $HOME)
printf "--- Diferencas entre o snapshot e o estado atual em \$HOME ---\n"
(
    cd "$BACKUP_DIR"
    find . \( -type f -o -type l \) | while IFS= read -r _rel; do
        _target="$HOME/${_rel#./}"
        if [ -e "$_target" ] || [ -L "$_target" ]; then
            diff -u "$_target" "$_rel" 2>/dev/null || true
        else
            printf "Item novo/ausente em \$HOME: %s\n" "${_rel#./}"
        fi
    done
)

# 4. Remover os links simbolicos do GNU Stow ANTES de restaurar (evita sobrescrever o repositorio)
cd "$HOME/dotfiles"
stow --delete --target="$HOME" \
    zsh starship tmux nvim lazygit lazydocker yazi btop fastfetch git local-bin

# 5. Restaurar os arquivos originais preservando atributos
cp -a "$BACKUP_DIR"/. "$HOME"/
printf "Restauracao concluida com sucesso a partir de %s\n" "$BACKUP_DIR"
```
