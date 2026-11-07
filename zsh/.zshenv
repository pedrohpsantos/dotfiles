# ============================================================
# ~/.zshenv — XDG Base Directories, Core Env & Curated PATH
# ============================================================
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

export LANG="${LANG:-C.UTF-8}"
export LC_ALL="${LC_ALL:-C.UTF-8}"
export EDITOR="nvim"
export VISUAL="nvim"
export PAGER="less -FRX"

export GOPATH="${GOPATH:-$XDG_DATA_HOME/go}"
export CARGO_HOME="${CARGO_HOME:-$XDG_DATA_HOME/cargo}"
export RUSTUP_HOME="${RUSTUP_HOME:-$XDG_DATA_HOME/rustup}"

# Curated PATH for both login and non-login Zsh invocations
path=(
    "$HOME/.local/bin"
    "$CARGO_HOME/bin"
    "$GOPATH/bin"
    /usr/local/sbin
    /usr/local/bin
    /usr/sbin
    /usr/bin
    /sbin
    /bin
    /usr/lib/wsl/lib
    "/mnt/c/WINDOWS/system32"
    "/mnt/c/WINDOWS"
    "/mnt/c/WINDOWS/System32/Wbem"
    "/mnt/c/WINDOWS/System32/WindowsPowerShell/v1.0"
    "/mnt/c/Users/pedrohpsantos/AppData/Local/Microsoft/WindowsApps"
    "/mnt/c/Users/pedrohpsantos/AppData/Local/Programs/Microsoft VS Code/bin"
    "/mnt/c/Users/pedrohpsantos/.gemini/antigravity-cli/bin"
    "/mnt/c/Users/pedrohpsantos/AppData/Local/agy/bin"
)
typeset -gU path PATH
export PATH
