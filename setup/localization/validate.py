"""Validate bundled language packs without contacting any external service.

Run from any directory: python setup/localization/validate.py
"""
from __future__ import annotations

import collections
import json
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[2]
PACKS = ROOT / 'assets/shared/languages'
MARKERS = re.compile(r'\{\d+\}|%[vd]')
API = re.compile(r'\b[a-z][a-zA-Z]*[A-Z][a-zA-Z]*\b')
HIDDEN = re.compile(r'[~&\\/;:<>#,\'"%?!]')
errors = []


def check(condition, message):
    if not condition:
        errors.append(message)


def read(path):
    raw = path.read_text(encoding='utf-8')
    check(not raw.startswith('\ufeff'), f'{path}: UTF-8 BOM')
    check('\ufffd' not in raw, f'{path}: replacement character')
    check('ZXQTOKEN' not in raw and 'ZXQLINE' not in raw, f'{path}: translation sentinel')
    return json.loads(raw, object_pairs_hook=unique_pairs)


def unique_pairs(pairs):
    result = {}
    for key, value in pairs:
        check(key not in result, f'Duplicate JSON key: {key}')
        result[key] = value
    return result


def flatten(data, prefix=''):
    result = {}
    for key, value in data.items():
        if key.startswith('$'):
            continue
        full = f'{prefix}.{key}' if prefix else key
        if isinstance(value, dict):
            result.update(flatten(value, full))
        else:
            check(isinstance(value, str), f'{full}: expected string')
            result[full] = value
    return result


def normalize(key):
    return HIDDEN.sub('', key.replace(' ', '_')).lower().strip()


def main():
    catalog = read(PACKS / 'index.json')
    entries = catalog['languages']
    check(len({e['code'] for e in entries}) == len(entries), 'Duplicate catalog language')
    english_manifest = read(PACKS / 'en-US/manifest.json')
    english = {}
    canonical = {}
    for bundle in english_manifest['bundles']:
        data = read(PACKS / 'en-US' / bundle)
        english[bundle] = data
        if bundle != 'assets.json':
            canonical.update(flatten(data, data['$namespace']))
    aliases_text = (ROOT / 'source/backend/TranslationKeys.hx').read_text('utf-8')
    aliases = dict(re.findall(r'"([^"]+)"\s*=>\s*"([^"]+)"', aliases_text))
    for old, new in aliases.items():
        check(normalize(old) == old, f'Unreachable unnormalized alias: {old}')
        check(new in canonical, f'Alias target missing: {old} -> {new}')
        check(new not in aliases, f'Chained alias: {new}')
    for entry in entries:
        code = entry['code']
        manifest = read(PACKS / code / 'manifest.json')
        check(manifest['code'] == code, f'{code}: manifest code mismatch')
        check(manifest['version'] == entry['version'], f'{code}: catalog version mismatch')
        check(manifest['name'] == entry['name'], f'{code}: catalog name mismatch')
        check(manifest['schemaVersion'] == 1, f'{code}: unsupported schema')
        check(manifest['fallback'] == ([] if code == 'en-US' else ['en-US']), f'{code}: invalid fallback')
        check(manifest['bundles'] == english_manifest['bundles'], f'{code}: bundle list mismatch')
        seen = set()
        for bundle in manifest['bundles']:
            path = PACKS / code / bundle
            data = read(path)
            check(data['$schema'] == 1, f'{code}/{bundle}: unsupported bundle schema')
            check(data['$namespace'] == english[bundle]['$namespace'], f'{code}/{bundle}: namespace mismatch')
            local = flatten(data)
            if bundle == 'assets.json':
                for source, target in local.items():
                    if source.startswith('fonts/'):
                        check((ROOT / 'assets' / target).is_file(), f'{code}: missing font {target}')
                continue
            base = flatten(english[bundle])
            for key in base:
                check(all(len(part) <= 48 for part in key.split('.')), f'{bundle}: use a shorter key: {key}')
            check(local.keys() == base.keys(), f'{code}/{bundle}: keys differ: missing {base.keys() - local.keys()}, extra {local.keys() - base.keys()}')
            for key in local.keys() & base.keys():
                value, original = local[key], base[key]
                check(bool(value.strip()) or not original.strip(), f'{code}/{bundle}:{key}: empty translation')
                check(collections.Counter(MARKERS.findall(value)) == collections.Counter(MARKERS.findall(original)), f'{code}/{bundle}:{key}: placeholders differ')
                if bundle == 'errors/script_debug.json' or '.details.' in '.' + key:
                    for api in API.findall(original):
                        check(api in value, f'{code}/{bundle}:{key}: API changed: {api}')
                full = normalize(data['$namespace'] + '.' + key)
                full = aliases.get(full, full)
                check(full not in seen, f'{code}: normalized key collision: {full}')
                seen.add(full)
        print(f'{code}: {len(manifest["bundles"])} bundles, {len(seen)} phrases')
    installed = {p.name for p in PACKS.iterdir() if p.is_dir()}
    check(installed == {e['code'] for e in entries}, 'Catalog does not match bundled pack folders')
    # Verify literal phrase references and short chart-editor helper references.
    canonical_keys = {normalize(k) for k in canonical}
    for path in (ROOT / 'source').rglob('*.hx'):
        text = path.read_text('utf-8')
        references = re.findall(r'Language\.getPhrase(?:ForLanguage)?\(\s*[\'"]([a-z][a-z0-9_./]+)[\'"]', text)
        if path.name == 'ChartingState.hx':
            references += ['editors.charting.' + key for key in re.findall(r'chartPhrase\(\s*[\'"]([a-z0-9_.]+)[\'"]', text)]
        for key in references:
            if '.' not in key or '/' in key:
                continue
            key = normalize(key)
            check(aliases.get(key, key) in canonical_keys, f'{path.relative_to(ROOT)}: unknown translation {key}')
    if errors:
        print('\n'.join(errors), file=sys.stderr)
        return 1
    print(f'OK: {len(entries)} languages; aliases, references, fonts and placeholders validated.')
    return 0


if __name__ == '__main__':
    sys.stdout.reconfigure(encoding='utf-8')
    sys.stderr.reconfigure(encoding='utf-8')
    raise SystemExit(main())
