# Modchart Editor

Open **Editors → Modchart Editor**. The editor starts with the current chart;
**Open chart** loads another chart JSON, including charts with a difficulty suffix.
The song name field loads the base chart by name. Audio is resolved from the song's
normal asset/mod location.

The preview uses Plus Engine's StrumNote, Note and modchart Manager renderer.
JSON stage objects and the song's characters are loaded. Importing a song Lua also
loads its visual setup from `onCreate` and `onCreatePost`: sprites, graphics, text,
animations, camera layers, position, scale, alpha, scroll factors and object order.
The preview replays supported song-start changes and alpha/position/angle tweens
when seeking. Haxe stages use a classic backdrop. Gameplay scoring, health and
game-over systems are not loaded.

## Timeline

- Space: play/pause. Left/right: seek by a quarter beat; Shift: four beats.
- Drag the scrollbar to pan quickly through the song without moving playback.
- Click the ruler or empty grid, or drag the yellow playhead to seek while playing
  or paused. Dragging past an edge pans the visible range.
- Enter an exact beat in **Seek to beat** and press **Go**. **Back/Forward** jump
  four beats; **Home** and **Start** return to beat -5.
- Click an event to edit its modifier, beat, duration, value, easing, player and field.
- Drag an event to move it, snapped to quarter beats. Right click adds an event.
- Wheel: pan; Ctrl+wheel: zoom; Alt+wheel: scroll modifier rows.
- New / Apply / Duplicate / Delete create, update, copy and remove events.
- Player `-1`: both sides; `0`: opponent; `1`: boyfriend. Field `-1`: all fields.

The editor starts at **beat -5**, with the stage countdown and its sounds. Negative
event beats are preserved, including initial modifier values before beat zero.
Timing uses Conductor's BPM map. Seeking rebuilds the Manager schedule from its
defaults and restores the notes at that time, including sustain segments. The note
cursor uses binary search; only nearby notes have live sprites.

## Files and Lua

**Save** saves the editable timeline as `modchart-project.json`; **Project**
reopens it. Keep the original chart alongside the project; the project contains
the modifier schedule, captured Lua scene and renderer settings, not song audio or
chart notes. Select the correct mod directory in the editor menu so Lua images
resolve from the same mod.

**Export Lua** writes `modchart.lua`. Put it in the mod's `data/<song>/` folder.
It schedules gameplay calls in `onInitModchart()` using `set`, `ease` and `add`,
with captured visual operations in their original creation/song-start hooks.
**Import Lua** and **Paste Lua** execute scheduling code in an isolated Lua VM,
so loops, locals and arithmetic can produce editable events.

Supported import calls: `addModifier`, `set`, `ease`, `add`, `setPercent`, `setNow`
and `easeNow` (initial beat -5),
`queueSet`, `queueEase`, `queueSetP`, `queueEaseP`, and immediate numeric `addPlayfield()`. `manager` and `Manager` tables
accept dot and colon calls. Initialization hooks `onCreate`, `onCreatePost`,
`onInitModchart` and `onSongStart` are collected. Renderer options and hold
subdivisions are preserved. Numeric fields are supported; field-specific
`addModifier` declarations are rejected instead of silently changed.

Videos and dynamic update/beat/step callbacks are skipped with a preview warning
when an `onInitModchart` schedule is available. Custom modifiers (`createModifier`),
named fields, arbitrary gameplay APIs and embedded HScript are not editable
imports. An unsupported call rejects the import and keeps the current timeline.
Filesystem/process/native module access is unavailable, with instruction and
event limits during import. English UI strings and Spanish translations are in
`languages/en-US/editors/modchart.json` and `languages/es-LA/editors/modchart.json`.

Example:

```lua
function onInitModchart()
    addModifier('drunk')
    set('drunk', -5, 0)
    for beat = 4, 28, 8 do
        ease('drunk', beat, 4, 1, 'sineInOut', 1)
        ease('drunk', beat + 4, 4, 0, 'sineInOut', 1)
    end
end
```

## Verification

Official build: `lime build windows -D officialBuild`.
Type checking without producing an executable:
`haxe export/debug/windows/haxe/debug.hxml --no-output` (after Lime has generated
the project HXML). Debug checks: `haxelib run lime build windows -debug -D officialBuild`.
Run the debug executable with `--modchart-self-test` to check real Lua imports,
project/Lua roundtrips, execution limits, Manager seeking and dense chart source
preservation. Results are written to `modchart-checks.txt` in its working directory.
`--modchart-editor` starts the editor directly in a debug build.
Set `PLUS_MODCHART_TEST_MOD` to an Anomaly `data` folder to additionally test its
real scripts; the custom `ellipse` modifier is expected to be rejected explicitly.

The stage-and-timeline workflow was reviewed against the community
[Modchart Editor for Codename Engine](https://github.com/Martincraft7887/modcharteditor-cne-1.0.1),
originally by TheZoroForce240. This implementation uses Plus Engine's own Manager
and preview adapter, rather than importing Codename Engine source.
