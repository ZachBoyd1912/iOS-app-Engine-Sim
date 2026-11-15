// Captures App Store screenshots of the real game UI at the exact pixel sizes App Store
// Connect accepts, for iPhone and iPad. No mock-ups: every image is the running game.
//
//   node scripts/store-screenshots.mjs            all sets
//   node scripts/store-screenshots.mjs ipad-13    one set
//
// Output: ../docs/store/screenshots/<set>/NN-<screen>.png (raw UI, no caption overlay).
// The order matches the captions in docs/store/listing.md.
import { spawn } from 'node:child_process'
import { mkdirSync, readFileSync } from 'node:fs'
import { chromium } from 'playwright'

// CSS viewport x device scale = the pixel size App Store Connect requires.
const SETS = {
  'iphone-6.9': { width: 440, height: 956, scale: 3, phone: true }, // 1320 x 2868
  'iphone-6.3': { width: 402, height: 874, scale: 3, phone: true }, // 1206 x 2622
  'ipad-13': { width: 1032, height: 1376, scale: 2, phone: false }, // 2064 x 2752
}

const wanted = process.argv.slice(2)
const sets = Object.entries(SETS).filter(([name]) => wanted.length === 0 || wanted.includes(name))
if (sets.length === 0) {
  console.error(`Unknown set. Choose from: ${Object.keys(SETS).join(', ')}`)
  process.exit(1)
}

const port = 4800 + Math.floor(Math.random() * 150)
const url = `http://127.0.0.1:${port}/`
const outRoot = process.env.SHOTS_DIR ?? '../docs/store/screenshots'
const server = spawn(process.execPath, ['node_modules/vite/bin/vite.js', '--port', String(port), '--strictPort', '--host', '127.0.0.1'], { stdio: 'ignore' })
let browser

async function waitForServer() {
  for (let i = 0; i < 120; i += 1) {
    try {
      if ((await fetch(url)).ok) return
    } catch {}
    await new Promise(r => setTimeout(r, 250))
  }
  throw new Error('dev server did not start')
}

/** Width, height and colour type straight from the PNG header. */
function pngInfo(path) {
  const bytes = readFileSync(path)
  return { width: bytes.readUInt32BE(16), height: bytes.readUInt32BE(20), colorType: bytes[25] }
}

// Software rendering at these sizes takes a while to put a frame on screen.
const SETTLE_MS = 3500

async function capture(name, set) {
  const dir = `${outRoot}/${name}`
  mkdirSync(dir, { recursive: true })
  const context = await browser.newContext({
    viewport: { width: set.width, height: set.height },
    deviceScaleFactor: set.scale,
    isMobile: set.phone,
    hasTouch: true,
    locale: 'en-US',
  })
  const page = await context.newPage()
  const errors = []
  page.on('pageerror', e => errors.push(String(e)))
  await page.goto(url)
  await page.waitForSelector('html[data-ready="true"]', { state: 'attached', timeout: 240_000 })

  const shot = async file => {
    await page.waitForTimeout(SETTLE_MS)
    const path = `${dir}/${file}.png`
    // Software rendering a 2064 x 2752 scene can take longer than the 30 s default.
    await page.screenshot({ path, timeout: 300_000 })
    const info = pngInfo(path)
    const expected = { width: set.width * set.scale, height: set.height * set.scale }
    if (info.width !== expected.width || info.height !== expected.height) {
      throw new Error(`${path}: ${info.width}x${info.height}, expected ${expected.width}x${expected.height}`)
    }
    // Colour type 2 is RGB with no alpha channel, which is what App Store Connect wants.
    if (info.colorType !== 2) throw new Error(`${path}: PNG colour type ${info.colorType}; it must have no alpha channel (2)`)
    console.log(`  ${file}.png ${info.width}x${info.height}`)
  }

  // A clean career start with the coach card off, so the screens show the game itself.
  await page.evaluate(() => {
    const { app } = window.__game
    app.startCareer()
    app.updateSetting('tips', false)
  })

  await page.evaluate(() => window.__game.app.setScreen('engine'))
  await shot('01-engine')

  await page.evaluate(() => window.__game.app.setScreen('garage'))
  await shot('02-garage')

  await page.evaluate(() => window.__game.app.setScreen('ecu'))
  await shot('03-ecu')

  // Dyno: capture part-way through a real pull, with the trace building.
  await page.evaluate(() => {
    const { app } = window.__game
    app.setScreen('dyno')
    app.startDynoPull()
    for (let i = 0; i < 60 * 3; i += 1) app.step(1 / 60)
  })
  await shot('04-dyno')
  await page.evaluate(() => {
    const { app, ui } = window.__game
    const before = app.state.pulls
    for (let i = 0; i < 60 * 60 && app.state.pulls === before; i += 1) app.step(1 / 60)
    ui.closeModal?.()
  })

  // Strip: capture mid-run, after the launch.
  await page.evaluate(() => {
    const { app } = window.__game
    app.setScreen('test')
    app.setTestTab('drag')
    app.stageDrag()
    app.startTree()
    for (let i = 0; i < 60 * 7; i += 1) app.step(1 / 60)
  })
  await shot('05-strip')

  if (errors.length) throw new Error(`page errors in ${name}:\n  ${errors.join('\n  ')}`)
  await context.close()
}

try {
  await waitForServer()
  browser = await chromium.launch({ args: ['--ignore-gpu-blocklist', '--enable-unsafe-swiftshader'] })
  for (const [name, set] of sets) {
    console.log(`${name} (${set.width * set.scale} x ${set.height * set.scale})`)
    await capture(name, set)
  }
  await browser.close()
  server.kill('SIGTERM')
  console.log(`screenshots: OK in ${outRoot}/`)
} catch (error) {
  console.error(`screenshots: FAIL — ${error?.message ?? error}`)
  await browser?.close().catch(() => {})
  server.kill('SIGTERM')
  process.exit(1)
}
