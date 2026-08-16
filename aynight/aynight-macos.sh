#!/usr/bin/env bash
# ╭──────────────────────────────────────────────────────────────╮
# │  aynight-macos.sh · macOS wrapper                           │
# │  Defines OS label + pkg count, then sources the shared core.  │
# ╰──────────────────────────────────────────────────────────────╯

# ── Flags: pick the art variant ─────────────────────────────────
_aygea_usage() {
    cat <<EOF
AygeaNight system fetch (macOS)

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

AYNIGHT_OS="macOS"

get_os() {
    local name="macOS" ver="" out
    if command -v sw_vers >/dev/null 2>&1; then
        out=$(sw_vers 2>/dev/null)
        name=$(awk -F':\t*' '/ProductName/{print $2}' <<< "$out")
        ver=$(awk -F':\t*' '/ProductVersion/{print $2}' <<< "$out")
    fi
    if [[ -n "$ver" ]]; then
        printf '%s %s' "${name:-macOS}" "$ver"
    else
        printf '%s' "${name:-macOS}"
    fi
}

get_pkgs() {
    local n=0 cellar=""
    for cand in "${HOMEBREW_CELLAR:-}" "${HOMEBREW_PREFIX:-}/Cellar" "/opt/homebrew/Cellar" "/usr/local/Cellar"; do
        [[ -n "$cand" && -d "$cand" ]] && { cellar="$cand"; break; }
    done
    if [[ -n "$cellar" ]]; then
        local nf
        nf=$(find "$cellar" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
        n=$(( n + ${nf:-0} ))
    elif command -v brew >/dev/null 2>&1; then
        local nf
        nf=$(brew list --formula 2>/dev/null | wc -l | tr -d ' ')
        n=$(( n + ${nf:-0} ))
    fi
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
