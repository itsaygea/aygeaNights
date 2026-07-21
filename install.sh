#!/usr/bin/env bash
# ╭──────────────────────────────────────────────────────────────────╮
# │  install.sh  ·  AygeaNight terminal theme installer              │
# │  curl -fsSL <url>/install.sh | bash                           │
# ╰──────────────────────────────────────────────────────────────────╯
set -euo pipefail

VERSION="1.0.0"
REPO="itsaygea/aygeaNights"
REPO_URL="https://github.com/${REPO}"
MARKER_BEGIN="# >>> aygea-night >>>"
MARKER_END="# <<< aygea-night <<<"

# ── Globals ──────────────────────────────────────────────────────
OS=""
SCRIPT_DIR=""
USE_SUDO=0
UNINSTALL=0
STEP_NUM=0
LOCAL_BIN="$HOME/.local/bin"
TMPDIR_AYGEA=""

# ── Menu state ───────────────────────────────────────────────────
MENU_COUNT=0
MENU_CURSOR=0
MENU_LINES=0
declare -a M_LABEL=() M_DESC=() M_STATUS=() M_SELECTED=()
declare -a M_SELECTABLE=() M_NEEDS_SUDO=() M_FUNC=()
_MENU_ACTIVE=0

# ── Cleanup temp dir + restore terminal on exit ─────────────────
cleanup() {
    if [[ -n "${TMPDIR_AYGEA:-}" && -d "${TMPDIR_AYGEA:-}" ]]; then
        rm -rf "${TMPDIR_AYGEA}" || true
    fi
    if [[ ${_MENU_ACTIVE:-0} -eq 1 ]]; then
        stty echo 2>/dev/null || true
        tput cnorm 2>/dev/null || true
    fi
}
trap cleanup EXIT

# ── Color palette (truecolor) ──────────────────────────────────
_tput() { [[ -t 1 ]] && printf '\033[38;2;%s;%s;%sm' "$1" "$2" "$3" || true; }
C_RESET=""
[[ -t 1 ]] && C_RESET=$(printf '\033[0m') || true

C_BLUE=$(_tput 175 203 255)    # Baby Blue #AFCBFF
C_SAPPHIRE=$(_tput 106 143 211) # Sapphire #6A8FD3
C_PINK=$(_tput 248 200 220)    # Soft Pink #F8C8DC
C_PINK_DK=$(_tput 216 140 168) # Pink Dark #D88CA8
C_SILVER=$(_tput 230 238 248)  # Silver #E6EEF8
C_DIM=$(_tput 59  74  117)    # Navy dim #3B4A75
C_NAVY=$(_tput 42  58  94)     # Navy mid #2A3A5E
C_BOLD=""
[[ -t 1 ]] && C_BOLD=$(printf '\033[1m') || true

# Cursor-line highlight (baby blue bg + dark text)
HL_BG=$(printf '\033[48;2;175;203;255m')
HL_FG=$(printf '\033[38;2;30;30;50m')

# ── Output functions ──────────────────────────────────────────────
info()    { printf '%s  -> %s%s\n' "$C_BLUE" "$*" "$C_RESET"; }
success() { printf '%s  ok %s%s\n' "$C_SILVER" "$*" "$C_RESET"; }
warn()    { printf '%s  !! %s%s\n' "$C_PINK_DK" "$*" "$C_RESET"; }
error()   { printf '%s  XX %s%s\n' "$C_BOLD$C_PINK_DK" "$*" "$C_RESET"; }

step() {
    STEP_NUM=$((STEP_NUM + 1))
    printf '\n%s%s[%s]%s %s%s%s\n' "$C_BOLD" "$C_SAPPHIRE" "$STEP_NUM" "$C_RESET" "$C_BOLD" "$*" "$C_RESET"
    printf '%s---%s------------------------------------------\n' "$C_NAVY" "$C_RESET"
}

banner() {
    printf '\n'
    printf '%s%sAygea%s%sNight%s  %s🦊%s\n' \
        "$C_BOLD" "$C_BLUE" "$C_PINK" "$C_BOLD" "$C_RESET" "$C_DIM" "$C_RESET"
    printf '%sTokyo Night base  ·  Aygea brand accents  ·  v%s%s\n' "$C_DIM" "$VERSION" "$C_RESET"
    printf '\n'
}

# ── Ask yes/no (reads from /dev/tty for curl support) ──────────
ask_yn() {
    local prompt="$1" default="${2:-n}"
    local choices
    [[ "$default" == "y" ]] && choices="[Y/n]" || choices="[y/N]"
    while true; do
        printf '%s%s %s? %s ' "$C_BOLD" "$C_SAPPHIRE" "$prompt" "$choices"
        printf '%s' "$C_RESET"
        read -r answer < /dev/tty || answer=""
        answer="${answer,,}"
        [[ -z "$answer" ]] && answer="$default"
        case "$answer" in
            y|yes) return 0 ;;
            n|no)  return 1 ;;
        esac
    done
}

# ── Run with or without sudo ────────────────────────────────────
maybe_sudo() {
    if [[ $USE_SUDO -eq 1 ]]; then
        sudo "$@"
    else
        "$@"
    fi
}

# ── Usage ──────────────────────────────────────────────────────────
usage() {
    cat <<EOF
${C_BOLD}AygeaNight Terminal Theme Installer${C_RESET} v$VERSION

${C_SAPPHIRE}Usage:${C_RESET}
  install.sh [flags]

${C_SAPPHIRE}Flags:${C_RESET}
  --sudo            Use sudo for system-wide installs (non-interactive)
  --motd            Install just the login MOTD (Linux, prompts for sudo)
  --uninstall       Remove AygeaNight (restore backups)
  -h, --help        Show this help

${C_SAPPHIRE}Examples:${C_RESET}
  ./install.sh                    # interactive menu
  ./install.sh --sudo             # use sudo without prompting
  ./install.sh --motd             # add login MOTD only
  curl -fsSL <url>/install.sh | bash   # remote install
EOF
    exit 0
}

# ── OS detection ──────────────────────────────────────────────────
detect_os() {
    case "$OSTYPE" in
        darwin*) OS="macos" ;;
        *)
            if [[ -f /etc/os-release ]]; then
                local id
                id=$(grep '^ID=' /etc/os-release | head -1 | cut -d= -f2)
                case "$id" in
                    ubuntu|pop|linuxmint|debian) OS="ubuntu" ;;
                    arch|manjaro|endeavouros|garuda|cachyos) OS="arch" ;;
                    *)
                        local id_like
                        id_like=$(grep '^ID_LIKE=' /etc/os-release | head -1 | cut -d= -f2 | tr -d '"')
                        case "$id_like" in
                            *ubuntu*|*debian*) OS="ubuntu" ;;
                            *arch*) OS="arch" ;;
                            *) error "Unsupported OS: $id"; exit 1 ;;
                        esac
                        ;;
                esac
            else
                error "Cannot detect OS"
                exit 1
            fi
            ;;
    esac
}

# ── Resolve source directory (local vs curl pipe) ───────────────
resolve_source() {
    if [[ -n "${BASH_SOURCE[0]:-}" && -f "${BASH_SOURCE[0]}" ]]; then
        SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        if [[ -f "$SCRIPT_DIR/starship.toml" && -f "$SCRIPT_DIR/tmux.conf" ]]; then
            info "Running from local directory"
            return 0
        fi
    fi

    info "Downloading aygeaNights from GitHub..."
    TMPDIR_AYGEA=$(mktemp -d)
    local archive_url="${REPO_URL}/archive/refs/heads/main.tar.gz"

    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$archive_url" | tar xz -C "$TMPDIR_AYGEA" --strip-components=1
    elif command -v wget >/dev/null 2>&1; then
        wget -qO- "$archive_url" | tar xz -C "$TMPDIR_AYGEA" --strip-components=1
    else
        error "Need curl or wget to download"
        exit 1
    fi

    SCRIPT_DIR="$TMPDIR_AYGEA"
    success "Downloaded to temp directory"
}

# ── Helper: detect shell (zsh or bash) ──────────────────────────
# macOS defaults to zsh; on Linux honor $SHELL so a zsh install on
# Arch/Cachyos writes ~/.zshrc (not ~/.bashrc).
detect_shell() {
    if [[ "$OS" == "macos" ]]; then
        printf 'zsh'
        return
    fi
    local sh
    sh=$(basename "${SHELL:-bash}")
    case "$sh" in
        zsh) printf 'zsh' ;;
        *)   printf 'bash' ;;
    esac
}

# ── Helper: rc file path ─────────────────────────────────────────
rc_file() {
    case "$(detect_shell)" in
        zsh)  printf '%s' "$HOME/.zshrc" ;;
        *)    printf '%s' "$HOME/.bashrc" ;;
    esac
}

# ── Helper: ensure directory and PATH ────────────────────────────
ensure_local_bin() {
    mkdir -p "$LOCAL_BIN"
    local rc
    rc=$(rc_file)
    if ! grep -qF 'export PATH="$HOME/.local/bin:$PATH"' "$rc" 2>/dev/null; then
        ensure_rc_line "$rc" 'export PATH="$HOME/.local/bin:$PATH"' top "aygea path"
    fi
    export PATH="$LOCAL_BIN:$PATH"
}

# ── Helper: backup a file ────────────────────────────────────────
backup_file() {
    local src="$1"
    if [[ -f "$src" ]]; then
        local bak="${src}.aygea.bak.$(date +%Y%m%d%H%M%S)"
        cp "$src" "$bak"
        info "Backed up: $bak"
    fi
}

# ── Helper: idempotent rc line insertion ─────────────────────────
# Strips any existing marker block(s) with the same comment first, so
# re-running the installer (or upgrading the line content, e.g.
# aygeafetch -> aynight) never stacks duplicate blocks.
ensure_rc_line() {
    local file="$1" line="$2" pos="$3" comment="${4:-}"
    [[ -f "$file" ]] || touch "$file"

    # Remove any prior block(s) for this exact comment (dedup across runs)
    if [[ -n "$comment" ]]; then
        local tmp; tmp=$(mktemp)
        local in_old=0
        local needle="$MARKER_BEGIN  ($comment)"
        while IFS= read -r rl || [[ -n "$rl" ]]; do
            if [[ "$rl" == *"$needle"* ]]; then in_old=1; continue; fi
            if [[ "$in_old" -eq 1 && "$rl" == *"$MARKER_END"* ]]; then in_old=0; continue; fi
            [[ "$in_old" -eq 0 ]] && printf '%s\n' "$rl"
        done < "$file" > "$tmp"
        # drop trailing blank lines, keep file tidy
        awk 'NF{p=1} p' "$tmp" > "${tmp}.2" && mv "${tmp}.2" "$file"
        rm -f "$tmp"
    fi

    # Already present (exact line)? Nothing to do.
    if grep -qF "$line" "$file" 2>/dev/null; then
        return 0
    fi

    local block="$MARKER_BEGIN"
    [[ -n "$comment" ]] && block="$block  ($comment)"
    block="$block"$'\n'"$line"$'\n'"$MARKER_END"

    if [[ "$pos" == "top" ]]; then
        local tmp2; tmp2=$(mktemp)
        printf '%s\n' "$block" > "$tmp2"
        cat "$file" >> "$tmp2"
        mv "$tmp2" "$file"
    else
        printf '\n%s\n' "$block" >> "$file"
    fi
}

# ── Helper: remove marked blocks from rc file ────────────────────
remove_rc_blocks() {
    local file="$1"
    [[ -f "$file" ]] || return 0

    local tmp
    tmp=$(mktemp)
    local in_block=0
    while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ "$line" == *"$MARKER_BEGIN"* ]]; then
            in_block=1
            continue
        fi
        if [[ "$line" == *"$MARKER_END"* ]]; then
            in_block=0
            continue
        fi
        if [[ $in_block -eq 0 ]]; then
            printf '%s\n' "$line"
        fi
    done < "$file" > "$tmp"

    local tmp2
    tmp2=$(mktemp)
    awk 'NF {p=1} p' "$tmp" > "$tmp2"
    mv "$tmp2" "$file"
    rm -f "$tmp"
}

# ══════════════════════════════════════════════════════════════════
# ── Detection functions ──────────────────────────────────────────
# ══════════════════════════════════════════════════════════════════

detect_fonts_installed() {
    if [[ "$OS" == "macos" ]]; then
        local f
        for f in "$HOME/Library/Fonts/JetBrainsMonoNerdFont"*.ttf; do
            [[ -f "$f" ]] && return 0
        done
        return 1
    else
        [[ -d "$HOME/.local/share/fonts/aygea-night" ]] || return 1
        local count
        count=$(find "$HOME/.local/share/fonts/aygea-night" -name '*.ttf' 2>/dev/null | wc -l) || count=0
        [[ "$count" -gt 0 ]]
    fi
}

detect_tmux_installed() {
    command -v tmux &>/dev/null || return 1
    [[ -f "$HOME/.tmux.conf" ]] || return 1
    grep -q "AygeaNight" "$HOME/.tmux.conf" 2>/dev/null
}

detect_starship_installed() {
    command -v starship &>/dev/null || return 1
    [[ -f "$HOME/.config/starship.toml" ]] || return 1
    grep -q "AygeaNight" "$HOME/.config/starship.toml" 2>/dev/null
}

detect_fetch_installed() {
    [[ -x "$LOCAL_BIN/aynight" ]]
}

detect_locale_installed() {
    locale -a 2>/dev/null | grep -qi 'en_US\.utf'
}

detect_motd_installed() {
    [[ -x /etc/update-motd.d/99-aygea ]] && return 0
    [[ -f /etc/profile.d/aygea-motd.sh ]]
}

# ══════════════════════════════════════════════════════════════════
# ── Install functions ────────────────────────────────────────────
# ══════════════════════════════════════════════════════════════════

install_fonts() {
    local src="$SCRIPT_DIR/fonts/JetBrainsMono"
    local tmp_dl=""

    # ── No bundled fonts (curl-pipe install)? Download from Nerd Fonts. ──
    if [[ ! -d "$src" ]] || [[ -z "$(find "$src" -name '*.ttf' 2>/dev/null)" ]]; then
        info "Bundled fonts missing — downloading JetBrainsMono Nerd Font..."
        local nf_ver="v3.3.0"
        local nf_url="https://github.com/ryanoasis/nerd-fonts/releases/download/${nf_ver}/JetBrainsMono.tar.xz"
        if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
            warn "Need curl or wget to download fonts (or clone the repo for bundled fonts)"
            return 1
        fi
        tmp_dl=$(mktemp -d)
        if command -v curl >/dev/null 2>&1; then
            curl -fsSL "$nf_url" -o "$tmp_dl/JetBrainsMono.tar.xz" || { warn "Font download failed"; rm -rf "$tmp_dl"; return 1; }
        else
            wget -qO "$tmp_dl/JetBrainsMono.tar.xz" "$nf_url" || { warn "Font download failed"; rm -rf "$tmp_dl"; return 1; }
        fi
        tar -xf "$tmp_dl/JetBrainsMono.tar.xz" -C "$tmp_dl" 2>/dev/null || { warn "Font extract failed"; rm -rf "$tmp_dl"; return 1; }
        src="$tmp_dl"
        success "Downloaded Nerd Font v${nf_ver#v}"
    fi

    local count
    count=$(find "$src" -name '*.ttf' 2>/dev/null | wc -l | tr -d ' ')
    if [[ "$count" -eq 0 ]]; then
        warn "No .ttf font files available"
        [[ -n "$tmp_dl" ]] && rm -rf "$tmp_dl"
        return 1
    fi

    if [[ "$OS" == "macos" ]]; then
        local dest="$HOME/Library/Fonts"
        mkdir -p "$dest"
        cp "$src"/*.ttf "$dest/"
        success "Installed $count font files to $dest"
    else
        local dest="$HOME/.local/share/fonts/aygea-night"
        mkdir -p "$dest"
        cp "$src"/*.ttf "$dest/"
        if command -v fc-cache >/dev/null 2>&1; then
            fc-cache -f "$dest" 2>/dev/null || true
        fi
        success "Installed $count font files to $dest"
        info "Set 'JetBrainsMono Nerd Font' in your terminal emulator settings"
    fi
    [[ -n "$tmp_dl" ]] && rm -rf "$tmp_dl"
}

install_tmux() {
    if ! command -v tmux >/dev/null 2>&1; then
        info "tmux not found, installing..."
        case "$OS" in
            macos)
                if command -v brew >/dev/null 2>&1; then
                    brew install tmux
                else
                    warn "Homebrew not found. Install tmux manually."
                    return 1
                fi
                ;;
            ubuntu)
                maybe_sudo apt-get update -qq && maybe_sudo apt-get install -y -qq tmux
                ;;
            arch)
                maybe_sudo pacman -Sy --noconfirm tmux
                ;;
        esac
    else
        info "tmux already installed"
    fi

    backup_file "$HOME/.tmux.conf"
    cp "$SCRIPT_DIR/tmux.conf" "$HOME/.tmux.conf"
    success "Deployed ~/.tmux.conf"

    if tmux ls >/dev/null 2>&1; then
        info "Run 'tmux kill-server' then start a new session to apply"
    fi
}

install_locale() {
    [[ "$OS" == "macos" ]] && return 0

    info "Setting up en_US.UTF-8 locale..."
    case "$OS" in
        ubuntu)
            maybe_sudo apt-get install -y -qq locales 2>/dev/null || true
            maybe_sudo locale-gen en_US.UTF-8 2>/dev/null || true
            maybe_sudo update-locale LANG=en_US.UTF-8 2>/dev/null || true
            ;;
        arch)
            if [[ -f /etc/locale.gen ]]; then
                maybe_sudo sed -i 's/^#en_US\.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
                maybe_sudo locale-gen
                maybe_sudo localectl set-locale LANG=en_US.UTF-8 2>/dev/null || true
            fi
            ;;
    esac
    success "Locale configured (log out and back in to fully apply)"
}

# ── System MOTD: show aynight at every login (Linux, needs sudo) ──
# Backs up /etc/motd + any prior aynight/aygea motd file before writing.
# Prompted at install time; rerun via `install.sh --motd` or `./install.sh --motd`.
install_motd() {
    [[ "$OS" == "macos" ]] && { info "MOTD install skipped (macOS)"; return 0; }

    # Already installed? Nothing to do.
    if detect_motd_installed; then
        info "Login MOTD already installed"
        return 0
    fi

    local stamp; stamp=$(date +%Y%m%d%H%M%S)
    local motd_dir="/etc/update-motd.d"

    # Back up existing motd artifacts (best effort)
    if [[ -f /etc/motd ]]; then
        maybe_sudo cp /etc/motd "/etc/motd.ayn.bak.$stamp" 2>/dev/null || true
    fi
    if [[ -f "$motd_dir/99-aygea" ]]; then
        maybe_sudo cp "$motd_dir/99-aygea" "$motd_dir/99-aygea.ayn.bak.$stamp" 2>/dev/null || true
    fi

    if [[ ! -d "$motd_dir" ]]; then
        # Arch/CachyOS: no update-motd.d by default; wire via /etc/profile.d.
        # Back up /etc/motd + any motd.d snippets (Cockpit, etc.) first.
        if [[ -f /etc/motd ]]; then
            maybe_sudo cp /etc/motd "/etc/motd.ayn.bak.$stamp" 2>/dev/null || true
        fi
        if [[ -d /etc/motd.d ]]; then
            maybe_sudo mkdir -p "/etc/motd.d.ayn.bak.$stamp"
            maybe_sudo cp -a /etc/motd.d/. "/etc/motd.d.ayn.bak.$stamp/" 2>/dev/null || true
        fi

        # Mode: replace hides other motd.d snippets (Cockpit line, etc.),
        # merge leaves them alone.
        local mode="replace"
        if [[ "${AYN_MOTD_MODE:-}" == "merge" ]]; then mode="merge"
        elif [[ "${AYN_MOTD_MODE:-}" != "replace" ]]; then
            printf '%s  %sHide other motd snippets (e.g. Cockpit line)?%s\n' "$C_BOLD" "$C_SAPPHIRE" "$C_RESET"
            printf '    1) Replace — only aynight fox + update notices\n'
            printf '    2) Merge   — keep existing motd snippets, add aynight\n'
            local m
            while true; do
                printf '%s  Choice [1]%s ' "$C_DIM" "$C_RESET"
                read -r m < /dev/tty || m=""
                case "${m:-1}" in 1) mode="replace"; break ;; 2) mode="merge"; break ;; esac
            done
        fi

        if [[ "$mode" == "replace" ]]; then
            # Move motd.d + issue.d snippets aside (reversible; tracked for restore)
            maybe_sudo mkdir -p /etc/motd.d
            local moved=0
            shopt -s nullglob
            for s in /etc/motd.d/* /etc/issue.d/*; do
                [[ -e "$s" ]] || continue
                maybe_sudo mv "$s" "$s.ayn.hidden" 2>/dev/null && moved=$((moved+1)) || true
            done
            shopt -u nullglob
            (( moved > 0 )) && success "Hid $moved motd.d/issue.d snippet(s) (replace mode)"
        fi

        local pd="/etc/profile.d/aynight-motd.sh"
        [[ -f "$pd" ]] && maybe_sudo cp "$pd" "$pd.ayn.bak.$stamp" 2>/dev/null || true
        maybe_sudo tee "$pd" >/dev/null <<'EOF'
# AygeaNight login fetch + notices — show on first interactive login shell
if [[ -n "$SSH_CONNECTION" || -z "$DISPLAY" ]] && [[ -t 1 ]] && [[ -z "$AYNIGHT_MOTD_SHOWN" ]]; then
    command -v aynight >/dev/null 2>&1 && aynight --fox
    _ayn_notices() {
        local RESET=$'\033[0m' PINK=$'\033[38;2;216;140;168m' BLUE=$'\033[38;2;175;203;255m'
        if command -v pacman >/dev/null 2>&1; then
            local n; n=$(pacman -Qu 2>/dev/null | grep -c .)
            (( n > 0 )) && printf '\n%s  ↑ %d pacman updates available%s (pacman -Syu)\n' "$PINK" "$n" "$RESET"
        fi
        [[ -f /var/run/reboot-required ]] && printf '%s  ⟳ reboot required%s\n' "$PINK" "$RESET"
        printf '%s\n' "$RESET"
    }
    _ayn_notices 2>/dev/null
    unset -f _ayn_notices
    export AYNIGHT_MOTD_SHOWN=1
fi
EOF
        success "Login fetch installed to $pd ($mode mode)"
        info "Backups in /etc/motd.d.ayn.bak.* — --uninstall restores everything"
        return 0
    fi
    # Mode prompt: replace Ubuntu motd, or merge beneath it?
    local mode="replace"
    if [[ "${AYN_MOTD_MODE:-}" == "merge" ]]; then
        mode="merge"
    elif [[ "${AYN_MOTD_MODE:-}" != "replace" ]]; then
        printf '%s  %sReplace the Ubuntu MOTD, or merge beneath it?%s\n' "$C_BOLD" "$C_SAPPHIRE" "$C_RESET"
        printf '    1) Replace — only aynight fox + update/firmware notices\n'
        printf '    2) Merge   — keep Ubuntu info, add aynight below it\n'
        local m
        while true; do
            printf '%s  Choice [1]%s ' "$C_DIM" "$C_RESET"
            read -r m < /dev/tty || m=""
            case "${m:-1}" in
                1) mode="replace"; break ;;
                2) mode="merge"; break ;;
                *) ;;
            esac
        done
    fi

    maybe_sudo tee "$motd_dir/99-aygea" >/dev/null <<'EOF'
#!/usr/bin/env bash
# AygeaNight MOTD — system fetch + compact update/firmware notices.
# Shown at every login (SSH + console). Disable: chmod -x this file.
RESET=$'\033[0m'; DIM=$'\033[38;2;105;122;150m'
PINK=$'\033[38;2;216;140;168m'; BLUE=$'\033[38;2;175;203;255m'
SILVER=$'\033[38;2;192;209;230m'

# 1) the fox fetch
command -v aynight >/dev/null 2>&1 && aynight --fox

# 2) compact update / security / firmware notices (best effort, non-fatal)
{
    printf '\n'
    # apt updates
    if command -v apt >/dev/null 2>&1; then
        n=$(apt list --upgradable 2>/dev/null | grep -c '/')
        (( n > 0 )) && printf '%s  ↑ %d apt updates available%s (apt upgrade)\n' "$PINK" "$n" "$RESET"
        # ESM/security (Ubuntu Pro) — needs ubuntu-security-status or pro
        if command -v pro >/dev/null 2>&1; then
            esm=$(pro security-status 2>/dev/null | awk '/ESM Apps/{print $1; exit}')
            [[ -n "$esm" ]] && printf '%s  ⚠ %s additional security updates via ESM%s (Ubuntu Pro)\n' "$PINK" "$esm" "$RESET"
        fi
    elif command -v pacman >/dev/null 2>&1; then
        n=$(pacman -Qu 2>/dev/null | grep -c .)
        (( n > 0 )) && printf '%s  ↑ %d pacman updates available%s (pacman -Syu)\n' "$PINK" "$n" "$RESET"
    elif command -v dnf >/dev/null 2>&1; then
        n=$(dnf check-update 2>/dev/null | grep -cE '\.$')
        (( n > 0 )) && printf '%s  ↑ %d dnf updates available%s (dnf upgrade)\n' "$PINK" "$n" "$RESET"
    fi

    # firmware (fwupd)
    if command -v fwupdmgr >/dev/null 2>&1; then
        fwn=$(fwupdmgr get-updates 2>/dev/null | grep -cE '^[0-9]+\.' || true)
        (( ${fwn:-0} > 0 )) && printf '%s  ⚙ %s firmware update(s) available%s (fwupdmgr update)\n' "$BLUE" "$fwn" "$RESET"
    fi

    # reboot required (Linux)
    if [[ -f /var/run/reboot-required ]]; then
        printf '%s  ⟳ reboot required%s\n' "$PINK" "$RESET"
    fi
    printf '%s\n' "$RESET"
} 2>/dev/null
exit 0
EOF
    maybe_sudo chmod +x "$motd_dir/99-aygea"

    # In replace mode: disable the noisy Ubuntu motd scripts (reversible).
    # Backs them up by recording the list; --uninstall re-enables.
    if [[ "$mode" == "replace" ]]; then
        local disabled_list="/etc/update-motd.d/.ayn-disabled"
        local noisy="00-header 10-help-text 50-landscape-sysinfo 50-motd-news 85-fwupd 90-updates-available 91-contract-ua-esm-status 91-release-upgrade 92-unattended-upgrades 95-hwe-eol 97-overlayroot 98-fsck-at-reboot 98-reboot-required"
        : > /tmp/.ayn-dlist.$$
        for s in $noisy; do
            if [[ -x "$motd_dir/$s" ]]; then
                maybe_sudo chmod -x "$motd_dir/$s" 2>/dev/null && echo "$s" >> /tmp/.ayn-dlist.$$
            fi
        done
        maybe_sudo cp /tmp/.ayn-dlist.$$ "$disabled_list" 2>/dev/null || true
        rm -f /tmp/.ayn-dlist.$$
        success "MOTD installed (replace mode) — fox + update notices"
        info "Disabled Ubuntu motd scripts (list in $disabled_list). --uninstall re-enables them."
    else
        # merge mode: remove any prior disabled list so nothing stays off
        maybe_sudo rm -f /etc/update-motd.d/.ayn-disabled 2>/dev/null || true
        success "MOTD installed (merge mode) — aynight appended below Ubuntu info"
    fi
    info "Disable: chmod -x $motd_dir/99-aygea"
}

install_starship() {
    if ! command -v starship >/dev/null 2>&1; then
        info "Installing starship..."
        case "$OS" in
            macos)
                if command -v brew >/dev/null 2>&1; then
                    brew install starship
                else
                    ensure_local_bin
                    curl -sS https://starship.rs/install.sh | sh -s -- -y -b "$LOCAL_BIN"
                fi
                ;;
            ubuntu|arch)
                ensure_local_bin
                curl -sS https://starship.rs/install.sh | sh -s -- -y -b "$LOCAL_BIN"
                ;;
        esac
    else
        info "starship already installed"
    fi

    mkdir -p "$HOME/.config"
    backup_file "$HOME/.config/starship.toml"
    cp "$SCRIPT_DIR/starship.toml" "$HOME/.config/starship.toml"
    success "Deployed ~/.config/starship.toml"

    local rc sh
    rc=$(rc_file)
    sh=$(detect_shell)

    if [[ "$OS" == "macos" ]]; then
        ensure_rc_line "$rc" 'eval "$(starship init zsh)"' bottom "aygea-night starship"
        success "Starship init added to $rc"
    else
        ensure_rc_line "$rc" 'export LANG=en_US.UTF-8' top "aygea locale"
        ensure_rc_line "$rc" 'export LC_ALL=en_US.UTF-8' top "aygea locale"
        ensure_rc_line "$rc" 'export TERM=xterm-256color' top "aygea terminal"
        ensure_rc_line "$rc" 'export COLORTERM=truecolor' top "aygea terminal"
        ensure_rc_line "$rc" "eval \"\$(starship init $sh)\"" bottom "aygea-night starship"
        success "Starship init + locale exports added to $rc ($sh)"
    fi
}

install_fetch() {
    ensure_local_bin
    local rc wrapper src core
    rc=$(rc_file)

    # ── OS wrapper selection ──
    case "$OS" in
        macos) wrapper="aynight-macos.sh" ;;
        ubuntu) wrapper="aynight-ubuntu.sh" ;;
        arch)   wrapper="aynight-arch.sh" ;;
    esac
    src="$SCRIPT_DIR/aynight/$wrapper"
    core="$SCRIPT_DIR/aynight/_aynight_core.sh"
    if [[ ! -f "$src" || ! -f "$core" ]]; then
        warn "Fetch files missing ($wrapper / _aynight_core.sh)"
        return 1
    fi

    # ── Build a single self-contained binary: wrapper + inlined core ──
    # Strip the wrapper's "source _aynight_core.sh" block, then append
    # the core body. Art is embedded in the core as fallback arrays, so no
    # external files are needed — one file in ~/.local/bin, nothing else.
    {
        # wrapper lines, skipping the _aygea_core source block
        awk '/^# ── Source the shared engine/{skip=1} skip{next} {print}' "$src"
        printf '\n# ════════════════════════════════════════════════════════════════\n'
        printf '# %s — inlined engine (art embedded, no external files) \n' "aynight core"
        printf '# ════════════════════════════════════════════════════════════════\n'
        # core body, skipping its shebang + header comment block
        awk 'f{print} /^export LANG=en_US.UTF-8$/{print; f=1}' "$core"
    } > "$LOCAL_BIN/aynight"
    chmod +x "$LOCAL_BIN/aynight"
    ensure_rc_line "$rc" 'aynight' bottom "aygea-night fetch"
    success "aynight installed (single binary) to $LOCAL_BIN/aynight"
}

install_iterm_colors() {
    [[ "$OS" != "macos" ]] && return 0

    local colorscheme="$SCRIPT_DIR/AygeaNight.itermcolors"
    if [[ ! -f "$colorscheme" ]]; then
        warn "iTerm2 color scheme not found"
        return 1
    fi

    if command -v open >/dev/null 2>&1; then
        info "Opening iTerm2 color scheme for import..."
        open "$colorscheme"
        success "In iTerm2: Preferences -> Profiles -> Colors -> Color Presets -> AygeaNight"
    else
        info "Double-click AygeaNight.itermcolors to import into iTerm2"
    fi
}

# ── Uninstall ────────────────────────────────────────────────────
do_uninstall() {
    banner
    info "Uninstalling AygeaNight..."

    local rc
    rc=$(rc_file)

    if [[ -f "$rc" ]]; then
        remove_rc_blocks "$rc"
        success "Cleaned $rc"
    fi

    if [[ -f "$HOME/.tmux.conf" ]]; then
        rm -f "$HOME/.tmux.conf"
        info "Removed ~/.tmux.conf"
    fi

    if [[ -f "$HOME/.config/starship.toml" ]]; then
        rm -f "$HOME/.config/starship.toml"
        info "Removed ~/.config/starship.toml"
    fi

    rm -f "$LOCAL_BIN/aynight"
    info "Removed $LOCAL_BIN/aynight"
    rm -f "$HOME/aynight.zsh" 2>/dev/null || true  # legacy path
    if [[ -d "$HOME/.local/share/aygea" ]]; then       # legacy layout
        rm -rf "$HOME/.local/share/aygea"
        info "Removed $HOME/.local/share/aygea"
    fi

    # Remove MOTD/login-fetch (best effort, may need sudo) + restore backups
    for f in /etc/update-motd.d/99-aygea /etc/profile.d/aynight-motd.sh /etc/profile.d/aygea-motd.sh; do
        if [[ -f "$f" ]]; then
            { rm -f "$f" 2>/dev/null || sudo rm -f "$f" 2>/dev/null; } || true
            info "Removed $f"
        fi
    done
    # Re-enable Ubuntu motd scripts we disabled in replace mode (full restore)
    local dlist="/etc/update-motd.d/.ayn-disabled"
    if [[ -f "$dlist" ]]; then
        local re=0
        while IFS= read -r s; do
            [[ -n "$s" ]] || continue
            { chmod +x "/etc/update-motd.d/$s" 2>/dev/null || sudo chmod +x "/etc/update-motd.d/$s" 2>/dev/null; } && re=$((re+1)) || true
        done < "$dlist"
        { rm -f "$dlist" 2>/dev/null || sudo rm -f "$dlist" 2>/dev/null; } || true
        (( re > 0 )) && success "Re-enabled $re Ubuntu motd script(s)"
    fi
    # Arch: restore hidden motd.d snippets (replace mode hid them as .ayn.hidden)
    shopt -s nullglob
    local hid=0
    for s in /etc/motd.d/*.ayn.hidden /etc/issue.d/*.ayn.hidden; do
        local orig="${s%.ayn.hidden}"
        { mv "$s" "$orig" 2>/dev/null || sudo mv "$s" "$orig" 2>/dev/null; } && hid=$((hid+1)) || true
    done
    shopt -u nullglob
    (( hid > 0 )) && success "Restored $hid Arch motd.d snippet(s)"
    # Arch: restore /etc/motd.d backup dir if it exists
    local motdd_bak; motdd_bak=$(ls -1d /etc/motd.d.ayn.bak.* 2>/dev/null | head -1)
    if [[ -n "$motdd_bak" ]]; then
        maybe_sudo mkdir -p /etc/motd.d 2>/dev/null || sudo mkdir -p /etc/motd.d 2>/dev/null || true
        { cp -a "$motdd_bak/." /etc/motd.d/ 2>/dev/null || sudo cp -a "$motdd_bak/." /etc/motd.d/ 2>/dev/null; } || true
        success "Restored /etc/motd.d from $motdd_bak"
    fi
    # Restore newest /etc/motd backup if one exists
    local motd_bak
    motd_bak=$(ls -1t /etc/motd.ayn.bak.* 2>/dev/null | head -1)
    if [[ -n "$motd_bak" ]]; then
        { cp "$motd_bak" /etc/motd 2>/dev/null || sudo cp "$motd_bak" /etc/motd 2>/dev/null; } && \
            success "Restored /etc/motd from $motd_bak" || true
    fi

    if [[ "$OS" == "macos" ]]; then
        local dest="$HOME/Library/Fonts"
        local removed=0
        for f in "$dest"/JetBrainsMonoNerdFont*.ttf "$dest"/JetBrainsMonoNerdFontMono*.ttf \
                 "$dest"/JetBrainsMonoNerdFontPropo*.ttf "$dest"/JetBrainsMonoNLNerdFont*.ttf; do
            [[ -f "$f" ]] && { rm -f "$f"; removed=$((removed + 1)); }
        done
        [[ $removed -gt 0 ]] && info "Removed $removed font files"
    else
        local dest="$HOME/.local/share/fonts/aygea-night"
        if [[ -d "$dest" ]]; then
            rm -rf "$dest"
            command -v fc-cache >/dev/null 2>&1 && fc-cache -f 2>/dev/null || true
            info "Removed $dest"
        fi
    fi

    local bak
    for bak in "$HOME/.tmux.conf.aygea.bak."* "$HOME/.config/starship.toml.aygea.bak."*; do
        if [[ -f "$bak" ]]; then
            local orig="${bak%.aygea.bak.*}"
            mv "$bak" "$orig"
            success "Restored backup: $orig"
        fi
    done

    printf '\n'
    success "AygeaNight uninstalled. Restart your terminal."
}

# ══════════════════════════════════════════════════════════════════
# ── Interactive Menu ──────────────────────────────────────────────
# ══════════════════════════════════════════════════════════════════

add_item() {
    local label="$1" desc="$2" status="$3" selectable="${4:-1}" needs_sudo="${5:-0}" func="${6:-}"
    M_LABEL+=( "$label" )
    M_DESC+=( "$desc" )
    M_STATUS+=( "$status" )
    M_SELECTABLE+=( "$selectable" )
    M_NEEDS_SUDO+=( "$needs_sudo" )
    M_FUNC+=( "$func" )
    if [[ "$selectable" -eq 1 ]]; then
        M_SELECTED+=( 1 )
    else
        M_SELECTED+=( 0 )
    fi
    MENU_COUNT=$((MENU_COUNT + 1))
}

build_menu() {
    # 1. Nerd Font
    if detect_fonts_installed; then
        add_item "Nerd Font" "JetBrainsMono Nerd Font" "already installed" 1 0 "install_fonts"
    else
        add_item "Nerd Font" "JetBrainsMono Nerd Font" "not installed" 1 0 "install_fonts"
    fi

    # 2. iTerm2 colors (macOS only, non-selectable on Linux)
    if [[ "$OS" == "macos" ]]; then
        add_item "iTerm2 colors" "AygeaNight.itermcolors" "macOS" 1 0 "install_iterm_colors"
    else
        add_item "iTerm2 colors" "AygeaNight.itermcolors" "macOS only — skipped" 0 0 ""
    fi

    # 3. tmux config
    if detect_tmux_installed; then
        add_item "tmux config" "~/.tmux.conf" "already installed" 1 0 "install_tmux"
    else
        add_item "tmux config" "~/.tmux.conf" "not installed" 1 0 "install_tmux"
    fi

    # 4. Starship prompt
    if detect_starship_installed; then
        add_item "Starship prompt" "~/.config/starship.toml" "already installed" 1 0 "install_starship"
    else
        add_item "Starship prompt" "~/.config/starship.toml" "not installed" 1 0 "install_starship"
    fi

    # 5. Fetch script
    if detect_fetch_installed; then
        add_item "Fetch script" "aynight" "already installed" 1 0 "install_fetch"
    else
        add_item "Fetch script" "aynight" "not installed" 1 0 "install_fetch"
    fi

    # 6. Locale (Linux only, needs sudo)
    if [[ "$OS" != "macos" ]]; then
        if detect_locale_installed; then
            add_item "Locale setup" "en_US.UTF-8" "already installed" 1 1 "install_locale"
        else
            add_item "Locale setup" "en_US.UTF-8" "not installed" 1 1 "install_locale"
        fi
    fi

    # 7. System MOTD (Linux, needs sudo) — aynight at every login
    if [[ "$OS" != "macos" ]]; then
        if detect_motd_installed; then
            add_item "Login MOTD" "aynight at login" "already installed" 1 1 "install_motd"
        else
            add_item "Login MOTD" "aynight at login" "not installed" 1 1 "install_motd"
        fi
    fi
}

# ── Draw a single menu line ─────────────────────────────────────
draw_menu_line() {
    local idx=$1
    local is_cursor=0
    [[ $idx -eq $MENU_CURSOR ]] && is_cursor=1

    # Install button (one past last item)
    if [[ $idx -ge $MENU_COUNT ]]; then
        if [[ $is_cursor -eq 1 ]]; then
            printf '%s  [ Install selected ]   (press enter)\033[K\033[0m\n' "${HL_BG}${HL_FG}"
        else
            printf '%s  [ Install selected ]   (press enter)\033[K%s\n' "$C_DIM" "$C_RESET"
        fi
        return
    fi

    local selectable=${M_SELECTABLE[$idx]:-0}
    local selected=${M_SELECTED[$idx]:-0}
    local label="${M_LABEL[$idx]}"
    local desc="${M_DESC[$idx]}"
    local status="${M_STATUS[$idx]}"

    if [[ $is_cursor -eq 1 ]]; then
        # Highlighted: baby blue bg, dark text
        local check
        [[ $selected -eq 1 ]] && check="[x]" || check="[ ]"
        printf '%s  %s  %-16s %-30s %s\033[K\033[0m\n' \
            "${HL_BG}${HL_FG}" "$check" "$label" "$desc" "$status"
    else
        # Normal: colored checkbox, default text
        local check check_color
        if [[ $selected -eq 1 ]]; then
            check="[x]"; check_color="$C_SAPPHIRE"
        else
            check="[ ]"; check_color="$C_DIM"
        fi
        printf '  %s%s%s  %-16s %-30s %s\n' \
            "$check_color" "$check" "$C_RESET" "$label" "$desc" "$status"
    fi
}

# ── Draw (or redraw) the full menu ──────────────────────────────
draw_menu() {
    MENU_LINES=0
    local i
    for ((i = 0; i < MENU_COUNT; i++)); do
        draw_menu_line "$i"
        MENU_LINES=$((MENU_LINES + 1))
    done
    printf '\n'
    MENU_LINES=$((MENU_LINES + 1))
    draw_menu_line "$MENU_COUNT"
    MENU_LINES=$((MENU_LINES + 1))
}

redraw_menu() {
    if [[ $MENU_LINES -gt 0 ]]; then
        printf '\033[%dA' "$MENU_LINES"
    fi
    draw_menu
}

# ── Move cursor to next selectable item ─────────────────────────
next_cursor() {
    local dir=$1  # -1 up, +1 down
    local idx=$MENU_CURSOR
    local start=$idx
    local total=$((MENU_COUNT + 1))  # +1 for install button

    while true; do
        idx=$(( (idx + dir + total) % total ))
        # Install button is always valid
        [[ $idx -eq $MENU_COUNT ]] && break
        # Selectable items are valid
        [[ ${M_SELECTABLE[$idx]:-1} -eq 1 ]] && break
        # Guard: all items non-selectable
        [[ $idx -eq $start ]] && break
    done
    MENU_CURSOR=$idx
}

# ── Interactive menu loop ───────────────────────────────────────
menu_loop() {
    # Non-interactive fallback: install everything
    if [[ ! -t 0 ]]; then
        info "Non-interactive terminal — installing all components"
        return
    fi

    _MENU_ACTIVE=1
    tput civis 2>/dev/null || true   # hide cursor
    # Ensure terminal restore on interrupt
    trap 'stty echo 2>/dev/null; tput cnorm 2>/dev/null; printf "\n"; info "Cancelled."; exit 130' INT
    trap 'stty echo 2>/dev/null; tput cnorm 2>/dev/null; printf "\n"; info "Cancelled."; exit 143' TERM

    # ── Header ──
    local shell_name
    shell_name=$(basename "${SHELL:-bash}")
    local os_display="$OS"
    if [[ "$OS" != "macos" ]] && [[ -f /etc/os-release ]]; then
        os_display=$(grep '^PRETTY_NAME=' /etc/os-release 2>/dev/null | head -1 | cut -d= -f2 | tr -d '"' || echo "$OS")
    elif [[ "$OS" == "macos" ]]; then
        local mac_ver
        mac_ver=$(sw_vers -productVersion 2>/dev/null || echo "")
        os_display="macOS ${mac_ver}"
    fi

    printf '\n'
    printf '%s  Detected: %s · %s · %s%s\n' "$C_SILVER" "$os_display" "$shell_name" "${USER:-$(whoami)}" "$C_RESET"
    printf '\n'
    printf '%s  Use arrow keys to move  ·  space to select  ·  enter to confirm  ·  q to quit%s\n' "$C_DIM" "$C_RESET"
    printf '\n'

    # Set initial cursor to first selectable item
    MENU_CURSOR=0
    if [[ ${M_SELECTABLE[0]:-1} -eq 0 ]]; then
        next_cursor 1
    fi

    draw_menu

    # ── Key reading loop ──
    local key="" seq="" dir=""
    while true; do
        key=""
        IFS= read -rsn1 key || true

        case "$key" in
            $'\x1b')  # ESC — could be arrow key or standalone ESC
                seq=""
                IFS= read -rsn1 -t 0.05 seq || seq=""
                if [[ "$seq" == "[" ]]; then
                    dir=""
                    IFS= read -rsn1 -t 0.05 dir || dir=""
                    case "$dir" in
                        A) next_cursor -1; redraw_menu ;;  # up
                        B) next_cursor 1;  redraw_menu ;;  # down
                    esac
                elif [[ -z "$seq" ]]; then
                    # Standalone ESC = quit
                    tput cnorm 2>/dev/null || true
                    _MENU_ACTIVE=0
                    printf '\n'
                    info "Cancelled."
                    exit 0
                fi
                ;;
            ''|$'\n')  # Enter
                break
                ;;
            ' ')  # Space — toggle selection
                if [[ $MENU_CURSOR -lt $MENU_COUNT && ${M_SELECTABLE[$MENU_CURSOR]:-0} -eq 1 ]]; then
                    M_SELECTED[$MENU_CURSOR]=$(( 1 - ${M_SELECTED[$MENU_CURSOR]:-0} ))
                    redraw_menu
                fi
                ;;
            q|Q)  # Quit
                tput cnorm 2>/dev/null || true
                _MENU_ACTIVE=0
                printf '\n'
                info "Cancelled."
                exit 0
                ;;
        esac
    done

    # ── Restore terminal state ──
    tput cnorm 2>/dev/null || true
    _MENU_ACTIVE=0
    trap - INT TERM

    # ── Clear the menu display (header + items + button) ──
    local total=$((5 + MENU_LINES))  # 5 header lines
    printf '\033[%dA' "$total"
    local i
    for ((i = 0; i < total; i++)); do
        printf '\033[K\n'
    done
    printf '\033[%dA' "$total"
}

# ══════════════════════════════════════════════════════════════════
# ── Main ────────────────────────────────────────────────────────
# ══════════════════════════════════════════════════════════════════
main() {
    # Minimal flag parsing (--uninstall, --help, --sudo, --motd)
    MOTD_ONLY=0
    YES=0
    FULL_MOTD=""   # set when --motd-replace/--motd-merge used WITHOUT being a shortcut
    for arg in "$@"; do
        case "$arg" in
            --sudo)      USE_SUDO=1 ;;
            --yes|-y)    YES=1; USE_SUDO=1 ;;
            --uninstall) UNINSTALL=1 ;;
            --motd)      MOTD_ONLY=1 ;;
            --motd-replace) AYN_MOTD_MODE=replace; YES=1; USE_SUDO=1 ;;
            --motd-merge)   AYN_MOTD_MODE=merge;   YES=1; USE_SUDO=1 ;;
            -h|--help)   usage ;;
            *)           warn "Unknown flag: $arg" ;;
        esac
    done

    detect_os
    resolve_source

    # --motd: jump straight to MOTD install (skips menu)
    if [[ $MOTD_ONLY -eq 1 ]]; then
        banner
        if [[ "$OS" != "macos" ]]; then
            if [[ $USE_SUDO -eq 0 ]]; then
                ask_yn "MOTD install needs sudo. Use sudo?" && USE_SUDO=1
            fi
            # Ensure aynight binary is installed first (motd script calls it)
            if ! command -v aynight >/dev/null 2>&1; then
                info "Installing aynight first..."
                ensure_local_bin
                install_fetch
            fi
            AYN_MOTD_CONFIRM=y install_motd
        else
            info "MOTD not supported on macOS"
        fi
        exit 0
    fi

    if [[ $UNINSTALL -eq 1 ]]; then
        do_uninstall
        exit 0
    fi

    banner
    build_menu
    menu_loop

    # ── Sudo handling: ask once if any selected item needs it ──
    local any_need_sudo=0
    local i
    for ((i = 0; i < MENU_COUNT; i++)); do
        if [[ ${M_SELECTED[$i]:-0} -eq 1 && ${M_NEEDS_SUDO[$i]:-0} -eq 1 ]]; then
            any_need_sudo=1
            break
        fi
    done

    if [[ $any_need_sudo -eq 1 && $USE_SUDO -eq 0 && "$OS" != "macos" ]]; then
        if ask_yn "Some steps need sudo. Use sudo?"; then
            USE_SUDO=1
        fi
    fi

    # ── Install selected items ──
    local installed_list="" skipped_list="" already_list=""
    for ((i = 0; i < MENU_COUNT; i++)); do
        # Skip non-applicable items (e.g. iTerm2 on Linux)
        [[ ${M_SELECTABLE[$i]:-0} -eq 0 ]] && continue

        local label="${M_LABEL[$i]}"
        local was_status="${M_STATUS[$i]}"

        if [[ ${M_SELECTED[$i]:-0} -eq 0 ]]; then
            skipped_list+="$label (deselected), "
            continue
        fi

        # Needs sudo but not available
        if [[ ${M_NEEDS_SUDO[$i]:-0} -eq 1 && $USE_SUDO -eq 0 ]]; then
            skipped_list+="$label (needs sudo), "
            continue
        fi

        step "$label"
        "${M_FUNC[$i]}"

        if [[ "$was_status" == *"already"* ]]; then
            already_list+="$label, "
        else
            installed_list+="$label, "
        fi
    done

    # ── Summary ──
    printf '\n'
    [[ -n "${installed_list}" ]] && success "Installed:  ${installed_list%, }"
    [[ -n "${skipped_list}" ]]   && printf '%s  Skipped:    %s%s\n' "$C_DIM" "${skipped_list%, }" "$C_RESET"
    [[ -n "${already_list}" ]]   && printf '%s  Already had: %s%s\n' "$C_SILVER" "${already_list%, }" "$C_RESET"

    printf '\n'
    success "AygeaNight installation complete!"
    printf '\n'
    local rc
    rc=$(rc_file)
    printf '  -> Restart your terminal or run: %s%s%s\n' "$C_BOLD" "source $rc" "$C_RESET"
    printf '\n'
}

main "$@"
