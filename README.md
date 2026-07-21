# AygeaNight

A personal terminal theme — Tokyo Night base with Aygea brand accent colors. Baby blue, sapphire, pink, and silver on dark navy. Works on macOS, Ubuntu/Debian, and Arch/CachyOS/Manjaro, in zsh or bash.

<img src="assets/tmux.png" alt="AygeaNight — tmux with system fetch" width="700">

> This is a personal terminal theme for my own machines. It's not a framework or library — just a collection of config files I use daily. If it's useful to you, cool, but I'm not supporting it or taking requests.

## Install

**One command (clone the repo):**

```bash
./install.sh
```

**Or remote (curl pipe — no clone needed):**

```bash
curl -fsSL https://raw.githubusercontent.com/itsaygea/aygeaNights/main/install.sh | bash
```

The installer auto-detects your OS (macOS, Ubuntu/Debian, Arch/CachyOS/Manjaro) and shell (zsh or bash), installs dependencies, and configures tmux, Starship, fonts, and the system fetch. It asks about sudo on Linux; defaults to user-level installs otherwise.

Flags: `--sudo` · `--motd` · `--skip-fonts` · `--skip-tmux` · `--skip-starship` · `--skip-fetch` · `--uninstall`

For the full step-by-step manual process, see [TERMINAL-SETUP.md](TERMINAL-SETUP.md). Run `./install.sh --help` for all options.

## Change the fetch art

`aynight` shows a dot-art laying fox by default. Switch designs with a flag:

```bash
aynight --fox        # laying fox        (default)
aynight --fox-inv    # inverted laying fox
aynight --face       # bordered fox face
aynight --face-inv   # inverted blob face
aynight --art face   # same as --face
aynight --help       # all options
```

Or set it permanently: `export AYNIGHT_ART=face` in your shell rc. The raw art lives in `aynight/art/*.txt` — edit those and the dev script picks up changes; re-run the installer to bake edits into the installed binary.

Optional **Login MOTD** step (`--motd`, Linux + sudo) runs `aynight` at every SSH/console login. It asks Yes/No before writing, backs up `/etc/motd`, and `--uninstall` restores it.

## What's included

| File | What it does |
|---|---|
| `AygeaNight.itermcolors` | iTerm2 color scheme |
| `tmux.conf` | tmux status bar and colors |
| `starship.toml` | Shell prompt theme |
| `aynight/aynight-macos.sh` | System fetch wrapper for macOS |
| `aynight/aynight-ubuntu.sh` | System fetch wrapper for Ubuntu / Debian / Pop |
| `aynight/aynight-arch.sh` | System fetch wrapper for Arch / CachyOS / Manjaro |
| `aynight/_aynight_core.sh` | Shared fetch engine (art, info, dot-meters) |
| `aynight/art/*.txt` | Dot-art fox + face designs (regular + inverted) |

## Font

JetBrainsMono Nerd Font. Bundled in `fonts/JetBrainsMono/` if you clone; downloaded automatically from [Nerd Fonts](https://www.nerdfonts.com/) if you curl-pipe. Either way: set **JetBrainsMono Nerd Font** in your terminal emulator after install.

## Colors

Baby Blue `#AFCBFF` · Soft Pink `#F8C8DC` · Silver `#E6EEF8` · Sapphire `#6A8FD3` · Pink Dark `#D88CA8` · Silver Dark `#C0D1E6` · Purple `#9480B9` · Purple Dark `#5A4878` · Deep Sapphire `#0F52BA` · Sapphire Dark `#083B89`

Background: Tokyo Night base `#0F1020`

## Screenshots

| | |
|---|---|
| tmux + fetch | `assets/tmux.png` |
| tmux (tabs) | `assets/tmux_1.png` |
| fox | `assets/fox.png` |
| fox (inverted) | `assets/fox-inv.png` |
| face | `assets/face.png` |
| face (inverted) | `assets/face-inv.png` |
