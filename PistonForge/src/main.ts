import './styles/forge.css'
import { App } from './app'
import { SoundEngine } from './audio/sound'
import { Stage } from './game/stage'
import { GameStore } from './sim/save'
import { UI } from './ui/ui'

function fail(message: string): void {
  const boot = document.getElementById('boot')
  if (boot) {
    boot.innerHTML = `<div class="boot-fail"><b>Piston Forge could not start</b><span></span></div>`
    const span = boot.querySelector('span')
    if (span) span.textContent = message
  }
}

async function boot(): Promise<void> {
  const canvas = document.querySelector<HTMLCanvasElement>('#game')
  const root = document.getElementById('ui')
  if (!canvas || !root) throw new Error('Missing game canvas or UI root.')

  const store = new GameStore()
  const stage = new Stage(canvas)
  const sound = new SoundEngine()
  const app = new App(store, stage, sound)
  const ui = new UI(app, root)
  app.attachUI(ui)

  try {
    await document.fonts.ready
  } catch {
    // Font loading is not a hard dependency.
  }

  app.start()
  document.documentElement.dataset.ready = 'true'
  const boot = document.getElementById('boot')
  if (boot) {
    window.requestAnimationFrame(() => {
      boot.classList.add('is-done')
      window.setTimeout(() => boot.remove(), 520)
    })
  }

  const unlock = () => {
    void sound.unlock()
    window.removeEventListener('pointerdown', unlock)
    window.removeEventListener('keydown', unlock)
  }
  window.addEventListener('pointerdown', unlock, { once: true })
  window.addEventListener('keydown', unlock, { once: true })

  const save = () => app.saveNow()
  window.addEventListener('pagehide', save)
  document.addEventListener('visibilitychange', () => {
    if (document.hidden) save()
  })

  const debug = { app, ui, store, stage, sound }
  ;(window as unknown as { __game: typeof debug }).__game = debug
}

boot().catch(error => {
  console.error(error)
  const message = error instanceof Error ? error.message : String(error)
  fail(message)
})
