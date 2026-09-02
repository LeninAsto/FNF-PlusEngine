# Plus Engine Scripting Backend

This folder contains the new script backend layer for Plus Engine.

The goal is to keep the legacy Psych/Lua surface compatible while moving classed
HScript support into one central `scripting` package. The backend is intentionally
split from `psychlua` so loaders, registries, globals, and future scripted states
can be migrated piece by piece without breaking old mods.

Current layout:

- `hscript/`: hxscript-backed HScript runtime and interpreter glue.
- `ScriptBackend.hx`: one-time boot setup for scripting configuration.
- `ScriptGlobals.hx`: shared imports and helpers exposed to scripts.
- `ScriptError.hx`: debug/trace reporting helpers.

The old `psychlua` package remains the compatibility layer for existing Funkin Lua
and Psych-style plain HScript.
