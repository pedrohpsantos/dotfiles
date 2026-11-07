# Política de Segurança (`SECURITY.md`)

## 1. Segurança e Prevenção de Vazamento de Segredos

Este repositório de dotfiles é público e versionado no GitHub. A governança do repositório adota política estrita de **zero segredos**:

- Arquivos `.env`, `.env.*`, credenciais, chaves SSH (`id_ed25519*`, `id_rsa*`), certificados (`*.pem`, `*.key`) e tokens de API (`~/.config/gh/hosts.yml`) são explicitamente bloqueados no [`.gitignore`](.gitignore).
- Toda modificação passa por escaneamento automatizado prévio via **Gitleaks** tanto localmente quanto no pipeline de CI do GitHub Actions (`.github/workflows/ci.yml`).

## 2. Reportando Vulnerabilidades

Se você identificar qualquer credencial acidentalmente exposta no histórico do repositório ou uma vulnerabilidade nos scripts de bootstrap e integração WSL:

1. **Não abra uma issue pública.**
2. Envie uma notificação privada através do recurso [Private Vulnerability Reporting do GitHub](https://github.com/pedrohpsantos/dotfiles/security/advisories/new) ou entre em contato diretamente com o mantenedor.
3. Se um segredo for identificado, a credencial será imediatamente revogada e rotacionada no provedor correspondente.
