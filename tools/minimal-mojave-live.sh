#!/usr/bin/env bash
set -u

VIDEO="$HOME/.local/share/backgrounds/Minimal-Mojave-Live/Minimal-Mojave-live.mp4"
export DISPLAY="${DISPLAY:-:1}"

ffplay -loop 0 -x 1920 -y 1080 -an -window_title 'Minimal-Mojave-Live' "$VIDEO" >/dev/null 2>&1 &
ffplay_pid=$!

wid=""
for _ in $(seq 1 50); do
    wid="$(DISPLAY="$DISPLAY" xdotool search --name 'Minimal-Mojave-Live' 2>/dev/null | head -n1 || true)"
    [ -n "$wid" ] && break
    sleep 0.2
done

if [ -n "$wid" ]; then
    DISPLAY="$DISPLAY" xdotool windowmove "$wid" 0 0 windowsize "$wid" 1920 1080 || true
    DISPLAY="$DISPLAY" xprop -id "$wid" -f _NET_WM_WINDOW_TYPE 32a -set _NET_WM_WINDOW_TYPE _NET_WM_WINDOW_TYPE_DESKTOP || true
    DISPLAY="$DISPLAY" xprop -id "$wid" -f _NET_WM_STATE 32a -set _NET_WM_STATE _NET_WM_STATE_STICKY || true
    DISPLAY="$DISPLAY" xdotool windowunmap "$wid" || true
    sleep 0.2
    DISPLAY="$DISPLAY" xdotool windowmap "$wid" || true
fi

wait "$ffplay_pid"
