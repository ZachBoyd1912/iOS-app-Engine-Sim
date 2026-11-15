import './styles/forge.css'
import { App } from './app'
import { SoundEngine } from './audio/sound'
import { Stage } from './game/stage'
import { bindLifecycle, createHaptics, isNativeApp, prepareSaveStorage } from './platform'
import { BACKUP_KEY, GameStore, SAVE_KEY } from './sim/save'
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
  if (isNativeApp()) document.documentElement.dataset.native = 'true'

  // In the app, put the save back from native storage if the web view lost it.
  const saves = await prepareSaveStorage([SAVE_KEY, BACKUP_KEY])
  const store = new GameStore(saves.storage)
  const stage = new Stage(canvas)
  const sound = new SoundEngine()
  const app = new App(store, stage, sound, createHaptics())
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

  if (store.loadStatus === 'recovered' || saves.outcome === 'restored') app.toast('Your shop was restored from the backup save.', 'ok')
  else if (store.loadStatus === 'lost') app.toast('The save could not be read, so a new shop was started.', 'warn')
  else if (store.loadStatus === 'newer') app.toast('This save is from a newer version. It was kept safe; update the game to use it.', 'warn')

  // Audio can only start from a touch or key press. Keep listening after the first one:
  // iOS suspends audio again after a call or a trip to the background, and the next touch
  // is what brings it back.
  const wake = () => { void sound.unlock() }
  window.addEventListener('pointerdown', wake, { passive: true })
  window.addEventListener('keydown', wake)

  bindLifecycle({
    save: () => app.saveNow(),
    suspendAudio: () => sound.suspend(),
    resumeAudio: () => { void sound.resume() },
    resetClock: () => app.loop.resetAccumulator(),
  })

  const debug = { app, ui, store, stage, sound }
  ;(window as unknown as { __game: typeof debug }).__game = debug
}

boot().catch(error => {
  console.error(error)
  const message = error instanceof Error ? error.message : String(error)
  fail(message)
})
