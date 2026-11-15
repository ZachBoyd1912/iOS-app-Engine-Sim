import { describe, expect, it, vi } from 'vitest'
import { CUE_PLAN, HapticEngine, MIN_GAP_MS, webVibrationDriver, type HapticDriver } from '../src/platform/haptics'
import { hydrateSave, looksLikeSave, mirrorWrites, type AsyncStore, type SyncStore } from '../src/platform/durableSave'
import { bindLifecycle, type LifecycleTarget } from '../src/platform/lifecycle'

function fakeDriver() {
  const calls: string[] = []
  const driver: HapticDriver = {
    impact: weight => { calls.push(`impact:${weight}`) },
    notify: kind => { calls.push(`notify:${kind}`) },
    selection: () => { calls.push('selection') },
  }
  return { calls, driver }
}

function memoryStore(initial: Record<string, string> = {}): SyncStore & { data: Map<string, string> } {
  const data = new Map(Object.entries(initial))
  return {
    data,
    getItem: key => data.get(key) ?? null,
    setItem: (key, value) => { data.set(key, value) },
    removeItem: key => { data.delete(key) },
  }
}

function asyncStore(initial: Record<string, string> = {}): AsyncStore & { data: Map<string, string>; log: string[] } {
  const data = new Map(Object.entries(initial))
  const log: string[] = []
  return {
    data,
    log,
    get: async key => data.get(key) ?? null,
    set: async (key, value) => { log.push(`set:${value}`); data.set(key, value) },
    remove: async key => { log.push('remove'); data.delete(key) },
  }
}

describe('haptics', () => {
  it('maps each cue to a strength that matches its importance', () => {
    const { calls, driver } = fakeDriver()
    let clock = 0
    const haptics = new HapticEngine(driver, () => clock)
    for (const cue of ['tap', 'select', 'shift', 'launch', 'success', 'warning', 'failure'] as const) {
      clock += 1000
      haptics.cue(cue)
    }
    expect(calls).toEqual(['impact:light', 'selection', 'impact:medium', 'impact:heavy', 'notify:success', 'notify:warning', 'notify:error'])
    expect(CUE_PLAN.launch).toEqual({ kind: 'impact', weight: 'heavy' })
  })

  it('drops rapid small cues but never an important one', () => {
    const { calls, driver } = fakeDriver()
    let clock = 0
    const haptics = new HapticEngine(driver, () => clock)
    haptics.cue('select')
    clock += MIN_GAP_MS - 1
    haptics.cue('select')
    haptics.cue('tap')
    expect(calls).toEqual(['selection'])
    haptics.cue('failure')
    expect(calls).toEqual(['selection', 'notify:error'])
    clock += MIN_GAP_MS
    haptics.cue('tap')
    expect(calls).toEqual(['selection', 'notify:error', 'impact:light'])
  })

  it('does nothing when switched off or when the device has no haptics', () => {
    const { calls, driver } = fakeDriver()
    const off = new HapticEngine(driver, () => 0)
    off.enabled = false
    off.cue('launch')
    expect(calls).toEqual([])
    expect(() => new HapticEngine(null).cue('launch')).not.toThrow()
  })

  it('never lets a failing driver reach the game', async () => {
    const thrower: HapticDriver = {
      impact: () => { throw new Error('no taptic engine') },
      notify: () => Promise.reject(new Error('denied')),
      selection: () => {},
    }
    const haptics = new HapticEngine(thrower, () => 0)
    expect(() => haptics.cue('launch')).not.toThrow()
    expect(() => haptics.cue('failure')).not.toThrow()
    await Promise.resolve()
  })

  it('uses the Vibration API where the browser has one and reports none otherwise', () => {
    const vibrate = vi.fn(() => true)
    const driver = webVibrationDriver({ vibrate })
    expect(driver).not.toBeNull()
    driver!.impact('heavy')
    driver!.selection()
    expect(vibrate).toHaveBeenNthCalledWith(1, 28)
    expect(vibrate).toHaveBeenNthCalledWith(2, 5)
    expect(webVibrationDriver({} as Navigator)).toBeNull()
  })
})

describe('durable save', () => {
  const KEY = 'save'
  const good = JSON.stringify({ version: 1, cash: 9000 })
  const older = JSON.stringify({ version: 1, cash: 100 })

  it('recognises a save and rejects junk', () => {
    expect(looksLikeSave(good)).toBe(true)
    for (const junk of [null, '', '{"version":1', '[1,2]', '42', 'null']) expect(looksLikeSave(junk)).toBe(false)
  })

  it('keeps the working copy when it is readable, even if the durable copy differs', async () => {
    const local = memoryStore({ [KEY]: good })
    const durable = asyncStore({ [KEY]: older })
    expect(await hydrateSave(local, durable, KEY)).toBe('kept')
    expect(local.getItem(KEY)).toBe(good)
  })

  it('restores the durable copy when the working copy was wiped', async () => {
    const local = memoryStore()
    expect(await hydrateSave(local, asyncStore({ [KEY]: good }), KEY)).toBe('restored')
    expect(local.getItem(KEY)).toBe(good)
  })

  it('restores the durable copy when the working copy is corrupt', async () => {
    const local = memoryStore({ [KEY]: '{"version":1,"cas' })
    expect(await hydrateSave(local, asyncStore({ [KEY]: good }), KEY)).toBe('restored')
    expect(local.getItem(KEY)).toBe(good)
  })

  it('reports an empty first launch and never restores junk', async () => {
    expect(await hydrateSave(memoryStore(), asyncStore(), KEY)).toBe('empty')
    const local = memoryStore()
    expect(await hydrateSave(local, asyncStore({ [KEY]: 'not json' }), KEY)).toBe('empty')
    expect(local.getItem(KEY)).toBeNull()
  })

  it('survives a durable store that throws', async () => {
    const broken: AsyncStore = {
      get: async () => { throw new Error('storage unavailable') },
      set: async () => {},
      remove: async () => {},
    }
    expect(await hydrateSave(memoryStore(), broken, KEY)).toBe('empty')
    expect(await hydrateSave(undefined, asyncStore({ [KEY]: good }), KEY)).toBe('empty')
  })

  it('writes every save through to the durable store, in order', async () => {
    const local = memoryStore()
    const durable = asyncStore()
    const store = mirrorWrites(local, durable)
    store.setItem(KEY, older)
    store.setItem(KEY, good)
    expect(local.getItem(KEY)).toBe(good)
    await store.settled()
    expect(durable.log).toEqual([`set:${older}`, `set:${good}`])
    expect(durable.data.get(KEY)).toBe(good)
    store.removeItem(KEY)
    await store.settled()
    expect(durable.data.has(KEY)).toBe(false)
    expect(local.getItem(KEY)).toBeNull()
  })

  it('keeps saving locally when the durable store fails, and keeps the queue alive', async () => {
    const local = memoryStore()
    let fail = true
    const durable = asyncStore()
    const flaky: AsyncStore = {
      get: durable.get,
      remove: durable.remove,
      set: async (key, value) => {
        if (fail) throw new Error('disk full')
        await durable.set(key, value)
      },
    }
    const errors: unknown[] = []
    const store = mirrorWrites(local, flaky, error => errors.push(error))
    store.setItem(KEY, older)
    await store.settled()
    expect(local.getItem(KEY)).toBe(older)
    expect(errors).toHaveLength(1)
    fail = false
    store.setItem(KEY, good)
    await store.settled()
    expect(durable.data.get(KEY)).toBe(good)
  })
})

describe('lifecycle', () => {
  function harness(startHidden = false) {
    const listeners = new Map<string, () => void>()
    const doc = {
      hidden: startHidden,
      addEventListener: (type: string, fn: () => void) => { listeners.set(`doc:${type}`, fn) },
      removeEventListener: (type: string) => { listeners.delete(`doc:${type}`) },
    }
    const win = {
      addEventListener: (type: string, fn: () => void) => { listeners.set(`win:${type}`, fn) },
      removeEventListener: (type: string) => { listeners.delete(`win:${type}`) },
    }
    const calls: string[] = []
    const target: LifecycleTarget = {
      save: () => calls.push('save'),
      suspendAudio: () => calls.push('suspend'),
      resumeAudio: () => calls.push('resume'),
      resetClock: () => calls.push('resetClock'),
    }
    const unbind = bindLifecycle(target, doc as never, win as never)
    const fire = (name: string) => listeners.get(name)?.()
    return { doc, calls, fire, unbind, listeners }
  }

  it('saves and silences the engine when the app is hidden, then recovers on return', () => {
    const h = harness()
    h.doc.hidden = true
    h.fire('doc:visibilitychange')
    expect(h.calls).toEqual(['save', 'suspend'])
    h.doc.hidden = false
    h.fire('doc:visibilitychange')
    expect(h.calls).toEqual(['save', 'suspend', 'resetClock', 'resume'])
  })

  it('saves on every hide signal but suspends audio only once', () => {
    const h = harness()
    h.doc.hidden = true
    h.fire('doc:visibilitychange')
    h.fire('win:pagehide')
    expect(h.calls).toEqual(['save', 'suspend', 'save'])
  })

  it('does not resume when it was never hidden', () => {
    const h = harness()
    h.fire('win:pageshow')
    expect(h.calls).toEqual([])
  })

  it('removes its listeners when unbound', () => {
    const h = harness()
    h.unbind()
    expect(h.listeners.size).toBe(0)
  })
})
