import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';

export default defineConfig({
  site: 'https://psych-plus-engine.cc',
  integrations: [
    starlight({
      title: 'Plus Engine',
      description: 'Guides and verified API reference for Plus Engine modding.',
      defaultLocale: 'root',
      locales: {
        root: { label: 'English', lang: 'en' },
        'es-LA': { label: 'Español (Latinoamérica)', lang: 'es-LA' }
      },
      social: [
        { icon: 'github', label: 'GitHub', href: 'https://github.com/LeninAsto/FNF-PlusEngine' },
        { icon: 'discord', label: 'Discord', href: 'https://discord.gg/EBvUWcMdqV' }
      ],
      head: [{ tag: 'script', attrs: { src: '/language-entry.js' } }],
      components: {
        LanguageSelect: './src/components/LanguageSelect.astro'
      },
      customCss: ['./src/styles/material.css'],
      sidebar: [
        {
          label: 'Start here',
          translations: { 'es-LA': 'Primeros pasos' },
          items: [
            { label: 'Overview', translations: { 'es-LA': 'Introducción' }, slug: 'index' },
            { label: 'Create a mod', translations: { 'es-LA': 'Crear un mod' }, slug: 'guides/create-mod' }
          ]
        },
        {
          label: 'Scripting',
          items: [
            { label: 'Lua', slug: 'scripting/lua' },
            { label: 'HScript', slug: 'scripting/hscript' }
          ]
        },
        {
          label: 'API reference',
          translations: { 'es-LA': 'Referencia API' },
          items: [
            { label: 'Psych PlayState', slug: 'api/psych/playstate' },
            { label: 'Plus modifiers', translations: { 'es-LA': 'Modifiers de Plus' }, slug: 'api/plus/modifiers' }
          ]
        }
      ]
    })
  ]
});
