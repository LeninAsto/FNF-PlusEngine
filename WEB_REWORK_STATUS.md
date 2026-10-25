# Web rework status

The v2 site is developed alongside the legacy `docs/` directory. Astro builds to `dist/`; the published site can keep using `docs/` until the migration checks pass.

## Implemented foundation

- Astro and Starlight with pinned dependencies and a reproducible lockfile.
- Canonical English routes without a prefix and Spanish routes under `/es-LA/`.
- Device-language resolution only at `/`, with a persistent manual selector and an Automatic option.
- Static rendering, responsive Starlight navigation, keyboard support, reduced-motion handling, and local search generated at build time.
- Structured API metadata separated from translations. Entries cannot be marked `verified` without a tested commit and at least one recorded version.
- Representative English and Spanish pages for getting started, Lua, HScript, Psych PlayState, and Plus modifiers.
- Redirects only for v2 destinations that already exist.
- A generated full legacy route inventory in `MIGRATION_MAP.md`.

## Next release gates

1. Complete the Psych and Plus API extraction and source audit.
2. Run example scripts in a built target and record commit/platform results.
3. Migrate every route marked `Pending content` before enabling its redirect.
4. Move and optimize legacy videos, then test at 320 px and with reduced motion.
5. Add link/anchor checks and browser tests for the language cases T01–T15.
6. Configure Cloudflare Pages to run `npm ci && npm run build` with output `dist`, preview it, and only then replace the production output setting.

## Local workflow

```sh
npm ci
npm run inventory
npm run build
npm run dev
```

The source audit uses Plus `dev` commit `ac6374135b68a78e167cd8557d3a1babf51f9c24` as its initial reference. Stable and platform support remain unclaimed until tested.
