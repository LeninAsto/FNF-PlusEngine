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

test('community catalog filters, sorts and progressively loads videos', async ({ page }) => {
  await page.goto('/community/');
  await expect(page.getByRole('heading', { name: 'Psych Engine porters' })).toBeVisible();
  await expect(page.locator('.community-video-card')).toHaveCount(10);
  await expect(page.locator('#portsStatus')).toHaveText('10 of 150 videos');

  await page.locator('#loadMorePorts').click();
  await expect(page.locator('.community-video-card')).toHaveCount(20);

  await page.locator('#porterFilter').selectOption('junior07beta');
  await expect(page.getByRole('heading', { name: 'Junior07BETA' })).toBeVisible();
  await expect(page.locator('.community-video-card')).toHaveCount(10);
  await expect(page.locator('#communityHeroImage')).toHaveAttribute('src', /junior07beta\.jpg/);
  await expect(page.locator('.video-channel-link').first()).toHaveAttribute('href', 'https://www.youtube.com/@Junior_07_BETA');

  const mostPopular = await page.evaluate(async () => {
    const data = await fetch('../data/ports.json').then((response) => response.json());
    return data.videos.filter((video) => video.porter === 'junior07beta').sort((left, right) => right.views - left.views)[0].id;
  });
  await page.locator('#videoSort').selectOption('popular');
  await expect(page.locator('.video-poster').first()).toHaveAttribute('data-video-id', mostPopular);
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
  await expect(page.locator('.site-counter-title')).toHaveText('Page Views');
  await expect(page.locator('.site-counter img')).toHaveAttribute('src', /count\.getloli\.com\/@psych-plus-page/);
});

test('mobile API navigation opens without horizontal overflow', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 });
  await page.goto('/pages/playstate/');
  await page.getByRole('button', { name: 'Menu' }).click();
  await expect(page.locator('body')).toHaveClass(/nav-open/);
  expect(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth)).toBeTruthy();
});
