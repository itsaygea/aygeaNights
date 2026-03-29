#!/usr/bin/env bash
# ╭──────────────────────────────────────────────────────────────────╮
# │  install.sh  ·  AygeaNight terminal theme installer              │
# │  curl -fsSL <url>/install.sh | bash                           │
# ╰──────────────────────────────────────────────────────────────────╯
set -euo pipefail

parse_flags() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --sudo)          USE_SUDO=1; shift ;;
            --skip-fonts)    SKIP_FONTS=1; shift ;;
            --skip-tmux)     SKIP_TMUX=1; shift ;;
            --skip-starship) SKIP_STARSHIP=1; shift ;;
            --skip-fetch)    SKIP_FETCH=1; shift ;;
            --uninstall)     UNINSTALL=1; shift ;;
            -h|--help)       usage ;;
            *) warn "Unknown flag: $1"; shift ;;
        esac
    done
}

VERSION="1.0.0"
REPO="itsaygea/aygeaNight"
REPO_URL="https://github.com/${REPO}"
MARKER_BEGIN="# >>> aygea-night >>>"
MARKER_END="# <<< aygea-night <<<"

# ── Globals ──────────────────────────────────────────────────────
OS=""
SCRIPT_DIR=""
USE_SUDO=0
SKIP_FONTS=0
SKIP_TMUX=0
SKIP_STARSHIP=0
SKIP_FETCH=0
UNINSTALL=0
STEP_NUM=0
LOCAL_BIN="$HOME/.local/bin"
TMPDIR_AYGEA=""

# ── Cleanup temp dir on exit ────────────────────────────────────
cleanup() {
    if [[ -n "${TMPDIR_AYGEA}" && -d "${TMPDIR_AYGEA}" ]]; then
        rm -rf "${TMPDIR_AYGEA}" || true
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
    printf '%s    _   _                      _   _ _   _ \n' "$C_BLUE"
    printf '%s   / \\ | |__   __ _ _ __   ___| | | | \\ | |\n' "$C_BLUE"
    printf '%s  / _ \\| `_ \\ / _` | `_ \\ / _ \\ | | |  \\| |\n' "$C_BLUE"
    printf '%s / ___ \\ | | | (_| | | | |  __/ |_| | |\\  |\n' "$C_BLUE"
    printf '%s/_/   \\_\\_| |_| |\\__,_|_| |_|\\___/\\___/|_| \\_|\n' "$C_BLUE"
    printf '%s         Night\n' "$C_PINK"
    printf '%s\n' "$C_RESET"
    printf '%s  Tokyo Night base  ·  Aygea brand accents  ·  v%s%s\n' "$C_DIM" "$VERSION" "$C_RESET"
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

# ── Flag parsing ──────────────────────────────────────────────────
usage() {
    cat <<EOF
${C_BOLD}AygeaNight Terminal Theme Installer${C_RESET} v$VERSION

${C_SAPPHIRE}Usage:${C_RESET}
  install.sh [flags]

${C_SAPPHIRE}Flags:${C_RESET}
  --sudo            Use sudo for system-wide installs
  --skip-fonts      Skip font installation
  --skip-tmux       Skip tmux config
  --skip-starship   Skip starship prompt
  --skip-fetch      Skip fetch script
  --uninstall       Remove AygeaNight (restore backups)
  -h, --help        Show this help

${C_SAPPHIRE}Examples:${C_RESET}
  ./install.sh                    # interactive install
  ./install.sh --sudo             # use sudo without prompting
  curl -fsSL <url>/install.sh | bash   # remote install
EOF
    exit 0
}

parse_flags() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --sudo)          USE_SUDO=1; shift ;;
            --skip-fonts)    SKIP_FONTS=1; shift ;;
            --skip-tmux)     SKIP_TMUX=1; shift ;;
            --skip-starship) SKIP_STARSHIP=1; shift ;;
            --skip-fetch)    SKIP_FETCH=1; shift ;;
            --uninstall)     UNINSTALL=1; shift ;;
            -h|--help)       usage ;;
            *) warn "Unknown flag: $1"; shift ;;
        esac
    done
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
                    arch|manjaro|endeavouros|garuda) OS="arch" ;;
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

    info "Downloading aygeaNight from GitHub..."
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

# ── Helper: rc file path ─────────────────────────────────────────
rc_file() {
    if [[ "$OS" == "macos" ]]; then
        printf '%s' "$HOME/.zshrc"
    else
        printf '%s' "$HOME/.bashrc"
    fi
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
ensure_rc_line() {
    local file="$1" line="$2" pos="$3" comment="${4:-}"
    [[ -f "$file" ]] || touch "$file"

    if grep -qF "$line" "$file" 2>/dev/null; then
        return 0
    fi

    local block="$MARKER_BEGIN"
    [[ -n "$comment" ]] && block="$block  ($comment)"
    block="$block"$'\n'"$line"$'\n'"$MARKER_END"

    if [[ "$pos" == "top" ]]; then
        local tmp
        tmp=$(mktemp)
        printf '%s\n' "$block" > "$tmp"
        cat "$file" >> "$tmp"
        mv "$tmp" "$file"
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

# ── Install: Fonts ───────────────────────────────────────────────
install_fonts() {
    local src="$SCRIPT_DIR/fonts/JetBrainsMono"
    if [[ ! -d "$src" ]]; then
        warn "Font directory not found: $src"
        return 1
    fi

    local count
    count=$(find "$src" -name '*.ttf' 2>/dev/null | wc -l | tr -d ' ')
    if [[ "$count" -eq 0 ]]; then
        warn "No .ttf files found in $src"
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
}

# ── Install: tmux ────────────────────────────────────────────────
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

# ── Install: Locale (Linux only, needs sudo) ────────────────────
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

# ── Install: Starship prompt ────────────────────────────────────
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

    local rc
    rc=$(rc_file)

    if [[ "$OS" == "macos" ]]; then
        ensure_rc_line "$rc" 'eval "$(starship init zsh)"' bottom "aygea-night starship"
        success "Starship init added to $rc"
    else
        ensure_rc_line "$rc" 'export LANG=en_US.UTF-8' top "aygea locale"
        ensure_rc_line "$rc" 'export LC_ALL=en_US.UTF-8' top "aygea locale"
        ensure_rc_line "$rc" 'export TERM=xterm-256color' top "aygea terminal"
        ensure_rc_line "$rc" 'export COLORTERM=truecolor' top "aygea terminal"
        ensure_rc_line "$rc" 'eval "$(starship init bash)"' bottom "aygea-night starship"
        success "Starship init + locale exports added to $rc"
    fi
}

# ── Install: Fetch script ───────────────────────────────────────
install_fetch() {
    ensure_local_bin
    local rc
    rc=$(rc_file)

    case "$OS" in
        macos)
            cp "$SCRIPT_DIR/fetch/aygeafetch.zsh" "$HOME/aygeafetch.zsh"
            chmod +x "$HOME/aygeafetch.zsh"
            ensure_rc_line "$rc" 'source ~/aygeafetch.zsh' bottom "aygea-night fetch"
            success "aygeafetch installed to ~/aygeafetch.zsh"
            ;;
        ubuntu)
            cp "$SCRIPT_DIR/fetch/aygeafetch-ubuntu.sh" "$LOCAL_BIN/aygeafetch"
            chmod +x "$LOCAL_BIN/aygeafetch"
            ensure_rc_line "$rc" 'aygeafetch' bottom "aygea-night fetch"
            success "aygeafetch installed to $LOCAL_BIN/aygeafetch"
            ;;
        arch)
            cp "$SCRIPT_DIR/fetch/aygeafetch-arch.sh" "$LOCAL_BIN/aygeafetch"
            chmod +x "$LOCAL_BIN/aygeafetch"
            ensure_rc_line "$rc" 'aygeafetch' bottom "aygea-night fetch"
            success "aygeafetch installed to $LOCAL_BIN/aygeafetch"
            ;;
    esac
}

# ── Install: iTerm2 colors (macOS only) ─────────────────────────
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

    case "$OS" in
        macos)
            rm -f "$HOME/aygeafetch.zsh"
            info "Removed ~/aygeafetch.zsh"
            ;;
        *)
            rm -f "$LOCAL_BIN/aygeafetch"
            info "Removed $LOCAL_BIN/aygeafetch"
            ;;
    esac

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

# ── Main ────────────────────────────────────────────────────────
main() {
    parse_flags "$@"
    detect_os
    resolve_source

    if [[ $UNINSTALL -eq 1 ]]; then
        do_uninstall
        exit 0
    fi

    banner
    info "Detected OS: ${C_BOLD}$OS${C_RESET}"

    # Ask about sudo (Linux only, skip if already set via --sudo flag)
    if [[ $USE_SUDO -eq 0 && "$OS" != "macos" ]]; then
        if ask_yn "Use sudo for system-wide installs (locale, package manager)?"; then
            USE_SUDO=1
        else
            info "Installing without sudo (user-level only)"
        fi
    fi

    printf '\n'

    # Step 1: Locale (Linux only)
    if [[ "$OS" != "macos" && $USE_SUDO -eq 1 ]]; then
        step "Setting up locale (en_US.UTF-8)"
        install_locale
    fi

    # Step 2: Fonts
    if [[ $SKIP_FONTS -eq 0 ]]; then
        step "Installing JetBrainsMono Nerd Font"
        install_fonts
    fi

    # Step 3: tmux
    if [[ $SKIP_TMUX -eq 0 ]]; then
        step "Installing tmux config"
        install_tmux
    fi

    # Step 4: Starship
    if [[ $SKIP_STARSHIP -eq 0 ]]; then
        step "Installing Starship prompt"
        install_starship
    fi

    # Step 5: Fetch script
    if [[ $SKIP_FETCH -eq 0 ]]; then
        step "Installing aygeafetch"
        install_fetch
    fi

    # Step 6: iTerm2 (macOS only)
    if [[ "$OS" == "macos" ]]; then
        step "iTerm2 color scheme"
        install_iterm_colors
    fi

    printf '\n'
    success "AygeaNight installation complete!"
    printf '\n'
    local rc; rc=$(rc_file)
    printf '  -> Restart your terminal or run: %s%s%s\n' "$C_BOLD" "source $rc" "$C_RESET"
    printf '\n'
}

main "$@"
