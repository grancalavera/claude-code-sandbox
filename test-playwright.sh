#!/bin/bash
set -e

DIR=$(mktemp -d)
cd "$DIR"

npm init -y --silent
npm install playwright --silent

node -e "
const { chromium } = require('playwright');
(async () => {
  const browser = await chromium.launch({
    executablePath: process.env.CHROMIUM_PATH || '/usr/bin/chromium',
  });
  const page = await browser.newPage();
  await page.setContent('<h1>Hello from Playwright</h1>');
  const title = await page.evaluate(() => document.querySelector('h1').textContent);
  console.log('Content:', title);
  await browser.close();
  console.log('Playwright test passed!');
})();
"

rm -rf "$DIR"
