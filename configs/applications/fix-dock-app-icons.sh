#!/usr/bin/env bash
set -euo pipefail

DRY_RUN=0
TARGET=""

usage() {
  cat <<EOF
Usage: $0 {edge|terminator|todesk|all} [--dry-run]

Fix common duplicate Dock icons for installed desktop applications.

Targets:
  edge        keep com.microsoft.Edge.desktop as the visible/default Edge entry
  terminator  add StartupWMClass=terminator to the Terminator desktop entry
  todesk      install a Dock launcher that reveals ToDesk's hidden main window
  all         apply all fixes

Options:
  --dry-run   print what would be changed without writing files
  -h, --help  show this help
EOF
}

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

log() {
  printf '[fix-dock] %s\n' "$*"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    edge|terminator|todesk|all)
      TARGET="$1"
      ;;
    --dry-run)
      DRY_RUN=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "unknown argument: $1"
      ;;
  esac
  shift
done

if [ -z "$TARGET" ]; then
  usage
  die "missing target: edge, terminator or all"
fi

if [ -z "${HOME:-}" ]; then
  die "HOME is not set"
fi

XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
USER_APPS="$XDG_DATA_HOME/applications"
SYSTEM_APPS="/usr/share/applications"
PLANK_LAUNCHERS="$HOME/.config/plank/dock1/launchers"
MIMEAPPS="$HOME/.config/mimeapps.list"

copy_to_user() {
  local src="$1"
  local dst="$2"

  if [ -f "$dst" ]; then
    log "already exists: $dst"
    return 0
  fi
  if [ ! -f "$src" ]; then
    die "source desktop file not found: $src"
  fi
  if [ "$DRY_RUN" -eq 1 ]; then
    log "dry-run: copy $src -> $dst"
    return 0
  fi

  mkdir -p "$(dirname "$dst")"
  cp -a "$src" "$dst"
  log "created $dst"
}

set_desktop_key() {
  local file="$1"
  local key="$2"
  local value="$3"

  if [ "$DRY_RUN" -eq 1 ]; then
    if [ -f "$file" ] && grep -q "^$key=" "$file"; then
      log "dry-run: set $key=$value in $file"
    else
      log "dry-run: add $key=$value to $file"
    fi
    return 0
  fi
  if [ ! -f "$file" ]; then
    die "missing desktop file: $file"
  fi

  if grep -q "^$key=" "$file"; then
    sed -i "s|^$key=.*|$key=$value|" "$file"
  elif grep -q '^Type=' "$file"; then
    sed -i "/^Type=/a $key=$value" "$file"
  else
    printf '%s=%s\n' "$key" "$value" >> "$file"
  fi
  log "set $key=$value in $file"
}

remove_desktop_key() {
  local file="$1"
  local key="$2"

  if [ ! -f "$file" ]; then
    return 0
  fi
  if ! grep -q "^$key=" "$file"; then
    return 0
  fi
  if [ "$DRY_RUN" -eq 1 ]; then
    log "dry-run: remove $key from $file"
    return 0
  fi

  sed -i "/^$key=/d" "$file"
  log "removed $key from $file"
}

write_hidden_legacy_edge() {
  local dst="$USER_APPS/microsoft-edge.desktop"

  if [ -f "$dst" ]; then
    return 0
  fi
  if [ "$DRY_RUN" -eq 1 ]; then
    log "dry-run: create hidden legacy override $dst"
    return 0
  fi

  mkdir -p "$USER_APPS"
  cat > "$dst" <<'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Microsoft Edge
GenericName=Web Browser
Comment=Hidden legacy Edge desktop entry
Exec=/usr/bin/microsoft-edge-stable %U
Icon=microsoft-edge
Terminal=false
NoDisplay=true
StartupWMClass=__dock_hidden_microsoft_edge__
Categories=Network;WebBrowser;
EOF
  log "created $dst"
}

ensure_edge_files() {
  if [ ! -f "$USER_APPS/com.microsoft.Edge.desktop" ]; then
    copy_to_user \
      "$SYSTEM_APPS/com.microsoft.Edge.desktop" \
      "$USER_APPS/com.microsoft.Edge.desktop"
  fi

  if [ -f "$USER_APPS/microsoft-edge.desktop" ]; then
    :
  elif [ -f "$SYSTEM_APPS/microsoft-edge.desktop" ]; then
    copy_to_user \
      "$SYSTEM_APPS/microsoft-edge.desktop" \
      "$USER_APPS/microsoft-edge.desktop"
  else
    write_hidden_legacy_edge
  fi

  set_desktop_key "$USER_APPS/com.microsoft.Edge.desktop" NoDisplay false
  set_desktop_key "$USER_APPS/com.microsoft.Edge.desktop" StartupWMClass microsoft-edge
  set_desktop_key "$USER_APPS/microsoft-edge.desktop" NoDisplay true
  set_desktop_key "$USER_APPS/microsoft-edge.desktop" StartupWMClass __dock_hidden_microsoft_edge__
  remove_desktop_key "$USER_APPS/microsoft-edge.desktop" MimeType
}

ensure_terminator_file() {
  if [ ! -f "$USER_APPS/terminator.desktop" ]; then
    copy_to_user \
      "$SYSTEM_APPS/terminator.desktop" \
      "$USER_APPS/terminator.desktop"
  fi

  set_desktop_key "$USER_APPS/terminator.desktop" StartupWMClass terminator
}

update_plank_launchers() {
  local pattern="$1"
  local target="$2"

  if [ ! -d "$PLANK_LAUNCHERS" ]; then
    log "no Plank launcher directory: $PLANK_LAUNCHERS"
    return 0
  fi

  while IFS= read -r -d '' launcher; do
    if [ "$DRY_RUN" -eq 1 ]; then
      if grep -qF "Launcher=file://$target" "$launcher"; then
        log "already points to $target: $launcher"
      else
        log "dry-run: update $launcher -> file://$target"
      fi
      continue
    fi

    if grep -qF "Launcher=file://$target" "$launcher"; then
      log "already points to $target: $launcher"
      continue
    fi

    sed -i "s|^Launcher=.*|Launcher=file://$target|" "$launcher"
    log "updated $launcher -> file://$target"
  done < <(find "$PLANK_LAUNCHERS" -maxdepth 1 -type f \( -iname "$pattern" \) -print0 2>/dev/null)
}

update_mimeapps_for_edge() {
  if [ "$DRY_RUN" -eq 1 ]; then
    log "dry-run: update $MIMEAPPS defaults to com.microsoft.Edge.desktop"
    return 0
  fi

  mkdir -p "$HOME/.config"
  if [ ! -f "$MIMEAPPS" ]; then
    printf '[Default Applications]\n' > "$MIMEAPPS"
  fi
  if ! grep -q '^\[Default Applications\]' "$MIMEAPPS"; then
    printf '\n[Default Applications]\n' >> "$MIMEAPPS"
  fi

  for mime in text/html x-scheme-handler/http x-scheme-handler/https application/xhtml+xml; do
    if grep -q "^$mime=" "$MIMEAPPS"; then
      sed -i "s|^$mime=.*|$mime=com.microsoft.Edge.desktop|" "$MIMEAPPS"
    else
      sed -i "/^\[Default Applications\]/a $mime=com.microsoft.Edge.desktop" "$MIMEAPPS"
    fi
  done

  sed -i 's|microsoft-edge\.desktop|com.microsoft.Edge.desktop|g' "$MIMEAPPS"
  log "updated $MIMEAPPS"
}

fix_edge() {
  ensure_edge_files
  update_plank_launchers '*edge*.dockitem' "$USER_APPS/com.microsoft.Edge.desktop"
  update_mimeapps_for_edge
}

fix_terminator() {
  ensure_terminator_file
  update_plank_launchers '*terminator*.dockitem' "$USER_APPS/terminator.desktop"
}

ensure_todesk_wrapper() {
  local dst="$HOME/.local/bin/todesk-dock"

  if [ -f "$dst" ]; then
    chmod +x "$dst"
    return 0
  fi
  if [ "$DRY_RUN" -eq 1 ]; then
    log "dry-run: create $dst"
    return 0
  fi

  mkdir -p "$HOME/.local/bin"
  cat > "$dst" <<'TODESK_DOCK'
#!/usr/bin/env bash
set -u

export LIBVA_DRIVER_NAME=iHD
export LIBVA_DRIVERS_PATH=/opt/todesk/bin
export GDK_BACKEND=x11

pid=""
launched=0
if pgrep -x ToDesk >/dev/null 2>&1; then
  pid=$(pgrep -x ToDesk | head -n1)
else
  setsid /opt/todesk/bin/ToDesk >/dev/null 2>&1 &
  launched=1
fi

ids=""
main=""
for _ in $(seq 1 40); do
  current=$(pgrep -x ToDesk | head -n1 || true)
  if [ -n "$current" ]; then
    pid="$current"
  fi
  if [ -n "$pid" ] && pgrep -x ToDesk >/dev/null 2>&1; then
    ids=$(xdotool search --pid "$pid" 2>/dev/null || true)
  fi
  main=""
  if [ -n "$ids" ]; then
    for id in $ids; do
      geom=$(xdotool getwindowgeometry --shell "$id" 2>/dev/null || true)
      if [ -z "$geom" ]; then
        continue
      fi
      eval "$geom"
      if [ "${WIDTH:-0}" -gt 600 ] && [ "${HEIGHT:-0}" -gt 500 ]; then
        main="$id"
        break
      fi
    done
  fi
  if [ -n "$main" ]; then
    sleep 1
    ids=$(xdotool search --pid "$pid" 2>/dev/null || true)
    main=""
    for id in $ids; do
      geom=$(xdotool getwindowgeometry --shell "$id" 2>/dev/null || true)
      if [ -z "$geom" ]; then
        continue
      fi
      eval "$geom"
      if [ "${WIDTH:-0}" -gt 600 ] && [ "${HEIGHT:-0}" -gt 500 ]; then
        main="$id"
        break
      fi
    done
    break
  fi
  sleep 0.25
done

[ -n "$ids" ] || exit 0

for id in $ids; do
  xdotool windowmap "$id" >/dev/null 2>&1 || true
done

if [ -n "$main" ]; then
  xdotool windowmove "$main" 480 220 >/dev/null 2>&1 || true
fi

if [ "$launched" -eq 1 ]; then
  sleep 3
  ids=$(xdotool search --pid "$pid" 2>/dev/null || true)
  main=""
  for id in $ids; do
    xdotool windowmap "$id" >/dev/null 2>&1 || true
    geom=$(xdotool getwindowgeometry --shell "$id" 2>/dev/null || true)
    if [ -z "$geom" ]; then
      continue
    fi
    eval "$geom"
    if [ "${WIDTH:-0}" -gt 600 ] && [ "${HEIGHT:-0}" -gt 500 ] && [ -z "$main" ]; then
      main="$id"
    fi
  done
  if [ -n "$main" ]; then
    xdotool windowmove "$main" 480 220 >/dev/null 2>&1 || true
  fi
fi

exit 0
TODESK_DOCK
  chmod +x "$dst"
  log "created $dst"
}

ensure_todesk_desktop() {
  local dst="$USER_APPS/todesk.desktop"

  if [ ! -f "$dst" ]; then
    if [ "$DRY_RUN" -eq 1 ]; then
      log "dry-run: create $dst"
    else
      mkdir -p "$USER_APPS"
      cat > "$dst" <<EOF
[Desktop Entry]
Type=Application
Name=ToDesk
Comment=Remote Control Software
Comment[zh_CN]=ToDesk远程控制软件
Exec=env DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u)/bus XDG_RUNTIME_DIR=/run/user/$(id -u) LIBVA_DRIVER_NAME=iHD LIBVA_DRIVERS_PATH=/opt/todesk/bin GDK_BACKEND=x11 $HOME/.local/bin/todesk-dock
Icon=todesk
GenericName=Remote Control
Keywords=todesk
Categories=Network;
Terminal=false
StartupWMClass=ToDesk
EOF
      log "created $dst"
    fi
  fi

  if [ -f "$dst" ]; then
    set_desktop_key "$dst" Exec "env DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u)/bus XDG_RUNTIME_DIR=/run/user/$(id -u) LIBVA_DRIVER_NAME=iHD LIBVA_DRIVERS_PATH=/opt/todesk/bin GDK_BACKEND=x11 $HOME/.local/bin/todesk-dock"
    set_desktop_key "$dst" StartupWMClass ToDesk
    set_desktop_key "$dst" NoDisplay false
  fi
}

fix_todesk() {
  if ! command -v xdotool >/dev/null 2>&1; then
    if [ "$TARGET" = "todesk" ]; then
      die "todesk fix requires xdotool; install it with: sudo apt install -y xdotool"
    fi
    log "skip todesk: xdotool not installed; install it with: sudo apt install -y xdotool"
    return 0
  fi
  ensure_todesk_wrapper
  ensure_todesk_desktop
  update_plank_launchers '*todesk*.dockitem' "$USER_APPS/todesk.desktop"
}

update_user_desktop_database() {
  if [ ! -d "$USER_APPS" ]; then
    log "skip desktop database: $USER_APPS missing"
    return 0
  fi
  if [ "$DRY_RUN" -eq 1 ]; then
    log "dry-run: update-desktop-database $USER_APPS"
    return 0
  fi
  if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$USER_APPS" || true
    log "updated desktop database: $USER_APPS"
  else
    log "update-desktop-database not found; skip"
  fi
}

print_reload_hint() {
  log "Done. Close existing Edge/Terminator/ToDesk windows before testing."
  log "For ToDesk, run ~/.local/bin/todesk-dock if the main window stays hidden."
  log "If icons remain duplicated, restart Plank or log out/in."
}

case "$TARGET" in
  edge)
    fix_edge
    ;;
  terminator)
    fix_terminator
    ;;
  todesk)
    fix_todesk
    ;;
  all)
    fix_edge
    fix_terminator
    fix_todesk
    ;;
esac

update_user_desktop_database
print_reload_hint
