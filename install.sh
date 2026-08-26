#!/usr/bin/env bash
set -euo pipefail

BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Copy WhiteSur themes"
mkdir -p "$HOME/.themes"
cp -a "$BASE"/themes/WhiteSur-Light* "$HOME/.themes/"
cp -a "$BASE"/themes/Tahoe-Dark* "$HOME/.themes/"

echo "==> Copy WhiteSur icons and McMojave cursors"
mkdir -p "$HOME/.local/share/icons"
cp -a "$BASE"/icons/WhiteSur* "$HOME/.local/share/icons/"
cp -a "$BASE/icons/McMojave-cursors" "$HOME/.local/share/icons/"

echo "==> Copy GNOME Shell extensions"
mkdir -p "$HOME/.local/share/gnome-shell/extensions"
for ext in "$BASE"/extensions/*; do
    [ -d "$ext" ] || continue
    name="$(basename "$ext")"
    cp -a "$ext" "$HOME/.local/share/gnome-shell/extensions/$name"
    if [ -d "$HOME/.local/share/gnome-shell/extensions/$name/schemas" ]; then
        glib-compile-schemas "$HOME/.local/share/gnome-shell/extensions/$name/schemas" || true
    fi
done

echo "==> Copy Plank autostart"
mkdir -p "$HOME/.config/autostart"
cp -a "$BASE/configs/autostart/plank.desktop" "$HOME/.config/autostart/"

echo "==> Copy GTK configuration"
mkdir -p "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0"
cp -a "$BASE/configs/gtk-3.0/." "$HOME/.config/gtk-3.0/"
cp -a "$BASE/configs/gtk-4.0/." "$HOME/.config/gtk-4.0/"

echo "==> Copy wallpapers"
mkdir -p "$HOME/.local/share/backgrounds/Tahoe"
cp -a "$BASE/wallpapers/Tahoe-5k-dark.jpg" "$HOME/.local/share/backgrounds/Tahoe/"
cp -a "$BASE/wallpapers/Blue_flower_by_Elena_Stravoravdi.jpg" "$HOME/.local/share/backgrounds/"

echo "==> Install Minimal-Mojave dynamic wallpaper"
mkdir -p "$HOME/.local/share/backgrounds/gnome/Minimal-Mojave-timed"
mkdir -p "$HOME/.local/share/gnome-background-properties"
cp -a "$BASE/wallpapers/Minimal-Mojave/"*.jpeg "$HOME/.local/share/backgrounds/gnome/Minimal-Mojave-timed/"
sed "s+__LOCATION__+$HOME/.local/share+g" \
    "$BASE/wallpapers/Minimal-Mojave/Minimal-Mojave-timed.xml" \
    > "$HOME/.local/share/backgrounds/gnome/Minimal-Mojave-timed.xml"
sed "s+__LOCATION__+$HOME/.local/share+g" \
    "$BASE/wallpapers/Minimal-Mojave/Minimal-Mojave.xml" \
    > "$HOME/.local/share/gnome-background-properties/Minimal-Mojave.xml"

echo "==> Install Minimal-Mojave live wallpaper"
mkdir -p "$HOME/.local/share/backgrounds/Minimal-Mojave-Live" "$HOME/.local/bin"
cp -a "$BASE/wallpapers/Minimal-Mojave/Minimal-Mojave-live.mp4" "$HOME/.local/share/backgrounds/Minimal-Mojave-Live/"
cp -a "$BASE/tools/minimal-mojave-live.sh" "$HOME/.local/bin/"
chmod +x "$HOME/.local/bin/minimal-mojave-live.sh"
mkdir -p "$HOME/.config/systemd/user"
cp -a "$BASE/configs/systemd/minimal-mojave-live.service" "$HOME/.config/systemd/user/"
systemctl --user daemon-reload

echo "==> Apply dconf settings"
dconf load /net/launchpad/plank/ < "$BASE/configs/dconf/plank-dconf.txt"
dconf load /org/gnome/shell/extensions/ < "$BASE/configs/dconf/extensions-dconf.txt"
dconf load /org/gnome/shell/ < "$BASE/configs/dconf/shell-dconf.txt"

echo "==> Apply theme gsettings"
export GSETTINGS_SCHEMA_DIR="/usr/share/glib-2.0/schemas:$HOME/.local/share/gnome-shell/extensions/user-theme@gnome-shell-extensions.gcampax.github.com/schemas"
gsettings set org.gnome.desktop.interface gtk-theme 'WhiteSur-Light-solid'
gsettings set org.gnome.desktop.interface icon-theme 'WhiteSur-dark'
gsettings set org.gnome.desktop.interface cursor-theme 'McMojave-cursors'
gsettings set org.gnome.desktop.interface color-scheme 'prefer-light'
gsettings set org.gnome.shell.extensions.user-theme name 'WhiteSur-Light-solid'
gsettings set org.gnome.desktop.background picture-uri "file://$HOME/.local/share/backgrounds/gnome/Minimal-Mojave-timed.xml"
gsettings set org.gnome.desktop.background picture-uri-dark "file://$HOME/.local/share/backgrounds/gnome/Minimal-Mojave-timed.xml"

echo
echo "Done. Restart GNOME Shell or log out/in to make it visible:"
echo "  kill -HUP \$(pgrep -x gnome-shell | head -1)"
echo
echo "Live wallpaper is installed but disabled by default:"
echo "  systemctl --user start minimal-mojave-live.service"
