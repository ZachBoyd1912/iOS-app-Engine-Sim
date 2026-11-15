/**
 * A second, more durable home for the save file.
 *
 * In the browser the save lives in localStorage and that is all there is. Inside the iOS app
 * the web view's localStorage is still the working copy (the game reads it synchronously at
 * boot), but iOS is free to clear web-view storage, so every save is also written through to
 * native app storage. At boot, if the working copy is missing or unreadable and the durable
 * copy is good, the durable copy is restored before the game loads.
 *
 * Both sides are passed in, so this is tested with plain in-memory fakes.
 */

export type SyncStore = Pick<Storage, 'getItem' | 'setItem' | 'removeItem'>

export interface AsyncStore {
  get(key: string): Promise<string | null>
  set(key: string, value: string): Promise<void>
  remove(key: string): Promise<void>
}

export type HydrateOutcome =
  /** The working copy was fine; nothing was changed. */
  | 'kept'
  /** The working copy was missing or broken and the durable copy was put back. */
  | 'restored'
  /** Neither copy holds a usable save (first launch). */
  | 'empty'

/** True when `raw` is a JSON object, which is the minimum shape of any save we write. */
export function looksLikeSave(raw: string | null): raw is string {
  if (!raw) return false
  try {
    const parsed: unknown = JSON.parse(raw)
    return !!parsed && typeof parsed === 'object' && !Array.isArray(parsed)
  } catch {
    return false
  }
}

/**
 * Run once at boot, before the game reads its save.
 * The working copy wins whenever it is readable: it is written synchronously, so it is never
 * older than the durable copy, which is written a moment later.
 */
export async function hydrateSave(local: SyncStore | undefined, durable: AsyncStore, key: string): Promise<HydrateOutcome> {
  if (!local) return 'empty'
  let working: string | null = null
  try {
    working = local.getItem(key)
  } catch {
    working = null
  }
  if (looksLikeSave(working)) return 'kept'
  let kept: string | null = null
  try {
    kept = await durable.get(key)
  } catch {
    kept = null
  }
  if (!looksLikeSave(kept)) return 'empty'
  try {
    local.setItem(key, kept)
  } catch {
    return 'empty'
  }
  return 'restored'
}

/**
 * Wrap the working store so every write and delete is also sent to the durable store.
 * Durable writes are queued one after another so an older save can never land after a newer
 * one, and a failed durable write never disturbs the game.
 */
export function mirrorWrites(local: SyncStore, durable: AsyncStore, onError: (error: unknown) => void = () => {}): SyncStore & { settled(): Promise<void> } {
  let queue: Promise<void> = Promise.resolve()
  const enqueue = (job: () => Promise<void>) => {
    queue = queue.then(job).catch(onError)
  }
  return {
    getItem: key => local.getItem(key),
    setItem: (key, value) => {
      local.setItem(key, value)
      enqueue(() => durable.set(key, value))
    },
    removeItem: key => {
      local.removeItem(key)
      enqueue(() => durable.remove(key))
    },
    /** Resolves when every queued durable write has finished. Used before the app is suspended. */
    settled: () => queue,
  }
}
