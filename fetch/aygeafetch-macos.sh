#!/usr/bin/env bash
# ╭──────────────────────────────────────────────────────────────╮
# │  aygeafetch-macos.sh · macOS wrapper                           │
# │  Defines OS label + pkg count, then sources the shared core.  │
# ╰──────────────────────────────────────────────────────────────╯

# ── Flags: pick the art variant ─────────────────────────────────
_aygea_usage() {
    cat <<EOF
AygeaNight system fetch (macOS)

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

AYGEAFETCH_OS="macOS"

get_os() {
    local name ver
    name=$(sw_vers -productName 2>/dev/null) || name="macOS"
    ver=$(sw_vers -productVersion 2>/dev/null) || ver=""
    printf '%s %s' "$name" "$ver"
}

get_pkgs() {
    local n
    n=$(brew list --formula 2>/dev/null | wc -l | tr -d ' ')
    printf '%s' "${n:-N/A}"
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
