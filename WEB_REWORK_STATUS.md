# Web rework status

The v2 site is developed alongside the legacy `docs/` directory. Astro builds to `dist/`; the published site can keep using `docs/` until the migration checks pass.

## Implemented

- Astro and Starlight with pinned dependencies and a reproducible lockfile.
- Canonical English routes without a prefix and Spanish routes under `/es-LA/`.
- Device-language resolution only at `/`, with a persistent manual selector and an Automatic option.
- Static rendering, responsive Starlight navigation, keyboard support, reduced-motion handling, and local search generated at build time.
- Structured API metadata separated from translations. Entries cannot be marked `verified` without a tested commit and at least one recorded version.
- All 66 legacy routes represented by 72 English and Spanish content pages.
- Generated reference pages for 24 Psych categories and 6 Plus categories: 242 functions, 106 variables, 34 modifiers, and 10 snippet links.
- Source links pinned to audited Psych and Plus commits. Imported Psych material is identified as GPL-3.0 in `THIRD_PARTY_NOTICES.md` and `PSYCH_API_AUDIT.md`.
- 195 safe redirects covering the old route, trailing-slash, and `index.html` forms.
- Four legacy modifier videos served with deferred loading and no autoplay.
- Production browser tests for language selection, persistent preferences, anchors, JavaScript-free reading, the 320 px menu, videos, redirects, and Pagefind.
- A generated full legacy route inventory in `MIGRATION_MAP.md`; it currently reports 66 implemented and 0 pending routes.

## Next release gates

1. Run API examples in built Windows and Linux targets, then promote supported entries from `needs-review` to `verified` with recorded commit and platform evidence.
2. Replace the 22 explicit Spanish fallback collections with reviewed translations.
3. Review external snippet links and either pin their content locally with licensing metadata or keep their unverified label.
4. Optimize or re-encode modifier videos if preview transfer measurements justify it.
5. Configure Cloudflare Pages to run `npm ci && npm run build` with output `dist`, review its branch preview, and only then change the production output setting.

## Local workflow

```sh
npm ci
npm run inventory
npm run build
npm run test:e2e
npm run dev
```

The source audit uses Plus `dev` commit `ac6374135b68a78e167cd8557d3a1babf51f9c24` and Psych commit `e2e36943bfe1d4d6407becafcf6d64e631122cb1`. Stable and platform support remain unclaimed until tested.
