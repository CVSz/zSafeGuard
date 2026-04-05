const { test, expect } = require('@playwright/test')

test('homepage renders loading state', async ({ page }) => {
  await page.goto('/')
  await expect(page.getByText('Loading...')).toBeVisible()
})
