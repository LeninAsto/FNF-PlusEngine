# Plus Engine language bundles

Plus Engine keeps `Language.getPhrase()`, `Language.getPhrases()`,
`Language.getPhraseForLanguage()` and `Language.getFileTranslation()` as its
public localization API. JSON bundles are loaded on top of the existing Haxe
and `.lang` catalogues so screens can be migrated gradually.

## Layout

Each locale has a manifest under `assets/shared/languages/<locale>/`:

```text
languages/en-US/
├── manifest.json
├── global.json
├── states/playstate.json
├── substates/pause.json
├── options/common.json
├── options/gameplay_changers.json
├── editors/master.json
└── editors/modchart_converter.json
```

Only files listed in `manifest.json` are loaded. Bundles declare a namespace
and can use nested objects:

```json
{
  "$schema": 1,
  "$namespace": "playstate",
  "hud": {
    "score": "Score: {1}",
    "misses": "Misses: {1}"
  }
}
```

The resulting keys are `playstate.hud.score` and
`playstate.hud.misses`:

```haxe
Language.getPhrase('playstate.hud.score', null, [songScore]);
```

Use a screen-owned namespace so identical words can differ by context:

```text
playstate.hud.score
freeplay.score
substates.pause.menu.resume
options.categories.graphics.name
editors.master.items.chart_editor
```

`Option` automatically asks for `options.settings.<translation>.name`,
`.description`, and `.values.<value>`. `GameplayOption` does the same under
`options.gameplay_changers.<variable>`. Both retain the old `setting_*` and
`description_*` lookups as fallbacks, so existing language packs can migrate
without breaking.

Lua scripts may override a phrase for the current language session. Runtime
overrides are cleared by `Language.reloadPhrases()` so they do not leak into a
different state or mod:

```lua
setTranslationPhrase('playstate.hud.score', 'Points: {1}')
local value = getTranslationPhrase('playstate.hud.score', nil, {score})
removeTranslationPhrase('playstate.hud.score')
```

HScript can use the same layer directly through `Language.setPhrase()`,
`Language.removePhrase()`, `Language.hasPhrase()` and
`Language.clearPhrases()`. `Language.revision` increments whenever the active
catalogue changes, allowing localized UI components to refresh themselves.

Keys are lowercase namespaces separated by dots. Display strings should not
be used as identifiers. English (`en-US`) is loaded first as the offline
fallback, followed by the selected legacy catalogue and its JSON bundles.

Mods may provide the same structure at
`mods/<mod>/languages/<locale>/`. Their manifests and bundles are applied in
the normal Plus Engine mod order. Bundle paths containing `..` or absolute
paths are rejected.

`languages/index.json` lists JSON-only locales so the language selection menu
can discover them without compiling a new Haxe class.
