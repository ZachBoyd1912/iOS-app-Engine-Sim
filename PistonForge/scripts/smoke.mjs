// End-to-end smoke test for Piston Forge.
// Boots the game in headless Chromium and plays the real loop:
//   title → career → garage → engine → ECU → dyno pull → drag run → settings → reload (save check)
// then repeats the key screens at an iPhone-sized portrait viewport.
// Fails on any console error, page error, failed request or sideways page overflow.
// Screenshots land in ./shots/.
//
// By default it runs against the Vite dev server so no local production build is needed
// (this project is developed on a low-memory machine). Set SMOKE_TARGET=preview to test dist/.
import { spawn } from 'node:child_process'
import { mkdirSync } from 'node:fs'
import { chromium } from 'playwright'

const target = process.env.SMOKE_TARGET === 'preview' ? 'preview' : 'dev'
const port = 4300 + Math.floor(Math.random() * 500)
const url = `http://127.0.0.1:${port}/`
const out = process.env.SHOTS_DIR ?? 'shots'
mkdirSync(out, { recursive: true })

const viteArgs = target === 'preview'
  ? ['preview', '--port', String(port), '--strictPort', '--host', '127.0.0.1']
  : ['--port', String(port), '--strictPort', '--host', '127.0.0.1']
const server = spawn(process.execPath, ['node_modules/vite/bin/vite.js', ...viteArgs], { stdio: 'ignore' })
let browser
const guard = setTimeout(() => fail('timed out after 600 s'), 600_000)

function cleanup() {
  clearTimeout(guard)
  try { server.kill('SIGTERM') } catch {}
}
async function fail(msg) {
  console.error(`smoke: FAIL — ${msg}`)
  await browser?.close().catch(() => {})
  cleanup()
  process.exit(1)
}

async function waitForServer() {
  for (let i = 0; i < 120; i += 1) {
    try {
      if ((await fetch(url)).ok) return
    } catch {}
    await new Promise(r => setTimeout(r, 250))
  }
  throw new Error(`${target} server did not start`)
}

function watch(page, errors, label) {
  page.on('console', m => m.type() === 'error' && errors.push(`[${label}] console: ${m.text()}`))
  page.on('pageerror', e => errors.push(`[${label}] pageerror: ${String(e)}`))
  page.on('requestfailed', r => errors.push(`[${label}] request failed: ${r.url()} ${r.failure()?.errorText ?? ''}`))
  page.on('response', r => r.status() >= 400 && errors.push(`[${label}] HTTP ${r.status()} ${r.url()}`))
}

const screenIs = (page, name) => page.waitForSelector(`#ui[data-screen="${name}"]`, { timeout: 30_000 })
const game = (page, fn) => page.evaluate(fn)
const act = (page, action) => page.click(`[data-action="${action}"]:visible`)

async function openGame(context, errors, label) {
  const page = await context.newPage()
  watch(page, errors, label)
  await page.goto(url)
  await page.waitForSelector('html[data-ready="true"]', { state: 'attached', timeout: 180_000 })
  await screenIs(page, 'title')
  await page.waitForTimeout(900)
  return page
}

async function assertNoSidewaysScroll(page, label) {
  const { scroll, client } = await page.evaluate(() => ({
    scroll: document.documentElement.scrollWidth,
    client: document.documentElement.clientWidth,
  }))
  if (scroll > client + 1) throw new Error(`${label}: page is wider than the screen (${scroll}px > ${client}px)`)
}

try {
  await waitForServer()
  const args = ['--ignore-gpu-blocklist', '--enable-unsafe-swiftshader']
  browser = await chromium.launch({ args }).catch(() => chromium.launch({ args, channel: 'chrome' }))
  const errors = []

  // ---- Desktop: the full loop -------------------------------------------------------------
  const desktop = await browser.newContext({ viewport: { width: 1280, height: 720 }, locale: 'en-US' })
  const page = await openGame(desktop, errors, 'desktop')
  await page.screenshot({ path: `${out}/01-title.png` })

  await act(page, 'start-career')
  await screenIs(page, 'garage')
  await page.waitForTimeout(700)
  await page.screenshot({ path: `${out}/02-garage.png` })

  // Phones take the GPU context away in the background. Take it away here and check the
  // scene comes back and keeps drawing without errors.
  const context = await page.evaluate(async () => {
    const canvas = document.getElementById('game')
    const gl = canvas.getContext('webgl2') ?? canvas.getContext('webgl')
    const ext = gl?.getExtension('WEBGL_lose_context')
    if (!gl || !ext) return 'unsupported'
    const wait = ms => new Promise(resolve => setTimeout(resolve, ms))
    ext.loseContext()
    await wait(400)
    const wasLost = gl.isContextLost()
    ext.restoreContext()
    await wait(1200)
    return wasLost && !gl.isContextLost() ? 'restored' : 'not-restored'
  })
  if (context !== 'restored') throw new Error(`WebGL context loss was not recovered (${context})`)
  await page.waitForTimeout(600)
  await page.screenshot({ path: `${out}/02b-garage-after-context-loss.png` })
  console.log('smoke: WebGL context lost and restored, scene still drawing')

  await act(page, 'go-engine')
  await screenIs(page, 'engine')
  await page.waitForTimeout(700)
  await page.screenshot({ path: `${out}/03-engine.png` })

  await act(page, 'go-ecu')
  await screenIs(page, 'ecu')
  await page.waitForTimeout(500)
  await page.screenshot({ path: `${out}/04-ecu.png` })

  await act(page, 'go-dyno')
  await screenIs(page, 'dyno')
  const pullsBefore = await game(page, () => window.__game.app.state.pulls)
  await act(page, 'run-dyno')
  await page.waitForFunction(before => window.__game.app.state.pulls > before, pullsBefore, { timeout: 60_000 })
  await page.waitForTimeout(600)
  await page.screenshot({ path: `${out}/05-dyno-result.png` })
  const dyno = await game(page, () => {
    const d = window.__game.app.activeBuild().dyno
    return d ? { hp: d.peakHp, torque: d.peakTorque, points: d.points.length } : null
  })
  if (!dyno || !(dyno.hp > 0) || !(dyno.torque > 0) || dyno.points < 10) throw new Error(`dyno pull produced no usable result: ${JSON.stringify(dyno)}`)
  console.log(`smoke: dyno pull ${dyno.hp.toFixed(0)} hp / ${dyno.torque.toFixed(0)} torque over ${dyno.points} points`)

  // Close any result modal, then run the quarter mile through the real app actions.
  await game(page, () => { window.__game.ui.closeModal?.() })
  await game(page, () => {
    const { app } = window.__game
    app.setScreen('test')
    app.setTestTab('drag')
  })
  await screenIs(page, 'test')
  await page.waitForTimeout(400)
  await game(page, () => window.__game.app.stageDrag())
  await page.waitForTimeout(600)
  await game(page, () => window.__game.app.startTree())
  // Headless software rendering runs at a few frames a second, so the 60 Hz simulation would
  // take minutes of wall time. Advance the real fixed-step simulation directly instead: same
  // code path the frame loop calls, just not waiting on the renderer.
  await game(page, () => {
    const { app } = window.__game
    for (let i = 0; i < 60 * 40 && !app.activeBuild().drag; i += 1) app.step(1 / 60)
  })
  await page.waitForFunction(() => Boolean(window.__game.app.activeBuild().drag), null, { timeout: 15_000 })
  await page.waitForTimeout(600)
  await page.screenshot({ path: `${out}/06-drag-result.png` })
  const drag = await game(page, () => window.__game.app.activeBuild().drag)
  if (!drag || !(drag.topSpeed > 0)) throw new Error(`drag run produced no usable result: ${JSON.stringify(drag)}`)
  console.log(`smoke: drag run valid=${drag.valid} et=${Number(drag.et ?? 0).toFixed(2)} s top=${drag.topSpeed.toFixed(0)}`)

  await game(page, () => { window.__game.ui.closeModal?.(); window.__game.app.setScreen('settings') })
  await screenIs(page, 'settings')
  await page.waitForTimeout(400)
  await page.screenshot({ path: `${out}/07-settings.png` })

  // Save survives a reload.
  const saved = await game(page, () => { window.__game.app.saveNow(); return window.__game.app.state.pulls })
  await page.reload()
  await page.waitForSelector('html[data-ready="true"]', { state: 'attached', timeout: 180_000 })
  const restored = await game(page, () => ({ pulls: window.__game.app.state.pulls, intro: window.__game.app.state.introSeen }))
  if (restored.pulls !== saved || !restored.intro) throw new Error(`save did not survive a reload (saved pulls ${saved}, restored ${JSON.stringify(restored)})`)
  console.log(`smoke: save restored after reload (pulls ${restored.pulls})`)
  await desktop.close()

  // ---- Phone portrait (iPhone-sized, 430 pt wide) ------------------------------------------
  const phone = await browser.newContext({ viewport: { width: 430, height: 932 }, deviceScaleFactor: 1, isMobile: true, hasTouch: true, locale: 'en-US' })
  const mobile = await openGame(phone, errors, 'phone')
  await assertNoSidewaysScroll(mobile, 'phone title')
  await mobile.screenshot({ path: `${out}/08-phone-title.png` })
  await mobile.tap('[data-action="start-career"]')
  await screenIs(mobile, 'garage')
  await mobile.waitForTimeout(700)
  await assertNoSidewaysScroll(mobile, 'phone garage')
  await mobile.screenshot({ path: `${out}/09-phone-garage.png` })
  for (const [index, screen] of [['10', 'engine'], ['11', 'ecu'], ['12', 'dyno'], ['13', 'test'], ['14', 'shop'], ['15', 'jobs']]) {
    await game(mobile, () => window.__game.ui.closeModal?.())
    await mobile.evaluate(name => window.__game.app.setScreen(name), screen)
    await screenIs(mobile, screen)
    await mobile.waitForTimeout(500)
    await assertNoSidewaysScroll(mobile, `phone ${screen}`)
    await mobile.screenshot({ path: `${out}/${index}-phone-${screen}.png` })
  }
  await phone.close()

  // ---- Phone landscape ---------------------------------------------------------------------
  const land = await browser.newContext({ viewport: { width: 932, height: 430 }, deviceScaleFactor: 1, isMobile: true, hasTouch: true, locale: 'en-US' })
  const landPage = await openGame(land, errors, 'landscape')
  await landPage.tap('[data-action="start-career"]')
  await screenIs(landPage, 'garage')
  await landPage.waitForTimeout(700)
  await landPage.screenshot({ path: `${out}/16-landscape-garage.png` })
  await land.close()

  if (errors.length) throw new Error(`browser errors:\n  ${errors.join('\n  ')}`)
  await browser.close()
  cleanup()
  console.log(`smoke: OK (${target}) — screenshots in ${out}/`)
} catch (err) {
  await fail(err?.message ?? String(err))
}
