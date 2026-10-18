# Plus Engine language packs

`assets/shared/languages/en-US` is the canonical source. Every language pack mirrors its bundle files and keys; only user-facing values change. Plus Engine loads `en-US` first as the offline fallback, then overlays the selected language.

## Create a language pack

1. Copy `assets/shared/languages/en-US` into a folder named with a BCP 47 code, such as `pt-BR`.
2. Translate user-facing string values. Keep keys, `$namespace`, line breaks, technical identifiers, and placeholders such as `{1}`, `{2}`, `%v`, and `%d` unchanged.
3. Edit the copied `manifest.json`:

```json
{
  "schemaVersion": 1,
  "code": "pt-BR",
  "name": "Portugu?s (Brasil)",
  "version": 1,
  "fallback": ["en-US"],
  "bundles": ["global.json", "assets.json", "options/common.json"]
}
```

4. Add the language to `assets/shared/languages/index.json`:

```json
{
  "code": "pt-BR",
  "name": "Portugu?s (Brasil)",
  "version": 1
}
```

5. Open a pull request to `Psych-Plus-Team/FNF-PlusEngine`. After it is merged into `main`, the catalog and package files become available through GitHub Raw.

Increase `version` in both the manifest and catalog whenever an existing package changes. Clients skip a package when its installed version is equal to or newer than the catalog version.

## Localize images and other assets

Text and asset redirection are separate. Put path redirects in the pack's `assets.json`, which uses an empty namespace:

```json
{
  "$schema": 1,
  "$namespace": "",
  "images/mainmenu/menu_story_mode": "images/pt-BR/mainmenu/menu_story_mode",
  "images/menu_tracks": "images/pt-BR/Menu_Tracks"
}
```

The key is the original path requested by the engine. The value is the localized path, without an extension. Keep matching atlas files together: if an image uses Sparrow Atlas, localize both its `.png` and `.xml` under the redirected path. JSON and TXT atlases follow the same rule. Assets without a redirect continue using the original file.

Bundled translations currently place localized files under `assets/translations/shared/images/<language-code>/`. A downloadable package must also list every binary file in the optional `assets` section of its manifest:

```json
{
  "assets": [
    {
      "source": "resources/images/mainmenu/menu_story_mode.png",
      "target": "images/pt-BR/mainmenu/menu_story_mode.png"
    },
    {
      "source": "resources/images/mainmenu/menu_story_mode.xml",
      "target": "images/pt-BR/mainmenu/menu_story_mode.xml"
    }
  ]
}
```

`source` may be relative to the language manifest or an HTTPS URL. `target` is relative to the user's `mods/` directory. Use safe relative targets, keep each file below 16 MiB, and keep the package's localized assets below 64 MiB total.

This mechanism also supports localized XML/JSON atlases, fonts, sounds, or other files that already pass through `Language.getFileTranslation()`. Prefer text for ordinary labels; use localized images only when artwork itself contains text.

## OTA download flow

In **Options > Language**, **Download or update languages** fetches the official catalog over HTTPS. For every new or newer package, Plus Engine:

1. downloads the manifest and all JSON bundles;
2. validates language codes, paths, sizes, JSON syntax, and namespaces;
3. downloads and validates optional binary assets;
4. writes text bundles to `mods/languages/<code>/` and localized assets to their declared `mods/<target>` paths;
5. commits the manifest last, so an interrupted download never becomes active.

The language screen discovers installed manifests and displays each installed language as its own option. Downloaded packages live outside the executable and can be updated without rebuilding the engine.

## Quality rules

- Save every JSON and documentation file as UTF-8.
- Check for mojibake indicators such as `U+00C3`, `U+00C2`, or replacement character `U+FFFD`.
- Preserve placeholders, newlines, file paths, callback names, and engine terminology.
- Keep short labels close to the English length so they fit buttons and editor controls.
- Verify that the selected font contains every required glyph.
- Test at 1280?720, especially Options, Chart Editor, popups, debug messages, and error dialogs.
