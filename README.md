# Meus Dotfiles - Catppuccin Rice ᓚᘏᗢ

Bem-vindo(a) às minhas configurações pessoais para o Ubuntu 24.04 LTS com GNOME. Este repositório contém todos os "dotfiles" e scripts necessários para recriar meu ambiente de trabalho, focado em produtividade e em uma estética suave e coesa baseada no tema Catppuccin.

![Meu Desktop](https-placeholder-para-sua-screenshot.png)

---

## 📖 Especificações

| Componente | Seleção |
| :--- | :--- |
| **OS** | Ubuntu 24.04.2 LTS |
| **Desktop Environment** | GNOME 46 |
| **Sistema de Janelas** | Wayland |
| **Tema GTK/Shell** | [Catppuccin](https://github.com/catppuccin/gtk) (Mocha com sotaque Lavender) |
| **Ícones** | [Papirus Dark](https://github.com/PapirusDevelopmentTeam/papirus-icon-theme) |
| **Cursor** | [Catppuccin Cursors](https://github.com/catppuccin/cursors) |
| **Terminal** | [Kitty](https://sw.kovidgoyal.net/kitty/) |
| **Shell** | Bash |
| **Prompt** | [Starship](https://starship.rs/) |
| **Fonte do Terminal** | [FiraCode Nerd Font](https://www.nerdfonts.com/font-downloads) |
| **Gerenciador de Janelas** | [Pop!\_Shell](https://github.com/pop-os/shell) |
| **Widgets** | [Conky](https://github.com/brndnmtthws/conky) (Tema Catppuccin) |
| **Navegação (Terminal)** | `zoxide` + `fzf` |
| **Gerenciador de Arquivos (TUI)**| [Yazi](https://github.com/sxyazi/yazi) |
| **Sessões do Terminal** | [tmux](https://github.com/tmux/tmux) (Tema Catppuccin) |
| **Extensões GNOME**| User Themes, Blur my Shell, Vitals |

---

## 🚀 Instalação

Estas são as instruções para replicar este setup em uma instalação nova do Ubuntu 24.04.

### 1. Clonar o Repositório

```bash
git clone [https://github.com/pedrohpsantos/dotfiles.git](https://github.com/pedrohpsantos/dotfiles.git)


### 2\. Instalar Dependências Principais

Este comando instala a maioria dos pacotes necessários via `apt`.

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install gnome-tweaks gnome-shell-extension-manager git curl make node-typescript npm papirus-icon-theme conky-all fzf tmux yazi ffmpegthumbnailer unar poppler-utils -y
```

### 3\. Instalar Ferramentas Externas

Algumas ferramentas precisam de instalação manual.

  * **Kitty Terminal:**
    ```bash
    curl -L [https://sw.kovidgoyal.net/kitty/installer.sh](https://sw.kovidgoyal.net/kitty/installer.sh) | sh /dev/stdin
    # Siga as instruções da nossa conversa para criar os links simbólicos
    ```
  * **Pop\!\_Shell:**
    ```bash
    git clone [https://github.com/pop-os/shell](https://github.com/pop-os/shell)
    cd shell
    git checkout master_noble
    npm install -D typescript@next
    make local-install
    # É necessário fazer logout e login para ativar
    ```
  * **Starship:**
    ```bash
    curl -sS [https://starship.rs/install.sh](https://starship.rs/install.sh) | sh
    ```

### 4\. Linkar os Dotfiles

Com os arquivos de configuração neste repositório, use o `stow` para criar os links simbólicos para os locais corretos.

```bash
# Instalar o stow
sudo apt install stow -y

# Navegar para a pasta dos dotfiles clonada
cd dotfiles

# Criar os links
stow bash
stow tmux
stow starship
stow kitty
stow conky
```

### 5\. Configurações Finais

  * Abra o **Gerenciador de Extensões** e instale `User Themes` e `Blur my Shell`.
  * Abra o **Ajustes (GNOME Tweaks)** e aplique o tema GTK/Shell `Catppuccin`, os ícones `Papirus-Dark` e o cursor.
  * Inicie o `tmux` pela primeira vez e instale os plugins com **`Ctrl+a`** + **`I`**.
  * Reinicie o sistema para que o Conky e o Pop\!\_Shell sejam carregados corretamente.

-----

## ✨ Atalhos Principais

  * **Prefixo `tmux`:** `Ctrl + a`
  * **Busca no Histórico:** `Ctrl + R`
  * **Busca de Arquivos:** `Ctrl + T`
  * **Navegação Inteligente:** `z <nome-da-pasta>`
