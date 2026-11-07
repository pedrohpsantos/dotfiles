# ============================================================
# ~/.config/zsh/aliases.zsh — Organized Aliases & Functions
# Use `aliases-help` to list all custom aliases and functions.
# ============================================================

# --- Navigation ---
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias proj='cd "$HOME/Projects"'
alias docs='cd "$HOME/System-Documentation"'
alias winhome='cd "/mnt/c/Users/pedrohpsantos"'
alias windocs='cd "/mnt/c/Users/pedrohpsantos/Documents"'

# --- Files & Modern CLI (non-destructive) ---
if command -v eza >/dev/null 2>&1; then
    alias ls='eza --group-directories-first --icons=auto'
    alias ll='eza -lh --git --group-directories-first --icons=auto'
    alias la='eza -lah --git --group-directories-first --icons=auto'
    alias lt='eza --tree --level=2 --group-directories-first --icons=auto'
else
    alias ll='ls -lh'
    alias la='ls -lah'
fi
alias batp='bat --paging=never --style=plain'
alias dfh='df -hT -x tmpfs -x devtmpfs'
alias duh='du -sh * .[!.]* 2>/dev/null | sort -hr | head -n 25'

# --- Git & GitHub ---
alias g='git'
alias gs='git status -sb'
alias gl='git log --oneline --graph --decorate -n 20'
alias gd='git diff'
alias gds='git diff --staged'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gb='git branch -vv'
alias lg='lazygit'

# --- Alpine APK (Read-only & Safe Maintenance) ---
alias apks='apk search -v'
alias apki='apk info -a'
alias apkl='apk info -vv | sort'
alias apkw='sort /etc/apk/world'
alias apku='doas apk update && doas apk upgrade --available --simulate'

# --- Docker & Containers ---
alias d='docker'
alias dps='docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"'
alias dpa='docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"'
alias dc='docker compose'
alias dcu='docker compose up -d'
alias dcd='docker compose down'
alias dcl='docker compose logs -f --tail=100'

# --- Languages & Toolchains ---
alias py='python3'
alias uvr='uv run'
alias uvs='uv sync'
alias uva='uv add'
alias uvt='uv tool'
alias cb='cargo build'
alias ct='cargo test'
alias cc='cargo check'
alias ccl='cargo clippy'
alias gor='go run .'
alias got='go test ./...'
alias gov='go vet ./...'
alias v='nvim'
alias ta='tmux attach -t'
alias tn='tmux new -s'
alias tl='tmux ls'

# --- System, Processes & Networking ---
alias psa='ps -ef'
alias ports='ss -tulpn'
alias myip='ip -br addr'
alias rcs='rc-status -a'
alias open='explorer.exe'
alias pbcopy='clip.exe'
alias pbpaste='powershell.exe -NoProfile -Command Get-Clipboard | tr -d "\r"'

# --- Dotfiles Repository Manager ---
alias dotfiles='git -C "${DOTFILES_DIR:-$HOME/dotfiles}"'

# --- Helper Functions ---
mkcd() {
    mkdir -p -- "$1" && cd -- "$1"
}

aliases-help() {
    printf "\033[1;36m=== Custom Aliases & Functions (~/.config/zsh/aliases.zsh) ===\033[0m\n"
    grep -E '^(alias |# ---|[a-zA-Z0-9_-]+\(\))' "$HOME/.config/zsh/aliases.zsh" | sed 's/^# --- /\n\x1b[1;33m--- /; s/ ---$/ ---\x1b[0m/'
}

# --- Rasp32 Embedded Lab (UnB FSE) ---
alias rasp32='ssh rasp32'
alias rasp32-status='ssh -G rasp32 | grep -E "^(user|hostname|port|identityfile|identitiesonly|connecttimeout) "'

rasp32-check() {
    ssh -o BatchMode=yes -o ConnectTimeout=8 "${1:-rasp32}" \
        'printf "SSH_KEY_AUTH_OK\n"; id; hostname; uptime'
}

rasp32-info() {
    ssh -o BatchMode=yes -o ConnectTimeout=8 "${1:-rasp32}" '
        echo "=== OS & KERNEL ==="
        uname -a
        cat /etc/os-release 2>/dev/null || true
        echo "=== HARDWARE MODEL ==="
        if [ -r /proc/device-tree/model ]; then tr -d "\000" < /proc/device-tree/model; printf "\n"; fi
        lscpu 2>/dev/null || true
        echo "=== MEMORY & STORAGE ==="
        free -h
        df -h /
        lsblk 2>/dev/null || true
        echo "=== GPIO TOOLS ==="
        for g in gpiodetect gpioinfo gpiofind gpioget gpioset raspi-gpio pinctrl; do
            printf "%-12s : %s\n" "$g" "$(command -v "$g" 2>/dev/null || echo AUSENTE)"
        done
    '
}

rasp32-sync() {
    if [ $# -lt 1 ]; then
        echo "Uso: rasp32-sync <diretorio_local> [destino_remoto_em_rasp32]"
        return 1
    fi
    _src="$1"
    _dst="${2:-~/$(basename "$_src")}"
    rsync -avz --exclude '.git' --exclude '.venv' --exclude '__pycache__' --exclude 'node_modules' "$_src" "rasp32:$_dst"
}

rasp32-copy() {
    if [ $# -lt 2 ]; then
        echo "Uso: rasp32-copy <arquivo_origem> <destino (ex: rasp32:~/ ou ./local)>"
        return 1
    fi
    scp -r "$1" "$2"
}

# --- Workstation 2026 Modern TUI & Workbench Shortcuts ---
alias ld='lazydocker'
alias btm='btop'
alias wb='workbench'
alias reload='exec zsh -l'
alias devdoctor="$HOME/.local/bin/devdoctor"
alias tf='tofu'

# Yazi wrapper: changes CWD on exit only if yazi exits with 0 (press q in Yazi to cd, Q to stay)
y() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd rc=0
    yazi "$@" --cwd-file="$tmp" || rc=$?
    if [ "$rc" -eq 0 ] && cwd="$(command cat -- "$tmp" 2>/dev/null)" && [ -n "$cwd" ] && [ -d "$cwd" ] && [ "$cwd" != "$PWD" ]; then
        builtin cd -- "$cwd"
    fi
    rm -f -- "$tmp"
    return "$rc"
}
