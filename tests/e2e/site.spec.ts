import { expect, test } from '@playwright/test';

test.beforeEach(async ({ page }) => {
  await page.route(/^https:\/\/(?:fonts\.googleapis\.com|fonts\.gstatic\.com|www\.youtube-nocookie\.com)\//, (route) => route.abort());
});

test('documentation home uses the formal reference layout and real media', async ({ page }) => {
  await page.goto('/');
  await expect(page.getByRole('heading', { name: 'Plus Engine', exact: true })).toBeVisible();
  await expect(page.getByRole('heading', { name: 'API documentation' })).toBeVisible();
  await expect(page.locator('.documentation-videos video')).toHaveCount(4);
  expect(await page.locator('.docs-intro-logo').evaluate((image: HTMLImageElement) => image.naturalWidth)).toBeGreaterThan(0);
});

test('Spanish home is translated without mojibake', async ({ page }) => {
  await page.goto('/es/');
  await expect(page.getByRole('heading', { name: 'Documentación de API' })).toBeVisible();
  await expect(page.locator('body')).not.toContainText('Ã');
});

test('Psych search matches function names across all sections', async ({ page }) => {
  await page.goto('/pages/playstate/');
  await page.locator('#pageSearch').fill('makeLuaSprite');
  await expect(page.locator('#pageNav a')).toHaveCount(1);
  await expect(page.locator('#pageNav a').first()).toContainText('makeLuaSprite');
  await expect(page.locator('#pageNav a').first()).toHaveAttribute('href', /spritesheet.*makeLuaSprite/);
});

test('Plus search matches functions outside the current section', async ({ page }) => {
  await page.goto('/plus/pages/modifiers/');
  await page.locator('#pageSearch').fill('playLuaVideoSprite');
  await expect(page.locator('#pageNav a').first()).toContainText('playLuaVideoSprite');
  await expect(page.locator('#pageNav a').first()).toHaveAttribute('href', /video.*playLuaVideoSprite/);
});

test('community directory groups videos under selected porters', async ({ page }) => {
  await page.goto('/community/');
  await expect(page.getByRole('heading', { name: 'Psych Engine porters' })).toBeVisible();
  await expect(page.locator('.porter-profile')).toHaveCount(8);
  await expect(page.locator('.community-video-card')).toHaveCount(24);
  await expect(page.locator('.compatibility-state')).toHaveCount(0);

  await page.locator('#porterFilter').selectOption('junior07beta');
  await expect(page.locator('.porter-profile')).toHaveCount(1);
  await expect(page.getByRole('heading', { name: 'Junior07BETA' })).toBeVisible();
  await page.locator('.video-poster').first().click();
  await expect(page.locator('.community-video-card iframe')).toHaveCount(1);
});

test('Plus home mirrors the Psych documentation shell', async ({ page }) => {
  await page.goto('/plus/');
  await expect(page.locator('.psych-layout')).toHaveCount(1);
  await expect(page.locator('.psych-sidebar')).toHaveCount(1);
  await expect(page.locator('.psych-hero')).toHaveCount(1);
  await expect(page.locator('#sectionSearch')).toBeVisible();
});

test('visitor counter is added at the end of every page', async ({ page }) => {
  await page.goto('/pages/playstate/');
  await expect(page.locator('body > .site-counter')).toHaveCount(1);
  await expect(page.locator('.site-counter img')).toHaveAttribute('src', /count\.getloli\.com\/@psych-plus-page/);
});

test('mobile API navigation opens without horizontal overflow', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 });
  await page.goto('/pages/playstate/');
  await page.getByRole('button', { name: 'Menu' }).click();
  await expect(page.locator('body')).toHaveClass(/nav-open/);
  expect(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth)).toBeTruthy();
});
