#!/bin/sh
# ==============================================================================
# install.sh — Automated & Idempotent Bootstrap for Alpine Linux WSL 2 Dotfiles
# Architecture: GNU Stow + Native musl APK + OpenRC + Devdoctor
# ==============================================================================
set -eu

REPO_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)"
TARGET_HOME="${HOME:-/home/pedrohpsantos}"
DRY_RUN=0
SKIP_PACKAGES=0
SKIP_OPENRC=0
SKIP_DOCTOR=0
INCLUDE_OPTIONAL=0

STOW_PACKAGES="zsh starship tmux nvim lazygit lazydocker yazi btop fastfetch git local-bin"

ESC="$(printf '\033')"
C_RESET="${ESC}[0m"
C_BOLD="${ESC}[1m"
C_BLUE="${ESC}[38;2;137;180;250m"
C_TEAL="${ESC}[38;2;148;226;213m"
C_GREEN="${ESC}[38;2;166;227;161m"
C_YELLOW="${ESC}[38;2;249;226;175m"
C_RED="${ESC}[38;2;243;139;168m"

log_info()  { printf "%s[INFO]%s  %s\n" "$C_BLUE" "$C_RESET" "$*"; }
log_step()  { printf "\n%s%s==> %s%s\n" "$C_BOLD" "$C_TEAL" "$*" "$C_RESET"; }
log_ok()    { printf "%s[OK]%s    %s\n" "$C_GREEN" "$C_RESET" "$*"; }
log_warn()  { printf "%s[WARN]%s  %s\n" "$C_YELLOW" "$C_RESET" "$*" >&2; }
log_err()   { printf "%s[ERROR]%s %s\n" "$C_RED" "$C_RESET" "$*" >&2; }
log_dry()   { printf "%s[DRY-RUN]%s %s\n" "$C_YELLOW" "$C_RESET" "$*"; }

on_exit() {
    _rc=$?
    if [ "$_rc" -ne 0 ]; then
        log_err "Bootstrap interrupted (exit code: $_rc). Inspect logs and backups before retrying."
    fi
    exit "$_rc"
}
trap on_exit EXIT INT TERM

usage() {
    cat << 'HELP'
Usage: ./install.sh [OPTIONS]

Idempotent bootstrap for Alpine Linux 3.23 (musl) on WSL 2 using GNU Stow.

Options:
  --dry-run          Simulate all steps without modifying packages, files or services
  --with-optional    Also install optional APK packages (packages/alpine/optional.txt)
  --skip-packages    Skip APK package verification and installation
  --skip-openrc      Skip OpenRC service validation (crond, syslog, redis)
  --skip-doctor      Skip running devdoctor at the end of bootstrap
  --help, -h         Show this help message
HELP
}

for arg in "$@"; do
    case "$arg" in
        --dry-run|-n)
            DRY_RUN=1
            ;;
        --with-optional)
            INCLUDE_OPTIONAL=1
            ;;
        --skip-packages)
            SKIP_PACKAGES=1
            ;;
        --skip-openrc)
            SKIP_OPENRC=1
            ;;
        --skip-doctor)
            SKIP_DOCTOR=1
            ;;
        --help|-h)
            usage
            trap - EXIT
            exit 0
            ;;
        *)
            log_err "Unknown option: $arg"
            usage >&2
            exit 1
            ;;
    esac
done

PRIV_CMD=""
detect_priv() {
    if [ "$(id -u)" -eq 0 ]; then
        PRIV_CMD=""
    elif command -v doas >/dev/null 2>&1; then
        PRIV_CMD="doas"
    elif command -v sudo >/dev/null 2>&1; then
        PRIV_CMD="sudo"
    else
        log_err "Administrative privileges required (root, doas, or sudo not available)."
        exit 1
    fi
}

run_priv() {
    if [ "$DRY_RUN" -eq 1 ]; then
        if [ -n "$PRIV_CMD" ]; then
            log_dry "$PRIV_CMD $*"
        else
            log_dry "$*"
        fi
        return 0
    fi
    if [ -n "$PRIV_CMD" ]; then
        "$PRIV_CMD" "$@"
    else
        "$@"
    fi
}

# ------------------------------------------------------------------------------
# 1. Pre-flight Checks
# ------------------------------------------------------------------------------
preflight_checks() {
    log_step "1. Running Pre-flight Environment Checks"

    if [ ! -f /etc/alpine-release ]; then
        log_err "/etc/alpine-release not found. This bootstrap supports Alpine Linux only."
        exit 1
    fi

    _alpine_ver="$(cat /etc/alpine-release)"
    case "$_alpine_ver" in
        3.23.*)
            log_ok "Alpine Linux version verified: $_alpine_ver"
            ;;
        *)
            log_err "Unsupported Alpine version: $_alpine_ver (expected 3.23.x)."
            exit 1
            ;;
    esac

    _arch="$(uname -m)"
    if [ "$_arch" != "x86_64" ]; then
        log_err "Unsupported architecture: $_arch (expected x86_64)."
        exit 1
    fi
    log_ok "Architecture verified: $_arch"

    _wsl_detected=0
    if [ -e /proc/sys/fs/binfmt_misc/WSLInterop ] || [ -e /dev/dxg ]; then
        _wsl_detected=1
    elif uname -r | grep -qi "microsoft"; then
        _wsl_detected=1
    fi
    if [ "$_wsl_detected" -ne 1 ]; then
        log_err "WSL 2 environment not detected (checked WSLInterop, /dev/dxg, and kernel release)."
        exit 1
    fi
    log_ok "WSL 2 environment verified (kernel: $(uname -r))"

    if ! ldd --version 2>&1 | grep -qi "musl"; then
        if [ ! -e /lib/ld-musl-x86_64.so.1 ]; then
            log_err "musl libc not detected."
            exit 1
        fi
    fi
    log_ok "C standard library verified: musl libc"

    if ! command -v apk >/dev/null 2>&1; then
        log_err "apk package manager not found."
        exit 1
    fi
    log_ok "APK package manager available"

    if [ ! -d "$REPO_DIR" ] || [ ! -f "$REPO_DIR/install.sh" ]; then
        log_err "Repository directory invalid: $REPO_DIR"
        exit 1
    fi
    case "$REPO_DIR" in
        /mnt/*)
            log_warn "Repository is located on Windows mount ($REPO_DIR). Keep dotfiles in the Linux ext4 filesystem for symlink reliability and I/O performance."
            ;;
    esac
    log_ok "Repository root verified: $REPO_DIR"

    detect_priv
    log_ok "Privilege escalation helper verified: ${PRIV_CMD:-root}"
}

# ------------------------------------------------------------------------------
# 2. APK Package Management
# ------------------------------------------------------------------------------
install_apk_packages() {
    log_step "2. Auditing & Installing APK Packages"
    if [ "$SKIP_PACKAGES" -eq 1 ]; then
        log_info "Skipping APK package checks (--skip-packages)."
        return 0
    fi

    _manifests="base.txt tui.txt dev.txt security.txt"
    if [ "$INCLUDE_OPTIONAL" -eq 1 ]; then
        _manifests="$_manifests optional.txt"
    fi

    _missing_pkgs=""
    for _m in $_manifests; do
        _mpath="$REPO_DIR/packages/alpine/$_m"
        if [ ! -f "$_mpath" ]; then
            log_warn "Manifest missing: $_mpath"
            continue
        fi
        while IFS= read -r _line || [ -n "$_line" ]; do
            _pkg="$(printf '%s' "$_line" | sed 's/#.*//; s/^[[:space:]]*//; s/[[:space:]]*$//')"
            [ -z "$_pkg" ] && continue
            if apk info -e "$_pkg" >/dev/null 2>&1; then
                continue
            fi
            if apk search -e "$_pkg" 2>/dev/null | grep -q "^${_pkg}-[0-9]"; then
                _missing_pkgs="$_missing_pkgs $_pkg"
            else
                log_warn "Package '$_pkg' from $_m is not available in enabled APK repositories."
            fi
        done < "$_mpath"
    done

    if [ -n "$_missing_pkgs" ]; then
        log_info "Installing missing APK packages:$_missing_pkgs"
        # shellcheck disable=SC2086
        run_priv apk add --no-cache $_missing_pkgs
    else
        log_ok "All required APK packages from manifests are already installed."
    fi

    # Verify optional external tools in ~/.local/bin
    for _ext in gitleaks trivy hadolint bandit pip-audit esptool; do
        if command -v "$_ext" >/dev/null 2>&1 || [ -x "$TARGET_HOME/.local/bin/$_ext" ]; then
            log_ok "External tool present: $_ext"
        else
            log_warn "Optional external tool not installed: $_ext (documented in packages/alpine/optional.txt)"
        fi
    done

    if ! command -v stow >/dev/null 2>&1; then
        if [ "$DRY_RUN" -eq 1 ]; then
            log_dry "stow will be available after apk add stow"
        else
            log_err "GNU Stow is not available even after APK check."
            exit 1
        fi
    else
        log_ok "GNU Stow available: $(stow --version | head -n 1)"
    fi
}

# ------------------------------------------------------------------------------
# 3. Conflict Detection & Backup before GNU Stow
# ------------------------------------------------------------------------------
resolve_stow_conflicts() {
    log_step "3. Auditing Stow Targets & Backing Up Any Conflicts"

    _timestamp="$(date '+%Y%m%d_%H%M%S')"
    _backup_dir="$TARGET_HOME/.dotfiles_backup_${_timestamp}"
    _conflicts_found=0

    for _pkg in $STOW_PACKAGES; do
        _pkg_dir="$REPO_DIR/$_pkg"
        [ ! -d "$_pkg_dir" ] && continue

        # Inspect every file and symlink inside the Stow package
        _items="$(find "$_pkg_dir" \( -type f -o -type l \))"
        for _src in $_items; do
            _rel="${_src#"$_pkg_dir"/}"
            _dst="$TARGET_HOME/$_rel"

            # If destination does not exist (neither file nor broken symlink), no conflict
            if [ ! -e "$_dst" ] && [ ! -L "$_dst" ]; then
                continue
            fi

            # Check if _dst already resolves to _src (already stowed)
            if [ -L "$_dst" ]; then
                _resolved_dst="$(readlink -f "$_dst" 2>/dev/null || true)"
                _resolved_src="$(readlink -f "$_src" 2>/dev/null || true)"
                if [ -n "$_resolved_dst" ] && [ "$_resolved_dst" = "$_resolved_src" ]; then
                    continue
                fi
                # Check if both are symlinks with the exact same relative target (e.g. .tmux.conf -> .config/tmux/tmux.conf)
                if [ -L "$_src" ]; then
                    _link_dst="$(readlink "$_dst" 2>/dev/null || true)"
                    _link_src="$(readlink "$_src" 2>/dev/null || true)"
                    if [ "$_link_dst" = "$_link_src" ]; then
                        # Stow needs to replace the standalone symlink with a symlink into the stow package
                        _conflicts_found=1
                        if [ "$DRY_RUN" -eq 1 ]; then
                            log_dry "Would back up symlink $_dst -> $_backup_dir/$_rel and replace with Stow link"
                        else
                            mkdir -p "$(dirname "$_backup_dir/$_rel")"
                            cp -P "$_dst" "$_backup_dir/$_rel"
                            rm -f "$_dst"
                            log_info "Backed up symlink: $_rel -> $_backup_dir/$_rel"
                        fi
                        continue
                    fi
                fi
                log_err "Pre-existing symlink $_dst points to unknown target ($(readlink "$_dst")). Aborting to protect user state."
                exit 1
            fi

            # Regular file at destination: back up preserving metadata before stowing
            _conflicts_found=1
            if [ "$DRY_RUN" -eq 1 ]; then
                if cmp -s "$_src" "$_dst"; then
                    log_dry "Would back up identical file $_dst -> $_backup_dir/$_rel and replace with Stow symlink"
                else
                    log_dry "Would back up differing file $_dst -> $_backup_dir/$_rel and replace with Stow symlink"
                fi
            else
                mkdir -p "$(dirname "$_backup_dir/$_rel")"
                cp -a "$_dst" "$_backup_dir/$_rel"
                if ! cmp -s "$_dst" "$_backup_dir/$_rel"; then
                    log_err "Backup verification failed for $_dst"
                    exit 1
                fi
                rm -f "$_dst"
                log_info "Backed up: $_rel -> $_backup_dir/$_rel"
            fi
        done
    done

    if [ "$_conflicts_found" -eq 0 ]; then
        log_ok "Zero conflicting files found (all targets already stowed or clean)."
    elif [ "$DRY_RUN" -eq 0 ]; then
        log_ok "All pre-existing target files safely backed up to: $_backup_dir"
    fi
}

# ------------------------------------------------------------------------------
# 4. Apply GNU Stow Packages
# ------------------------------------------------------------------------------
apply_stow_packages() {
    log_step "4. Applying Modular GNU Stow Packages"

    _valid_pkgs=""
    for _pkg in $STOW_PACKAGES; do
        if [ -d "$REPO_DIR/$_pkg" ]; then
            _valid_pkgs="$_valid_pkgs $_pkg"
        else
            log_warn "Stow package directory not found, skipping: $_pkg"
        fi
    done

    if [ "$DRY_RUN" -eq 1 ]; then
        if ! command -v stow >/dev/null 2>&1; then
            log_warn "GNU Stow is not installed; cannot simulate package linking."
            return 0
        fi
        log_info "Simulating GNU Stow package application (read-only conflict check)..."
        (
            cd "$REPO_DIR"
            # shellcheck disable=SC2086
            stow --simulate --restow --no-folding --target="$TARGET_HOME" $_valid_pkgs
        )
        log_ok "GNU Stow dry-run simulation completed without conflicts:$_valid_pkgs"
        return 0
    fi

    (
        cd "$REPO_DIR"
        # shellcheck disable=SC2086
        stow --restow --no-folding --target="$TARGET_HOME" $_valid_pkgs
    )
    log_ok "GNU Stow applied packages:$_valid_pkgs"

    # Verify symlinks
    for _check in \
        ".zshenv" \
        ".zprofile" \
        ".zshrc" \
        ".config/starship.toml" \
        ".config/tmux/tmux.conf" \
        ".config/nvim/init.lua" \
        ".config/lazygit/config.yml" \
        ".config/lazydocker/config.yml" \
        ".config/yazi/yazi.toml" \
        ".config/btop/btop.conf" \
        ".config/fastfetch/config.jsonc" \
        ".gitconfig" \
        ".local/bin/devdoctor"; do
        if [ ! -L "$TARGET_HOME/$_check" ]; then
            log_err "Verification failed: $TARGET_HOME/$_check is not a symbolic link!"
            exit 1
        fi
    done
    log_ok "Verified all core symlinks in $TARGET_HOME"
}

# ------------------------------------------------------------------------------
# 5. System Configuration (/etc/wsl.conf)
# ------------------------------------------------------------------------------
verify_wsl_system_conf() {
    log_step "5. Verifying /etc/wsl.conf System Configuration"
    if [ ! -f "$REPO_DIR/wsl-system/wsl.conf" ]; then
        return 0
    fi
    if [ -f /etc/wsl.conf ] && cmp -s "$REPO_DIR/wsl-system/wsl.conf" /etc/wsl.conf; then
        log_ok "/etc/wsl.conf matches versioned wsl-system/wsl.conf"
    else
        if [ "$DRY_RUN" -eq 1 ]; then
            log_dry "Would back up /etc/wsl.conf and install $REPO_DIR/wsl-system/wsl.conf"
        else
            if [ -f /etc/wsl.conf ]; then
                run_priv cp -a /etc/wsl.conf "/etc/wsl.conf.bak.$(date '+%Y%m%d_%H%M%S')"
            fi
            run_priv cp -a "$REPO_DIR/wsl-system/wsl.conf" /etc/wsl.conf
            log_ok "Updated /etc/wsl.conf (backup created)"
        fi
    fi
}

# ------------------------------------------------------------------------------
# 6. Permissions & Custom Scripts in ~/.local/bin
# ------------------------------------------------------------------------------
ensure_permissions() {
    log_step "6. Verifying Executable Permissions in ~/.local/bin"
    for _script in devdoctor workbench wb alpine-maint nvidia-smi docker ollama agy rasp32-check rasp32-sync rasp32-info; do
        _spath="$REPO_DIR/local-bin/.local/bin/$_script"
        if [ -f "$_spath" ]; then
            if [ ! -x "$_spath" ]; then
                if [ "$DRY_RUN" -eq 1 ]; then
                    log_dry "chmod 755 $_spath"
                else
                    chmod 755 "$_spath"
                    log_info "Set executable mode 755 on $_script"
                fi
            fi
        fi
    done
    log_ok "All custom scripts in ~/.local/bin have executable permissions (755)"
}

# ------------------------------------------------------------------------------
# 7. Zsh Syntax Validation & Bytecode Compilation (zcompile)
# ------------------------------------------------------------------------------
compile_zsh_configs() {
    log_step "7. Validating & Compiling Zsh Startup Files (zcompile)"
    if ! command -v zsh >/dev/null 2>&1; then
        log_warn "zsh binary not found; skipping zcompile."
        return 0
    fi

    for _zfile in "$TARGET_HOME/.zshenv" "$TARGET_HOME/.zprofile" "$TARGET_HOME/.zshrc"; do
        if [ ! -f "$_zfile" ]; then
            log_warn "Missing Zsh file: $_zfile"
            continue
        fi
        if ! zsh -n "$_zfile"; then
            log_err "Zsh syntax error in $_zfile! Aborting zcompile."
            exit 1
        fi
        if [ "$DRY_RUN" -eq 1 ]; then
            log_dry "zsh -c 'zcompile \"$_zfile\"'"
        else
            if [ ! -f "${_zfile}.zwc" ] || [ -n "$(find "$_zfile" -newer "${_zfile}.zwc" 2>/dev/null)" ]; then
                zsh -c "zcompile '$_zfile'"
                log_info "Compiled ${_zfile}.zwc"
            else
                log_ok "Up-to-date: ${_zfile}.zwc"
            fi
        fi
    done
    log_ok "Zsh syntax and bytecode caches validated"
}

# ------------------------------------------------------------------------------
# 8. OpenRC Service Governance (WSL 2 Compatible)
# ------------------------------------------------------------------------------
configure_openrc() {
    log_step "8. Validating OpenRC Boot Runlevels & Active Daemons"
    if [ "$SKIP_OPENRC" -eq 1 ]; then
        log_info "Skipping OpenRC checks (--skip-openrc)."
        return 0
    fi

    # 8.1 Ensure Redis is disabled in boot/default runlevels (without killing a running instance)
    for _rl in boot default; do
        if [ -e "/etc/runlevels/$_rl/redis" ]; then
            log_info "Removing redis from OpenRC '$_rl' runlevel..."
            run_priv rc-update del redis "$_rl"
        fi
    done
    log_ok "Redis is disabled in boot/default runlevels"

    # 8.2 Ensure syslog is enabled in boot runlevel
    if [ -x /etc/init.d/syslog ] && [ ! -e /etc/runlevels/boot/syslog ]; then
        log_info "Enabling syslog in 'boot' runlevel..."
        run_priv rc-update add syslog boot
    fi
    log_ok "syslog enabled in 'boot' runlevel"

    # 8.3 Ensure crond is enabled in default runlevel
    if [ -x /etc/init.d/crond ] && [ ! -e /etc/runlevels/default/crond ]; then
        log_info "Enabling crond in 'default' runlevel..."
        run_priv rc-update add crond default
    fi
    log_ok "crond enabled in 'default' runlevel"

    # 8.4 Ensure /run/openrc/softlevel and start syslog + crond with --nodeps if not running
    if [ ! -f /run/openrc/softlevel ]; then
        run_priv mkdir -p /run/openrc
        run_priv touch /run/openrc/softlevel
    fi

    if ! pgrep -x syslogd >/dev/null 2>&1; then
        log_info "Starting syslog daemon (--nodeps for WSL 2)..."
        run_priv rc-service --nodeps syslog start
    else
        log_ok "syslogd is active (PID $(pgrep -x syslogd | tr '\n' ' '))"
    fi

    if ! pgrep -x crond >/dev/null 2>&1; then
        log_info "Starting crond daemon (--nodeps for WSL 2)..."
        run_priv rc-service --nodeps crond start
    else
        log_ok "crond is active (PID $(pgrep -x crond | tr '\n' ' '))"
    fi
}

# ------------------------------------------------------------------------------
# 9. Run Devdoctor Diagnostic Suite
# ------------------------------------------------------------------------------
run_devdoctor() {
    log_step "9. Running Devdoctor Health Verification"
    if [ "$SKIP_DOCTOR" -eq 1 ]; then
        log_info "Skipping devdoctor (--skip-doctor)."
        return 0
    fi
    if [ "$DRY_RUN" -eq 1 ]; then
        if [ -x "$TARGET_HOME/.local/bin/devdoctor" ]; then
            log_info "Running read-only health diagnostics (devdoctor)..."
            "$TARGET_HOME/.local/bin/devdoctor"
        elif [ -x "$REPO_DIR/local-bin/.local/bin/devdoctor" ]; then
            log_info "Running read-only health diagnostics from repo (devdoctor)..."
            "$REPO_DIR/local-bin/.local/bin/devdoctor"
        else
            log_dry "devdoctor not available to run read-only diagnostics."
        fi
        return 0
    fi
    if [ -x "$TARGET_HOME/.local/bin/devdoctor" ]; then
        "$TARGET_HOME/.local/bin/devdoctor"
    else
        log_err "$TARGET_HOME/.local/bin/devdoctor not found or not executable."
        exit 1
    fi
}

main() {
    preflight_checks
    install_apk_packages
    resolve_stow_conflicts
    apply_stow_packages
    verify_wsl_system_conf
    ensure_permissions
    compile_zsh_configs
    configure_openrc
    run_devdoctor
    log_step "Bootstrap Completed Successfully"
}

main
