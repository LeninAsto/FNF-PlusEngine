import { readFile, writeFile } from 'node:fs/promises';
import { resolve } from 'node:path';

const root = resolve(import.meta.dirname, '..');
const check = process.argv.includes('--check');
const plusCommit = 'ac6374135b68a78e167cd8557d3a1babf51f9c24';
const legacyCommit = 'f75228d80ea9887ca1d69eedea3df71c67bf3fad';
const raw = JSON.parse((await readFile(resolve(root, 'docs/data/plus-api.json'), 'utf8')).replace(/^\uFEFF/, ''));
const expected = new Map();

function repairText(value) {
  if (typeof value !== 'string' || !/[ÃÂâ]/.test(value)) return value;
  const repaired = Buffer.from(value, 'latin1').toString('utf8');
  return repaired.includes('�') ? value : repaired;
}

function repair(value) {
  if (Array.isArray(value)) return value.map(repair);
  if (value && typeof value === 'object') return Object.fromEntries(Object.entries(value).map(([key, item]) => [key, repair(item)]));
  return repairText(value);
}

const source = repair(raw);
const sourceFiles = {
  video: 'source/psychlua/VideoFunctions.hx',
  modchart: 'source/psychlua/ModchartFunctions.hx',
  windows: 'source/psychlua/WindowsFunctions.hx',
  gdi: 'source/psychlua/WindowsFunctions.hx'
};

function json(value) {
  return `${JSON.stringify(value, null, 2)}\n`;
}

function params(value, signature) {
  if (!value) return [];
  return (Array.isArray(value) ? value : [value]).map((parameter) => ({
    name: parameter.name,
    type: parameter.type,
    optional: signature.includes(`?${parameter.name}`)
  }));
}

function parameterCopy(value, locale) {
  if (!value) return {};
  return Object.fromEntries((Array.isArray(value) ? value : [value]).map((parameter) => [
    parameter.name,
    parameter.description?.[locale] ?? ''
  ]));
}

function flattenFunctions(page) {
  if (page.functions) return page.functions.map((fn) => ({ ...fn, group: null }));
  return page.groups.flatMap((group) => group.functions.map((fn) => ({ ...fn, group: { en: group.en, es: group.es } })));
}

function functionData(pageId, page) {
  return {
    kind: 'functions',
    category: pageId,
    language: 'lua',
    sourceCommit: plusCommit,
    functions: flattenFunctions(page).map((fn) => ({
      id: fn.name,
      signature: fn.signature,
      origin: 'plus-added',
      status: 'needs-review',
      available: [],
      platforms: [],
      sourceLinks: [
        {
          label: 'Plus development source',
          url: `https://github.com/LeninAsto/FNF-PlusEngine/blob/${plusCommit}/${sourceFiles[pageId]}`
        },
        {
          label: 'Legacy Plus catalog',
          url: `https://github.com/LeninAsto/FNF-PlusEngine/blob/${legacyCommit}/docs/data/plus-api.json`
        }
      ],
      testedAtCommit: null,
      group: fn.group?.en ?? null,
      parameters: params(fn.params, fn.signature),
      examples: (fn.examples ?? []).map((example) => ({ code: typeof example === 'string' ? example : example.code }))
    }))
  };
}

function functionCopy(page, locale) {
  return Object.fromEntries(flattenFunctions(page).map((fn) => [fn.name, {
    description: fn[locale] ?? '',
    parameters: parameterCopy(fn.params, locale),
    examples: (fn.examples ?? []).map((example) => typeof example === 'string' ? '' : example.description?.[locale] ?? example.description ?? '')
  }]));
}

function functionPage(pageId, page, locale) {
  const spanish = locale === 'es-LA';
  const depth = spanish ? '../../../../../' : '../../../../';
  const langKey = spanish ? 'es' : 'en';
  const warning = page.warningText?.[langKey];
  return `---
title: ${JSON.stringify(page[langKey].title)}
description: ${JSON.stringify(page[langKey].summary)}
---

import ApiEntry from '${depth}components/ApiEntry.astro';
import api from '${depth}data/api/plus/${pageId}.json';
import copy from '${depth}data/translations/${locale}/plus/${pageId}.json';

:::caution[${spanish ? 'Compatibilidad en revisión' : 'Compatibility audit in progress'}]
${spanish ? 'Estas entradas se compararon con el código de desarrollo, pero todavía no tienen pruebas registradas por versión y plataforma.' : 'These entries were linked to development source, but do not yet have recorded tests by version and platform.'}
:::
${warning ? `\n:::danger[${spanish ? 'Advertencia de plataforma' : 'Platform warning'}]\n${warning}\n:::\n` : ''}
{api.functions.map((entry) => <ApiEntry {...entry} copy={copy[entry.id]} locale="${locale}" />)}
`;
}

for (const pageId of ['video', 'modchart', 'windows', 'gdi']) {
  const page = source.pages[pageId];
  expected.set(`src/data/api/plus/${pageId}.json`, json(functionData(pageId, page)));
  expected.set(`src/data/translations/en/plus/${pageId}.json`, json(functionCopy(page, 'en')));
  expected.set(`src/data/translations/es-LA/plus/${pageId}.json`, json(functionCopy(page, 'es')));
  expected.set(`src/content/docs/api/plus/${pageId}.mdx`, functionPage(pageId, page, 'en'));
  expected.set(`src/content/docs/es-LA/api/plus/${pageId}.mdx`, functionPage(pageId, page, 'es-LA'));
}

const modifierPage = source.pages.modifiers;
const modifierData = {
  kind: 'modifiers',
  category: 'modifiers',
  sourceCommit: plusCommit,
  items: modifierPage.items.map((item) => ({
    id: item.aliases[0],
    name: item.name,
    aliases: item.aliases,
    origin: 'plus-added',
    status: 'needs-review',
    available: [],
    platforms: [],
    sourceLinks: [
      {
        label: 'Plus modifier implementation',
        url: `https://github.com/LeninAsto/FNF-PlusEngine/tree/${plusCommit}/source/modchart/engine/modifiers`
      }
    ],
    testedAtCommit: null,
    video: item.video
  }))
};
for (const locale of ['en', 'es-LA']) {
  const langKey = locale === 'es-LA' ? 'es' : 'en';
  const copy = Object.fromEntries(modifierPage.items.map((item) => [item.aliases[0], {
    description: item[langKey],
    videoNote: item.videoNote?.[langKey] ?? null
  }]));
  const depth = locale === 'es-LA' ? '../../../../../' : '../../../../';
  const page = `---
title: ${JSON.stringify(modifierPage[langKey].title)}
description: ${JSON.stringify(modifierPage[langKey].summary)}
---

import ModifierEntry from '${depth}components/ModifierEntry.astro';
import data from '${depth}data/api/plus/modifiers.json';
import copy from '${depth}data/translations/${locale}/plus/modifiers.json';

:::caution[${locale === 'es-LA' ? 'Compatibilidad en revisión' : 'Compatibility audit in progress'}]
${locale === 'es-LA' ? 'La lista proviene del catálogo anterior y del árbol de código de desarrollo. Cada modifier permanece sin verificar hasta completar las pruebas visuales y de plataforma.' : 'This list comes from the legacy catalog and development source tree. Each modifier remains unverified until visual and platform tests are complete.'}
:::

{data.items.map((entry) => <ModifierEntry {...entry} {...copy[entry.id]} locale="${locale}" />)}
`;
  expected.set(`src/data/translations/${locale}/plus/modifiers.json`, json(copy));
  expected.set(`src/content/docs/${locale === 'es-LA' ? 'es-LA/' : ''}api/plus/modifiers.mdx`, page);
}
expected.set('src/data/api/plus/modifiers.json', json(modifierData));

const variablesPage = source.pages.variables;
const variablesData = {
  kind: 'glossary',
  category: 'variables',
  sourceCommit: plusCommit,
  groups: variablesPage.groups.map((group) => ({ id: group.en.toLowerCase().replace(/[^a-z0-9]+/g, '-'), items: group.items }))
};
for (const locale of ['en', 'es-LA']) {
  const langKey = locale === 'es-LA' ? 'es' : 'en';
  const copy = {
    intro: variablesPage[langKey].intro,
    groups: variablesPage.groups.map((group) => group[langKey])
  };
  const depth = locale === 'es-LA' ? '../../../../../' : '../../../../';
  const page = `---
title: ${JSON.stringify(variablesPage[langKey].title)}
description: ${JSON.stringify(variablesPage[langKey].summary)}
---

import data from '${depth}data/api/plus/variables.json';
import copy from '${depth}data/translations/${locale}/plus/variables.json';

:::caution[${locale === 'es-LA' ? 'Glosario en revisión' : 'Glossary under review'}]
${locale === 'es-LA' ? 'Estos nombres ayudan a navegar la API, pero no implican que cada valor sea una variable global accesible en todas las plataformas.' : 'These names help navigate the API, but do not imply that every value is a global variable available on every platform.'}
:::

{copy.intro}

{data.groups.map((group, index) => (
  <section aria-labelledby={group.id}>
    <h2 id={group.id}>{copy.groups[index]}</h2>
    <p>{group.items.map((item) => <code style="margin-inline-end: 0.5rem">{item}</code>)}</p>
  </section>
))}
`;
  expected.set(`src/data/translations/${locale}/plus/variables.json`, json(copy));
  expected.set(`src/content/docs/${locale === 'es-LA' ? 'es-LA/' : ''}api/plus/variables.mdx`, page);
}
expected.set('src/data/api/plus/variables.json', json(variablesData));

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
  console.error(`Generated Plus files are stale:\n${changed.map((file) => `- ${file}`).join('\n')}`);
  process.exit(1);
}

const functionCount = ['video', 'modchart', 'windows', 'gdi']
  .reduce((count, pageId) => count + flattenFunctions(source.pages[pageId]).length, 0);
console.log(`${check ? 'Checked' : 'Generated'} 6 Plus categories, ${functionCount} functions, and ${modifierData.items.length} modifiers.`);
