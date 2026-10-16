#!/bin/sh
set -eu

# Windows Lime links OpenAL dynamically and needs OpenAL32.dll beside Neko.
# Unix Lime packages OpenAL differently: Linux embeds OpenAL Soft in lime.ndll,
# while macOS uses the system OpenAL framework. Validate the host binary and
# fail during setup if one of its native dependencies cannot be resolved.

HAXELIB_REPO=$(haxelib config | sed -n '1{s/\r$//;p;}')
HAXELIB_REPO=${HAXELIB_REPO%/}
LIME_ROOT="$HAXELIB_REPO/lime/git"
HOST_OS=$(uname -s)
HOST_ARCH=$(uname -m)

case "$HOST_OS:$HOST_ARCH" in
	Linux:x86_64|Linux:amd64)
		LIME_NATIVE="$LIME_ROOT/ndll/Linux64/lime.ndll"
		;;
	Linux:i386|Linux:i486|Linux:i586|Linux:i686)
		LIME_NATIVE="$LIME_ROOT/ndll/Linux/lime.ndll"
		;;
	Darwin:arm64|Darwin:aarch64)
		LIME_NATIVE="$LIME_ROOT/ndll/MacArm64/lime.ndll"
		;;
	Darwin:x86_64|Darwin:amd64)
		LIME_NATIVE="$LIME_ROOT/ndll/Mac64/lime.ndll"
		;;
	*)
		echo "[OpenAL] ERROR: Unsupported host: $HOST_OS $HOST_ARCH" >&2
		exit 1
		;;
esac

if [ ! -f "$LIME_NATIVE" ]; then
	echo "[OpenAL] ERROR: Lime native library was not found at:" >&2
	echo "$LIME_NATIVE" >&2
	exit 1
fi

case "$HOST_OS" in
	Linux)
		if ! command -v ldd >/dev/null 2>&1; then
			echo "[OpenAL] ERROR: ldd is required to validate Lime native dependencies." >&2
			exit 1
		fi

		MISSING_LIBS=$(ldd "$LIME_NATIVE" 2>/dev/null | awk '/not found/ { print $1 }')
		if [ -n "$MISSING_LIBS" ]; then
			echo "[OpenAL] ERROR: Lime has unresolved native dependencies:" >&2
			echo "$MISSING_LIBS" >&2
			echo "Install the matching runtime packages with your distribution package manager." >&2
			exit 1
		fi

		if ldd "$LIME_NATIVE" 2>/dev/null | grep -qi 'libopenal'; then
			echo "[OpenAL] Linux system OpenAL dependency resolved."
		else
			echo "[OpenAL] Linux OpenAL Soft is embedded in lime.ndll."
		fi
		;;
	Darwin)
		if ! command -v otool >/dev/null 2>&1; then
			echo "[OpenAL] ERROR: otool is required to validate Lime native dependencies." >&2
			exit 1
		fi

		if otool -L "$LIME_NATIVE" | grep -qi 'OpenAL.framework'; then
			if [ ! -d /System/Library/Frameworks/OpenAL.framework ] && [ ! -d /Library/Frameworks/OpenAL.framework ]; then
				echo "[OpenAL] ERROR: The macOS OpenAL framework is not available." >&2
				exit 1
			fi
			echo "[OpenAL] macOS OpenAL framework resolved."
		else
			echo "[OpenAL] macOS OpenAL support is embedded in lime.ndll."
		fi
		;;
esac
