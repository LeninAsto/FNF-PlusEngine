# Changelog

## 1.3.0 development — compared with `1.3-prerelease`

**Comparison:** `1.3-prerelease` (`f8716b57`, 2026-07-28) → remote `origin/dev`
(`aac1210f`, fetched 2026-11-04). This is a consolidated, user-facing summary
of the net changes in that range: it intentionally omits asset-only churn,
temporary reverts, and commits whose message does not describe a feature.

> The project version in `Project.xml` is now `1.3.0`.

### Gameplay and modcharts

- Added a dedicated **Modchart Editor** with timeline, scene preview, Lua
  importer, and validation checks.
- Expanded the modifier set with Boomerang, Column Rotate, Distance Scale,
  Expand, ModSpline, Object Transform, Perspective, Pulse, Shrink, Snap,
  Spiral Axis, Sway, Tangent, and XMode.
- Refactored playfields and the modchart manager so the global manager is
  active by default and modcharts render in, and respect, `camHUD`.
- Added ActorFrame support and its Lua bridge/proxy/texture-source helpers for
  NotITG-style content.
- Added or restored gameplay events and controls: Change UI, extended event
  values, Change BPM, Secondary Icon, animated three-frame icons, and
  configurable icon-bounce behavior including a Codename option.
- Added combo and miss popups in PlayState, camera bopping, a warm-graphic
  helper, winning-icon support, and pixel-splash handling for pixel stages.
- Added botplay CPU support and utilities for ratings/accuracy, HUD safe zones,
  health icons, note splashes, play modes, and window-border pulse effects.
- Removed the current Opponent Mode implementation and the legacy no-RGB hold
  cover / noteskin / notesplash asset variants. Mods should not rely on those
  bundled legacy assets being present.

### Softcoding, scripting, and mods

- Introduced the `scripting/` layer for HScript: registry, hooks, globals,
  preprocessing, errors, shims, drawing helpers, and HScript documentation.
- Added scriptable state, substate, stage, and global-script routing, plus
  exported core-state templates under `assets/shared/scripts/classes/`.
- Added compile-time macros that generate scripting bridges and synchronize the
  state/substate script templates from their Haxe counterparts.
- Added `GlobalScriptManager`, `TransitionManager`, and mod-aware state,
  transition, language, and asset-loading flows.
- Added mod launch/loading overlay support, custom cursors, edition-name
  handling, required-mod helpers, and a security review UI.
- Added `ModSecurity` and `SecurityReview`: mod script scans, saved approval
  records, and configurable checks for risky script patterns.
- Added a restricted script HTTP bridge rather than exposing unrestricted
  system access to scripts.
- Softcoded additional UI/asset paths and converted language handling from
  compiled language classes to JSON language packs. Language packs can be
  validated and synchronized through `LanguagePackManager`.

### Editors and creator tools

- Expanded ChartingState timing, waveform visibility, event icons, toasts,
  grid behavior, note metadata, JSON printing, and V-Slice-related tooling.
- Restored character dragging in the Character Editor; added configurable
  character-icon animation FPS and camera-stage controls.
- Added modchart conversion/import and preview tooling to the editor suite.
- Improved the Master Editor/Stage/Dialogue/Week/Note Splash editor paths and
  added clearer file-dialog and preload-list support.

### Performance, loading, and runtime

- Added normalized-chart disk caching (`CompiledChartCache`) and a song load
  plan/cache path, alongside one-shot song-load metrics for chart, assets,
  audio, note generation, and cache hits.
- Reworked asset loading and introduced utility/cache layers for bitmaps,
  sounds, paths, textures, and loading tasks.
- Added native C++ backends/wrappers for audio, geometry, math, and notes.
- Added garbage-collection helpers, rendering/interpolation updates, GPU cache
  settings, and note generation metrics.
- Optimized and reorganized many image/audio assets; moved several atlases to
  Sparrow/Packer atlas formats. Asset paths are therefore not all backward
  compatible with their prerelease locations.

### Audio, video, and graphics

- Added audio-device monitoring and recovery support for OpenAL Soft output
  changes.
- Added tempo control with a preserve-pitch path for supported streamed audio.
- Raised the configured desktop OpenGL target to 4.6 and mobile OpenGL ES to
  3.2, and added graphics-capability/shader compatibility helpers.
- Improved video compatibility, global antialiasing, rendering color
  transforms, and light-hit visual controls.
- Added depth and stencil buffers to the project window configuration.

### Mobile and platform support

- Reworked the Android launcher/activity and manifest integration, including
  package-query handling, game launch behavior, localized launcher strings,
  and multiple mobile button mappings.
- Improved mobile BACK behavior and TouchButton/TouchPad interaction across
  menus and states; fixed virtual keyboard and Android lag issues.
- Added platform-specific guards for controls such as Instant Window Close,
  plus mobile feature defines in the build configuration.
- Updated the desktop Windows package to include the bundled `PsychEngine.exe`
  compatibility asset and the required OpenAL runtime handling.

### UI, menus, and results

- Reworked dropdown selection/touch behavior and native UI controls; adjusted
  options, graphics, modchart, language, and mod-security menus.
- Updated Freeplay, loading, mods, main menu, credits, achievements, title,
  and results flows, including a loading progress substate.
- Added the newer results-screen score, tally, clear-percent, and masking
  components.
- Added new stickers, event icons, cursor assets, platform icons, loading
  visuals, and several base-game/menu visual updates.

### Libraries, build system, and integrations

- Moved Lime, HaxeFlixel, Flixel Addons, and HScript dependencies to their git
  revisions; added `hxscript` alongside `hscript-iris` for the softcoding
  stack.
- Added engine macros for enhanced Flixel base/sprite/path behavior and updated
  build defines, including the renamed `MODCHART_ALLOWED` feature flag.
- Updated CI packaging, Android setup, optimized-build handling, and asset
  export rules.
- Migrated Discord presence toward `hxDiscordSocial`, with richer presence,
  authentication/session hooks, Android Social SDK support, packaged runtime
  DLLs, and CI bootstrap/path fixes.

### Localization, compatibility, and fixes

- Added/updated Indonesian and Spanish mobile/launcher localization, plus the
  JSON-language infrastructure used by the engine.
- Improved Freeplay compatibility without requiring a renamed V-Slice folder.
- Fixed noteskin sizing, mobile receptor alignment, Change Character handling,
  results-state and winning-icon placement issues, dropdown interaction, and
  several chart/editor/UI regressions.
- Updated V-Slice build/API handling and base-game asset organization.

### Upgrade notes

- Treat this as a significant development jump, not a drop-in patch over the
  prerelease. Test custom scripts, modcharts, asset paths, old non-RGB skins,
  Android controls, and Discord integration before publishing a modpack.
- The comparison is against the **remote** branch only. Local uncommitted work
  is deliberately excluded so this file stays reproducible from Git history.
