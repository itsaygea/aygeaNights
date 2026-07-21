#!/usr/bin/env bash
# ╭──────────────────────────────────────────────────────────────╮
# │  aynight-ubuntu.sh · Ubuntu / Debian / Pop wrapper         │
# │  Defines OS label + pkg count, then sources the shared core.  │
# ╰──────────────────────────────────────────────────────────────╯

# ── Flags: pick the art variant ─────────────────────────────────
_aygea_usage() {
    cat <<EOF
AygeaNight system fetch (Ubuntu / Debian / Pop)

Usage: aynight [option]
  --<name>       load art/<name>.txt        (e.g. --fox, --jirachi)
  --<name>-inv   inverted variant           (e.g. --fox-inv, --jirachi-inv)
  --art <name>   explicit name              (fox | fox-inv | face | jirachi | ...)
  -h, --help     show this help

Built-in:   --fox (default), --fox-inv, --face, --face-inv
Custom:     drop art/<name>.txt + art/<name>-inverted.txt, use --<name>

Env:  AYNIGHT_ART=<name>   (flag overrides env)
EOF
}
for _a in "$@"; do
    case "$_a" in
        -h|--help) _aygea_usage; exit 0 ;;
        --art) shift; AYNIGHT_ART="$1" ;;
        --art=*) AYNIGHT_ART="${_a#--art=}" ;;
        --*) AYNIGHT_ART="${_a#--}" ;;  # generic --<name> / --<name>-inv
        *) printf 'aynight: unknown option %s\n' "$_a" >&2; _aygea_usage; exit 2 ;;
    esac
done
export AYNIGHT_ART

AYNIGHT_OS="Ubuntu"

get_os() {
    local name=""
    if [[ -f /etc/os-release ]]; then
        while IFS='=' read -r key val; do
            if [[ "$key" == "PRETTY_NAME" ]]; then name="${val//\"/}"; break; fi
        done < /etc/os-release
    fi
    printf '%s' "${name:-Ubuntu}"
}

get_pkgs() {
    local dpkg_n snap_n total
    dpkg_n=$(dpkg -l 2>/dev/null | grep -c '^ii') || dpkg_n=0
    if command -v snap >/dev/null 2>&1; then
        snap_n=$(snap list 2>/dev/null | tail -n +2 | wc -l | tr -d ' ') || snap_n=0
    else
        snap_n=0
    fi
    total=$(( dpkg_n + snap_n ))
    printf '%s' "${total:-N/A}"
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
