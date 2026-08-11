# Plus Engine Haxelib Map

This engine uses the normal/global `haxelib` repo. The main setup scripts are:

- `setup/windows-lib.bat` for Windows.
- `setup/unish-lib.sh` for Linux/macOS-like shells.
- `setup/vslice-haxelib/install-vslice-libs.ps1` only when you want to refresh the VSlice-specific libraries.

## Core Build Stack

Required for the engine in general.

| Library | Current setup source | Used by |
| --- | --- | --- |
| `hxcpp` | `Psych-Plus-Team/hxcpp` git | C++ targets |
| `lime` | `Psych-Plus-Team/lime` git | OpenFL/Lime app build |
| `openfl` | `9.5.0` | Rendering/assets/audio |

## HaxeFlixel Stack

Required by Plus/Psych and the copied VSlice runtime.

| Library | Current setup source | Used by |
| --- | --- | --- |
| `flixel` | `Psych-Plus-Team/flixel` git | Main game framework |
| `flixel-addons` | `3.3.2` | Addon helpers |
| `flixel-tools` | `1.5.1` | Tooling |
| `flixel-ui` | `2.6.2` | UI/editor compatibility |

## Plus/Psych Runtime

Classic Plus/Psych systems and classic mods.

| Library | Current setup source | Notes |
| --- | --- | --- |
| `hscript-iris` | `Psych-Plus-Team/hscript-iris` git | HScript/Iris, custom classes support |
| `linc_luajit` | `kittycathy233/linc_luajit` git | Lua scripts |
| `flxanimate` | `4.0.0` | Psych/Plus AnimateAtlas package, imports `flxanimate.*` |
| `moonchart` | `0.5.0` | Chart conversion/loading helpers |
| `tjson` | `1.4.0` | Legacy JSON parsing |

## Optional Integrations

Only active when the matching Project.xml flag is enabled.

| Library | Current setup source | Flag |
| --- | --- | --- |
| `hxdiscord_rpc` | `1.3.0` | `DISCORD_ALLOWED` |
| `hxvlc` | `2.2.6` | `VIDEOS_ALLOWED` |

## VSlice Runtime

Needed for `source/funkin`, VSlice mods, Polymod metadata, scripted classes,
registries, and official-style asset loading. These are needed when compiling
with `-D vslice` / `FEATURE_POLYMOD_MODS`.

| Library | Current setup source | Why VSlice needs it |
| --- | --- | --- |
| `polymod` | `Psych-Plus-Team/polymod` git | VSlice mod loading, `_merge`, scripted classes |
| `json2object` | `FunkinCrew/json2object` git `59e0467...` | Typed JSON parsing for Funkin data |
| `jsonpatch` | `1.1.0` | Polymod JSON patches |
| `jsonpath` | `1.1.0` | Polymod patch paths |
| `thx.core` | `0.44.0` | Funkin save/data helpers |
| `thx.semver` | `0.2.2` | Mod/API version checks |
| `flixel-animate` | `Psych-Plus-Team/flixel-animate` git `main` | VSlice AnimateAtlas package, imports `animate.*` |
| `FlxPartialSound` | `FunkinCrew/FlxPartialSound` git `2f984e2...` | Partial audio loading |
| `hxjsonast` | `nadako/hxjsonast` git `20e72cc...` | HScript/Polymod parser support |
| `funkin.vis` | `FunkinCrew/funkVis` git `22b1ce0...` | Funkin base-game visualization |
| `grig.audio` | `grig.audio` git `cbf91e2...` | Audio analysis used by Funkin visualization |
| `extension-androidtools` | Android-only | VSlice/mobile Android helpers |

Important: keep `flxanimate` and `flixel-animate` separate. Psych/Plus imports
`flxanimate.*`; VSlice/Funkin imports `animate.*`. Merging those packages is how
atlas logic gets cursed.
