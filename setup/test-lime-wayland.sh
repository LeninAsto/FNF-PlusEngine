#!/usr/bin/env bash
set -eu

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
  echo "Usage: bash setup/test-lime-wayland.sh PATH_TO_LIME_NDLL [PATH_TO_GAME]" >&2
  exit 2
fi

lime_path="$(realpath "$1")"
game_path="${2:-}"
if [ -n "$game_path" ]; then game_path="$(realpath "$game_path")"; fi

export XDG_RUNTIME_DIR="$(mktemp -d)"
chmod 700 "$XDG_RUNTIME_DIR"
weston --backend=headless-backend.so --socket=wayland-ci --idle-time=0 --log="$XDG_RUNTIME_DIR/weston.log" &
weston_pid=$!
trap 'kill "$weston_pid" 2>/dev/null || true; rm -rf "$XDG_RUNTIME_DIR"' EXIT
for attempt in $(seq 1 30); do
  [ -S "$XDG_RUNTIME_DIR/wayland-ci" ] && break
  sleep 1
done
if [ ! -S "$XDG_RUNTIME_DIR/wayland-ci" ]; then
  cat "$XDG_RUNTIME_DIR/weston.log"
  exit 1
fi
WAYLAND_DISPLAY=wayland-ci SDL_VIDEODRIVER=wayland LIBGL_ALWAYS_SOFTWARE=1 \
  python3 setup/check-lime-wayland.py "$lime_path"

if [ -n "$game_path" ]; then
  set +e
  (cd "$(dirname "$game_path")" && WAYLAND_DISPLAY=wayland-ci SDL_VIDEODRIVER=wayland \
    SDL_AUDIODRIVER=dummy LIBGL_ALWAYS_SOFTWARE=1 WAYLAND_DEBUG=1 \
    timeout 20 "$game_path") > "$XDG_RUNTIME_DIR/game.log" 2>&1
  status=$?
  set -e
  if ! grep -q 'wl_compositor' "$XDG_RUNTIME_DIR/game.log" || { [ "$status" -ne 0 ] && [ "$status" -ne 124 ]; }; then
    echo "Wayland game smoke test failed (exit $status):" >&2
    tail -n 40 "$XDG_RUNTIME_DIR/game.log" >&2
    exit 1
  fi
  echo "PlusEngine connected to Wayland (exit $status)"
fi
