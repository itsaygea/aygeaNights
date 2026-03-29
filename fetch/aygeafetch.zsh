#!/usr/bin/env zsh
# ╭──────────────────────────────────────────────────────────────╮
# │  aygeafetch.zsh  ·  AygeaNight system fetch  ·  macOS       │
# │  Fox kitsune ASCII art + system info in brand colors         │
# ╰──────────────────────────────────────────────────────────────╯
#
# INSTALL:
#   chmod +x fetch/aygeafetch.zsh
#   cp fetch/aygeafetch.zsh ~/aygeafetch.zsh
#   Add to ~/.zshrc (at the end):
#     aygeafetch
#     # or: source ~/aygeafetch.zsh
#
# REQUIREMENTS:
#   - zsh (macOS default)
#   - Truecolor terminal (iTerm2, Kitty, Alacritty, WezTerm)
#   - A Nerd Font for best results (JetBrainsMono Nerd Font)
#
# NO EXTERNAL DEPENDENCIES - pure zsh, no python/jq/neofetch

export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

COLOR=0
[[ -t 1 ]] && COLOR=1

ART_W=27
GAP=3

# ── Helper: truecolor foreground escape ─────────────────────────
_c() {
    [[ "$COLOR" = 1 ]] && printf '\033[38;2;%s;%s;%sm' "$1" "$2" "$3"
}

R=""
[[ "$COLOR" = 1 ]] && R=$(printf '\033[0m')

# ── Helper: visible length (strips ANSI, pure shell) ────────────
_vlen() {
    local s="$1" out="" i=1 char skip=0
    local -i len=${#s}
    while (( i <= len )); do
        char="${s[$i]}"
        if (( skip )); then
            [[ "$char" =~ [a-zA-Z] ]] && skip=0
            (( i++ )) && continue
        fi
        if [[ "$char" == $(printf '\033') ]]; then
            skip=1
            (( i++ )) && continue
        fi
        out="${out}${char}"
        (( i++ ))
    done
    printf '%s' "${#out}"
}

# ── Helper: pad art line to ART_W visible chars ─────────────────
_pad() {
    local vis
    vis=$(_vlen "$1")
    printf '%s%*s' "$1" $((ART_W - vis)) ""
}

# ── Palette shortcuts ───────────────────────────────────────────
_s=$(_c 230 238 248);  _e=$(_c 15 82 186)
_b=$(_c 245 195 215);  _p=$(_c 248 200 220)
_m=$(_c 216 140 168);  _x=$(_c 155 135 195)
_d=$(_c 105 88 140);   _f=$(_c 192 209 230)
_t1=$(_c 210 218 238); _t2=$(_c 170 182 210)
_t3=$(_c 130 145 175); _t4=$(_c 106 122 150)

# ── ASCII art - built with printf to avoid quoting issues ────────
typeset -a ART
ART=()
ART+=$(printf '%s       /\\          /\\%s' "$_s" "$R")
ART+=$(printf '%s      /  \\        /  \\%s' "$_s" "$R")
ART+=$(printf '%s     / %s/\\%s\\      / %s/\\%s\\%s' "$_s" "$_p" "$_s" "$_p" "$_s" "$R")
ART+=$(printf '%s    / %s/  \\%s\\    / %s/  \\%s\\%s' "$_s" "$_p" "$_s" "$_p" "$_s" "$R")
ART+=$(printf '%s    |                |%s' "$_f" "$R")
ART+=$(printf '%s    | %s*            * %s|%s' "$_f" "$_b" "$_f" "$R")
ART+=$(printf '%s    |                |%s' "$_f" "$R")
ART+=$(printf '%s    |   %s@@      @@%s   %s|%s' "$_f" "$_e" "$R" "$_f" "$R")
ART+=$(printf '%s    |                |%s' "$_f" "$R")
ART+=$(printf '%s    | %s*            * %s|%s' "$_f" "$_b" "$_f" "$R")
ART+=$(printf '%s    |      %s.w.%s       %s|%s' "$_f" "$_m" "$R" "$_f" "$R")
ART+=$(printf '%s    |                |%s' "$_f" "$R")
ART+=$(printf '%s    |  %s~~~~~~~~~~~~%s  %s|%s' "$_f" "$_x" "$R" "$_f" "$R")
ART+=$(printf '     \\  %s*=======*%s  /' "$_d" "$R")
ART+=$(printf '      \\ %s|       |%s /' "$_f" "$R")
ART+=$(printf '       %s\\|       |/%s' "$_f" "$R")
ART+=$(printf '        %s|       |%s' "$_f" "$R")
ART+=$(printf '  %s/| |\\  %s|=====|%s  %s/| |\\%s' "$_t1" "$_f" "$R" "$_t1" "$R")
ART+=$(printf ' %s/ | | \\ %s|=====|%s %s/ | | \\%s' "$_t1" "$_f" "$R" "$_t1" "$R")
ART+=$(printf '%s/  | |  %s\\|====|/%s  %s| |  \\%s' "$_t1" "$_t2" "$R" "$_t2" "$R")
ART+=$(printf '  %s| |   %s|====|%s  %s| |   \\%s' "$_t2" "$_t3" "$R" "$_t3" "$R")
ART+=$(printf '  %s| |    %s|==|%s   %s| |    \\%s' "$_t3" "$_t3" "$R" "$_t3" "$R")
ART+=$(printf '  %s| |     %s||%s    %s| |     \\%s' "$_t3" "$_t4" "$R" "$_t4" "$R")
ART+=$(printf '  %s|               |      \\%s' "$_t4" "$R")

# ── Data gathering (macOS) ──────────────────────────────────────
get_os() {
    local name ver
    name=$(sw_vers -productName 2>/dev/null) || name="macOS"
    ver=$(sw_vers -productVersion 2>/dev/null) || ver=""
    printf '%s %s' "$name" "$ver"
}

get_kernel() {
    local k
    k=$(uname -r 2>/dev/null) || k="N/A"
    printf '%s' "$k"
}

get_shell() {
    local sh="${SHELL:t}"
    printf '%s' "${sh:-zsh}"
}

get_term() {
    printf '%s' "${TERM_PROGRAM:-${TERM:-N/A}}"
}

get_cpu() {
    local cpu
    cpu=$(sysctl -n machdep.cpu.brand_string 2>/dev/null) || cpu=""
    [[ -z "$cpu" ]] && cpu="Apple Silicon"
    cpu="${cpu//(tm)/}"; cpu="${cpu//(TM)/}"
    cpu="${cpu//(r)/}";  cpu="${cpu//(R)/}"
    printf '%s' "$cpu"
}

get_gpu() {
    local gpu
    gpu=$(system_profiler SPDisplaysDataType 2>/dev/null \
        | grep 'Chipset Model' | head -1 \
        | sed 's/.*: *//')
    printf '%s' "${gpu:-N/A}"
}

get_ram() {
    local pagesize total wired active comp used
    pagesize=$(sysctl -n hw.pagesize 2>/dev/null) || pagesize=4096
    total=$(sysctl -n hw.memsize 2>/dev/null) || total=0
    wired=$(vm_stat 2>/dev/null | grep 'Pages wired down' | sed 's/[^0-9]//g') || wired=0
    active=$(vm_stat 2>/dev/null | grep 'Pages active' | sed 's/[^0-9]//g') || active=0
    comp=$(vm_stat 2>/dev/null | grep 'Pages occupied by compressor' | sed 's/[^0-9]//g') || comp=0
    used=$(( (wired + active + comp) * pagesize ))
    if (( total > 0 )); then
        printf '%dM / %dM' $((used / 1048576)) $((total / 1048576))
    else
        printf 'N/A'
    fi
}

get_uptime() {
    local boot s d h m
    boot=$(sysctl -n kern.boottime 2>/dev/null) || boot=""
    boot=${boot#*=}
    boot=${boot%,*}
    [[ -z "$boot" ]] && { printf 'N/A'; return; }
    (( s = $(date +%s) - boot ))
    (( d = s / 86400 )); (( s = s % 86400 ))
    (( h = s / 3600 ));  (( s = s % 3600 ))
    (( m = s / 60 ))
    printf '%dd %dh %dm' "$d" "$h" "$m"
}

get_pkgs() {
    local n
    n=$(brew list --formula 2>/dev/null | wc -l | tr -d ' ')
    printf '%s' "${n:-N/A}"
}

get_ip() {
    local ip
    ip=$(ipconfig getifaddr en0 2>/dev/null) || ip=""
    [[ -z "$ip" ]] && ip=$(ipconfig getifaddr en1 2>/dev/null) || ip=""
    printf '%s' "${ip:-N/A}"
}

# ── Info formatting ─────────────────────────────────────────────
LBL_W=10
_lc=$(_c 175 203 255)
_vc=$(_c 230 238 248)
_uc=$(_c 175 203 255)
_hc=$(_c 192 209 230)
_sc=$(_c 42  58  94)

_info() {
    local label="$1" value="$2"
    printf '%s%*s%s %s%s%s' "$_lc" "$LBL_W" "$label" "$R" "$_vc" "$value" "$R"
}

# ── Build info array ────────────────────────────────────────────
typeset -a INFO
INFO=()
INFO+=$(printf '%s%s%s@%s%s' "$_uc" "$(whoami)" "$_hc" "$(hostname -s 2>/dev/null || printf 'localhost')" "$R")
INFO+=$(printf '%s──────────────────────%s' "$_sc" "$R")
INFO+=$(_info OS       "$(get_os)")
INFO+=$(_info Kernel   "$(get_kernel)")
INFO+=$(_info Shell    "$(get_shell)")
INFO+=$(_info Terminal "$(get_term)")
INFO+=$(_info CPU      "$(get_cpu)")
INFO+=$(_info GPU      "$(get_gpu)")
INFO+=$(_info RAM      "$(get_ram)")
INFO+=$(_info Uptime   "$(get_uptime)")
INFO+=$(_info Packages "$(get_pkgs)")
INFO+=$(_info IP       "$(get_ip)")

# ── Render side by side ────────────────────────────────────────
art_n=${#ART}
info_n=${#INFO}
info_start=4
max_lines=$art_n
needed=$((info_start + info_n))
if (( needed > max_lines )); then max_lines=$needed; fi

for (( row=1; row<=max_lines; row++ )); do
    if (( row <= art_n )); then
        _pad "${ART[$row]}"
    else
        printf '%*s' "$ART_W" ""
    fi
    printf '%*s' "$GAP" ""
    idx=$(( row - info_start ))
    if (( idx >= 1 && idx <= info_n )); then
        printf '%s\n' "${INFO[$idx]}"
    else
        printf '\n'
    fi
done

# ── Color swatch (10 brand colors) ─────────────────────────────
printf '%*s' "$((ART_W + GAP))" ""
swatch_r=(175 248 230 106 216 192 148  90  15   8)
swatch_g=(203 200 238 143 140 209 128  72  82  59)
swatch_b=(255 220 248 211 168 230 185 120 186 137)
for (( i=1; i<=10; i++ )); do
    ec=$(_c ${swatch_r[$i]} ${swatch_g[$i]} ${swatch_b[$i]})
    printf '%s' "$ec"
    printf '\xe2\x96\x88\xe2\x96\x88'
done
printf '%s\n' "$R"
