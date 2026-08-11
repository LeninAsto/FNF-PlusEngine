# VSlice Haxelib Setup

This folder documents the global `haxelib` set needed by the copied
`source/funkin` runtime. Use the PowerShell script when a machine is missing the
VSlice libs or when you want the same refs used by Plus Engine's VSlice bridge.

The important runtime libraries are:

- `polymod` from `Psych-Plus-Team/polymod`
- `json2object`
- `jsonpatch`
- `jsonpath`
- `thx.core`
- `thx.semver`
- `flixel-animate` from `Psych-Plus-Team/flixel-animate` with the `animate.*` package
- `FlxPartialSound`
- `hxjsonast`
- `extension-androidtools` on Android

The script installs into the normal global `haxelib` repo used by Plus Engine.
It intentionally does not install ads, IAP, Newgrounds, HaxeUI, or extra mobile
store libraries. V1 only needs gameplay/runtime compatibility.

Keep Plus/Psych animation support on `flxanimate`. VSlice uses the separate
`flixel-animate` library with `animate.FlxAnimateFrames`. Do not merge those two
packages: Psych imports `flxanimate.*`, VSlice imports `animate.*`.
