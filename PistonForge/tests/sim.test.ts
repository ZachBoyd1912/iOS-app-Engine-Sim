import { describe, expect, it } from 'vitest'
import { defaultEcu, setCell } from '../src/sim/ecu'
import { emptyParts } from '../src/sim/data'
import { defaultEngine, enginePresets, engineSpec, fitment } from '../src/sim/engine'
import { veAt } from '../src/sim/airflow'
import { operatingPoint, dynoPull, estimatePeak, torqueCurve } from '../src/sim/performance'
import { makeBuild, startingBuild, sandboxStartingBuild } from '../src/sim/builds'
import { handlingResult, simulateDrag, vehicleMass } from '../src/sim/vehicle'
import {
  acceptContract,
  defaultState,
  deliverJob,
  diagnoseJob,
  repairFault,
} from '../src/sim/career'
import { parseState, SAVE_KEY } from '../src/sim/save'
import type { DynoResult, EngineConfig } from '../src/sim/types'

function tunedEngine(layout: EngineConfig['layout'], induction: EngineConfig['induction']): EngineConfig {
  return {
    ...defaultEngine(layout, 'Test engine'),
    compression: 9,
    induction,
    fuel: 'p98',
    parts: { ...emptyParts(), head: 1, cams: 1, injectors: 2, pump: 2, internals: 2, gasket: 1, intercooler: 1 },
  }
}

describe('engine math', () => {
  it('computes displacement from bore, stroke and cylinder count', () => {
    const engine = defaultEngine('i4')
    engine.bore = 86
    engine.stroke = 86
    expect(engineSpec(engine).displacementCc).toBe(1998)
  })

  it('shows a healthy VE peak and a low-speed penalty', () => {
    const engine = defaultEngine('i4')
    const spec = engineSpec(engine)
    expect(veAt(engine, spec.camPeakRpm)).toBeGreaterThan(veAt(engine, 1000))
    expect(veAt(engine, spec.camPeakRpm)).toBeGreaterThan(0.7)
  })

  it('rejects a big-block V8 in a kei bay', () => {
    const big = enginePresets().find(preset => preset.id === 'bigblock')!.build
    const fit = fitment(big, 'kei')
    expect(fit.fits).toBe(false)
    expect(fit.blocker).not.toBeNull()
  })

  it('makes more torque with boost than an equivalent NA engine', () => {
    const na = tunedEngine('i4', 'na')
    const turbo = tunedEngine('i4', 'turboM')
    const naOp = operatingPoint(na, defaultEcu(na), 4000, 1, 6)
    const turboOp = operatingPoint(turbo, defaultEcu(turbo), 4000, 1, 6)
    expect(turboOp.boost).toBeGreaterThan(1)
    expect(turboOp.torque).toBeGreaterThan(naOp.torque)
  })
})

describe('ECU and dyno', () => {
  it('goes lean when the fuel table under-reports airflow', () => {
    const engine = tunedEngine('i4', 'na')
    const ecu = defaultEcu(engine)
    const leanEcu = { ...ecu, fuel: ecu.fuel.map(row => row.map(value => value * 0.62)) }
    const rich = operatingPoint(engine, ecu, 5000, 1, 8)
    const lean = operatingPoint(engine, leanEcu, 5000, 1, 8)
    expect(lean.afr).toBeGreaterThan(rich.afr)
    expect(lean.afr).toBeGreaterThan(ecu.afr * 1.06)
  })

  it('returns a full dyno curve with peaks and condition wear', () => {
    const engine = tunedEngine('i4', 'na')
    const result = dynoPull(engine, defaultEcu(engine), 88)
    expect(result.points.length).toBeGreaterThan(20)
    expect(result.peakHp).toBeGreaterThan(80)
    expect(result.peakTorque).toBeGreaterThan(100)
    expect(result.conditionAfter).toBeLessThanOrEqual(88)
    expect(result.redline).toBeGreaterThan(5000)
  })

  it('reports the peak at a sensible rpm', () => {
    const engine = tunedEngine('i6', 'na')
    const peak = estimatePeak(engine, defaultEcu(engine))
    expect(peak.hp).toBeGreaterThan(150)
    expect(peak.hpRpm).toBeGreaterThan(3000)
  })

  it('can set a single map cell without mutating the old table', () => {
    const engine = defaultEngine('i4')
    const ecu = defaultEcu(engine)
    const next = setCell(ecu, 'fuel', 3, 4, 111)
    expect(next.fuel[3][4]).toBe(111)
    expect(ecu.fuel[3][4]).not.toBe(111)
  })
})

describe('vehicle performance', () => {
  it('runs a quarter mile and records timing', () => {
    const build = startingBuild()
    const curve = torqueCurve(build.engine, build.ecu, 50)
    const result = simulateDrag(build, curve)
    expect(result.valid).toBe(true)
    expect(result.et).not.toBeNull()
    expect(result.et!).toBeGreaterThan(8)
    expect(result.sixtyFt).toBeGreaterThan(1)
  })

  it('makes a heavier, more powerful build quicker than the starter kei', () => {
    const slow = startingBuild()
    const fast = sandboxStartingBuild()
    const slowResult = simulateDrag(slow, torqueCurve(slow.engine, slow.ecu, 50))
    const fastResult = simulateDrag(fast, torqueCurve(fast.engine, fast.ecu, 50))
    expect(fastResult.et).not.toBeNull()
    expect(slowResult.et).not.toBeNull()
    expect(fastResult.et!).toBeLessThan(slowResult.et!)
    expect(vehicleMass(fast)).toBeGreaterThan(vehicleMass(slow))
  })

  it('produces a plausible handling lap and lateral g', () => {
    const build = sandboxStartingBuild()
    const peak = estimatePeak(build.engine, build.ecu)
    const handling = handlingResult(build, peak.hp)
    expect(handling.lap).toBeGreaterThan(25)
    expect(handling.lap).toBeLessThan(180)
    expect(handling.lateralG).toBeGreaterThan(0.7)
  })
})

describe('career', () => {
  it('starts with the promised cash, kei and salvage engine', () => {
    const state = defaultState()
    expect(state.cash).toBe(4800)
    expect(state.ownedBodies).toContain('kei')
    expect(state.careerBuilds[0].engine.name).toBe('Salvage 1.6')
  })

  it('diagnoses a fault, repairs it and pays a completed contract', () => {
    let state = defaultState()
    state = acceptContract(state, 'hatch-heart').state
    expect(state.job).not.toBeNull()
    const diag = diagnoseJob(state)
    state = diag.state
    expect(diag.findings.length).toBe(1)
    const repair = repairFault(state, 'weakPump')
    expect(repair.error).toBeUndefined()
    state = repair.state
    expect(state.job!.build.engine.faults).toHaveLength(0)
    const dyno: DynoResult = {
      points: [],
      peakHp: 170,
      peakHpRpm: 6000,
      peakTorque: 220,
      peakTorqueRpm: 4500,
      redline: 7000,
      boostPeak: 0,
      afrMin: 12.4,
      afrMax: 12.9,
      knockPeak: 0,
      egtPeak: 820,
      conditionBefore: 76,
      conditionAfter: 75,
      failure: null,
      valid: true,
      at: Date.now(),
    }
    state.job!.build.dyno = dyno
    const before = state.cash
    const delivered = deliverJob(state)
    expect(delivered.outcome.ok).toBe(true)
    expect(delivered.state.cash).toBeGreaterThan(before)
    expect(delivered.state.job).toBeNull()
  })

  it('rejects delivery when the target is not met', () => {
    let state = defaultState()
    state = acceptContract(state, 'hatch-heart').state
    state.job!.build.engine.faults = []
    const delivered = deliverJob(state)
    expect(delivered.outcome.ok).toBe(false)
    expect(delivered.state.job).not.toBeNull()
  })
})

describe('save migration', () => {
  it('round-trips a game state through JSON', () => {
    const state = defaultState()
    state.cash = 7777
    state.rep = 42
    const parsed = parseState(JSON.stringify(state))
    expect(parsed.cash).toBe(7777)
    expect(parsed.rep).toBe(42)
    expect(parsed.careerBuilds[0].engine.name).toBe('Salvage 1.6')
    expect(parsed.settings.engineVolume).toBeGreaterThan(0)
  })

  it('falls back to a fresh state for corrupt storage', () => {
    expect(parseState('{not json').cash).toBe(4800)
    expect(parseState(null).cash).toBe(4800)
    expect(SAVE_KEY).toContain('pistonforge')
  })

  it('sanitizes out-of-range build values', () => {
    const state = defaultState()
    state.careerBuilds[0].condition = 9999
    state.careerBuilds[0].engine.bore = 9999
    const parsed = parseState(JSON.stringify(state))
    expect(parsed.careerBuilds[0].condition).toBe(100)
    expect(parsed.careerBuilds[0].engine.bore).toBeLessThanOrEqual(112)
  })

  it('clamps a malformed job budget', () => {
    let state = defaultState()
    state.rep = 10
    state = acceptContract(state, 'kei-cup').state
    state.job!.spent = 999999
    const parsed = parseState(JSON.stringify(state))
    expect(parsed.job).not.toBeNull()
    expect(parsed.job!.spent).toBeLessThanOrEqual(state.job!.contract.budget)
  })

  it('keeps a build made from a preset', () => {
    const build = makeBuild('hotHatch', enginePresets()[2].build)
    expect(build.engine.induction).toBe('turboM')
    expect(build.ecu.fuel.length).toBe(8)
  })
})
