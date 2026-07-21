#!/usr/bin/env bash
# ╭──────────────────────────────────────────────────────────────╮
# │  aynight-arch.sh · Arch Linux / CachyOS / Manjaro wrapper  │
# │  Defines OS label + pkg count, then sources the shared core.  │
# ╰──────────────────────────────────────────────────────────────╯

# ── Flags: pick the art variant ─────────────────────────────────
_aygea_usage() {
    cat <<EOF
AygeaNight system fetch (Arch / CachyOS / Manjaro)

Usage: aynight [option]
  --fox          laying fox        (default)
  --fox-inv      inverted laying fox
  --face         bordered fox face
  --face-inv     inverted blob face
  --art <name>   fox | fox-inv | face | face-inv
  -h, --help     show this help

Env:  AYNIGHT_ART=<name>   (flag overrides env)
EOF
}
for _a in "$@"; do
    case "$_a" in
        --fox|--fox-inv|--face|--face-inv) AYNIGHT_ART="${_a#--}" ;;
        --art) shift; AYNIGHT_ART="$1" ;;
        --art=*) AYNIGHT_ART="${_a#--art=}" ;;
        -h|--help) _aygea_usage; exit 0 ;;
        *) printf 'aynight: unknown option %s\n' "$_a" >&2; _aygea_usage; exit 2 ;;
    esac
done
export AYNIGHT_ART

AYNIGHT_OS="Arch"

get_os() {
    local name=""
    if [[ -f /etc/os-release ]]; then
        while IFS='=' read -r key val; do
            if [[ "$key" == "PRETTY_NAME" ]]; then name="${val//\"/}"; break; fi
        done < /etc/os-release
    fi
    printf '%s' "${name:-Arch Linux}"
}

get_pkgs() {
    local n
    n=$(pacman -Qq 2>/dev/null | wc -l | tr -d ' ') || n=0
    printf '%s' "${n:-N/A}"
}

# ── Source the shared engine ────────────────────────────────────
_aygea_core=""
for _cand in \
    "$(dirname "${BASH_SOURCE[0]:-$0}")/_aynight_core.sh" \
    "$HOME/.local/share/aygea/_aynight_core.sh" \
    "$HOME/.config/aygea/_aynight_core.sh"; do
    [[ -f "$_cand" ]] && { _aygea_core="$_cand"; break; }
done
if [[ -z "$_aygea_core" ]]; then
    printf 'aynight: core engine not found\n' >&2; exit 1
fi
# shellcheck source=_aynight_core.sh
source "$_aygea_core"
