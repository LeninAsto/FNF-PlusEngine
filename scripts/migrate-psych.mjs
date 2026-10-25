import { readFile, writeFile } from 'node:fs/promises';
import { resolve } from 'node:path';
import vm from 'node:vm';

const root = resolve(import.meta.dirname, '..');
const check = process.argv.includes('--check');
const upstreamCommit = 'e2e36943bfe1d4d6407becafcf6d64e631122cb1';
const legacyCommit = 'f75228d80ea9887ca1d69eedea3df71c67bf3fad';

const psychSource = await readFile(resolve(root, 'docs/assets/psych.js'), 'utf8');
const start = psychSource.indexOf('[');
const end = psychSource.indexOf('\n];\n\nfunction');
if (start < 0 || end < 0) throw new Error('Could not locate psychCategories in docs/assets/psych.js');

const categories = vm.runInNewContext(
  `(${psychSource.slice(start, end + 2)})`,
  Object.create(null),
  { timeout: 1000, contextCodeGeneration: { strings: false, wasm: false } }
);
const pageMeta = JSON.parse(await readFile(resolve(root, 'docs/data/psych-pages.json'), 'utf8')).categories;
const overrides = JSON.parse(await readFile(resolve(root, 'src/data/audit-overrides.json'), 'utf8'));
const expected = new Map();

function normalizedExamples(examples = []) {
  return examples.map((example) => typeof example === 'string'
    ? { code: example, description: '' }
    : { code: String(example.code ?? ''), description: String(example.description ?? '') });
}

function metadata(category, fn) {
  const key = `psych/${category.id}/${fn.name}`;
  const override = overrides[key] ?? {};
  const examples = normalizedExamples(fn.examples);
  const base = {
    id: fn.name,
    signature: fn.signature,
    origin: 'psych-upstream',
    status: 'needs-review',
    available: [],
    platforms: [],
    sourceLinks: [
      {
        label: 'Psych upstream reference',
        url: `https://github.com/ShadowMario/psychengine.lua/blob/${upstreamCommit}/pages/${category.id}.html`
      },
      {
        label: 'Legacy Plus catalog',
        url: `https://github.com/LeninAsto/FNF-PlusEngine/blob/${legacyCommit}/docs/assets/psych.js`
      },
      ...(override.appendSourceLinks ?? [])
    ],
    testedAtCommit: null,
    parameters: (fn.parameters ?? []).map((parameter) => ({
      name: parameter.name,
      type: parameter.type,
      optional: Boolean(parameter.optional)
    })),
    examples: examples.map(({ code }) => ({ code }))
  };
  for (const field of ['signature', 'parameters', 'examples', 'warnings']) {
    if (override[field] !== undefined) base[field] = override[field];
  }
  return base;
}

function englishCopy(category, fn) {
  const override = overrides[`psych/${category.id}/${fn.name}`] ?? {};
  const examples = normalizedExamples(fn.examples);
  return override.copy ?? {
    description: fn.description,
    parameters: Object.fromEntries((fn.parameters ?? []).map((parameter) => [parameter.name, parameter.description ?? ''])),
    examples: examples.map(({ description }) => description)
  };
}

function json(value) {
  return `${JSON.stringify(value, null, 2)}\n`;
}

function englishPage(category, meta) {
  return `---
title: ${JSON.stringify(meta.en.title)}
description: ${JSON.stringify(meta.en.summary)}
---

import ApiEntry from '../../../../components/ApiEntry.astro';
import api from '../../../../data/api/psych/${category.id}.json';
import copy from '../../../../data/translations/en/psych/${category.id}.json';

:::caution[Compatibility audit in progress]
These entries were migrated from the legacy catalog and linked to the pinned upstream reference. They remain **Needs review** until Plus runtime tests record a commit and platforms.
:::

{api.functions.map((entry) => <ApiEntry {...entry} copy={copy[entry.id]} locale="en" />)}
`;
}

function spanishPage(category, meta) {
  return `---
title: ${JSON.stringify(meta.es.title)}
description: ${JSON.stringify(meta.es.summary)}
---

import ApiEntry from '../../../../../components/ApiEntry.astro';
import api from '../../../../../data/api/psych/${category.id}.json';
import copy from '../../../../../data/translations/es-LA/psych/${category.id}.json';
import englishCopy from '../../../../../data/translations/en/psych/${category.id}.json';

:::caution[Traducción y compatibilidad en revisión]
Las descripciones que todavía no tienen traducción muestran el texto inglés original. Ninguna entrada se considera compatible con Plus hasta registrar pruebas en runtime, commit y plataformas.
:::

{api.functions.map((entry) => <ApiEntry {...entry} copy={copy[entry.id] ?? englishCopy[entry.id]} locale="es-LA" />)}
`;
}

for (const category of categories) {
  const meta = pageMeta[category.id];
  if (!meta) throw new Error(`Missing page metadata for ${category.id}`);
  const data = {
    category: category.id,
    language: 'lua',
    sourceCommit: upstreamCommit,
    functions: category.functions.map((fn) => metadata(category, fn))
  };
  const en = Object.fromEntries(category.functions.map((fn) => [fn.name, englishCopy(category, fn)]));

  expected.set(`src/data/api/psych/${category.id}.json`, json(data));
  expected.set(`src/data/translations/en/psych/${category.id}.json`, json(en));
  expected.set(`src/data/translations/es-LA/psych/${category.id}.json`, '{}\n');
  expected.set(`src/content/docs/api/psych/${category.id}.mdx`, englishPage(category, meta));
  expected.set(`src/content/docs/es-LA/api/psych/${category.id}.mdx`, spanishPage(category, meta));
}

const changed = [];
for (const [relativePath, content] of expected) {
  const path = resolve(root, relativePath);
  let current = null;
  try { current = await readFile(path, 'utf8'); } catch {}
  if (current === content) continue;
  changed.push(relativePath);
  if (!check) await writeFile(path, content);
}

if (check && changed.length) {
  console.error(`Generated Psych files are stale:\n${changed.map((file) => `- ${file}`).join('\n')}`);
  process.exit(1);
}

const functionCount = categories.reduce((count, category) => count + category.functions.length, 0);
console.log(`${check ? 'Checked' : 'Generated'} ${categories.length} Psych categories and ${functionCount} API entries.`);
