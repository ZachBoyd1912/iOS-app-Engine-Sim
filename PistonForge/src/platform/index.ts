/**
 * The one place the game touches the native shell.
 *
 * Everything else in `src/` is plain web code and runs unchanged in a browser. This module
 * asks Capacitor whether the game is running inside the iOS app and, if so, connects the
 * haptic engine and the durable save store to their native plugins. In a browser the same
 * calls quietly fall back to web behaviour, so there is one code path to test.
 */
import { Capacitor } from '@capacitor/core'
import { Haptics, ImpactStyle, NotificationType } from '@capacitor/haptics'
import { Preferences } from '@capacitor/preferences'
import { hydrateSave, mirrorWrites, type AsyncStore, type HydrateOutcome, type SyncStore } from './durableSave'
import { HapticEngine, webVibrationDriver, type HapticDriver } from './haptics'

export { bindLifecycle } from './lifecycle'
export { HapticEngine } from './haptics'

/** True inside the installed iOS (or Android) app, false in any browser. */
export function isNativeApp(): boolean {
  try {
    return Capacitor.isNativePlatform()
  } catch {
    return false
  }
}

const nativeHaptics: HapticDriver = {
  impact: weight => Haptics.impact({ style: weight === 'heavy' ? ImpactStyle.Heavy : weight === 'medium' ? ImpactStyle.Medium : ImpactStyle.Light }),
  notify: kind => Haptics.notification({ type: kind === 'error' ? NotificationType.Error : kind === 'warning' ? NotificationType.Warning : NotificationType.Success }),
  selection: async () => {
    await Haptics.selectionStart()
    await Haptics.selectionChanged()
    await Haptics.selectionEnd()
  },
}

export function createHaptics(): HapticEngine {
  return new HapticEngine(isNativeApp() ? nativeHaptics : webVibrationDriver())
}

/** Native key-value storage (UserDefaults on iOS). Survives the web view's storage being cleared. */
const nativeStore: AsyncStore = {
  get: async key => (await Preferences.get({ key })).value,
  set: (key, value) => Preferences.set({ key, value }),
  remove: key => Preferences.remove({ key }),
}

function localStore(): SyncStore | undefined {
  try {
    return globalThis.localStorage
  } catch {
    return undefined
  }
}

const withTimeout = <T,>(work: Promise<T>, ms: number, fallback: T): Promise<T> =>
  Promise.race([work, new Promise<T>(resolve => setTimeout(() => resolve(fallback), ms))])

export type SaveStorage = {
  /** Hand this to the game's save store. Undefined when the browser blocks storage. */
  storage: SyncStore | undefined
  /** What happened to the save at boot; 'web' means no native store is involved. */
  outcome: HydrateOutcome | 'web'
  /** Wait for pending native writes (call before the app is suspended). */
  settled: () => Promise<void>
}

/**
 * Prepare save storage before the game boots.
 * In the app: restore the save from native storage if the web view lost it, then mirror
 * every later write to native storage. In a browser: plain localStorage.
 * Never rejects and never waits more than a moment, so a storage fault cannot block launch.
 */
export async function prepareSaveStorage(keys: readonly string[]): Promise<SaveStorage> {
  const local = localStore()
  if (!local || !isNativeApp()) return { storage: local, outcome: 'web', settled: () => Promise.resolve() }
  let outcome: HydrateOutcome = 'empty'
  for (const key of keys) {
    const result = await withTimeout(hydrateSave(local, nativeStore, key).catch((): HydrateOutcome => 'empty'), 1500, 'empty')
    if (result === 'restored' || (result === 'kept' && outcome === 'empty')) outcome = result
  }
  const mirrored = mirrorWrites(local, nativeStore, error => console.warn('Native save mirror failed', error))
  return { storage: mirrored, outcome, settled: mirrored.settled }
}
