#!/usr/bin/env bash
set -euo pipefail

find_sdk_root() {
  local header
  header="$(find "$1" -type f -path '*/include/discordpp.h' -print -quit)"
  [[ -n "$header" ]] || return 1
  dirname "$(dirname "$header")"
}

if [[ -n "${DISCORD_SOCIAL_SDK_DIR:-}" && -f "$DISCORD_SOCIAL_SDK_DIR/include/discordpp.h" ]]; then
  sdk_root="$(cd "$DISCORD_SOCIAL_SDK_DIR" && pwd -P)"
else
  : "${DISCORD_SOCIAL_SDK_URL:?Set DISCORD_SOCIAL_SDK_URL to a private SDK archive URL}"
  : "${DISCORD_SOCIAL_SDK_SHA256:?Set DISCORD_SOCIAL_SDK_SHA256 to the archive SHA-256}"
  [[ "$DISCORD_SOCIAL_SDK_SHA256" =~ ^[[:xdigit:]]{64}$ ]] || { echo 'DISCORD_SOCIAL_SDK_SHA256 must be 64 hex characters.' >&2; exit 1; }
  work="${RUNNER_TEMP:-${TMPDIR:-/tmp}}/discord-social-sdk"
  rm -rf "$work"; mkdir -p "$work/extracted"
  curl --fail --location --retry 3 --silent --show-error "$DISCORD_SOCIAL_SDK_URL" -o "$work/sdk.zip"
  actual="$(sha256sum "$work/sdk.zip" | awk '{print tolower($1)}')"
  expected="$(printf '%s' "$DISCORD_SOCIAL_SDK_SHA256" | tr '[:upper:]' '[:lower:]')"
  [[ "$actual" == "$expected" ]] || { echo "SDK checksum mismatch: expected $expected, got $actual." >&2; exit 1; }
  # Compress-Archive on Windows writes backslashes in ZIP entry names. Python
  # normalizes them here so the same artifact works on Linux runners.
  python3 - "$work/sdk.zip" "$work/extracted" <<'PY'
import pathlib
import sys
import zipfile

archive = pathlib.Path(sys.argv[1])
destination = pathlib.Path(sys.argv[2]).resolve()
with zipfile.ZipFile(archive) as bundle:
    for entry in bundle.infolist():
        name = entry.filename.replace("\\", "/")
        target = (destination / name).resolve()
        if target != destination and destination not in target.parents:
            raise RuntimeError(f"Unsafe ZIP entry: {entry.filename}")
        if entry.is_dir():
            target.mkdir(parents=True, exist_ok=True)
            continue
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(bundle.read(entry))
PY
  sdk_root="$(find_sdk_root "$work/extracted")" || { echo 'The archive does not contain include/discordpp.h.' >&2; exit 1; }
  sdk_root="$(cd "$sdk_root" && pwd -P)"
fi

[[ -n "${GITHUB_ENV:-}" ]] && printf 'DISCORD_SOCIAL_SDK_DIR=%s\n' "$sdk_root" >> "$GITHUB_ENV"
export DISCORD_SOCIAL_SDK_DIR="$sdk_root"
echo "Discord Social SDK ready at $sdk_root"
