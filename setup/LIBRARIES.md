# Plus Engine Haxelib Map

This engine uses the normal/global `haxelib` repo. The main setup scripts are:

- `setup/windows-lib.bat` for Windows.
- `setup/unish-lib.sh` for Linux/macOS-like shells.

## Core Build Stack

Required for the engine in general.

| Library | Current setup source | Used by |
| --- | --- | --- |
| `hxcpp` | `Psych-Plus-Team/hxcpp` git | C++ targets |
| `lime` | `Psych-Plus-Team/lime` git | OpenFL/Lime app build |
| `openfl` | `9.5.0` | Rendering/assets/audio |

## HaxeFlixel Stack

Required by Plus/Psych.

| Library | Current setup source | Used by |
| --- | --- | --- |
| `flixel` | `Psych-Plus-Team/flixel` git | Main game framework |
| `flixel-addons` | `3.3.2` | Addon helpers |
| `flixel-tools` | `1.5.1` | Tooling |
| `flixel-ui` | `2.6.2` | UI/editor helpers |

## Plus/Psych Runtime

Classic Plus/Psych systems and classic mods.

| Library | Current setup source | Notes |
| --- | --- | --- |
| `hscript-iris` | `Psych-Plus-Team/hscript-iris` git | HScript/Iris, custom classes support |
| `linc_luajit` | `kittycathy233/linc_luajit` git | Lua scripts |
| `flxanimate` | `4.0.0` | Psych/Plus AnimateAtlas package, imports `flxanimate.*` |
| `moonchart` | `0.5.0` | Chart conversion/loading helpers |
| `tjson` | `1.4.0` | Legacy JSON parsing |
| `funkin.vis` | `FunkinCrew/funkVis` git `22b1ce0...` | Lightweight audio visualization |
| `grig.audio` | `grig.audio` git `cbf91e2...` | Audio analysis used by visualization |

## Optional Integrations

Only active when the matching Project.xml flag is enabled.

| Library | Current setup source | Flag |
| --- | --- | --- |
| `hxdiscord_rpc` | `1.3.0` | `DISCORD_ALLOWED` |
| `hxvlc` | `2.2.6` | `VIDEOS_ALLOWED` |

