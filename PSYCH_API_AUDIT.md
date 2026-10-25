# Psych API audit

**Upstream commit:** `e2e36943bfe1d4d6407becafcf6d64e631122cb1`  
**Plus development commit:** `ac6374135b68a78e167cd8557d3a1babf51f9c24`

## Baseline

- Upstream contains 24 HTML reference pages under `pages/`.
- The legacy Plus catalog contains 22 function categories and 128 function entries in `docs/assets/psych.js`.
- `variables` and `snippets` are stored separately in `docs/data/special-pages.json` and are not yet included in the generated function migration.
- Upstream is licensed under GPL-3.0. The earlier planning document incorrectly identified it as Apache-2.0.
- All imported entries start as `needs-review`, with no claimed Plus version or platform support.

## Confirmed editorial issue upstream

On `pages/script.html`, the examples under `addLuaScript` and `addHScript` call `callScript(...)`. The signatures and surrounding text describe initialization, so these examples are treated as suspected editorial errors and will not be copied as verified examples.

## Source checks completed

- `startCountdown` is registered as a Lua callback in Plus `dev` at `source/psychlua/backend/FunkinLua.hx:1098`.
- The source check confirms symbol presence only. Runtime behavior, stable-version coverage, and platform coverage remain unverified.

## Outstanding work

1. Compare every upstream signature with the generated legacy catalog.
2. Locate each symbol in the Plus stable and development source trees.
3. Run representative scripts in built targets and record the exact commit and platform.
4. Correct or exclude suspicious examples before changing any status to `verified`.
