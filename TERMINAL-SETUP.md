# AygeaNight Terminal Setup Guide

Tokyo Night base · Aygea brand accent colors
Baby blue, sapphire, pink, silver — dark navy background

> **The recommended way to install is the automated installer: `./install.sh`**
> This guide covers the manual step-by-step process for reference or customization.

---

## Files in this repo

| File | Goes to | What it does |
|---|---|---|
| `AygeaNight.itermcolors` | double-click to install | iTerm2 color scheme |
| `tmux.conf` | `~/.tmux.conf` | tmux status bar + colors |
| `starship.toml` | `~/.config/starship.toml` | shell prompt |
| `fetch/aygeafetch.zsh` | macOS system fetch | fox + system info |
| `fetch/aygeafetch-ubuntu.sh` | Ubuntu system fetch | fox + system info |
| `fetch/aygeafetch-arch.sh` | Arch system fetch | fox + system info |

---

## Step 1 — Install a Nerd Font (required for icons)

Without this you'll see boxes or `>` instead of icons and powerline arrows in tmux and Starship.

1. Go to https://www.nerdfonts.com/font-downloads
2. Download **JetBrainsMono Nerd Font**
3. Unzip and double-click each `.ttf` file to install via Font Book
4. In iTerm2: Preferences → Profiles → Text → Font → select **JetBrainsMono Nerd Font**
   - Check "Use a different font for non-ASCII text" → same font

---

## Step 2 — Install iTerm2 color scheme (macOS only)

1. Double-click `AygeaNight.itermcolors` — iTerm2 imports it automatically
2. iTerm2 → Preferences → Profiles → Colors → Color Presets → **AygeaNight**

Optional vibe tweaks:
- Profiles → Window → Transparency: ~10–15%
- Profiles → Window → Blur: ~20
- Profiles → Window → Background image: drag any image, set opacity ~8%

---

## Step 3 — Set up tmux

```bash
cp tmux.conf ~/.tmux.conf
tmux kill-server
tmux
```

Reload from inside tmux any time with `Ctrl+A then R`.

---

## Step 4 — Starship prompt

### macOS (zsh)

```bash
brew install starship
mkdir -p ~/.config
cp starship.toml ~/.config/starship.toml
echo 'eval "$(starship init zsh)"' >> ~/.zshrc
source ~/.zshrc
```

### Linux — Ubuntu

```bash
curl -sS https://starship.rs/install.sh | sh
mkdir -p ~/.config
cp starship.toml ~/.config/starship.toml
```

Add to `~/.bashrc` **above everything else**:

```bash
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export TERM=xterm-256color
export COLORTERM=truecolor
```

Then add starship at the **very end** of `~/.bashrc`:

```bash
eval "$(starship init bash)"
```

**Locale setup (required — fixes broken ╭─ ╰─ ❯ inside tmux):**

```bash
sudo apt-get install -y locales
sudo locale-gen en_US.UTF-8
sudo update-locale LANG=en_US.UTF-8
# must fully log out and back in — source alone is not enough
tmux kill-server
tmux
```

### Linux — Arch

```bash
curl -sS https://starship.rs/install.sh | sh
mkdir -p ~/.config
cp starship.toml ~/.config/starship.toml
```

Add to `~/.bashrc` **above everything else**:

```bash
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export TERM=xterm-256color
export COLORTERM=truecolor
```

Then add at the **very end**:
```bash
eval "$(starship init bash)"
```

**Locale setup on Arch** (different from Ubuntu — no package needed):

```bash
sudo nano /etc/locale.gen
# uncomment this line:
# en_US.UTF-8 UTF-8
sudo locale-gen
sudo localectl set-locale LANG=en_US.UTF-8
# log out and back in
tmux kill-server
tmux
```

---

## Step 5 — Fetch Scripts (optional — system info with fox mascot)

Three self-contained fetch scripts that display a chibi white fox kitsune alongside your system info in AygeaNight brand colors. No dependencies — pure shell.

| File | Platform | Shell |
|---|---|---|
| `fetch/aygeafetch.zsh` | macOS | zsh |
| `fetch/aygeafetch-ubuntu.sh` | Ubuntu Linux | bash |
| `fetch/aygeafetch-arch.sh` | Arch Linux | bash |

### macOS (zsh)

```bash
chmod +x fetch/aygeafetch.zsh
cp fetch/aygeafetch.zsh ~/aygeafetch.zsh
```

Add to `~/.zshrc` (at the end):

```bash
aygeafetch
# or: source ~/aygeafetch.zsh
```

### Ubuntu (bash)

```bash
chmod +x fetch/aygeafetch-ubuntu.sh
sudo cp fetch/aygeafetch-ubuntu.sh /usr/local/bin/aygeafetch
```

Add to `~/.bashrc` (at the end):

```bash
aygeafetch
```

### Arch Linux (bash)

```bash
chmod +x fetch/aygeafetch-arch.sh
sudo cp fetch/aygeafetch-arch.sh /usr/local/bin/aygeafetch
```

Add to `~/.bashrc` (at the end):

```bash
aygeafetch
```

---

## Troubleshooting

**Icons showing as boxes/squares:**
→ Nerd Font not set in iTerm2. Preferences → Profiles → Text → Font.

**Powerline arrows showing as `>` or `?`:**
→ Same as above — Nerd Font required.

**╭─ ╰─ showing as `_─` or garbled in tmux:**
→ Locale not installed. Follow the locale setup steps for your distro. Must log out completely, not just source.

**tmux colors look wrong / still greenish:**
→ Run `tmux kill-server` then start fresh. Sourcing `.tmux.conf` alone doesn't always apply all color changes.

**Selection highlight invisible in tmux:**
→ Check `~/.tmux.conf` has: `set -g mode-style "fg=#0F1020,bg=#AFCBFF,bold"`

**Prompt not drawing correctly inside tmux:**
→ Make sure `TERM` and `COLORTERM` exports are at the top of `~/.bashrc` before everything else, then `tmux kill-server` and start fresh.

**Starship not loading:**
→ The eval line must be at the very END of your rc file, after all exports.

**Locale error: `cannot change locale (en_US.UTF-8)`:**
→ The locale isn't generated yet. Run the locale setup steps for your distro above.

**Mac prompt has unwanted gap between ╭─ and ╰─:**
→ Remove any blank line or trailing `\` after `$time` in `~/.config/starship.toml`.

**tmux prefix key:**
→ This config uses `Ctrl+A` instead of the tmux default `Ctrl+B`.

---

*AygeaNight — built March 2026* 🦊
