# Guia de Contribuição e Governança (`CONTRIBUTING.md`)

Este repositório define a infraestrutura declarativa pessoal para **Alpine Linux 3.23 (musl) no WSL 2** e integração visual com **Windows 11**.

Para manter a consistência, segurança e altíssima performance do ambiente, todas as alterações devem seguir as regras de governança abaixo.

---

## 1. Princípios de Arquitetura

1. **Compatibilidade Nativa `musl`:**
   - **Nunca introduzir binários `glibc`.**
   - **Mason é estritamente proibido no Neovim.** Todas as ferramentas de LSP, formatadores e diagnósticos devem ser instaladas através dos repositórios oficiais APK (`main` ou `community`) ou via `uv tool` para ferramentas em Python.
2. **Modularidade GNU Stow:**
   - Cada software reside em sua própria pasta raiz (ex: `zsh/`, `starship/`, `tmux/`, `nvim/`).
   - A aplicação é sempre feita com `--no-folding --target="$HOME"` para não transformar pastas compartilhadas (`~/.config`, `~/.local/bin`) em symlinks únicos de diretório.
   - Configurações que pertencem ao sistema (`/etc/wsl.conf`) ficam em `wsl-system/` e nunca são aplicadas via `stow` em `$HOME`.
3. **Idempotência do Bootstrap (`install.sh`):**
   - O script `install.sh` deve rodar quantas vezes forem necessárias sem duplicar conteúdo ou causar erros.
   - Qualquer nova automação deve suportar `--dry-run`.
4. **Governança de PATH:**
   - O arquivo `/etc/wsl.conf` desativa a importação do PATH Windows (`appendWindowsPath = false`).
   - Binários Windows necessários devem ser expostos via allowlist estrita em `~/.zshenv` ou wrappers dedicados em `local-bin/.local/bin/`.

---

## 2. Qualidade de Código e Gates Obrigatórios

Antes de enviar qualquer commit ou abrir um Pull Request:

```sh
# 1. Validar sintaxe POSIX sh (arquivo por arquivo)
sh -n install.sh
sh -n zsh/.profile
find local-bin/.local/bin -type f -exec sh -n {} \;

# 2. Executar ShellCheck com nível de severidade 'style'
shellcheck install.sh
shellcheck -S style local-bin/.local/bin/*

# 3. Validar sintaxe do Zsh (arquivo por arquivo)
for file in zsh/.zshenv zsh/.zprofile zsh/.zshrc zsh/.config/zsh/aliases.zsh; do
  zsh -n "$file" || exit 1
done

# 4. Executar simulação de conflitos do GNU Stow
stow --simulate --restow --no-folding --target="$HOME" \
  zsh starship tmux nvim lazygit lazydocker yazi btop fastfetch git local-bin

# 5. Executar o bootstrap em modo de simulação
./install.sh --dry-run

# 6. Escanear segredos com Gitleaks
~/.local/bin/gitleaks detect --source=. --no-git -v

# 7. Verificar integridade de diff e formatação
git diff --check
```

---

## 3. Adicionando um Novo Pacote Stow

1. Crie uma pasta de primeiro nível com o nome da ferramenta (ex: `mytool/`).
2. Estruture as subpastas espelhando exatamente a hierarquia relativa a `$HOME`:
   ```text
   mytool/
   └── .config/
       └── mytool/
           └── config.toml
   ```
3. Registre a nova pasta na variável `STOW_PACKAGES` em `install.sh`.
4. Adicione eventuais pacotes APK necessários em `packages/alpine/`.
5. Execute `stow --restow --no-folding -t "$HOME" mytool` para testar.
6. Documente atalhos e propósitos em `README.md` e `docs/ARCHITECTURE.md`.
