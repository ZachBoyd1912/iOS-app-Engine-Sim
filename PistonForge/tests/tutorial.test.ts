import { describe, expect, it } from 'vitest'
import { acceptContract, defaultState } from '../src/sim/career'
import { parseState } from '../src/sim/save'
import { nextTip } from '../src/sim/tutorial'
import type { DragResult, GameState } from '../src/sim/types'

// One base state for the file: defaultState() mints fresh build ids on every call.
const BASE = defaultState()

const DRAG: DragResult = {
  sixtyFt: 2.1, zeroTo100: null, et: 15.2, trapKmh: 140, trapMph: 87, topSpeed: 150,
  wheelspin: 0, shifts: 3, valid: true, at: 1,
}

/** A career state past the first pull, before any strip run. */
const afterPull = (): GameState => ({ ...BASE, pulls: 1 })

describe('nextTip', () => {
  it('shows the first dyno pull on a new career', () => {
    const tip = nextTip(BASE)
    expect(tip?.id).toBe('first-pull')
    expect(tip?.action).toBe('go-dyno')
  })

  it('asks for the first strip run once a pull exists but no drag result does', () => {
    const tip = nextTip(afterPull())
    expect(tip?.id).toBe('first-run')
    expect(tip?.action).toBe('go-test')
  })

  it('treats any career build with a drag result as already run, even if bests.et is still 0', () => {
    const state: GameState = {
      ...afterPull(),
      careerBuilds: BASE.careerBuilds.map(build => ({ ...build, drag: { ...DRAG, valid: false, et: null } })),
    }
    expect(nextTip(state)?.id).toBe('first-contract')
  })

  it('treats a recorded best ET as already run, even with no drag result on the build', () => {
    const state: GameState = { ...afterPull(), bests: { ...BASE.bests, et: 15.2 } }
    expect(nextTip(state)?.id).toBe('first-contract')
  })

  it('asks the player to accept a contract when no job is running', () => {
    const state: GameState = { ...afterPull(), bests: { ...BASE.bests, et: 15.2 } }
    const tip = nextTip(state)
    expect(tip?.id).toBe('first-contract')
    expect(tip?.action).toBe('go-jobs')
  })

  it('asks the player to deliver once a job is running', () => {
    const accepted = acceptContract({ ...afterPull(), bests: { ...BASE.bests, et: 15.2 } }, 'hatch-heart')
    expect(accepted.error).toBeUndefined()
    const tip = nextTip(accepted.state)
    expect(tip?.id).toBe('deliver-contract')
    expect(tip?.action).toBe('go-jobs')
  })

  it('returns null in sandbox mode', () => {
    expect(nextTip({ ...BASE, mode: 'sandbox' })).toBeNull()
    expect(nextTip({ ...afterPull(), mode: 'sandbox' })).toBeNull()
  })

  it('returns null when tips are switched off', () => {
    const off: GameState = { ...BASE, settings: { ...BASE.settings, tips: false } }
    expect(nextTip(off)).toBeNull()
    expect(nextTip({ ...afterPull(), settings: { ...BASE.settings, tips: false } })).toBeNull()
  })

  it('returns null once any contract has been completed', () => {
    expect(nextTip({ ...BASE, completedJobs: 1 })).toBeNull()
    expect(nextTip({ ...afterPull(), completedJobs: 2, bests: { ...BASE.bests, et: 15.2 } })).toBeNull()
  })

  it('gives every tip copy with no exclamation marks, em dashes or ellipses', () => {
    const states: GameState[] = [
      BASE,
      afterPull(),
      { ...afterPull(), bests: { ...BASE.bests, et: 15.2 } },
      acceptContract({ ...afterPull(), bests: { ...BASE.bests, et: 15.2 } }, 'hatch-heart').state,
    ]
    for (const state of states) {
      const tip = nextTip(state)
      expect(tip).not.toBeNull()
      for (const text of [tip!.title, tip!.body, tip!.actionLabel]) {
        expect(text).not.toMatch(/[!—…]/)
        expect(text.length).toBeGreaterThan(0)
      }
    }
  })
})

describe('tips setting in the save file', () => {
  it('defaults to on for a save written before the setting existed', () => {
    const old = JSON.parse(JSON.stringify({ ...BASE, settings: { ...BASE.settings, tips: undefined } }))
    expect(parseState(JSON.stringify(old)).settings.tips).toBe(true)
  })

  it('keeps an explicit off', () => {
    const saved = JSON.stringify({ ...BASE, settings: { ...BASE.settings, tips: false } })
    expect(parseState(saved).settings.tips).toBe(false)
  })
})
