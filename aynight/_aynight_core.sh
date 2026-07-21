#!/usr/bin/env bash
# ╭──────────────────────────────────────────────────────────────╮
# │  _aynight_core.sh · AygeaNight fetch · shared engine      │
# │  Block-art fox + sectioned info + dot meters                 │
# │                                                              │
# │  NOT standalone. Sourced by the OS wrappers:                 │
# │    aynight/aynight-arch.sh   aynight/aynight-ubuntu.sh     │
# │    aynight/aynight.zsh                                    │
# │  Each wrapper must define, before sourcing this file:        │
# │    AYNIGHT_OS   short label e.g. "Arch", "macOS"          │
# │    get_os()        full OS string                            │
# │    get_pkgs()      installed package count                   │
# ╰──────────────────────────────────────────────────────────────╯

export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

COLOR=0
[[ -t 1 ]] && COLOR=1

# ── truecolor foreground ────────────────────────────────────────
_c() { [[ "$COLOR" = 1 ]] && printf '\033[38;2;%s;%s;%sm' "$1" "$2" "$3"; }
R=""
[[ "$COLOR" = 1 ]] && R=$(printf '\033[0m')

# ── brand palette ───────────────────────────────────────────────
baby=$(_c 175 203 255)   # Baby Blue
sap=$(_c 106 143 211)    # Sapphire
pink=$(_c 248 200 220)   # Soft Pink
pinkdk=$(_c 216 140 168) # Pink Dark
silver=$(_c 230 238 248) # Silver
silverdk=$(_c 192 209 230) # Silver Dark
lav=$(_c 201 184 232)    # Opal Lavender
green=$(_c 184 232 216)  # Opal Green
navy=$(_c 42 58 94)      # Navy frame
dim=$(_c 105 122 150)    # dim text

# ════════════════════════════════════════════════════════════════
# ASCII art — dot-art braille foxes (regular + inverted variants).
#   AYNIGHT_ART=fox        regular laying fox   (default)
#   AYNIGHT_ART=fox-inv    inverted laying fox
#   AYNIGHT_ART=face       regular bordered face
#   AYNIGHT_ART=face-inv   inverted blob face
#
# Loaded from aynight/art/{fox,fox-inverted,face,face-inverted}.txt if
# present (edit those files to recolor/reshape without touching code).
# Embedded fallback below covers curl-pipe installs with no art dir.
# ════════════════════════════════════════════════════════════════

# Resolve art dir: beside this script (aynight/art), else $HOME/.local/share/aygea/art
_aygea_art_dir=""
if [[ -n "${BASH_SOURCE[0]:-}" && -d "$(dirname "${BASH_SOURCE[0]}")/art" ]]; then
    _aygea_art_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/art" && pwd)"
elif [[ -d "$HOME/.local/share/aygea/art" ]]; then
    _aygea_art_dir="$HOME/.local/share/aygea/art"
fi

# Load an art file into array $2, prefixing each line with $baby / $R.
# Falls back to embedded array $3 if file missing.
_aygea_load_art() {  # filename, array_name, embedded_array_name
    local file="$1" outvar="$2" emb="$3" f=""
    [[ -n "$_aygea_art_dir" && -f "$_aygea_art_dir/$file" ]] && f="$_aygea_art_dir/$file"
    if [[ -n "$f" ]]; then
        eval "$outvar=()"
        local line
        while IFS= read -r line || [[ -n "$line" ]]; do
            [[ -z "$line" ]] && continue
            eval "$outvar+=(\"\${baby}\${line}\${R}\")"
        done < "$f"
        [[ $(eval "echo \${#$outvar[@]}") -gt 0 ]] && return 0
    fi
    # Fall back to embedded array (only for the four built-ins)
    [[ -n "$emb" ]] && eval "$outvar=(\"\${$emb[@]}\")"
}

declare -a FOX FOX_INV FACE FACE_INV
FOX=()
FOX+=("${baby}⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀ ${R}")
FOX+=("${baby}⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀ ${R}")
FOX+=("${baby}⠀⠀⠀⠀⠀⢀⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀${R}")
FOX+=("${baby}⠀⠀⠀⠀⠀⣸⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀${R}")
FOX+=("${baby}⠀⠀⠀⠀⢠⡟⠘⣷⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀${R}")
FOX+=("${baby}⠀⠀⠀⢰⡟⠀⠀⠈⠻⣷⣤⣤⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀${R}")
FOX+=("${baby}⠀⠀⣠⡟⠀⠀⠀⠀⠀⠈⢻⡿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀${R}")
FOX+=("${baby}⠀⣰⡟⠀⠀⠀⠀⠀⠀⠀⠀⠻⠸⣷⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀${R}")
FOX+=("${baby}⢰⡏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢹⣇⠀⣠⣄⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣀⣀⠀⠀⠀⠀⠀⠀⠀${R}")
FOX+=("${baby}⣾⡁⢀⣠⠴⠒⠲⣤⣠⠶⠋⠳⣤⣸⣿⣰⣿⣿⣿⣷⣄⠀⠀⠀⠀⠀⠀⠀⠀⣠⣾⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀${R}")
FOX+=("${baby}⣿⠟⠉⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⣽⠏⣿⡿⢿⣿⣿⣿⣷⣄⠀⠀⠀⠀⢠⣾⣿⣿⣿⠋⢹⡇⠀⠀⠀⠀⠀⠀${R}")
FOX+=("${baby}⢹⡆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⡟⠀⣿⠁⠀⠙⣿⡛⠛⢿⡶⠶⠶⠶⣿⣄⣀⣰⠃⠀⢸⡇⠀⠀⠀⠀⠀⠀${R}")
FOX+=("${baby}⠈⢷⡀⠀⠀⠀⠀⠀⠀⠀⠀⢰⡿⠁⠀⣿⠀⠀⠀⠈⢷⡀⠘⠛⠀⠀⠀⠀⠈⠉⠳⣄⠀⢸⡇⠀⠀⠀⠀⠀⠀${R}")
FOX+=("${baby}⠀⠈⢿⣦⡀⠀⠀⠀⠀⠀⢀⣿⣇⣀⠀⢻⠀⠀⠀⠀⢰⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠳⣾⠃⠀⣤⣤⣄⠀⠀${R}")
FOX+=("${baby}⠀⠀⠀⠉⠻⢶⣄⣠⣴⠞⠛⠉⠉⠙⠻⢾⣇⠀⢀⣰⠏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⡄⠀⣿⢩⡿⣿⡆${R}")
FOX+=("${baby}⠀⠀⠀⠀⣠⣴⠟⠉⠀⠀⠀⠀⠀⠀⠀⠀⢹⡷⠞⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⡇⠀⣿⣟⣵⡿⠁${R}")
FOX+=("${baby}⠀⢀⣠⡾⠋⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣇⠀⠀⠀⣴⣿⠀⠀⠀⠀⠀⠀⢠⣶⠀⠀⣸⡇⠀⠙⠋⠁⠀⠀${R}")
FOX+=("${baby}⢸⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⣿⣄⣈⣀⣙⣁⠀⠀⣶⣾⡶⠀⠻⠿⠀⢠⣿⣁⡀⠀⠀⠀⠀⠀${R}")
FOX+=("${baby}⠈⠛⠻⠿⠶⠶⠶⡤⣤⣤⣤⣄⣀⣤⣀⣠⣤⣀⣀⣹⣿⣿⣿⣿⣤⣽⣿⣴⣶⣶⡦⢼⣿⣿⣿⣿⠇⠀⠀⠀⠀${R}")
FOX+=("${baby}⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀ ${R}")
FOX+=("${baby}⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀ ${R}")
FOX_INV=()
FOX_INV+=("${baby}⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿${R}")
FOX_INV+=("${baby}⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿${R}")
FOX_INV+=("${baby}⣿⣿⣿⣿⣿⡿⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿${R}")
FOX_INV+=("${baby}⣿⣿⣿⣿⣿⠇⠀⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿${R}")
FOX_INV+=("${baby}⣿⣿⣿⣿⡟⢠⣧⠈⠻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿${R}")
FOX_INV+=("${baby}⣿⣿⣿⡏⢠⣿⣿⣷⣄⠈⠛⠛⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿${R}")
FOX_INV+=("${baby}⣿⣿⠟⢠⣿⣿⣿⣿⣿⣷⡄⢀⠈⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿${R}")
FOX_INV+=("${baby}⣿⠏⢠⣿⣿⣿⣿⣿⣿⣿⣿⣄⣇⠈⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿${R}")
FOX_INV+=("${baby}⡏⢰⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡆⠸⣿⠟⠻⠿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠿⠿⣿⣿⣿⣿⣿⣿⣿${R}")
FOX_INV+=("${baby}⠁⢾⡿⠟⣋⣭⣍⠛⠟⣉⣴⣌⠛⠇⠀⠏⠀⠀⠀⠈⠻⣿⣿⣿⣿⣿⣿⣿⣿⠟⠁⠀⠀⠀⢻⣿⣿⣿⣿⣿⣿${R}")
FOX_INV+=("${baby}⠀⣠⣶⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⠂⣰⠀⢀⡀⠀⠀⠀⠈⠻⣿⣿⣿⣿⡟⠁⠀⠀⠀⣴⡆⢸⣿⣿⣿⣿⣿⣿${R}")
FOX_INV+=("${baby}⡆⢹⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠏⢠⣿⠀⣾⣿⣦⠀⢤⣤⡀⢉⣉⣉⣉⠀⠻⠿⠏⣼⣿⡇⢸⣿⣿⣿⣿⣿⣿${R}")
FOX_INV+=("${baby}⣷⡈⢿⣿⣿⣿⣿⣿⣿⣿⣿⡏⢀⣾⣿⠀⣿⣿⣿⣷⡈⢿⣧⣤⣿⣿⣿⣿⣷⣶⣌⠻⣿⡇⢸⣿⣿⣿⣿⣿⣿${R}")
FOX_INV+=("${baby}⣿⣷⡀⠙⢿⣿⣿⣿⣿⣿⡿⠀⠸⠿⣿⡄⣿⣿⣿⣿⡏⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣌⠁⣼⣿⠛⠛⠻⣿⣿${R}")
FOX_INV+=("${baby}⣿⣿⣿⣶⣄⡉⠻⠟⠋⣡⣤⣶⣶⣦⣄⡁⠸⣿⡿⠏⣰⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀⢻⣿⠀⡖⢀⠀⢹${R}")
FOX_INV+=("${baby}⣿⣿⣿⣿⠟⠋⣠⣶⣿⣿⣿⣿⣿⣿⣿⣿⡆⢈⣡⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⢸⣿⠀⠠⠊⢀⣾${R}")
FOX_INV+=("${baby}⣿⡿⠟⢁⣴⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⠸⣿⣿⣿⠋⠀⣿⣿⣿⣿⣿⣿⡟⠉⣿⣿⠇⢸⣿⣦⣴⣾⣿⣿${R}")
FOX_INV+=("${baby}⡇⠀⠀⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⠀⠻⠷⠿⠦⠾⣿⣿⠉⠁⢉⣿⣄⣀⣿⡟⠀⠾⢿⣿⣿⣿⣿⣿${R}")
FOX_INV+=("${baby}⣷⣤⣄⣀⣉⣉⣉⢛⠛⠛⠛⠻⠿⠛⠿⠟⠛⠿⠿⠆⠀⠀⠀⠀⠛⠂⠀⠋⠉⠉⢙⡃⠀⠀⠀⠀⣸⣿⣿⣿⣿${R}")
FOX_INV+=("${baby}⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿${R}")
FOX_INV+=("${baby}⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿${R}")
FACE=()
FACE+=("${baby}⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸${R}")
FACE+=("${baby}⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣀⣀⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣀⣀⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸${R}")
FACE+=("${baby}⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣾⣿⣿⣿⣿⣿⣶⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⣴⣾⣿⣿⣿⣿⣿⡆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸${R}")
FACE+=("${baby}⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣦⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣠⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸${R}")
FACE+=("${baby}⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⣿⠋⠉⠉⠻⢿⣿⣿⣿⣦⡀⠀⢀⣀⣀⣀⣀⣀⣀⠀⣀⣴⣿⣿⣿⣿⠟⠋⠉⠉⢿⣿⣿⣿⡆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸${R}")
FACE+=("${baby}⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⡇⠀⠀⠀⢀⣀⣽⣿⣿⣿⣿⡿⠿⠿⠿⠿⠿⠿⠿⠿⣿⣿⣿⣿⣯⣄⡀⠀⠀⠀⢸⣿⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸${R}")
FACE+=("${baby}⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⡇⢀⣤⣾⣿⠿⠛⠋⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠙⠛⠿⣿⣷⣤⣀⢸⣿⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸${R}")
FACE+=("${baby}⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⣷⣿⡿⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⠻⣿⣿⣿⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸${R}")
FACE+=("${baby}⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⡿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⢻⣿⣿⣿⠇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸${R}")
FACE+=("${baby}⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⡿⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢻⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸${R}")
FACE+=("${baby}⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢿⣿⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸${R}")
FACE+=("${baby}⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⣿⠏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣿⣧⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸${R}")
FACE+=("${baby}⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣿⡿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢻⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸${R}")
FACE+=("${baby}⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⠃⠀⠀⠀⠀⠀⠀⣰⣾⣿⣷⡄⠀⠀⣀⠤⠴⣲⣦⣶⡒⠦⢄⡀⠀⠀⢠⣾⣿⣷⡄⠀⠀⠀⠀⠀⠈⣿⣷⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸${R}")
FACE+=("${baby}⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣿⡟⠀⠀⠀⠀⠀⠀⠀⢻⣿⣿⣿⠃⠀⡴⠁⠀⠀⠻⣿⣿⠻⠀⠀⠉⢆⠀⠸⣿⣿⣿⠇⠀⠀⠀⠀⠀⠀⢹⣿⡆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸${R}")
FACE+=("${baby}⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⠁⠀⠀⠀⠀⠀⠀⠀⠤⠈⠉⠀⣠⠜⠀⠀⢸⣿⣿⣿⣿⣿⣿⠇⠀⠈⠢⣀⠀⠩⠡⠄⠀⠀⠀⠀⠀⠀⠀⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸${R}")
FACE+=("${baby}⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢻⣿⣏⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⠁⠀⠀⠀⠀⠀⠀⠀⠁⠀⠀⠀⠀⠀⠀⠀⠀⠈⠉⠉⠉⠉⠉⠉⠉⠉⠉⣩⣿⡿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸${R}")
FACE+=("${baby}⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠻⣿⣷⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⣴⣿⠟⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸${R}")
FACE+=("${baby}⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠛⢿⣿⣶⣤⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣤⣶⣿⡿⠛⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸${R}")
FACE+=("${baby}⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⠛⠿⣿⣿⣷⣶⣦⣤⣤⣤⣤⣀⣀⣀⣀⣀⣀⣀⣤⣤⣤⣤⣤⣶⣾⣿⡿⠿⠛⠋⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸${R}")
FACE+=("${baby}⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠉⠉⠛⠛⠛⠛⠻⠿⠿⠿⠿⠿⠟⠛⠛⠛⠛⠉⠉⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸${R}")
FACE+=("${baby}⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸${R}")
FACE+=("${baby}⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣼${R}")
FACE_INV=()
FACE_INV+=("${baby}⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇${R}")
FACE_INV+=("${baby}⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠿⠿⠿⠿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠿⠿⠿⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇${R}")
FACE_INV+=("${baby}⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠁⠀⠀⠀⠀⠀⠉⠻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠟⠋⠁⠀⠀⠀⠀⠀⢹⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇${R}")
FACE_INV+=("${baby}⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠟⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇${R}")
FACE_INV+=("${baby}⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⣴⣶⣶⣄⡀⠀⠀⠀⠙⢿⣿⡿⠿⠿⠿⠿⠿⠿⣿⠿⠋⠀⠀⠀⠀⣠⣴⣶⣶⡀⠀⠀⠀⢹⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇${R}")
FACE_INV+=("${baby}⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⢸⣿⣿⣿⡿⠿⠂⠀⠀⠀⠀⢀⣀⣀⣀⣀⣀⣀⣀⣀⠀⠀⠀⠀⠐⠻⢿⣿⣿⣿⡇⠀⠀⠀⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇${R}")
FACE_INV+=("${baby}⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⢸⡿⠛⠁⠀⣀⣤⣴⣶⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣦⣤⣀⠀⠈⠛⠿⡇⠀⠀⠀⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇${R}")
FACE_INV+=("${baby}⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⠈⠀⢀⣴⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣦⣄⠀⠀⠀⠀⠀⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇${R}")
FACE_INV+=("${baby}⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⢀⣼⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⡄⠀⠀⠀⣸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇${R}")
FACE_INV+=("${baby}⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀⠀⢀⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡄⠀⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇${R}")
FACE_INV+=("${baby}⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀⠀⣼⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡀⠀⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇${R}")
FACE_INV+=("${baby}⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠏⠀⣰⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣧⠀⠘⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇${R}")
FACE_INV+=("${baby}⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠀⢀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡄⠀⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇${R}")
FACE_INV+=("${baby}⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠃⠀⣼⣿⣿⣿⣿⣿⣿⠏⠁⠀⠈⢻⣿⣿⠿⣛⣋⠍⠙⠉⢭⣙⡻⢿⣿⣿⡟⠁⠀⠈⢻⣿⣿⣿⣿⣿⣷⠀⠈⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇${R}")
FACE_INV+=("${baby}⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡟⠀⢠⣿⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⣼⣿⢋⣾⣿⣿⣄⠀⠀⣄⣿⣿⣶⡹⣿⣇⠀⠀⠀⣸⣿⣿⣿⣿⣿⣿⡆⠀⢹⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇${R}")
FACE_INV+=("${baby}⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠃⠀⣾⣿⣿⣿⣿⣿⣿⣿⣛⣷⣶⣿⠟⣣⣿⣿⡇⠀⠀⠀⠀⠀⠀⣸⣿⣷⣝⠿⣿⣖⣞⣻⣿⣿⣿⣿⣿⣿⣿⠀⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇${R}")
FACE_INV+=("${baby}⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡄⠀⠰⣶⣶⣶⣶⣶⣶⣶⣶⣶⣶⣾⣿⣿⣿⣿⣿⣿⣿⣾⣿⣿⣿⣿⣿⣿⣿⣿⣷⣶⣶⣶⣶⣶⣶⣶⣶⣶⠖⠀⢀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇${R}")
FACE_INV+=("${baby}⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣄⠀⠈⠻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠟⠋⠀⣠⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇${R}")
FACE_INV+=("${baby}⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣤⡀⠀⠉⠛⠿⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠿⠛⠉⠀⢀⣤⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇${R}")
FACE_INV+=("${baby}⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣦⣤⣀⠀⠀⠈⠉⠙⠛⠛⠛⠛⠿⠿⠿⠿⠿⠿⠿⠛⠛⠛⠛⠛⠉⠁⠀⢀⣀⣤⣴⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇${R}")
FACE_INV+=("${baby}⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣶⣶⣤⣤⣤⣤⣄⣀⣀⣀⣀⣀⣠⣤⣤⣤⣤⣶⣶⣶⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇${R}")
FACE_INV+=("${baby}⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇${R}")
FACE_INV+=("${baby}⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠃${R}")
# ── Select + load the chosen art into ART ───────────────────────
declare -a ART
# Generic art selector: AYNIGHT_ART=<name> loads <name>.txt
# (or <name>-inverted.txt when name ends in -inv). Falls back to
# embedded arrays for the four built-ins, else to fox if unknown.
_a="${AYNIGHT_ART:-fox}"
case "$_a" in
    *-inv)
        _base="${_a%-inv}"
        case "$_base" in
            fox)  _aygea_load_art fox-inverted.txt   ART FOX_INV ;;
            face) _aygea_load_art face-inverted.txt  ART FACE_INV ;;
            *)    _aygea_load_art "${_base}-inverted.txt" ART ""  ;;
        esac
        ;;
    *)
        case "$_a" in
            fox)  _aygea_load_art fox.txt  ART FOX  ;;
            face) _aygea_load_art face.txt ART FACE ;;
            *)    _aygea_load_art "${_a}.txt" ART "" ;;
        esac
        ;;
esac
# Nothing loaded (unknown name, no file, no embedded match)? → fox
[[ ${#ART[@]} -eq 0 ]] && ART=("${FOX[@]}")
unset _a _base


# ── visible length (strips ANSI) ────────────────────────────────
_vlen() {
    local s="$1" out="" i=0 len=${#1} char skip=0
    while (( i < len )); do
        char="${s:$i:1}"
        if (( skip )); then
            case "$char" in [a-zA-Z]) skip=0 ;; esac
            (( i++ )) && continue
        fi
        if [[ "$char" == $(printf '\033') ]]; then skip=1; (( i++ )) && continue; fi
        out="${out}${char}"; (( i++ ))
    done
    printf '%s' "${#out}"
}
_pad() {
    local vis; vis=$(_vlen "$1")
    printf '%s%*s' "$1" $((ART_W - vis)) ""
}

# Widest art row by visible length — drives the info column offset.
ART_W=0
for _r in "${ART[@]}"; do
    _v=$(_vlen "$_r")
    (( _v > ART_W )) && ART_W=$_v
done
GAP=4
unset _r _v


# ════════════════════════════════════════════════════════════════
# Data — OS-independent getters. get_os + get_pkgs come from wrapper.
# ════════════════════════════════════════════════════════════════
get_kernel() { printf '%s' "$(uname -r 2>/dev/null)" || printf 'N/A'; }
get_shell()  { printf '%s' "${SHELL##*/:-bash}"; }
get_term()   { printf '%s' "${TERM:-${COLORTERM:-N/A}}"; }
get_host()   { printf '%s' "$(hostname -s 2>/dev/null || printf localhost)"; }
get_user()   { printf '%s' "${USER:-$(whoami 2>/dev/null || printf user)}"; }

get_uptime() {
    local s d h m
    if [[ -r /proc/uptime ]]; then
        s=$(awk '{printf "%d",$1}' /proc/uptime 2>/dev/null) || s=0
    elif command -v sysctl >/dev/null 2>&1; then
        s=$(sysctl -n kern.boottime 2>/dev/null | awk -F'[ =}]' '{print int($6)}') || s=0
        [[ "$s" -gt 0 ]] && s=$(( $(date +%s) - s ))
    else printf 'N/A'; return; fi
    (( d = s/86400 )); (( s = s%86400 ))
    (( h = s/3600 ));  (( s = s%3600 )); (( m = s/60 ))
    printf '%dd %dh %dm' "$d" "$h" "$m"
}

get_cpu() {
    local cpu=""
    if [[ -r /proc/cpuinfo ]]; then
        while IFS=: read -r k v; do [[ "$k" == "model name"* ]] && { cpu="${v# }"; break; }; done < /proc/cpuinfo
    elif command -v sysctl >/dev/null 2>&1; then
        cpu=$(sysctl -n machdep.cpu.brand_string 2>/dev/null)
    fi
    cpu="${cpu//(tm)/}"; cpu="${cpu//(TM)/}"; cpu="${cpu//(r)/}"; cpu="${cpu//(R)/}"
    cpu="${cpu// CPU/}"; cpu="${cpu// @ */ @ }"
    printf '%s' "${cpu:-N/A}"
}

# Short-name a single GPU line → "Vendor Model" (AMD Renoir, NVIDIA RTX 3070, …)
_gpu_short() {
    local raw="$1"
    local low; low=$(printf '%s' "$raw" | tr '[:upper:]' '[:lower:]')

    local vendor=""
    case "$low" in
        *nvidia*|*geforce*|*quadro*|*rtx*|*gtx*)   vendor="NVIDIA" ;;
        *intel*)                                    vendor="Intel" ;;
        *apple*|*m1*|*m2*|*m3*|*m4)                  vendor="Apple" ;;
        *advanced\ micro*|*\ amd/*|*radeon*|*navi*|*\.amd\.com*|*amd/ati*) vendor="AMD" ;;
    esac

    # No recognized vendor → likely a VM/container virtual adapter
    # (QEMU stdvga "Device [1234:1111]", Cirrus, Bochs, VirtIO, VMware SVGA).
    # Real passthrough cards are caught above (AMD/NVIDIA/Intel strings).
    if [[ -z "$vendor" ]]; then
        case "$low" in
            *device*|*bochs*|*cirrus*|*qemu*|*virtio*|*vmware*|*svga*|*basic\ display*|*\[*:*\]*)
                printf 'N/A'; return ;;
        esac
    fi


    # Prefer the LAST [bracket] (chip/model), cut at first '/', trim. If that
    # bracket is just a vendor tag ("[AMD/ATI]" on AMD APU lines like
    # "[AMD/ATI] Renoir"), fall back to the bareword after it so the codename
    # (Renoir/Cezanne) — and thus iGPU vs dGPU — shows.
    local model="" last_br
    if [[ "$raw" == *'['*']'* ]]; then
        last_br=${raw##*[}; last_br=${last_br%%]*}
        case "$(printf '%s' "$last_br" | tr '[:upper:]' '[:lower:]')" in
            amd/ati|"") model=${raw#*\] }; model=${model%%\[*} ;;
            *)          model=${last_br%%/*} ;;
        esac
    else
        model=${raw%% (*}
    fi
    model="${model# }"; model="${model% }"
    model="${model//$vendor/}"; model="${model//  / }"; model="${model# }"; model="${model% }"

    if   [[ -n "$vendor" && -n "$model" ]]; then printf '%s %s' "$vendor" "$model"
    elif [[ -n "$vendor" ]];                   then printf '%s' "$vendor"
    else printf '%s' "${raw%% (*}"; fi
}

get_gpu() {
    local -a gpus=()
    if command -v lspci >/dev/null 2>&1; then
        while IFS= read -r line; do
            [[ -z "$line" ]] && continue
            local raw=${line#*:*:}; raw=${raw# }
            gpus+=( "$(_gpu_short "$raw")" )
        done < <(lspci 2>/dev/null | grep -iE 'vga|3d|display')
    elif [[ "$(uname -s 2>/dev/null)" == "Darwin" ]] && command -v system_profiler >/dev/null 2>&1; then
        while IFS= read -r line; do
            gpus+=( "$(_gpu_short "$line")" )
        done < <(system_profiler SPDisplaysDataType 2>/dev/null | awk -F': +' '/Chipset Model/{print $2}')
    fi

    [[ ${#gpus[@]} -eq 0 ]] && { printf 'N/A'; return; }
    local out="" g
    for g in "${gpus[@]}"; do
        [[ -n "$out" ]] && out+=" + "
        out+="$g"
    done
    printf '%s' "$out"
}

# RAM: "usedGiB / totalGiB" + raw pct on stdout for the meter.
get_ram_str() {
    local used_kb tot_kb
    if [[ -r /proc/meminfo ]]; then
        read -r tot_kb av_kb < <(awk '/^MemTotal:/{t=$2}/^MemAvailable:/{a=$2}END{print t" "a}' /proc/meminfo 2>/dev/null)
        [[ -n "${av_kb:-}" ]] || av_kb=0
        used_kb=$(( tot_kb - av_kb )); (( used_kb < 0 )) && used_kb=0
    elif command -v vm_stat >/dev/null 2>&1 && command -v sysctl >/dev/null 2>&1; then
        local pgsize pages_free pages_act pages_inact pages_wired
        pgsize=$(sysctl -n hw.pagesize 2>/dev/null)
        pages_act=$(vm_stat 2>/dev/null | awk '/Pages active/{gsub(/\./,"",$3);print $3}')
        pages_wired=$(vm_stat 2>/dev/null | awk '/Pages wired/{gsub(/\./,"",$3);print $3}')
        pages_act=${pages_act:-0}; pages_wired=${pages_wired:-0}; pgsize=${pgsize:-0}
        tot_kb=$(sysctl -n hw.memsize 2>/dev/null)
        used_kb=$(( (pages_act + pages_wired) * pgsize / 1024 ))
        (( tot_kb > 0 )) || tot_kb=$used_kb
    else printf 'N/A\t0'; return; fi
    local ug tg pct
    ug=$(awk -v k="$used_kb" 'BEGIN{printf "%.1f",k/1048576}')
    tg=$(awk -v k="$tot_kb"  'BEGIN{printf "%.0f",k/1048576}')
    (( tot_kb > 0 )) && pct=$(( used_kb * 100 / tot_kb )) || pct=0
    printf '%sG / %sG\t%d' "$ug" "$tg" "$pct"
}

# Disk: used / total on / (or root vol) + pct.
get_disk_str() {
    local line used total pct
    if line=$(df -h / 2>/dev/null | awk 'NR==2{print $3"\t"$2"\t"$5}'); then
        read -r used total pct <<< "$line"
        pct="${pct%\%}"
    else printf 'N/A\t0'; return; fi
    printf '%s / %s\t%s' "${used:-N/A}" "${total:-N/A}" "${pct:-0}"
}

# IPv4 of first non-loopback interface (Linux ip / macOS ipconfig)
get_ipv4() {
    local ip=""
    if command -v ip >/dev/null 2>&1; then
        ip=$(ip -4 -o addr show scope global 2>/dev/null | awk '{print $2, $4}' | head -1)
    elif command -v hostname >/dev/null 2>&1; then
        ip=$(hostname -I 2>/dev/null | awk '{print $1}')
        [[ -n "$ip" ]] && ip="(default) $ip"
    fi
    [[ -z "$ip" ]] && command -v ipconfig >/dev/null 2>&1 && ip="en0 $(ipconfig getifaddr en0 2>/dev/null)"
    printf '%s' "${ip:-N/A}"
}

# IPv6 of first non-loopback global interface
get_ipv6() {
    local ip=""
    if command -v ip >/dev/null 2>&1; then
        ip=$(ip -6 -o addr show scope global 2>/dev/null | awk '{print $2, $4}' | head -1)
    fi
    [[ -z "$ip" ]] && { printf 'N/A'; return; }
    # trim /prefixlen
    ip=$(printf '%s' "$ip" | sed -E 's|/([0-9]+)||')
    printf '%s' "$ip"
}

# 1-min load average (Linux /proc/loadavg, macOS sysctl)
get_load() {
    local l=""
    if [[ -r /proc/loadavg ]]; then l=$(awk '{print $1}' /proc/loadavg 2>/dev/null)
    elif command -v sysctl >/dev/null 2>&1; then l=$(sysctl -n vm.loadavg 2>/dev/null | awk '{print $2}'); fi
    printf '%s' "${l:-N/A}"
}

# Swap usage pct (Linux /proc/meminfo, macOS vm.sys)
# Swap: "usedGiB / totalGiB\tpct" or empty when no swap configured.
get_swap_str() {
    local t u
    if [[ -r /proc/meminfo ]]; then
        read -r t u < <(awk '/^SwapTotal:/{t=$2}/^SwapFree:/{f=$2}END{print t" "(t-f)}' /proc/meminfo 2>/dev/null)
        [[ -n "${t:-}" ]] || t=0
        [[ -n "${u:-}" ]] || u=0
        (( t > 0 )) || { printf ''; return; }
        local ug tg pct
        ug=$(awk -v k="$u" 'BEGIN{printf "%.1f",k/1048576}')
        tg=$(awk -v k="$t" 'BEGIN{printf "%.0f",k/1048576}')
        pct=$(( u * 100 / t ))
        printf '%sG / %sG\t%d' "$ug" "$tg" "$pct"
    fi
}


# Running process count
get_procs() {
    local n=""
    [[ -r /proc/stat ]] && n=$(find /proc -maxdepth 1 -name '[0-9]*' 2>/dev/null | wc -l | tr -d ' ')
    [[ -z "$n" ]] && command -v ps >/dev/null 2>&1 && n=$(ps -e 2>/dev/null | wc -l | tr -d ' ')
    printf '%s' "${n:-N/A}"
}

# Logged-in user sessions (unique users)
get_users() {
    local n=""
    command -v who >/dev/null 2>&1 && n=$(who 2>/dev/null | awk '{print $1}' | sort -u | wc -l | tr -d ' ')
    printf '%s' "${n:-0}"
}

# Pending updates — wrapper may override. Default tries common package managers.
get_updates() {
    local n=""
    if command -v apt >/dev/null 2>&1; then
        n=$(apt list --upgradable 2>/dev/null | grep -c '/')
    elif command -v pacman >/dev/null 2>&1; then
        n=$(pacman -Qu 2>/dev/null | grep -c .)
    elif command -v dnf >/dev/null 2>&1; then
        n=$(dnf check-update 2>/dev/null | grep -cE '\.$')
    elif command -v brew >/dev/null 2>&1; then
        n=$(brew outdated 2>/dev/null | wc -l | tr -d ' ')
    fi
    printf '%s' "${n:-N/A}"
}

# Color the updates count: 0 = green, >0 = pink
_updates_value() {
    local n; n=$(get_updates)
    [[ "$n" == "N/A" ]] && { printf '%sN/A%s' "$silverdk" "$R"; return; }
    if (( n == 0 )); then printf '%s0 up to date%s' "$green" "$R"
    else printf '%s%d pending%s' "$pinkdk" "$n" "$R"; fi
}


# ════════════════════════════════════════════════════════════════
# Formatting primitives
# ════════════════════════════════════════════════════════════════
LBL_W=9
_kv() {  # label, value  ->  "label    value"
    printf '%s%-*s%s %s%s%s' "$dim" "$LBL_W" "$1" "$R" "$silver" "$2" "$R"
}
_section() {  # title
    printf '%s╴%s %s%s%s' "$navy" "$R" "$baby" "$1" "$R"
}

# dot meter — 10 cells, color-graded by pct (statusline idiom)
_meter() {  # pct
    local pct=$1 cells=10 filled empt i
    (( pct < 0 )) && pct=0; (( pct > 100 )) && pct=100
    filled=$(( pct * cells / 100 )); empt=$(( cells - filled ))
    local fc
    if   (( pct > 80 )); then fc="$pinkdk"
    elif (( pct >= 50 )); then fc="$lav"
    else fc="$sap"; fi
    local bar=""
    for (( i=0; i<filled; i++ )); do bar+="●"; done
    bar+="${silverdk}"
    for (( i=0; i<empt; i++ )); do bar+="○"; done
    printf '%s%s%s %s%d%%%s' "$fc" "$bar" "$R" "$fc" "$pct" "$R"
}

# ════════════════════════════════════════════════════════════════
# Build info rows (4 sections)
# ════════════════════════════════════════════════════════════════
declare -a INFO
INFO=()
INFO+=("$(_section SYSTEM)")
INFO+=("$(_kv Host     "$(get_host)")")
INFO+=("$(_kv OS       "$(get_os)")")
INFO+=("$(_kv Kernel   "$(get_kernel)")")
INFO+=("$(_kv Uptime   "$(get_uptime)")")
INFO+=("$(_kv Packages "$(get_pkgs)")")
INFO+=("$(printf '%s%-*s%s %s' "$dim" "$LBL_W" "Updates" "$R" "$(_updates_value)")")
INFO+=("$(_section HARDWARE)")
INFO+=("$(_kv CPU      "$(get_cpu)")")
INFO+=("$(_kv GPU      "$(get_gpu)")")

# RAM row with inline meter
{
    IFS=$'\t' read -r ram_str ram_pct <<< "$(get_ram_str)"
    INFO+=("$(printf '%s%-*s%s %s%-20s %s' "$dim" "$LBL_W" "Memory" "$R" "$silver" "$ram_str" "$(_meter "$ram_pct")")")
}
# Disk row with inline meter
{
    IFS=$'\t' read -r disk_str disk_pct <<< "$(get_disk_str)"
    INFO+=("$(printf '%s%-*s%s %s%-20s %s' "$dim" "$LBL_W" "Disk" "$R" "$silver" "$disk_str" "$(_meter "$disk_pct")")")
}
# Swap row: full format like Memory/Disk when swap exists, else N/A (no meter)
{
    swp=$(get_swap_str)
    if [[ -n "$swp" ]]; then
        IFS=$'\t' read -r sw_str sw_pct <<< "$swp"
        INFO+=("$(printf '%s%-*s%s %s%-20s %s' "$dim" "$LBL_W" "Swap" "$R" "$silver" "$sw_str" "$(_meter "$sw_pct")")")
    else
        INFO+=("$(printf '%s%-*s%s %sN/A%s' "$dim" "$LBL_W" "Swap" "$R" "$silverdk" "$R")")
    fi
}

INFO+=("$(_section SESSION)")
INFO+=("$(_kv Load     "$(get_load)")")
INFO+=("$(_kv Procs    "$(get_procs)")")
INFO+=("$(_kv Users    "$(get_users)")")
INFO+=("$(_section NETWORK)")
INFO+=("$(_kv IPv4     "$(get_ipv4)")")
INFO+=("$(_kv IPv6     "$(get_ipv6)")")

# ════════════════════════════════════════════════════════════════
# Render side by side (art vertically centered against info column)
# ════════════════════════════════════════════════════════════════
art_n=${#ART[@]}
info_n=${#INFO[@]}
# When info is taller than art, center the art block vertically so the
# blank-left tail (Users/IPv6 rows) is balanced top + bottom.
if (( info_n > art_n )); then
    art_start=$(( (info_n - art_n) / 2 ))
else
    art_start=0
fi
info_start=0
max_lines=$(( info_n > art_n ? info_n : art_n ))
(( art_start + art_n > max_lines )) && max_lines=$(( art_start + art_n ))

for (( row=0; row<max_lines; row++ )); do
    aidx=$(( row - art_start ))
    idx=$(( row - info_start ))
    # Art cell: pad to fixed width so info column always aligns.
    if (( aidx >= 0 && aidx < art_n )); then _pad "${ART[$aidx]}"
    else printf '%*s' "$ART_W" ""; fi
    printf '%*s' "$GAP" ""
    if (( idx >= 0 && idx < info_n )); then printf '%s' "${INFO[$idx]}"; fi
    printf '\n'
done

printf '\n'
