# Windows 11 Ricing & WSL 2 Host Configuration Guide (2026)

> **Identidade Visual:** Catppuccin Mocha + `JetBrainsMono Nerd Font`
> **Data de Verificação das Especificações:** 2026-11-07
> **Escopo:** Este documento é exclusivamente um guia de configuração manual para o **Windows 11 Host**. Nenhum arquivo de configuração do Windows é incluído nos pacotes GNU Stow do Linux.

---

## Sumário

1. [Paleta de Cores Oficial (Catppuccin Mocha)](#1-paleta-de-cores-oficial-catppuccin-mocha)
2. [Tipografia: JetBrainsMono Nerd Font](#2-tipografia-jetbrainsmono-nerd-font)
3. [Emulador de Terminal: WezTerm (Recomendação Primária)](#3-emulador-de-terminal-wezterm-recomendação-primária)
4. [Alternativa: Windows Terminal (`settings.json`)](#4-alternativa-windows-terminal-settingsjson)
5. [Tiling Window Manager: GlazeWM v3](#5-tiling-window-manager-glazewm-v3)
6. [Status Bar Flutuante: Zebar](#6-status-bar-flutuante-zebar)
7. [App Launcher: Flow Launcher](#7-app-launcher-flow-launcher)
8. [Configuração Global do WSL 2 (`%USERPROFILE%\.wslconfig`)](#8-configuração-global-do-wsl-2-userprofilewslconfig)

---

## 1. Paleta de Cores Oficial (Catppuccin Mocha)

Todos os componentes abaixo utilizam estritamente os códigos hexadecimais oficiais da especificação [Catppuccin Mocha](https://github.com/catppuccin/catppuccin):

| Papel Semântico | Nome Catppuccin | Hexadecimal | Uso no Ambiente |
| :--- | :--- | :--- | :--- |
| **Fundo Principal** | `Base` | `#1e1e2e` | Fundo de janelas, terminais e launcher |
| **Fundo Secundário** | `Mantle` | `#181825` | Barra de status (Zebar / Tmux) e abas inativas |
| **Fundo Profundo** | `Crust` | `#11111b` | Contraste de pílulas ativas e sombras |
| **Texto Principal** | `Text` | `#cdd6f4` | Texto primário e código |
| **Destaque Primário** | `Sapphire` | `#74c7ec` | Identidade Alpine WSL 2, borda de janela ativa |
| **Destaque Secundário** | `Blue` | `#89b4fa` | Bordas TUI, links e foco secundário |
| **Indicador / Acento** | `Lavender` | `#b4befe` | Indicadores ativos, cursores e badges |
| **Superfície Base** | `Surface0` | `#313244` | Cápsulas de módulos, seleção e borda inativa |
| **Superfície Média** | `Surface1` | `#45475a` | Separadores e hover |
| **Superfície Alta** | `Surface2` | `#585b70` | Textos secundários / comentários |

---

## 2. Tipografia: JetBrainsMono Nerd Font

### 2.1. Diferença entre `JetBrains Mono` e `JetBrainsMono Nerd Font`
- **`JetBrains Mono` (padrão):** Contém apenas glifos de código e ligaduras tipográficas (`->`, `=>`, `!==`), mas **não possui** os ícones Powerline (``, ``, ``), Devicons (``, ``, ``, ``, ``) nem os símbolos usados pelo Starship, Neovim/LazyVim, LazyGit, Yazi e Tmux.
- **`JetBrainsMono Nerd Font` (patched):** Inclui todos os glifos da fonte original mais o conjunto Nerd Fonts v3 completo.
  - **`JetBrainsMono Nerd Font`:** Variável proporcional para ícones (ideal para WezTerm, Windows Terminal, VS Code, Zebar e Flow Launcher).
  - **`JetBrainsMono Nerd Font Mono`:** Ícones estritamente monoespaçados (1 célula de largura).

> **Nota sobre o Alpine Linux:** A configuração de fonte é uma responsabilidade do emulador de terminal no Windows Host. Os processos rodando no Alpine (`zsh`, `tmux`, `nvim`) apenas emitem sequências UTF-8 que o terminal Windows renderiza.

### 2.2. Download e Instalação no Windows 11
1. Baixe o pacote oficial no repositório [ryanoasis/nerd-fonts — Releases (JetBrainsMono.zip)](https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip) ou instale via WinGet:
   ```powershell
   winget install --id=DEVCOM.JetBrainsMonoNerdFont -e
   ```
2. Caso utilize o arquivo `.zip`, extraia-o, selecione todos os arquivos `.ttf`, clique com o botão direito e escolha **Instalar para todos os usuários** (*Install for all users*).

### 2.3. Verificação de Glifos Powerline e Nerd Font
No terminal integrado ao Alpine WSL 2, execute:
```sh
printf "Powerline : \ue0b0 \ue0b2 \ue0b4 \ue0b6\n"
printf "Alpine/Dev: \uf300 \ue702 \uf308 \ue627 \ue7a8 \uf489\n"
```
Todos os símbolos devem aparecer nitidamente, sem retângulos vazios (`□` ou `?`).

---

## 3. Emulador de Terminal: WezTerm (Recomendação Primária)

- **Site Oficial:** [wezfurlong.org/wezterm](https://wezfurlong.org/wezterm/)
- **Repositório:** [github.com/wez/wezterm](https://github.com/wez/wezterm)
- **Versão de Referência Verificada:** `20240203-110809-5046fc22` / Nightly `2026`
- **Instalação via WinGet:**
  ```powershell
  winget install --id=wez.wezterm -e
  ```

### 3.1. Identificação do Nome Real da Distribuição WSL
No ambiente real auditado, `wsl.exe -l -v` registra a distribuição como **`Alpine-3.23.4`** (se em uma nova máquina a distribuição for importada como `Alpine`, basta alterar `wsl_distro_name` na configuração abaixo).

### 3.2. Arquivo Completo: `%USERPROFILE%\.wezterm.lua`
Salve o conteúdo abaixo em `%USERPROFILE%\.wezterm.lua`:

```lua
-- ============================================================================
-- %USERPROFILE%\.wezterm.lua — WezTerm Configuration (Windows 11 + Alpine WSL 2)
-- Theme: Catppuccin Mocha | Font: JetBrainsMono Nerd Font
-- ============================================================================
local wezterm = require("wezterm")
local act = wezterm.action
local config = wezterm.config_builder and wezterm.config_builder() or {}

-- Nome da distribuição WSL 2 ("Alpine-3.23.4" no ambiente atual, ou "Alpine" se renomeada)
local wsl_distro_name = "Alpine-3.23.4"

-- 1. Inicialização Direta no Alpine WSL 2 (ou "wsl.exe -d Alpine")
config.default_prog = { "wsl.exe", "-d", wsl_distro_name, "--cd", "~" }

config.launch_menu = {
  {
    label = "Alpine WSL 2 (Zsh)",
    args = { "wsl.exe", "-d", wsl_distro_name, "--cd", "~", "--", "zsh", "-l" },
  },
  {
    label = "PowerShell 7",
    args = { "pwsh.exe", "-NoLogo" },
  },
  {
    label = "Windows PowerShell 5.1",
    args = { "powershell.exe", "-NoLogo" },
  },
}

-- 2. Tipografia & Ligaduras
config.font = wezterm.font_with_fallback({
  { family = "JetBrainsMono Nerd Font", weight = "Medium", harfbuzz_features = { "calt=1", "clig=1", "liga=1" } },
  { family = "FiraCode Nerd Font Mono" },
})
config.font_size = 11.0
config.line_height = 1.05
config.cell_width = 1.0
config.warn_about_missing_glyphs = false

-- 3. Janela, Backdrop Acrylic & Minimalismo
config.window_decorations = "RESIZE"
config.window_background_opacity = 0.93
config.win32_system_backdrop = "Acrylic"
config.window_padding = {
  left = 10,
  right = 10,
  top = 10,
  bottom = 10,
}
config.enable_scroll_bar = false
config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = true
config.tab_bar_at_bottom = true
config.window_close_confirmation = "NeverPrompt"
config.audible_bell = "Disabled"
config.default_cursor_style = "SteadyBar"
config.max_fps = 120

-- 4. Paleta Exata Catppuccin Mocha
config.colors = {
  foreground = "#cdd6f4", -- Text
  background = "#1e1e2e", -- Base
  cursor_bg = "#b4befe",  -- Lavender
  cursor_fg = "#11111b",  -- Crust
  cursor_border = "#b4befe",
  selection_fg = "#cdd6f4",
  selection_bg = "#45475a", -- Surface1
  scrollbar_thumb = "#585b70", -- Surface2
  split = "#313244", -- Surface0

  ansi = {
    "#45475a", -- black (Surface1)
    "#f38ba8", -- red
    "#a6e3a1", -- green
    "#f9e2af", -- yellow
    "#89b4fa", -- blue
    "#f5c2e7", -- magenta (Pink)
    "#94e2d5", -- cyan (Teal)
    "#bac2de", -- white (Subtext1)
  },
  brights = {
    "#585b70", -- bright black (Surface2)
    "#f38ba8", -- bright red
    "#a6e3a1", -- bright green
    "#f9e2af", -- bright yellow
    "#74c7ec", -- bright blue (Sapphire)
    "#cba6f7", -- bright magenta (Mauve)
    "#94e2d5", -- bright cyan (Teal)
    "#cdd6f4", -- bright white (Text)
  },

  tab_bar = {
    background = "#11111b", -- Crust
    active_tab = {
      bg_color = "#74c7ec", -- Sapphire
      fg_color = "#11111b", -- Crust
      intensity = "Bold",
    },
    inactive_tab = {
      bg_color = "#181825", -- Mantle
      fg_color = "#cdd6f4", -- Text
    },
    inactive_tab_hover = {
      bg_color = "#313244", -- Surface0
      fg_color = "#cdd6f4", -- Text
    },
    new_tab = {
      bg_color = "#181825", -- Mantle
      fg_color = "#74c7ec", -- Sapphire
    },
    new_tab_hover = {
      bg_color = "#313244", -- Surface0
      fg_color = "#b4befe", -- Lavender
    },
  },
}

-- 5. Atalhos de Teclado (Sem conflito com Tmux Ctrl+b ou Neovim Space)
config.keys = {
  { key = "v", mods = "CTRL|SHIFT", action = act.PasteFrom("Clipboard") },
  { key = "c", mods = "CTRL|SHIFT", action = act.CopyTo("Clipboard") },
  { key = "t", mods = "CTRL|SHIFT", action = act.SpawnTab("CurrentPaneDomain") },
  { key = "p", mods = "CTRL|SHIFT", action = act.ShowLauncherArgs({ flags = "FUZZY|LAUNCH_MENU_ITEMS" }) },
  { key = "Enter", mods = "ALT", action = act.ToggleFullScreen },
}

return config
```

---

## 4. Alternativa: Windows Terminal (`settings.json`)

- **Repositório Oficial:** [github.com/microsoft/terminal](https://github.com/microsoft/terminal)
- **Caminho do Arquivo:** `%LOCALAPPDATA%\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json`

Abaixo está um bloco **JSON estrito** (sem comentários, pronto para validação/mesclagem no `settings.json` do Windows Terminal):

```json
{
  "defaultProfile": "{fed24c99-1d0c-5763-a607-d2f9055f50eb}",
  "copyFormatting": "none",
  "copyOnSelect": false,
  "actions": [
    {
      "command": {
        "action": "newTab",
        "profile": "{fed24c99-1d0c-5763-a607-d2f9055f50eb}"
      },
      "id": "User.newTabAlpine"
    }
  ],
  "keybindings": [
    {
      "id": "User.newTabAlpine",
      "keys": "ctrl+shift+a"
    }
  ],
  "profiles": {
    "defaults": {
      "bellStyle": "none",
      "colorScheme": "Catppuccin Mocha",
      "cursorShape": "bar",
      "font": {
        "face": "JetBrainsMono Nerd Font",
        "size": 11,
        "features": {
          "calt": 1,
          "liga": 1
        }
      },
      "opacity": 93,
      "padding": "10, 10, 10, 10",
      "useAcrylic": true
    },
    "list": [
      {
        "guid": "{fed24c99-1d0c-5763-a607-d2f9055f50eb}",
        "name": "Alpine WSL 2",
        "tabTitle": "Alpine",
        "commandline": "C:\\WINDOWS\\system32\\wsl.exe -d Alpine-3.23.4",
        "startingDirectory": "~",
        "colorScheme": "Catppuccin Mocha",
        "tabColor": "#181825"
      }
    ]
  },
  "schemes": [
    {
      "name": "Catppuccin Mocha",
      "background": "#1E1E2E",
      "foreground": "#CDD6F4",
      "cursorColor": "#B4BEFE",
      "selectionBackground": "#45475A",
      "black": "#45475A",
      "red": "#F38BA8",
      "green": "#A6E3A1",
      "yellow": "#F9E2AF",
      "blue": "#89B4FA",
      "purple": "#F5C2E7",
      "cyan": "#94E2D5",
      "white": "#BAC2DE",
      "brightBlack": "#585B70",
      "brightRed": "#F38BA8",
      "brightGreen": "#A6E3A1",
      "brightYellow": "#F9E2AF",
      "brightBlue": "#74C7EC",
      "brightPurple": "#CBA6F7",
      "brightCyan": "#94E2D5",
      "brightWhite": "#CDD6F4"
    }
  ]
}
```

---

## 5. Tiling Window Manager: GlazeWM v3

- **Repositório Oficial:** [github.com/glzr-io/glazewm](https://github.com/glzr-io/glazewm)
- **Versão de Referência Verificada:** `v3.8.x` (schema v3)
- **Instalação via WinGet:**
  ```powershell
  winget install --id=glzr-io.glazewm -e
  ```
- **Caminho do Arquivo:** `%USERPROFILE%\.glzr\glazewm\config.yaml`

### 5.1. Arquivo Completo: `%USERPROFILE%\.glzr\glazewm\config.yaml`

```yaml
# ==============================================================================
# %USERPROFILE%\.glzr\glazewm\config.yaml — GlazeWM v3 Configuration
# Theme: Catppuccin Mocha (Active: Sapphire #74c7ec | Inactive: Surface0 #313244)
# ==============================================================================
general:
  startup_commands: ['shell-exec zebar']
  shutdown_commands: ['shell-exec taskkill /IM zebar.exe /F']
  config_reload_commands: []
  focus_follows_cursor: false
  toggle_workspace_on_refocus: true
  cursor_jump:
    enabled: true
    trigger: 'monitor_focus'
  hide_method: 'cloak'
  show_all_in_taskbar: false

gaps:
  scale_with_dpi: true
  inner_gap: '6px'
  outer_gap:
    top: '42px'    # Reserva 36px da barra Zebar + 6px de gap externo
    right: '6px'
    bottom: '6px'
    left: '6px'

window_effects:
  focused_window:
    border:
      enabled: true
      color: '#74c7ec' # Catppuccin Mocha Sapphire
    hide_title_bar:
      enabled: false
    corner_style:
      enabled: true
      style: 'rounded'
  other_windows:
    border:
      enabled: true
      color: '#313244' # Catppuccin Mocha Surface0
    hide_title_bar:
      enabled: false
    corner_style:
      enabled: true
      style: 'rounded'

window_behavior:
  initial_state: 'tiling'
  state_defaults:
    floating:
      centered: true
      shown_on_top: false
    fullscreen:
      maximized: false
      shown_on_top: false

workspaces:
  - name: '1'
    display_name: '1 · Term'
    keep_alive: true
  - name: '2'
    display_name: '2 · Code'
    keep_alive: true
  - name: '3'
    display_name: '3 · Web'
  - name: '4'
    display_name: '4 · Ops'
  - name: '5'
    display_name: '5 · Docs'
  - name: '6'
    display_name: '6'
  - name: '7'
    display_name: '7'
  - name: '8'
    display_name: '8'
  - name: '9'
    display_name: '9'

window_rules:
  # 1. Ignorar barras de status, overlays, launchers e PiP
  - commands: ['ignore']
    match:
      - window_process: { equals: 'zebar' }
      - window_process: { equals: 'Flow.Launcher' }
      - window_process: { regex: 'PowerToys\..*' }
      - window_title: { regex: '[Pp]icture.in.[Pp]icture' }
      - window_class: { regex: 'Chrome_WidgetWin_1|MozillaDialogClass' }
        window_title: { equals: '' }

  # 2. Diálogos nativos do Windows (#32770), instaladores e popups de arquivo
  - commands: ['set-floating']
    match:
      - window_class: { equals: '#32770' }
      - window_class: { equals: 'OperationStatusWindow' }
      - window_class: { equals: 'Credential Dialog Xaml Host' }

  # 3. Gerenciadores de credenciais, autenticação e segurança
  - commands: ['set-floating']
    match:
      - window_process: { regex: '1Password|Bitwarden|KeePassXC|PinEntry' }
      - window_title: { regex: 'Sign in|Autenticação|Security|Windows Security' }

  # 4. Utilitários de sistema e ferramentas com dimensões fixas
  - commands: ['set-floating']
    match:
      - window_process: { regex: 'Taskmgr|calc|SystemSettings|SnippingTool|DiskInfo64' }

binding_modes:
  - name: 'resize'
    keybindings:
      - commands: ['resize --width -2%']
        bindings: ['h', 'left']
      - commands: ['resize --width +2%']
        bindings: ['l', 'right']
      - commands: ['resize --height +2%']
        bindings: ['k', 'up']
      - commands: ['resize --height -2%']
        bindings: ['j', 'down']
      - commands: ['wm-disable-binding-mode --name resize']
        bindings: ['escape', 'enter']

keybindings:
  # Navegação de foco estilo Vim (Alt + h/j/k/l)
  - commands: ['focus --direction left']
    bindings: ['alt+h']
  - commands: ['focus --direction down']
    bindings: ['alt+j']
  - commands: ['focus --direction up']
    bindings: ['alt+k']
  - commands: ['focus --direction right']
    bindings: ['alt+l']

  # Mover janelas estilo Vim (Alt + Shift + h/j/k/l)
  - commands: ['move --direction left']
    bindings: ['alt+shift+h']
  - commands: ['move --direction down']
    bindings: ['alt+shift+j']
  - commands: ['move --direction up']
    bindings: ['alt+shift+k']
  - commands: ['move --direction right']
    bindings: ['alt+shift+l']

  # Alternar estados de janela (Floating, Fullscreen, Direção de Tiling)
  - commands: ['toggle-floating --centered']
    bindings: ['alt+shift+f']
  - commands: ['toggle-fullscreen']
    bindings: ['alt+f']
  - commands: ['toggle-tiling-direction']
    bindings: ['alt+v']
  - commands: ['wm-enable-binding-mode --name resize']
    bindings: ['alt+r']

  # Selecionar Workspaces (Alt + 1..9)
  - commands: ['focus --workspace 1']
    bindings: ['alt+1']
  - commands: ['focus --workspace 2']
    bindings: ['alt+2']
  - commands: ['focus --workspace 3']
    bindings: ['alt+3']
  - commands: ['focus --workspace 4']
    bindings: ['alt+4']
  - commands: ['focus --workspace 5']
    bindings: ['alt+5']
  - commands: ['focus --workspace 6']
    bindings: ['alt+6']
  - commands: ['focus --workspace 7']
    bindings: ['alt+7']
  - commands: ['focus --workspace 8']
    bindings: ['alt+8']
  - commands: ['focus --workspace 9']
    bindings: ['alt+9']

  # Mover janela para Workspace e acompanhar foco (Alt + Shift + 1..9)
  - commands: ['move --workspace 1', 'focus --workspace 1']
    bindings: ['alt+shift+1']
  - commands: ['move --workspace 2', 'focus --workspace 2']
    bindings: ['alt+shift+2']
  - commands: ['move --workspace 3', 'focus --workspace 3']
    bindings: ['alt+shift+3']
  - commands: ['move --workspace 4', 'focus --workspace 4']
    bindings: ['alt+shift+4']
  - commands: ['move --workspace 5', 'focus --workspace 5']
    bindings: ['alt+shift+5']
  - commands: ['move --workspace 6', 'focus --workspace 6']
    bindings: ['alt+shift+6']
  - commands: ['move --workspace 7', 'focus --workspace 7']
    bindings: ['alt+shift+7']
  - commands: ['move --workspace 8', 'focus --workspace 8']
    bindings: ['alt+shift+8']
  - commands: ['move --workspace 9', 'focus --workspace 9']
    bindings: ['alt+shift+9']

  # Gerenciamento do GlazeWM
  - commands: ['wm-reload-config']
    bindings: ['alt+shift+r']
  - commands: ['wm-toggle-pause']
    bindings: ['alt+shift+p']
  - commands: ['close']
    bindings: ['alt+shift+q']
```

---

## 6. Status Bar Flutuante: Zebar

- **Repositório Oficial:** [github.com/glzr-io/zebar](https://github.com/glzr-io/zebar)
- **Por que Zebar em vez de YASB Reborn:** O Zebar é desenvolvido pela mesma equipe do GlazeWM (`glzr-io`), compartilha o IPC nativo de baixa latência para workspaces/foco sem polling externo e é iniciado automaticamente pelo GlazeWM.
- **Diretório do Pack Customizado:** `%USERPROFILE%\.glzr\zebar\catppuccin-alpine\`

### 6.1. Configuração de Inicialização: `%USERPROFILE%\.glzr\zebar\settings.json`

```json
{
  "$schema": "https://github.com/glzr-io/zebar/raw/v2.6.0/resources/settings-schema.json",
  "startupConfigs": [
    {
      "path": "catppuccin-alpine/catppuccin-alpine.zebar.json",
      "preset": "default"
    }
  ]
}
```

### 6.2. Definição da Janela da Barra: `%USERPROFILE%\.glzr\zebar\catppuccin-alpine\catppuccin-alpine.zebar.json`

```json
{
  "$schema": "https://github.com/glzr-io/zebar/raw/v2.6.0/resources/widget-schema.json",
  "htmlPath": "./index.html",
  "zOrder": "normal",
  "shownInTaskbar": false,
  "focused": false,
  "resizable": false,
  "transparent": true,
  "presets": [
    {
      "name": "default",
      "anchor": "top_left",
      "offsetX": "0px",
      "offsetY": "0px",
      "width": "100%",
      "height": "38px",
      "monitorSelection": {
        "type": "all"
      },
      "dockToEdge": {
        "enabled": false,
        "edge": null,
        "windowMargin": "0px"
      }
    }
  ]
}
```

### 6.3. Estilo Catppuccin Mocha em Pílulas: `%USERPROFILE%\.glzr\zebar\catppuccin-alpine\styles.css`

```css
/* ============================================================================
 * styles.css — Zebar Floating Capsules (Catppuccin Mocha)
 * ============================================================================ */
:root {
  --crust: #11111b;
  --mantle: #181825;
  --base: #1e1e2e;
  --surface0: #313244;
  --surface1: #45475a;
  --surface2: #585b70;
  --text: #cdd6f4;
  --sapphire: #74c7ec;
  --blue: #89b4fa;
  --lavender: #b4befe;
  --teal: #94e2d5;
  --green: #a6e3a1;
  --yellow: #f9e2af;
  --red: #f38ba8;
}

* {
  box-sizing: border-box;
  margin: 0;
  padding: 0;
  user-select: none;
}

body {
  font-family: "JetBrainsMono Nerd Font", monospace;
  font-size: 12px;
  font-weight: 600;
  color: var(--text);
  background: transparent;
  height: 38px;
  overflow: hidden;
}

.bar {
  display: grid;
  grid-template-columns: 1fr auto 1fr;
  align-items: center;
  height: 100%;
  padding: 4px 6px;
  gap: 8px;
}

.section-left {
  display: flex;
  align-items: center;
  gap: 6px;
  justify-self: start;
}

.section-center {
  display: flex;
  align-items: center;
  justify-self: center;
  max-width: 480px;
}

.section-right {
  display: flex;
  align-items: center;
  gap: 6px;
  justify-self: end;
}

.pill {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  background-color: rgba(24, 24, 37, 0.92); /* Mantle */
  border: 1px solid var(--surface0);
  border-radius: 999px;
  padding: 4px 12px;
  height: 28px;
  white-space: nowrap;
}

.workspaces {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  background-color: rgba(17, 17, 27, 0.94); /* Crust */
  border: 1px solid var(--surface0);
  border-radius: 999px;
  padding: 3px 6px;
  height: 28px;
}

.ws-btn {
  background: var(--surface0);
  color: var(--text);
  border: none;
  border-radius: 999px;
  padding: 2px 9px;
  font-family: inherit;
  font-size: 11px;
  font-weight: 700;
  cursor: pointer;
  transition: all 120ms ease;
}

.ws-btn.focused {
  background: var(--sapphire);
  color: var(--crust);
}

.ws-btn.active:not(.focused) {
  border: 1px solid var(--lavender);
  color: var(--lavender);
}

.window-title {
  overflow: hidden;
  text-overflow: ellipsis;
  max-width: 440px;
  color: var(--lavender);
}

.icon-sapphire { color: var(--sapphire); }
.icon-lavender { color: var(--lavender); }
.icon-teal     { color: var(--teal); }
.icon-blue     { color: var(--blue); }
```

### 6.4. Template HTML + Providers Reais: `%USERPROFILE%\.glzr\zebar\catppuccin-alpine\index.html`

Inclui todos os **8 módulos obrigatórios**: Workspaces GlazeWM, Título da Janela Ativa, CPU, RAM, Rede, Volume e Data ISO + Relógio 24h (`yyyy-LL-dd HH:mm`).

```html
<!DOCTYPE html>
<html lang="pt-BR">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Zebar — Catppuccin Mocha Alpine</title>
    <link rel="stylesheet" href="./styles.css" />
  </head>
  <body>
    <div id="root"></div>

    <script type="importmap">
      {
        "imports": {
          "react": "https://esm.sh/react@18?dev",
          "react-dom/client": "https://esm.sh/react-dom@18/client?dev",
          "zebar": "https://esm.sh/zebar@2"
        }
      }
    </script>

    <script type="module">
      import React, { useState, useEffect } from "react";
      import { createRoot } from "react-dom/client";
      import * as zebar from "zebar";

      const providers = zebar.createProviderGroup({
        glazewm: { type: "glazewm" },
        cpu: { type: "cpu", refreshInterval: 2000 },
        memory: { type: "memory", refreshInterval: 2000 },
        network: { type: "network", refreshInterval: 3000 },
        audio: { type: "audio" },
        date: { type: "date", formatting: "yyyy-LL-dd HH:mm" },
      });

      function findFocusedTitle(container) {
        if (!container) return "Desktop";
        if (container.type === "window" && container.hasFocus) {
          return container.title || container.processName || "Window";
        }
        if (Array.isArray(container.children)) {
          for (const child of container.children) {
            const found = findFocusedTitle(child);
            if (found !== "Desktop") return found;
          }
        }
        return "Desktop";
      }

      function App() {
        const [output, setOutput] = useState(providers.outputMap);

        useEffect(() => {
          providers.onOutput(() => setOutput({ ...providers.outputMap }));
        }, []);

        const gw = output.glazewm;
        const activeTitle = gw?.focusedContainer?.title || findFocusedTitle(gw?.currentWorkspace);
        const netName =
          output.network?.defaultInterface?.friendlyName ||
          output.network?.defaultGateway?.ssid ||
          "Online";
        const vol =
          output.audio?.defaultPlaybackDevice?.volume != null
            ? `${Math.round(output.audio.defaultPlaybackDevice.volume)}%`
            : "--%";

        return React.createElement(
          "div",
          { className: "bar" },
          // Esquerda: Workspaces GlazeWM
          React.createElement(
            "div",
            { className: "section-left" },
            React.createElement(
              "div",
              { className: "workspaces" },
              gw?.currentWorkspaces?.map((ws) =>
                React.createElement(
                  "button",
                  {
                    key: ws.name,
                    className: `ws-btn ${ws.hasFocus ? "focused" : ""} ${ws.isDisplayed ? "active" : ""}`,
                    onClick: () => gw.runCommand(`focus --workspace ${ws.name}`),
                  },
                  ws.displayName || ws.name
                )
              )
            )
          ),

          // Centro: Título da Janela Ativa
          React.createElement(
            "div",
            { className: "section-center" },
            React.createElement(
              "div",
              { className: "pill window-title" },
              React.createElement("span", { className: "icon-lavender" }, ""),
              React.createElement("span", null, activeTitle || "Alpine Workstation")
            )
          ),

          // Direita: CPU, RAM, Rede, Volume e Relógio ISO 24h (YYYY-MM-DD HH:mm)
          React.createElement(
            "div",
            { className: "section-right" },
            output.cpu &&
              React.createElement(
                "div",
                { className: "pill" },
                React.createElement("span", { className: "icon-sapphire" }, ""),
                React.createElement("span", null, `${Math.round(output.cpu.usage)}%`)
              ),
            output.memory &&
              React.createElement(
                "div",
                { className: "pill" },
                React.createElement("span", { className: "icon-teal" }, ""),
                React.createElement("span", null, `${Math.round(output.memory.usage)}%`)
              ),
            output.network &&
              React.createElement(
                "div",
                { className: "pill" },
                React.createElement("span", { className: "icon-blue" }, "󰖩"),
                React.createElement("span", null, netName)
              ),
            output.audio &&
              React.createElement(
                "div",
                { className: "pill" },
                React.createElement("span", { className: "icon-lavender" }, ""),
                React.createElement("span", null, vol)
              ),
            output.date &&
              React.createElement(
                "div",
                { className: "pill" },
                React.createElement("span", { className: "icon-sapphire" }, ""),
                React.createElement("span", null, output.date.formatted)
              )
          )
        );
      }

      createRoot(document.getElementById("root")).render(React.createElement(App));
    </script>
  </body>
</html>
```

---

## 7. App Launcher: Flow Launcher

- **Repositório Oficial:** [github.com/Flow-Launcher/Flow.Launcher](https://github.com/Flow-Launcher/Flow.Launcher)
- **Tema Oficial Catppuccin:** [github.com/catppuccin/flow-launcher](https://github.com/catppuccin/flow-launcher) (mantido oficialmente pela organização Catppuccin)
- **Atalho Global:** `Alt+Space`
- **Caminho de Dados / Temas:** `%APPDATA%\FlowLauncher\Themes\`

### 7.1. Instalação do Flow Launcher e do Tema Catppuccin Mocha
1. Instale o Flow Launcher via WinGet:
   ```powershell
   winget install --id=Flow-Launcher.Flow-Launcher -e
   ```
2. Baixe o arquivo oficial `Catppuccin Mocha.xaml` diretamente do repositório oficial:
   ```powershell
   Invoke-WebRequest -Uri "https://raw.githubusercontent.com/catppuccin/flow-launcher/main/themes/Catppuccin%20Mocha.xaml" -OutFile "$env:APPDATA\FlowLauncher\Themes\Catppuccin Mocha.xaml"
   ```
3. Abra as configurações do Flow Launcher (`Alt+Space` → digite `settings`), acesse **Appearance**:
   - **Theme:** `Catppuccin Mocha`
   - **Search Query Font:** `JetBrainsMono Nerd Font` (16 pt)
   - **Result Item Font:** `JetBrainsMono Nerd Font` (13 pt)
   - **Window Width:** `640 px`
   - **Max Results Shown:** `7`
4. Em **General → Hotkey**, confirme que o atalho principal está definido como **`Alt + Space`**.

### 7.2. Plugins de Produtividade Recomendados (Integração VS Code & WSL)
Execute os comandos abaixo no próprio Flow Launcher (`Alt+Space`):
- **VS Code Workspaces** (nativo ou `pm install VSCode Workspaces`): Abre pastas recentes e workspaces remotos do **WSL (`Alpine-3.23.4`)** diretamente no VS Code.
- **Shell Plugin** (nativo, acionado pelo prefixo `>`): Configure para executar comandos via `pwsh.exe` ou `wsl.exe -d Alpine-3.23.4 -- zsh -lc "<cmd>"`.
- **Explorer / Everything** (nativo): Busca instantânea de diretórios locais e projetos.

---

## 8. Configuração Global do WSL 2 (`%USERPROFILE%\.wslconfig`)

### 8.1. Diferença entre `%USERPROFILE%\.wslconfig` e `/etc/wsl.conf`
| Característica | `%USERPROFILE%\.wslconfig` (Windows Host) | `/etc/wsl.conf` (Alpine Linux Guest) |
| :--- | :--- | :--- |
| **Escopo** | Global para a VM utilitária do WSL 2 no Windows 11 | Específico para a distribuição `Alpine-3.23.4` |
| **Onde fica** | `C:\Users\pedrohpsantos\.wslconfig` | `/etc/wsl.conf` (versionado em `wsl-system/wsl.conf`) |
| **O que controla** | RAM (`memory`), CPUs (`processors`), `autoMemoryReclaim`, `sparseVhd`, `dnsTunneling` | `boot.systemd=false`, `automount` (`metadata`), `user.default`, `interop` |

### 8.2. Conteúdo Recomendado para `%USERPROFILE%\.wslconfig`
> **Importante:** Caso você já possua um arquivo `%USERPROFILE%\.wslconfig`, mescle as chaves abaixo nas seções `[wsl2]` e `[experimental]` existentes sem apagar configurações personalizadas que você utilize.

```ini
[wsl2]
memory=10GB
processors=12
swap=4GB
localhostForwarding=true
nestedVirtualization=true
networkingMode=nat
dnsTunneling=true
autoProxy=true

[experimental]
autoMemoryReclaim=gradual
sparseVhd=true
hostAddressLoopback=true
```

### 8.3. Aplicação e Reinicialização do WSL 2
Após editar `%USERPROFILE%\.wslconfig`, feche seus terminais Linux e execute no **PowerShell 7** (Windows):
```powershell
wsl --shutdown
```
Aguarde 8 segundos (regra de desligamento da VM utilitária do WSL 2) e inicie novamente o Alpine (`wsl -d Alpine-3.23.4`).

### 8.4. Comandos de Verificação Técnica (Pós-Reinicialização)
1. **Verificar Memória (10 GB):**
   ```sh
   free -h
   ```
2. **Verificar Processadores (12 vCPUs):**
   ```sh
   nproc
   ```
3. **Verificar Memory Reclaim (`gradual`):**
   ```sh
   cat /proc/sys/vm/drop_caches 2>/dev/null || grep -H . /sys/module/hv_balloon/parameters/* 2>/dev/null
   ```
4. **Verificar DNS Tunneling:**
   ```sh
   cat /etc/resolv.conf
   ```
5. **Verificar Sparse VHD (no PowerShell 7 do Windows):**
   ```powershell
   wsl.exe --manage Alpine-3.23.4 --set-sparse true
   ```
