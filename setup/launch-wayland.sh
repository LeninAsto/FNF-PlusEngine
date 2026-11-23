#!/usr/bin/env sh
set -eu
cd "$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
export SDL_VIDEODRIVER="${SDL_VIDEODRIVER:-wayland}"
exec ./PlusEngine "$@"
