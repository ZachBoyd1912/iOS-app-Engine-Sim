import {
  FUELS,
  GASKETS,
  INDUCTIONS,
  INJECTORS,
  PUMPS,
} from './data'
import { airflowGps, boostAt, chargeTempAt, injectorCapacityGps, loadAt, mbtAdvance, safeAdvance, veAt } from './airflow'
import { engineSpec } from './engine'
import type { BodySpec, EcuConfig, EngineConfig } from './types'

const clamp = (v: number, min: number, max: number) => Math.min(max, Math.max(min, v))
const round1 = (v: number) => Math.round(v * 10) / 10

export const RPM_BINS = [1000, 1500, 2000, 3000, 4000, 5000, 6500, 8000]
export const LOAD_BINS = [20, 35, 50, 65, 80, 100, 140, 180]
export const LOAD_LABELS = ['20', '35', '50', '65', '80', '100', '140', '180']

export function targetBoostDefault(config: EngineConfig): number {
  const induction = INDUCTIONS[config.induction]
  if (induction.maxBoost <= 0) return 0
  const gasket = GASKETS[config.parts.gasket].boostLimit
  return Math.round(Math.min(induction.maxBoost, gasket + 1) * 0.7 * 10) / 10
}

export function defaultEcu(config: EngineConfig): EcuConfig {
  const spec = engineSpec(config)
  const target = targetBoostDefault(config)
  const fuel = FUELS[config.fuel]
  const fuelTable: number[][] = []
  const ignitionTable: number[][] = []
  for (const load of LOAD_BINS) {
    const fuelRow: number[] = []
    const ignRow: number[] = []
    for (const rpm of RPM_BINS) {
      const ve = veAt(config, rpm)
      const loadFactor = 0.97 + 0.08 * (load / 180)
      fuelRow.push(round1(clamp(ve * loadFactor * 103, 22, 148)))
      const boostEstimate = boostAt(config, rpm, 0.9, target, 48)
      const safe = safeAdvance(config, boostEstimate, 48)
      const mbt = mbtAdvance(config, rpm, boostEstimate)
      ignRow.push(round1(clamp(Math.min(mbt - 0.5, safe - (load >= 100 ? 2.2 : 1.2)), 4, 35)))
    }
    fuelTable.push(fuelRow)
    ignitionTable.push(ignRow)
  }
  return {
    fuel: fuelTable,
    ignition: ignitionTable,
    afr: fuel.afrTarget,
    boostTarget: target,
    revLimit: Math.max(4500, Math.min(spec.mechanicalRedline - 150, 8500)),
    launchRpm: Math.round(Math.min(3600, spec.mechanicalRedline * 0.55) / 50) * 50,
  }
}

export function sanitizeEcu(input: EcuConfig | undefined, config: EngineConfig): EcuConfig {
  const fallback = defaultEcu(config)
  if (!input) return fallback
  const spec = engineSpec(config)
  const validGrid = (grid: unknown): grid is number[][] =>
    Array.isArray(grid) && grid.length === LOAD_BINS.length && grid.every(row => Array.isArray(row) && row.length === RPM_BINS.length)
  const fuel = validGrid(input.fuel)
    ? input.fuel.map(row => row.map(v => clamp(Number.isFinite(v) ? v : 90, 10, 160)))
    : fallback.fuel
  const ignition = validGrid(input.ignition)
    ? input.ignition.map(row => row.map(v => clamp(Number.isFinite(v) ? v : 20, -5, 50)))
    : fallback.ignition
  return {
    fuel,
    ignition,
    afr: clamp(Number.isFinite(input.afr) ? input.afr : fallback.afr, 7, 16),
    boostTarget: clamp(Number.isFinite(input.boostTarget) ? input.boostTarget : fallback.boostTarget, 0, INDUCTIONS[config.induction].maxBoost),
    revLimit: clamp(Number.isFinite(input.revLimit) ? input.revLimit : fallback.revLimit, 3500, spec.mechanicalRedline + 400),
    launchRpm: clamp(Number.isFinite(input.launchRpm) ? input.launchRpm : fallback.launchRpm, 1500, (input.revLimit ?? fallback.revLimit) - 300),
  }
}

/** Bilinear lookup over the RPM/load grid. */
export function tableValue(table: number[][], rpm: number, load: number): number {
  const rx = rpmIndex(rpm)
  const ry = loadIndex(load)
  const x = clamp(rpm, RPM_BINS[0], RPM_BINS[RPM_BINS.length - 1])
  const y = clamp(load, LOAD_BINS[0], LOAD_BINS[LOAD_BINS.length - 1])
  const x0 = RPM_BINS[rx.lo]
  const x1 = RPM_BINS[rx.hi]
  const y0 = LOAD_BINS[ry.lo]
  const y1 = LOAD_BINS[ry.hi]
  const tx = x1 === x0 ? 0 : (x - x0) / (x1 - x0)
  const ty = y1 === y0 ? 0 : (y - y0) / (y1 - y0)
  const a = table[ry.lo]?.[rx.lo] ?? 90
  const b = table[ry.lo]?.[rx.hi] ?? a
  const c = table[ry.hi]?.[rx.lo] ?? a
  const d = table[ry.hi]?.[rx.hi] ?? a
  return (a * (1 - tx) + b * tx) * (1 - ty) + (c * (1 - tx) + d * tx) * ty
}

function rpmIndex(rpm: number): { lo: number; hi: number } {
  if (rpm <= RPM_BINS[0]) return { lo: 0, hi: 0 }
  for (let i = 0; i < RPM_BINS.length - 1; i += 1) {
    if (rpm <= RPM_BINS[i + 1]) return { lo: i, hi: i + 1 }
  }
  return { lo: RPM_BINS.length - 1, hi: RPM_BINS.length - 1 }
}

function loadIndex(load: number): { lo: number; hi: number } {
  if (load <= LOAD_BINS[0]) return { lo: 0, hi: 0 }
  for (let i = 0; i < LOAD_BINS.length - 1; i += 1) {
    if (load <= LOAD_BINS[i + 1]) return { lo: i, hi: i + 1 }
  }
  return { lo: LOAD_BINS.length - 1, hi: LOAD_BINS.length - 1 }
}

export function setCell(ecu: EcuConfig, table: 'fuel' | 'ignition', row: number, col: number, value: number): EcuConfig {
  const grid = (table === 'fuel' ? ecu.fuel : ecu.ignition).map(r => [...r])
  if (!grid[row] || grid[row][col] === undefined) return ecu
  grid[row][col] = round1(clamp(value, table === 'fuel' ? 10 : -5, table === 'fuel' ? 160 : 50))
  return { ...ecu, [table]: grid }
}

export function smoothTable(ecu: EcuConfig, table: 'fuel' | 'ignition'): EcuConfig {
  const source = table === 'fuel' ? ecu.fuel : ecu.ignition
  const next = source.map((row, r) =>
    row.map((value, c) => {
      const around: number[] = [value]
      for (let dr = -1; dr <= 1; dr += 1) {
        for (let dc = -1; dc <= 1; dc += 1) {
          if (dr === 0 && dc === 0) continue
          const v = source[r + dr]?.[c + dc]
          if (v !== undefined) around.push(v)
        }
      }
      return round1(around.reduce((a, b) => a + b, 0) / around.length)
    }),
  )
  return { ...ecu, [table]: next }
}

export function autoBase(ecu: EcuConfig, config: EngineConfig): EcuConfig {
  const base = defaultEcu(config)
  return { ...base, revLimit: ecu.revLimit, launchRpm: Math.min(ecu.launchRpm, base.revLimit - 300) }
}

/** Set the fuel grid to match physical airflow, which should land on the commanded AFR. */
export function fixFuel(ecu: EcuConfig, config: EngineConfig): EcuConfig {
  const next = ecu.fuel.map((row, r) =>
    row.map((_, c) => {
      const ve = veAt(config, RPM_BINS[c])
      const load = LOAD_BINS[r]
      return round1(clamp(ve * 100 * (0.98 + 0.05 * (load / 180)), 18, 145))
    }),
  )
  return { ...ecu, fuel: next }
}

/** Push timing toward a safe-but-useful MBT estimate. The player can still go further. */
export function advanceTiming(ecu: EcuConfig, config: EngineConfig): EcuConfig {
  const next = ecu.ignition.map(row =>
    row.map((_, c) => {
      const rpm = RPM_BINS[c]
      const boost = boostAt(config, rpm, 0.95, ecu.boostTarget, 62)
      const safe = safeAdvance(config, boost, 72)
      const mbt = mbtAdvance(config, rpm, boost)
      return round1(clamp(Math.min(mbt, safe - 0.5), 3, 34))
    }),
  )
  return { ...ecu, ignition: next }
}

export function ecuWarnings(ecu: EcuConfig, config: EngineConfig, body: BodySpec): { level: 'ok' | 'warn' | 'bad'; text: string }[] {
  const spec = engineSpec(config)
  const out: { level: 'ok' | 'warn' | 'bad'; text: string }[] = []
  const ignition = INDUCTIONS[config.induction]
  const boost = boostAt(config, Math.min(spec.mechanicalRedline - 200, 6500), 1, ecu.boostTarget, 60)
  const load = loadAt(1, boost)
  const ve = veAt(config, Math.min(spec.mechanicalRedline - 200, 6500))
  const charge = chargeTempAt(config, boost, 18)
  const air = airflowGps(config, Math.min(spec.mechanicalRedline - 200, 6500), 1, ve, boost, charge)
  const target = Math.max(7, ecu.afr)
  const fuelCell = tableValue(ecu.fuel, Math.min(spec.mechanicalRedline - 200, 6500), load)
  const commanded = air / target * (fuelCell / (ve * 100))
  const injectorMax = injectorCapacityGps(config)
  const duty = (commanded / injectorMax) * 100
  const pumpMargin = ((PUMPS[config.parts.pump].lph * FUELS[config.fuel].density) / 3.6) / Math.max(0.01, commanded)

  if (duty > 100) out.push({ level: 'bad', text: `Injectors are at ${Math.round(duty)}% duty near the limiter. Fit larger injectors.` })
  else if (duty > 82) out.push({ level: 'warn', text: `Injector duty is ${Math.round(duty)}% near the limiter. Little headroom.` })
  else out.push({ level: 'ok', text: `Injector duty ${Math.round(duty)}% at the top of the pull.` })

  if (pumpMargin < 1.05) out.push({ level: 'bad', text: `Fuel pump margin is ${pumpMargin.toFixed(2)}×. It will run dry up top.` })
  else if (pumpMargin < 1.3) out.push({ level: 'warn', text: `Fuel pump margin is ${pumpMargin.toFixed(2)}×. Keep an eye on pressure.` })

  if (ignition.maxBoost > 0) {
    if (ecu.boostTarget > GASKETS[config.parts.gasket].boostLimit) out.push({ level: 'bad', text: `Boost target ${ecu.boostTarget.toFixed(1)} psi exceeds the ${GASKETS[config.parts.gasket].boostLimit} psi gasket rating.` })
    else if (ecu.boostTarget > GASKETS[config.parts.gasket].boostLimit - 1.5) out.push({ level: 'warn', text: 'Boost target is right at the gasket limit. Hot weather will find out.' })
    if (ecu.boostTarget < 1) out.push({ level: 'warn', text: 'Boost target is near zero. The turbo is installed but doing nothing.' })
  }

  if (ecu.revLimit > spec.mechanicalRedline) out.push({ level: 'bad', text: `Rev limiter ${ecu.revLimit} rpm is past the ${spec.mechanicalRedline} rpm mechanical limit.` })
  else if (ecu.revLimit > spec.mechanicalRedline - 250) out.push({ level: 'warn', text: 'Rev limiter is within 250 rpm of valve float.' })

  const afrTarget = FUELS[config.fuel].afrTarget
  if (Math.abs(ecu.afr - afrTarget) > 1.2) {
    out.push({ level: 'warn', text: `AFR target ${ecu.afr.toFixed(1)} is far from the ${afrTarget.toFixed(1)} baseline for ${FUELS[config.fuel].short}.` })
  }
  if (config.fuel === 'e85' && ecu.afr > 10.5) out.push({ level: 'bad', text: 'E85 needs a much richer AFR target than pump fuel.' })
  if (config.fuel !== 'e85' && ecu.afr < 10.5) out.push({ level: 'warn', text: 'This AFR is extremely rich for petrol; power will suffer.' })

  const maxIgn = Math.max(...ecu.ignition.flat())
  const safe = safeAdvance(config, boost, charge)
  if (maxIgn > safe + 3) out.push({ level: 'bad', text: `Ignition map peaks at ${maxIgn.toFixed(1)}°, about ${(maxIgn - safe).toFixed(1)}° past safe. Expect knock.` })
  else if (maxIgn > safe) out.push({ level: 'warn', text: `Ignition map is ${(maxIgn - safe).toFixed(1)}° past the safe estimate. Listen for knock.` })

  const fit = spec.envelopeMm.length <= body.bay.length && spec.envelopeMm.width <= body.bay.width && spec.envelopeMm.height <= body.bay.height
  if (!fit) out.push({ level: 'bad', text: 'This engine does not fit the current body. Repackage before running.' })
  return out
}

export function displayAfrs(config: EngineConfig): { target: number; label: string; safeRange: [number, number] } {
  const f = FUELS[config.fuel]
  return {
    target: f.afrTarget,
    label: f.short,
    safeRange: f.id === 'e85' ? [7.4, 9.2] : [11.8, 13.2],
  }
}

export function injectorHeadroom(config: EngineConfig): number {
  return Math.round((INJECTORS[config.parts.injectors].cc / 220) * 10) / 10
}
