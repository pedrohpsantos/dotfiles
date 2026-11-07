# ============================================================
# ~/.zshrc — Interactive Zsh Configuration (Alpine WSL 2)
# Fast, modular, XDG-compliant, cached hooks (< 60ms startup).
# ============================================================
[[ $- != *i* ]] && return

typeset -gU path PATH fpath FPATH

# --- History Configuration ---
HISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history"
HISTSIZE=50000
SAVEHIST=50000
setopt EXTENDED_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_FIND_NO_DUPS
setopt HIST_SAVE_NO_DUPS
setopt SHARE_HISTORY

# --- Shell Ergonomics ---
setopt AUTO_CD
setopt INTERACTIVE_COMMENTS
setopt NO_BEEP
bindkey -e

# --- Autocompletion (Cached 24h compdump) ---
if [ -d /usr/share/zsh/plugins/zsh-completions/src ]; then
    fpath=(/usr/share/zsh/plugins/zsh-completions/src $fpath)
fi
autoload -Uz compinit
_zcompdump="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump-${ZSH_VERSION}"
if [[ -f "$_zcompdump" ]]; then
    compinit -C -d "$_zcompdump"
else
    compinit -i -d "$_zcompdump"
    zcompile "$_zcompdump"
fi
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# --- Keybindings ---
bindkey '^[[A' up-line-or-search
bindkey '^[[B' down-line-or-search
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^[[3~' delete-char
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word

# --- Modern CLI Integrations (Cached Hooks) ---
_zcache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
if [ -f /usr/share/zsh/plugins/fzf/key-bindings.zsh ]; then
    source /usr/share/zsh/plugins/fzf/key-bindings.zsh
fi
if [ -f /usr/share/zsh/plugins/fzf/completion.zsh ]; then
    source /usr/share/zsh/plugins/fzf/completion.zsh
fi
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'

if [ -f "$_zcache/zoxide-init.zsh" ]; then
    source "$_zcache/zoxide-init.zsh"
elif command -v zoxide >/dev/null 2>&1; then
    zoxide init zsh > "$_zcache/zoxide-init.zsh"
    source "$_zcache/zoxide-init.zsh"
fi

if [ -f "$_zcache/direnv-hook.zsh" ]; then
    source "$_zcache/direnv-hook.zsh"
elif command -v direnv >/dev/null 2>&1; then
    direnv hook zsh > "$_zcache/direnv-hook.zsh"
    source "$_zcache/direnv-hook.zsh"
fi

# --- Aliases & Functions ---
if [ -f "${XDG_CONFIG_HOME:-$HOME/.config}/zsh/aliases.zsh" ]; then
    source "${XDG_CONFIG_HOME:-$HOME/.config}/zsh/aliases.zsh"
fi

# --- Plugins (Alpine native packages) ---
if [ -f /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
    ZSH_AUTOSUGGEST_STRATEGY=(history completion)
    ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
    source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

if [ -f /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
    source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

# --- Prompt (Starship Cached Init) ---
if [ -f "$_zcache/starship-init.zsh" ]; then
    source "$_zcache/starship-init.zsh"
elif command -v starship >/dev/null 2>&1; then
    starship init zsh > "$_zcache/starship-init.zsh"
    source "$_zcache/starship-init.zsh"
fi
unset _zcache

# --- Terminal Tab Title Identity (Alpine WSL 2) ---
_alpine_set_win_title() {
    print -Pn "\e]0;alpine · %~\a"
}
precmd_functions+=(_alpine_set_win_title)
