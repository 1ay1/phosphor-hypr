#!/usr/bin/env bash
# ============================================================================
#  wear — one-command installer for the whole desktop.
#  Everything themed: Hyprland, Waybar, Kitty, Rofi, Dunst, GTK 3/4, Qt 5/6,
#  KDE apps, cursors, icons, wallpaper. Safe: backs up whatever it replaces.
#
#  Usage:  ./install.sh [--theme <name>] [--skip-pkgs]
# ============================================================================
set -euo pipefail

# --- pretty output -----------------------------------------------------------
GREEN='\033[0;32m'; BOLD='\033[1m'; DIM='\033[2m'; RED='\033[0;31m'; NC='\033[0m'
say()  { echo -e "${GREEN}${BOLD}::${NC} $*"; }
info() { echo -e "   ${DIM}$*${NC}"; }
warn() { echo -e "${RED}!!${NC} $*"; }

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CFG="$HOME/.config"
BACKUP="$HOME/.phosphor-backup/$(date +%Y%m%d-%H%M%S)"

# --- flags -------------------------------------------------------------------
WANT_THEME="${PHOSPHOR_THEME:-}"
SKIP_PKGS="${PHOSPHOR_SKIP_PKGS:-0}"
while [ $# -gt 0 ]; do
  case "$1" in
    --theme)     WANT_THEME="${2:-}"; shift 2 ;;
    --theme=*)   WANT_THEME="${1#*=}"; shift ;;
    --skip-pkgs) SKIP_PKGS=1; shift ;;
    -h|--help)   echo "usage: ./install.sh [--theme <name>] [--skip-pkgs]"; exit 0 ;;
    *) warn "unknown flag: $1"; shift ;;
  esac
done

# --- sanity ------------------------------------------------------------------
if ! command -v pacman >/dev/null 2>&1; then
  warn "This setup targets Arch-based distros (pacman). Aborting."; exit 1
fi

# --- 1. packages -------------------------------------------------------------
PKGS_REPO=(
  hyprland hyprlock hypridle
  xdg-desktop-portal-hyprland xdg-desktop-portal-gtk xdg-desktop-portal
  waybar dunst rofi kitty alacritty
  qt5ct qt6ct kvantum qt5-wayland qt6-wayland
  papirus-icon-theme bibata-cursor-theme
  ttf-jetbrains-mono-nerd ttf-firacode-nerd ttf-nerd-fonts-symbols
  wl-clipboard cliphist grim slurp polkit-gnome network-manager-applet blueman libnotify
  satty wf-recorder jq fzf imagemagick hyprpicker wlogout brightnessctl playerctl
  pipewire wireplumber dolphin gvfs libcanberra
  glib2 python
  python-gobject gtk4 libadwaita   # native GTK4 appearance GUI (wear-gui)
  adw-gtk-theme                    # neutral GTK3 base recoloured by the palette
)
PKGS_AUR=(
  neowall-git                 # GPU shader wallpaper daemon
  papirus-folders             # recolors Papirus folders green
)

install_pkgs() {
  say "Installing packages"
  local helper=""
  for h in paru yay; do command -v "$h" >/dev/null 2>&1 && helper="$h" && break; done

  info "Syncing official repo packages (sudo)…"
  sudo pacman -S --needed --noconfirm "${PKGS_REPO[@]}" || warn "some repo pkgs failed (continuing)"

  if [ -n "$helper" ]; then
    info "Installing AUR packages via $helper…"
    "$helper" -S --needed --noconfirm "${PKGS_AUR[@]}" || warn "AUR install failed (neowall optional)"
  else
    warn "No AUR helper (paru/yay) found — skipping: ${PKGS_AUR[*]}"
    warn "Install neowall manually for the animated wallpaper, or the theme works without it."
  fi
}

# --- 2. backup + link/copy configs -------------------------------------------
backup() {   # $1 = target path to preserve if it exists
  [ -e "$1" ] || return 0
  mkdir -p "$BACKUP/$(dirname "${1#$HOME/}")"
  cp -a "$1" "$BACKUP/${1#$HOME/}"
}

deploy_config() {
  say "Deploying theme configs (backups → $BACKUP)"
  mkdir -p "$CFG"
  # copy each top-level dir under config/ into ~/.config, backing up first.
  # Template (*.tmpl) files stay in the repo — `wear` renders them.
  for src in "$REPO_DIR"/config/*/; do
    name="$(basename "$src")"
    dest="$CFG/$name"
    backup "$dest"
    mkdir -p "$dest"
    cp -a "$src." "$dest/"
    find "$dest" -name '*.tmpl' -delete 2>/dev/null || true
    info "~/.config/$name"
  done

  # substitute __HOME__ placeholder in templated configs
  sed -i "s|__HOME__|$HOME|g" \
    "$CFG/qt5ct/qt5ct.conf" "$CFG/qt6ct/qt6ct.conf" 2>/dev/null || true

  # make hypr helper scripts (screenshot/record) executable
  chmod +x "$CFG"/hypr/scripts/*.sh 2>/dev/null || true
}

# --- GPU auto-detection: NVIDIA env vars only where they belong ---------------
tune_gpu() {
  local conf="$CFG/hypr/hyprland.conf" have_nvidia=0
  [ -f "$conf" ] || return 0
  if [ -d /proc/driver/nvidia ] || lsmod 2>/dev/null | grep -q '^nvidia' \
     || lspci 2>/dev/null | grep -qi 'vga.*nvidia\|3d.*nvidia'; then
    have_nvidia=1
  fi
  if [ "$have_nvidia" = 1 ]; then
    say "NVIDIA GPU detected — keeping NVIDIA env vars"
  else
    say "No NVIDIA GPU — disabling NVIDIA-specific env vars"
    sed -i -E 's@^(env = (LIBVA_DRIVER_NAME,nvidia|__GLX_VENDOR_LIBRARY_NAME,nvidia|NVD_BACKEND,direct).*)@# \1  # disabled: no NVIDIA GPU@' "$conf"
  fi
}

deploy_local_bin() {
  say "Installing helper scripts to ~/.local/bin"
  mkdir -p "$HOME/.local/bin"
  if [ -d "$REPO_DIR/home/local-bin" ]; then
    for s in "$REPO_DIR"/home/local-bin/*; do
      [ -e "$s" ] || continue
      case "$(basename "$s")" in __pycache__) continue ;; esac
      cp -a "$s" "$HOME/.local/bin/"
      chmod +x "$HOME/.local/bin/$(basename "$s")"
      info "~/.local/bin/$(basename "$s")"
    done
  fi
  # record where the repo lives so `wear` finds its themes/templates forever
  mkdir -p "$CFG/phosphor"
  echo "$REPO_DIR" > "$CFG/phosphor/repo"
  # ~/.local/bin on PATH? warn if not (most shells have it, but be sure)
  case ":$PATH:" in
    *":$HOME/.local/bin:"*) : ;;
    *) warn '~/.local/bin is not on your PATH — add: export PATH="$HOME/.local/bin:$PATH"' ;;
  esac
  # screenshot + recording target dirs (hyprland binds)
  mkdir -p "$HOME/Pictures/Screenshots" "$HOME/Videos/Recordings"
}

deploy_home() {
  say "Deploying home-level files (kdeglobals)"
  backup "$HOME/.config/kdeglobals"
  cp -a "$REPO_DIR/home/kdeglobals" "$CFG/kdeglobals"
  info "~/.config/kdeglobals"
}

deploy_kde_scheme() {
  say "Installing KDE color scheme dir"
  mkdir -p "$HOME/.local/share/color-schemes"
  # `wear` renders the active scheme here; ship a baseline too
  [ -f "$REPO_DIR/kde/color-schemes/Phosphor.colors" ] && \
    cp -a "$REPO_DIR/kde/color-schemes/Phosphor.colors" "$HOME/.local/share/color-schemes/" 2>/dev/null || true
}

# --- deploy theme palettes + render the active theme -------------------------
deploy_themes() {
  say "Installing wear + palettes"
  # themes/ palettes are read by `wear` straight from the repo, so nothing to
  # copy here — just render the chosen/active/default theme now.
  local want="$WANT_THEME"
  if [ -z "$want" ] && [ -f "$CFG/phosphor/theme" ]; then
    # existing install: re-render the current look WITH live tweaks intact
    info "re-rendering current theme: $(cat "$CFG/phosphor/theme") (tweaks kept)"
    PHOSPHOR_REPO="$REPO_DIR" "$HOME/.local/bin/wear" reload >/dev/null 2>&1 \
      || warn "theme render failed (run: wear reload)"
    return 0
  fi
  [ -z "$want" ] && want="phosphor"
  info "rendering theme: $want"
  # run the freshly-installed switcher; PHOSPHOR_REPO points at this checkout
  PHOSPHOR_REPO="$REPO_DIR" "$HOME/.local/bin/wear" "$want" >/dev/null 2>&1 \
    || warn "theme render failed (run: wear $want)"
}

# --- 3. icons: green Papirus folders -----------------------------------------
# These need root (theme lives in /usr/share/icons). NEVER block on a sudo
# password prompt here — if we can't sudo non-interactively and have no TTY,
# skip: it's cosmetic and re-runnable.
_can_sudo() { sudo -n true 2>/dev/null || [ -t 0 ]; }

apply_icons() {
  say "Setting Papirus folders to green"
  if ! _can_sudo; then
    info "skipping (needs sudo, no interactive terminal) — run later: papirus-folders -C green --theme Papirus-Dark"
    return 0
  fi
  if command -v papirus-folders >/dev/null 2>&1; then
    papirus-folders -C green --theme Papirus-Dark >/dev/null 2>&1 || warn "papirus-folders failed"
  else
    info "papirus-folders not installed — skipping (install it for green folders)"
  fi
  command -v gtk-update-icon-cache >/dev/null 2>&1 && \
    sudo gtk-update-icon-cache -f /usr/share/icons/Papirus-Dark >/dev/null 2>&1 || true
}

# --- 4. gsettings handled by `wear` (per-theme) --------------------------------
# (kept as a no-op fallback if wear didn't run)
apply_gsettings() {
  command -v gsettings >/dev/null 2>&1 || return 0
  local S=org.gnome.desktop.interface
  gsettings set $S font-name 'JetBrainsMono Nerd Font 10' 2>/dev/null || true
}

# --- 5. Kvantum theme --------------------------------------------------------
apply_kvantum() {
  command -v kvantummanager >/dev/null 2>&1 || return 0
  say "Setting Kvantum theme (optional Sweet)"
  info "Kvantum config deployed; Qt uses Fusion+Phosphor by default."
}

# --- run ---------------------------------------------------------------------
main() {
  echo -e "${GREEN}${BOLD}"
  echo "  ┌────────────────────────────────────────────┐"
  echo "  │   wear  ·  one palette, your whole desktop   │"
  echo "  └────────────────────────────────────────────┘"
  echo -e "${NC}"

  if [ "$SKIP_PKGS" != "1" ]; then
    # ask for the sudo password ONCE, up front, from the real terminal
    if ! sudo -n true 2>/dev/null; then
      if [ -t 0 ]; then
        say "This needs sudo for packages + icon cache — asking once now"
        sudo -v || { warn "sudo failed — rerun, or use --skip-pkgs"; exit 1; }
      else
        warn "No terminal for the sudo prompt — skipping package install."
        warn "Run again from a terminal, or: sudo pacman -S ... (see install.sh)"
        SKIP_PKGS=1
      fi
    fi
  fi
  if [ "$SKIP_PKGS" != "1" ]; then install_pkgs; else say "Skipping package install (--skip-pkgs)"; fi

  deploy_config
  tune_gpu
  deploy_local_bin
  deploy_home
  deploy_kde_scheme
  deploy_themes
  apply_icons
  apply_gsettings
  apply_kvantum

  echo
  say "Done! 🟢"
  echo -e "   Backups of anything overwritten: ${BOLD}$BACKUP${NC}"
  echo
  if [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ] && command -v hyprctl >/dev/null 2>&1; then
    say "You're inside Hyprland — reloading now"
    hyprctl reload >/dev/null 2>&1 || true
    pkill -x waybar 2>/dev/null || true; sleep 0.4
    (waybar >/dev/null 2>&1 &) || true
    echo -e "   The new look is ${BOLD}live${NC}. Qt/KDE apps pick it up after relogin."
  else
    echo -e "   ${BOLD}Log in to Hyprland${NC} and everything is themed from the first frame."
  fi
  echo
  echo -e "   → ${BOLD}wear${NC}            theme picker      (also ${BOLD}Super+Shift+T${NC})"
  echo -e "   → ${BOLD}wear tweak${NC}      live GUI editor   (also ${BOLD}Super+A${NC})"
  echo -e "   → ${BOLD}wear random${NC}     dice-roll the whole look · ${BOLD}wear undo${NC} to revert"
  echo -e "   → ${BOLD}wear from <img>${NC}  a full theme from any wallpaper"
  echo
}

main
