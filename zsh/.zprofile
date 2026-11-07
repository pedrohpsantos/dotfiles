# ============================================================
# ~/.zprofile — Fast Login Shell Environment & Curated PATH
# ============================================================
umask 022

# Load /etc/profile.d/*.sh directly without /etc/profile's slow /mnt/c stat loop
for _script in /etc/profile.d/*.sh; do
    [ -r "$_script" ] && . "$_script"
done
unset _script

# Curated PATH:
# 1. User & Language local bins (~/.local/bin, cargo, go)
# 2. Alpine Linux native bins (/usr/local/bin, /usr/bin, /bin, etc.)
# 3. WSL GPU lib (/usr/lib/wsl/lib)
# 4. Windows Interop Allowlist ONLY (system32, Windows, PowerShell, VS Code, Antigravity CLI)
path=(
    "$HOME/.local/bin"
    "${CARGO_HOME:-$HOME/.local/share/cargo}/bin"
    "${GOPATH:-$HOME/.local/share/go}/bin"
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
