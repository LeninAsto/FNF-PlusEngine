import { expect, test } from '@playwright/test';

test('device language is applied only at the entry page', async ({ browser }) => {
  const context = await browser.newContext({ locale: 'es-PE' });
  const page = await context.newPage();

  await page.goto('/');
  await expect(page).toHaveURL(/\/es-LA\/$/);
  await expect(page.locator('html')).toHaveAttribute('lang', 'es-LA');

  await page.goto('/api/psych/playstate/');
  await expect(page).toHaveURL(/\/api\/psych\/playstate\/$/);
  await expect(page.locator('html')).toHaveAttribute('lang', 'en');
  await context.close();
});

test('English device preference stays at the unprefixed entry', async ({ browser }) => {
  const context = await browser.newContext({ locale: 'en-US' });
  const page = await context.newPage();
  await page.goto('/');
  await expect(page).toHaveURL('http://127.0.0.1:4321/');
  await expect(page.locator('html')).toHaveAttribute('lang', 'en');
  await context.close();
});

test('manual preference persists and Automatic restores device language', async ({ browser }) => {
  const context = await browser.newContext({ locale: 'es-PE' });
  const page = await context.newPage();
  await page.goto('/es-LA/guides/create-mod/');

  await page.locator('plus-language-select select').first().selectOption('/guides/create-mod/');
  await expect(page).toHaveURL(/\/guides\/create-mod\/$/);
  await page.goto('/');
  await expect(page).toHaveURL('http://127.0.0.1:4321/');

  await page.locator('plus-language-select select').first().selectOption('__automatic__');
  await expect(page).toHaveURL(/\/es-LA\/$/);
  await context.close();
});

test('language switch keeps the matching anchor', async ({ page }) => {
  await page.goto('/api/psych/playstate/#startCountdown');
  await page.locator('plus-language-select select').first().selectOption('/es-LA/api/psych/playstate/');
  await expect(page).toHaveURL(/\/es-LA\/api\/psych\/playstate\/#startCountdown$/);
  await expect(page.locator('#startCountdown')).toBeVisible();
});

test('unverified API status and translated fallback are explicit', async ({ page }) => {
  await page.goto('/es-LA/api/psych/playstate/');
  await expect(page.getByText('Traducción y compatibilidad en revisión')).toBeVisible();
  await expect(page.getByText('Necesita revisión').first()).toBeVisible();
  await expect(page.getByText('Verified').first()).toHaveCount(0);
});

test('English documentation remains readable without JavaScript', async ({ browser }) => {
  const context = await browser.newContext({ javaScriptEnabled: false });
  const page = await context.newPage();
  await page.goto('/api/psych/playstate/');
  await expect(page.getByRole('heading', { name: 'PlayState Functions' })).toBeVisible();
  await expect(page.locator('#startCountdown')).toBeVisible();
  await context.close();
});

test('320px layout has no global horizontal overflow and opens the menu', async ({ page }) => {
  await page.setViewportSize({ width: 320, height: 720 });
  await page.goto('/api/plus/modifiers/');
  const hasOverflow = await page.evaluate(() => document.documentElement.scrollWidth > document.documentElement.clientWidth);
  expect(hasOverflow).toBe(false);
  const menu = page.getByRole('button', { name: 'Menu' });
  await menu.click();
  await expect(page.locator('#starlight__sidebar')).toBeVisible();
  await page.keyboard.press('Escape');
  await expect(page.locator('#starlight__sidebar')).toBeHidden();
});

test('modifier videos are deferred and never autoplay', async ({ page }) => {
  await page.goto('/api/plus/modifiers/');
  const videos = page.locator('video');
  await expect(videos).toHaveCount(4);
  for (let index = 0; index < await videos.count(); index += 1) {
    await expect(videos.nth(index)).toHaveAttribute('preload', 'none');
    await expect(videos.nth(index)).not.toHaveAttribute('autoplay', '');
  }
});

test('legacy routes redirect to implemented localized pages', async ({ request }) => {
  const response = await request.get('/es/pages/camera/?source=legacy', { maxRedirects: 0 });
  expect(response.status()).toBe(301);
  expect(response.headers().location).toBe('/es-LA/api/psych/camera/?source=legacy');
});

test('production search index is served locally', async ({ request }) => {
  const response = await request.get('/pagefind/pagefind.js');
  expect(response.status()).toBe(200);
  expect(response.headers()['content-type']).toContain('text/javascript');
});
