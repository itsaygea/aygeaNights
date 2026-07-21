#!/usr/bin/env bash
# ╭──────────────────────────────────────────────────────────────╮
# │  aygeafetch-ubuntu.sh · Ubuntu / Debian / Pop wrapper         │
# │  Defines OS label + pkg count, then sources the shared core.  │
# ╰──────────────────────────────────────────────────────────────╯

# ── Flags: pick the art variant ─────────────────────────────────
_aygea_usage() {
    cat <<EOF
AygeaNight system fetch (Ubuntu / Debian / Pop)

Usage: aygeafetch [option]
  --fox          laying fox        (default)
  --fox-inv      inverted laying fox
  --face         bordered fox face
  --face-inv     inverted blob face
  --art <name>   fox | fox-inv | face | face-inv
  -h, --help     show this help

Env:  AYGEAFETCH_ART=<name>   (flag overrides env)
EOF
}
for _a in "$@"; do
    case "$_a" in
        --fox|--fox-inv|--face|--face-inv) AYGEAFETCH_ART="${_a#--}" ;;
        --art) shift; AYGEAFETCH_ART="$1" ;;
        --art=*) AYGEAFETCH_ART="${_a#--art=}" ;;
        -h|--help) _aygea_usage; exit 0 ;;
        *) printf 'aygeafetch: unknown option %s\n' "$_a" >&2; _aygea_usage; exit 2 ;;
    esac
done
export AYGEAFETCH_ART

AYGEAFETCH_OS="Ubuntu"

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
    "$(dirname "${BASH_SOURCE[0]:-$0}")/_aygeafetch_core.sh" \
    "$HOME/.local/share/aygea/_aygeafetch_core.sh" \
    "$HOME/.config/aygea/_aygeafetch_core.sh"; do
    [[ -f "$_cand" ]] && { _aygea_core="$_cand"; break; }
done
if [[ -z "$_aygea_core" ]]; then
    printf 'aygeafetch: core engine not found\n' >&2; exit 1
fi
# shellcheck source=_aygeafetch_core.sh
source "$_aygea_core"
