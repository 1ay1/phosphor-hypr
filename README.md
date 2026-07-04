<div align="center">

# 🟢 PHOSPHOR

### A themeable Hyprland desktop — switch EVERYTHING with one command

One palette drives your **entire** desktop — Hyprland, Waybar, Kitty, Rofi,
Dunst, GTK 3/4, Qt 5/6, KDE apps, hyprlock, satty, wlogout, cursors, icons, and
an animated GPU-shader wallpaper. Ships with **7 themes** (Phosphor, Tokyo
Night, Gruvbox, Catppuccin Mocha & Latte, Nord, Rosé Pine) and a `theme`
switcher that repaints all of it live. Nothing left un-themed.

![Phosphor desktop](assets/screenshot-1.png)
![Phosphor desktop](assets/screenshot-2.png)

</div>

---

## ⚡ One-command install

```sh
git clone https://github.com/1ay1/phosphor-hypr.git && cd phosphor-hypr && ./install.sh
```

or, straight from the web:

```sh
curl -fsSL https://raw.githubusercontent.com/1ay1/phosphor-hypr/main/bootstrap.sh | bash
```



The installer will:

1. Install every package the theme needs (repo + AUR via `paru`/`yay`)
2. **Back up** anything it's about to overwrite → `~/.phosphor-backup/<timestamp>/`
3. Copy all configs into `~/.config` (templates stay in the repo)
4. Install the `theme` switcher to `~/.local/bin` and **render the active theme**
5. Recolor **Papirus** folders and refresh the icon cache

---

## 🎨 Switching themes

```sh
theme                 # rofi/fzf picker (also bound to Super+Shift+T)
theme tokyo-night     # switch directly
theme list            # list available themes
theme current         # print the active theme
theme reload          # re-apply (after editing a palette)
```

Switching repaints **everything at once** — Hyprland borders/shadows, hyprlock,
waybar, rofi, dunst, kitty (live), GTK 3/4, Qt 5/6, the KDE colour scheme,
satty, wlogout, and the wallpaper shader — then reloads the running apps.

**Built-in themes:** `phosphor` · `tokyo-night` · `gruvbox` ·
`catppuccin-mocha` · `catppuccin-latte` (light) · `nord` · `rose-pine`

### Add your own

A theme is a single flat file. Copy one and edit the ~26 colour keys:

```sh
cp themes/nord.theme themes/my-theme.theme
$EDITOR themes/my-theme.theme      # hex values, no leading '#'
theme my-theme
```

Every colour-bearing config is a `*.tmpl` template with `{{key}}` placeholders
(and `{{key|rgb}}` for KDE's decimal format); the switcher renders them into
`~/.config` for the palette you pick.

---

## 🖥️ What's included

| Component | What it themes |
|-----------|----------------|
| `hypr/`   | Hyprland WM, hyprlock, hypridle |
| `waybar/` | Status bar (+ GPU script) |
| `kitty/`  | Terminal colors |
| `rofi/`   | App launcher (phosphor.rasi) |
| `dunst/`  | Notifications |
| `gtk-3.0/`, `gtk-4.0/` | GTK apps (Thunar, Nautilus, …) — full phosphor surfaces + green selection |
| `qt5ct/`, `qt6ct/` | Qt apps via Fusion + Phosphor color scheme |
| `Kvantum/` | Optional Kvantum theme |
| `kde/`    | KDE Plasma **Phosphor** color scheme (Dolphin, Kate, …) |
| `neowall/` | Animated GPU-shader wallpaper (matrix/synthwave/phosphor) |
| `wlogout/` | Themed logout menu |
| `satty/` | Screenshot annotation editor (grim+slurp → satty; Ctrl+C copies & saves) |
| `hypr/scripts/` | `screenshot.sh` (grim→satty) & `record.sh` (wf-recorder toggle, NVENC) |
| `~/.local/bin/` | `theme` (switcher) & `shader-switch.sh` (wallpaper picker) |
| `themes/` | Palette files (`*.theme`) — one per theme, ~26 colour keys each |
| `config/**/*.tmpl` | Templates the switcher renders into `~/.config` per theme |

Fonts: **JetBrainsMono Nerd Font** · Cursor: **Bibata-Modern-Amber** · Icons: **Papirus-Dark (green folders)**

---

## 🎨 The palette schema

Each `themes/*.theme` defines the same ~26 keys (hex, no `#`). Core roles:

| Key | Role |
|-----|------|
| `bg` / `bg_alt` / `bg_dim` | surfaces (darkest → panels) |
| `surface` / `overlay` | borders, hover fills |
| `fg` / `fg_dim` / `fg_faint` | text (primary → faint) |
| `accent` / `accent2` / `accent3` | primary / secondary / tertiary accents |
| `red green yellow blue magenta cyan` | semantic + ANSI |
| `br_*` | bright ANSI variants (terminal color8–15) |
| `on_accent` | text drawn on top of an accent fill |
| `mode` | `dark` or `light` (drives GTK/Qt dark hint) |
| `wallpaper_shader` | neowall shader to load for this theme |

---

## 🔧 Notes & customization

- **NVIDIA:** `hypr/hyprland.conf` sets NVIDIA env vars. On AMD/Intel, comment out
  the `LIBVA_DRIVER_NAME`, `__GLX_VENDOR_LIBRARY_NAME`, and `NVD_BACKEND` lines.
- **Qt/KDE:** after install, **log out and back in** so `QT_QPA_PLATFORMTHEME=qt6ct`
  and the color scheme apply to Qt6 apps.
- **Skip packages:** `PHOSPHOR_SKIP_PKGS=1 ./install.sh` deploys configs only.
- **Restore:** everything overwritten is in `~/.phosphor-backup/<timestamp>/`.

---

## 📦 Dependencies

Installed automatically: `hyprland hyprlock hypridle waybar dunst rofi kitty
alacritty qt5ct qt6ct kvantum papirus-icon-theme bibata-cursor-theme
ttf-jetbrains-mono-nerd ttf-firacode-nerd satty grim slurp wf-recorder jq fzf hyprpicker wlogout
brightnessctl playerctl pipewire wireplumber dolphin wl-clipboard cliphist
polkit-gnome libnotify` · AUR: `neowall-git catppuccin-gtk-theme-mocha catppuccin-gtk-theme-latte papirus-folders`

---

<div align="center"><sub>Take the red pill. 🔴 → 🟢</sub></div>
