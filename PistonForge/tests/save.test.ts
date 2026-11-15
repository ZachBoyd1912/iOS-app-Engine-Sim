import { describe, expect, it } from 'vitest'
import { defaultState } from '../src/sim/career'
import { BACKUP_KEY, GameStore, NEWER_KEY, SAVE_KEY, SAVE_VERSION, decodeSave } from '../src/sim/save'

function memory(initial: Record<string, string> = {}) {
  const data = new Map(Object.entries(initial))
  return {
    data,
    getItem: (key: string) => data.get(key) ?? null,
    setItem: (key: string, value: string) => { data.set(key, value) },
    removeItem: (key: string) => { data.delete(key) },
  }
}

// One base state for the whole file: defaultState() mints fresh build ids on every call, so
// two saves built from separate calls would never compare equal.
const BASE = defaultState()
const savedWith = (cash: number) => JSON.stringify({ ...BASE, cash })

describe('decodeSave', () => {
  it('reads a current save', () => {
    const decoded = decodeSave(savedWith(7000))
    expect(decoded.status).toBe('ok')
    if (decoded.status === 'ok') expect(decoded.data.cash).toBe(7000)
  })

  it('tells empty, corrupt and newer saves apart', () => {
    expect(decodeSave(null).status).toBe('empty')
    expect(decodeSave('').status).toBe('empty')
    for (const junk of ['{"version":1,"ca', '[]', '"text"', '{}', '{"version":"1"}', '{"version":0}', '{"version":1.5}']) {
      expect(decodeSave(junk).status, junk).toBe('corrupt')
    }
    expect(decodeSave(JSON.stringify({ version: SAVE_VERSION + 1 }))).toEqual({ status: 'newer', version: SAVE_VERSION + 1 })
  })

  it('runs migrations in order up to the target version', () => {
    const migrations = {
      1: (d: Record<string, unknown>) => ({ ...d, cash: (d.cash as number) + 1, trail: 'a' }),
      2: (d: Record<string, unknown>) => ({ ...d, trail: `${d.trail}b` }),
    }
    const decoded = decodeSave(JSON.stringify({ version: 1, cash: 10 }), migrations, 3)
    expect(decoded).toEqual({ status: 'ok', data: { version: 3, cash: 11, trail: 'ab' } })
  })

  it('treats a missing or throwing migration as corrupt instead of guessing', () => {
    expect(decodeSave(JSON.stringify({ version: 1 }), {}, 2).status).toBe('corrupt')
    const thrower = { 1: () => { throw new Error('bad step') } }
    expect(decodeSave(JSON.stringify({ version: 1 }), thrower, 2).status).toBe('corrupt')
  })

  it('does not let a migration change the original object', () => {
    const migrations = { 1: (d: Record<string, unknown>) => { (d.nested as { n: number }).n = 2; return d } }
    const raw = JSON.stringify({ version: 1, nested: { n: 1 } })
    decodeSave(raw, migrations, 2)
    expect(JSON.parse(raw).nested.n).toBe(1)
  })
})

describe('GameStore loading', () => {
  it('starts fresh with no save', () => {
    const store = new GameStore(memory())
    expect(store.loadStatus).toBe('fresh')
    expect(store.data.cash).toBe(defaultState().cash)
  })

  it('loads a good save and keeps a backup of it', () => {
    const storage = memory({ [SAVE_KEY]: savedWith(9100) })
    const store = new GameStore(storage)
    expect(store.loadStatus).toBe('loaded')
    expect(store.data.cash).toBe(9100)
    expect(storage.data.get(BACKUP_KEY)).toBe(savedWith(9100))
  })

  it('recovers from the backup when the main save is corrupt, and repairs the main save', () => {
    const storage = memory({ [SAVE_KEY]: '{"version":1,"cash":91', [BACKUP_KEY]: savedWith(8000) })
    const store = new GameStore(storage)
    expect(store.loadStatus).toBe('recovered')
    expect(store.data.cash).toBe(8000)
    expect(storage.data.get(SAVE_KEY)).toBe(savedWith(8000))
  })

  it('recovers from the backup when the main save is missing', () => {
    const store = new GameStore(memory({ [BACKUP_KEY]: savedWith(6500) }))
    expect(store.loadStatus).toBe('recovered')
    expect(store.data.cash).toBe(6500)
  })

  it('reports a lost save when both copies are unreadable', () => {
    const store = new GameStore(memory({ [SAVE_KEY]: 'junk', [BACKUP_KEY]: 'also junk' }))
    expect(store.loadStatus).toBe('lost')
    expect(store.data.cash).toBe(defaultState().cash)
  })

  it('does not overwrite a good backup with a corrupt main save', () => {
    const storage = memory({ [SAVE_KEY]: 'junk', [BACKUP_KEY]: savedWith(8000) })
    new GameStore(storage)
    expect(storage.data.get(BACKUP_KEY)).toBe(savedWith(8000))
  })

  it('sets a newer-version save aside instead of destroying it', () => {
    const newer = JSON.stringify({ version: SAVE_VERSION + 1, cash: 123456 })
    const storage = memory({ [SAVE_KEY]: newer })
    const store = new GameStore(storage)
    expect(store.loadStatus).toBe('newer')
    expect(storage.data.get(NEWER_KEY)).toBe(newer)
    store.save({ ...store.data, cash: 1 })
    expect(storage.data.get(NEWER_KEY)).toBe(newer)
  })

  it('reset clears the save and its backup', () => {
    const storage = memory({ [SAVE_KEY]: savedWith(9100) })
    const store = new GameStore(storage)
    store.reset()
    expect(storage.data.has(BACKUP_KEY)).toBe(false)
    expect(JSON.parse(storage.data.get(SAVE_KEY) as string).cash).toBe(defaultState().cash)
  })

  it('keeps working in memory when storage throws', () => {
    const broken = {
      getItem: () => { throw new Error('blocked') },
      setItem: () => { throw new Error('blocked') },
      removeItem: () => { throw new Error('blocked') },
    }
    const store = new GameStore(broken)
    expect(store.loadStatus).toBe('fresh')
    expect(() => store.save({ ...store.data, cash: 5 })).not.toThrow()
    expect(store.data.cash).toBe(5)
  })

  it('defaults the vibration setting to on for saves written before it existed', () => {
    const old = defaultState() as unknown as { settings: Record<string, unknown> }
    delete old.settings.haptics
    const store = new GameStore(memory({ [SAVE_KEY]: JSON.stringify(old) }))
    expect(store.data.settings.haptics).toBe(true)
  })
})
