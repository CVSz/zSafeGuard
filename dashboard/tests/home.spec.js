const fs = require('fs')
const { test, expect } = require('@playwright/test')

const hasChromiumSystemDeps = [
  '/usr/lib/x86_64-linux-gnu/libatk-1.0.so.0',
  '/lib/x86_64-linux-gnu/libatk-1.0.so.0'
].some(path => fs.existsSync(path))

test.skip(!hasChromiumSystemDeps, 'Skipping browser E2E test: missing Chromium system libraries (libatk).')

test('homepage renders real-time dashboard shell', async ({ page }) => {
  await page.goto('/')
  await expect(page.getByRole('heading', { name: 'zSafeGuard Real-time Risk Dashboard' })).toBeVisible()
})
