import { defineCollection } from 'astro:content';
import { docsLoader, i18nLoader } from '@astrojs/starlight/loaders';
import { docsSchema, i18nSchema } from '@astrojs/starlight/schema';

export const collections = {
  docs: defineCollection({
    loader: docsLoader({
      generateId: ({ entry, data }) => {
        if (data.slug) return String(data.slug);
        const id = entry.replace(/\.[^.]+$/, '').replace(/\/index$/, '');
        return id || 'index';
      }
    }),
    schema: docsSchema()
  }),
  i18n: defineCollection({ loader: i18nLoader(), schema: i18nSchema() })
};
