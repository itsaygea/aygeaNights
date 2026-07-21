#!/usr/bin/env bash
# ╭──────────────────────────────────────────────────────────────╮
# │  art-convert.sh · image → braille dot-art for aynight         │
# │                                                              │
# │  Turns a PNG/JPG into a braille .txt the fetch can render.    │
# │  Drop the output in fetch/art/<name>.txt, then run            │
# │  `aynight --<name>`.                                         │
# │                                                              │
# │  Usage:                                                      │
# │    ./art-convert.sh <image> <name> [width] [--invert]         │
# │                                                              │
# │  Examples:                                                   │
# │    ./art-convert.sh sprite.png jirachi                       │
# │    ./art-convert.sh sprite.png jirachi-inv 40 --invert        │
# │                                                              │
# │  Requires one of: chafa (best), jp2a+imagemagick, img2txt.   │
# │  The script auto-detects which is installed.                  │
# ╰──────────────────────────────────────────────────────────────╯
set -euo pipefail

if [[ $# -lt 2 ]]; then
    cat <<'EOF'
art-convert.sh — image to braille dot-art

Usage: ./art-convert.sh <image> <name> [width] [--invert]
  image    PNG/JPG/etc source
  name     output name (writes fetch/art/<name>.txt)
  width    target width in chars (default 40; braille = 2px/char)
  --invert dark-on-light source (negate before converting)

Examples:
  ./art-convert.sh jirachi.png jirachi
  ./art-convert.sh jirachi.png jirachi-inv 40 --invert
EOF
    exit 0
fi

IMG="$1"
NAME="$2"
WIDTH="${3:-40}"
INVERT=0
[[ "${4:-}" == "--invert" ]] && INVERT=1

[[ -f "$IMG" ]] || { echo "image not found: $IMG" >&2; exit 1; }

# Resolve art dir (beside this script)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ART_DIR="$SCRIPT_DIR"
[[ "$ART_DIR" == *fetch ]] && ART_DIR="$SCRIPT_DIR/art"
[[ -d "$ART_DIR" ]] || ART_DIR="$SCRIPT_DIR"

OUT="$ART_DIR/$NAME.txt"
TMP="$(mktemp)"
trap 'rm -f "$TMP" "$TMP.ppm"' EXIT

# ── Negate if needed (for --invert / dark subjects on light bg) ──
SRC="$IMG"
if [[ $INVERT -eq 1 ]] && command -v convert >/dev/null 2>&1; then
    convert "$IMG" -negate "$TMP.ppm"
    SRC="$TMP.ppm"
fi

echo "Converting $IMG → $OUT (width=$WIDTH, invert=$INVERT)..."

# ── chafa: best braille output ──
if command -v chafa >/dev/null 2>&1; then
    chafa --format symbols --symbols braille --size "${WIDTH}x" \
          --threshold-mode=median --fill=solid "$SRC" \
          | sed '/^[[:space:]]*$/d' > "$OUT"

# ── jp2a (ASCII fallback, not braille but usable) ──
elif command -v jp2a >/dev/null 2>&1; then
    echo "chafa not found — using jp2a (ASCII, not braille dots)" >&2
    jp2a --width="$WIDTH" --colors=none "$SRC" \
        | sed '/^[[:space:]]*$/d' > "$OUT"

# ── img2txt (libcaca) fallback ──
elif command -v img2txt >/dev/null 2>&1; then
    echo "chafa not found — using img2txt" >&2
    img2txt -W "$WIDTH" -f utf8 "$SRC" \
        | sed '/^[[:space:]]*$/d' > "$OUT"
else
    cat >&2 <<EOF
No image-to-text tool found. Install one:
  chafa    (best — true braille dots)   Debian: apt install chafa
                                      Arch:   pacman -S chafa
                                      macOS:  brew install chafa
  jp2a     (ASCII fallback)             apt install jp2a
  img2txt  (libcaca, ASCII fallback)    apt install caca-utils
EOF
    exit 1
fi

# ── Tidy: strip trailing spaces, drop empty lines, trim to <=30 rows ──
sed -i 's/[[:space:]]*$//' "$OUT"
sed -i '/^[[:space:]]*$/d' "$OUT"
# Keep first 30 rows so it fits beside the info column
if [[ $(wc -l < "$OUT") -gt 30 ]]; then
    head -30 "$OUT" > "$TMP" && mv "$TMP" "$OUT"
fi

ROWS=$(wc -l < "$OUT" | tr -d ' ')
COLS=$(head -1 "$OUT" | wc -m | tr -d ' ')
echo
echo "✓ wrote $OUT"
echo "  $ROWS rows × ${COLS} cols"
echo
echo "Preview with:"
echo "  aynight --$NAME"
echo
echo "To make the inverted twin:"
echo "  ./art-convert.sh \"$IMG\" \"$NAME-inv\" \"$WIDTH\" --invert"
