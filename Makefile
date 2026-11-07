# ==============================================================================
# Makefile — Dotfiles Automation & Local Quality Gates
# ==============================================================================
.DEFAULT_GOAL := help
SHELL := /bin/sh

.PHONY: help check lint test dry-run doctor clean

help: ## Exibe esta ajuda de comandos
	@printf "\033[1;36mDotfiles Management & Quality Automation\033[0m\n\n"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[33m%-15s\033[0m %s\n", $$1, $$2}'

check: lint test ## Executa todos os linters, verificações estáticas e testes de simulação

lint: ## Valida sintaxe POSIX, ShellCheck e arquivos Zsh
	@printf "\033[1;34m==> Validando sintaxe POSIX (sh -n)...\033[0m\n"
	sh -n install.sh
	find local-bin/.local/bin -type f -exec sh -n {} +
	@printf "\033[1;34m==> Executando ShellCheck...\033[0m\n"
	shellcheck install.sh
	shellcheck -S style local-bin/.local/bin/*
	@printf "\033[1;34m==> Validando sintaxe Zsh...\033[0m\n"
	zsh -n zsh/.zshenv zsh/.zprofile zsh/.zshrc zsh/.zlogin zsh/.config/zsh/aliases.zsh
	@printf "\033[1;32m[OK] Todos os linters passaram sem erros ou avisos.\033[0m\n"

test: dry-run ## Executa simulação do bootstrap e conflitos do Stow

dry-run: ## Executa o bootstrap em modo de simulação (--dry-run)
	@printf "\033[1;34m==> Executando ./install.sh --dry-run...\033[0m\n"
	./install.sh --dry-run

doctor: ## Executa o painel devdoctor de diagnóstico da workstation
	~/.local/bin/devdoctor

clean: ## Remove arquivos de cache compilados (.zwc)
	rm -f ~/.zshenv.zwc ~/.zprofile.zwc ~/.zshrc.zwc
