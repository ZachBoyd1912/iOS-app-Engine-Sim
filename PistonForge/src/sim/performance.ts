import {
  FUELS,
  GASKETS,
  INDUCTIONS,
  INTERCOOLERS,
} from './data'
import {
  afrPowerFactor,
  airflowGps,
  boostAt,
  chargeTempAt,
  egtAt,
  injectorCapacityGps,
  knockIndex,
  leakFactor,
  loadAt,
  mbtAdvance,
  misfireFactor,
  pumpCapacityGps,
  pumpHealthFactor,
  veAt,
} from './airflow'
import { tableValue } from './ecu'
import { engineSpec } from './engine'
import type { DynoPoint, DynoResult, EcuConfig, EngineConfig, FailureId } from './types'

const clamp = (v: number, min: number, max: number) => Math.min(max, Math.max(min, v))
const r1 = (v: number) => Math.round(v * 10) / 10
const r2 = (v: number) => Math.round(v * 100) / 100

export type OperatingPoint = {
  rpm: number
  throttle: number
  ve: number
  load: number
  boost: number
  chargeTemp: number
  targetAfr: number
  afr: number
  timing: number
  mbt: number
  knock: number
  torque: number
  hp: number
  duty: number
  pumpMargin: number
  egt: number
  airGps: number
  fuelGps: number
  limiter: boolean
  overrev: boolean
}

export function operatingPoint(
  config: EngineConfig,
  ecu: EcuConfig,
  rpm: number,
  throttle: number,
  heatSoak = 0,
): OperatingPoint {
  const spec = engineSpec(config)
  const fuel = FUELS[config.fuel]
  const induction = INDUCTIONS[config.induction]
  let boost = boostAt(config, rpm, throttle, ecu.boostTarget, 30 + heatSoak)
  let charge = chargeTempAt(config, boost, heatSoak)
  boost = boostAt(config, rpm, throttle, ecu.boostTarget, charge)
  charge = chargeTempAt(config, boost, heatSoak)
  const load = loadAt(throttle, boost)
  const ve = veAt(config, rpm)
  const fuelCell = tableValue(ecu.fuel, rpm, load)
  const advance = tableValue(ecu.ignition, rpm, load)
  const targetAfr = ecu.afr
  const airBase = airflowGps(config, rpm, throttle, ve, boost, charge)
  const airActual = airBase * leakFactor(config, rpm)
  const commandedFuel = airBase / Math.max(1, targetAfr) * (fuelCell / Math.max(1, ve * 100))
  const injectorMax = injectorCapacityGps(config)
  const pumpHealth = pumpHealthFactor(config, commandedFuel)
  const pumpMax = pumpCapacityGps(config) * pumpHealth
  const delivered = Math.max(0.0001, Math.min(commandedFuel, injectorMax * 0.96, pumpMax * 0.94))
  const afr = airActual / delivered
  const duty = (commandedFuel / Math.max(0.001, injectorMax)) * 100
  const pumpMargin = pumpMax / Math.max(0.001, commandedFuel)
  const knock = knockIndex(config, advance, boost, charge, afr, targetAfr)
  const mbt = mbtAdvance(config, rpm, boost)
  const timingFactor = advance < mbt ? 0.86 + 0.14 * clamp(advance / Math.max(1, mbt), 0, 1) : 1 - Math.min(0.015, (advance - mbt) * 0.0008)
  const pressureRatio = (14.7 + boost) / 14.7
  const fuelEnergy = fuel.energy / 43.5
  const mixture = afrPowerFactor(afr, targetAfr)
  const health = Math.max(0.35, 1 - knock * 0.0016) * misfireFactor(config, rpm)
  const bmep = 13.0 * ve * pressureRatio * fuelEnergy * mixture * timingFactor * health
  const torqueBase = (bmep * 1e5 * (spec.displacementCc / 1_000_000)) / (4 * Math.PI)
  const nitrousHp = induction.nitrousHp > 0 && throttle > 0.92 && rpm > 2800 ? induction.nitrousHp : 0
  const nitrousTorque = nitrousHp > 0 ? (nitrousHp * 7127) / Math.max(1500, rpm) : 0
  const limiter = rpm >= ecu.revLimit - 45
  const overrev = rpm > spec.mechanicalRedline + 80
  let torque = torqueBase + nitrousTorque
  if (limiter) torque *= 0.04
  if (overrev) torque *= clamp(1 - (rpm - spec.mechanicalRedline) / 500, 0.25, 0.92)
  const hp = (torque * rpm) / 7127
  const egt = egtAt(config, rpm, boost, afr, targetAfr, heatSoak)
  return {
    rpm,
    throttle,
    ve: r2(ve),
    load: r1(load),
    boost: r2(boost),
    chargeTemp: r1(charge),
    targetAfr: r1(targetAfr),
    afr: r1(afr),
    timing: r1(advance),
    mbt: r1(mbt),
    knock: r1(knock),
    torque: Math.max(0, Math.round(torque)),
    hp: Math.max(0, Math.round(hp)),
    duty: Math.round(duty),
    pumpMargin: r2(pumpMargin),
    egt: Math.round(egt),
    airGps: r1(airBase),
    fuelGps: r2(delivered),
    limiter,
    overrev,
  }
}

export function torqueCurve(config: EngineConfig, ecu: EcuConfig, points = 70): DynoPoint[] {
  const spec = engineSpec(config)
  const top = Math.min(ecu.revLimit, spec.mechanicalRedline)
  const step = Math.max(100, Math.round((top - 1000) / points / 100) * 100)
  const out: DynoPoint[] = []
  let heat = 6
  for (let rpm = 1000; rpm <= top; rpm += step) {
    heat = clamp(heat + 0.055, 0, 22)
    const op = operatingPoint(config, ecu, rpm, 1, heat)
    out.push({
      rpm,
      hp: op.hp,
      torque: op.torque,
      boost: op.boost,
      afr: op.afr,
      timing: op.timing,
      knock: op.knock,
      egt: op.egt,
      ve: op.ve,
      duty: op.duty,
      pumpMargin: op.pumpMargin,
    })
  }
  return out
}

export function estimatePeak(config: EngineConfig, ecu: EcuConfig): { hp: number; hpRpm: number; torque: number; torqueRpm: number } {
  const points = torqueCurve(config, ecu, 52)
  return peak(points)
}

function peak(points: DynoPoint[]): { hp: number; hpRpm: number; torque: number; torqueRpm: number } {
  let hp = 0
  let hpRpm = 0
  let torque = 0
  let torqueRpm = 0
  for (const p of points) {
    if (p.hp > hp) { hp = p.hp; hpRpm = p.rpm }
    if (p.torque > torque) { torque = p.torque; torqueRpm = p.rpm }
  }
  return { hp, hpRpm, torque, torqueRpm }
}

type Severity = { knock: number; lean: number; overboost: number; overrev: number; heat: number; catastrophic: FailureId | null }

export function dynoPull(config: EngineConfig, ecu: EcuConfig, conditionBefore: number): DynoResult {
  const spec = engineSpec(config)
  const points = torqueCurve(config, ecu, 70)
  const severity: Severity = { knock: 0, lean: 0, overboost: 0, overrev: 0, heat: 0, catastrophic: null }
  const gasketLimit = GASKETS[config.parts.gasket].boostLimit
  let heat = 7

  for (const p of points) {
    const ratio = p.afr / Math.max(1, ecu.afr)
    if (p.knock > 62) {
      severity.knock += (p.knock - 62) * 0.015
      if (p.knock > 94) severity.catastrophic ??= 'knock'
    }
    if (ratio > 1.075) {
      severity.lean += (ratio - 1.075) * 4.5
      if (ratio > 1.27) severity.catastrophic ??= 'lean'
    }
    if (p.boost > gasketLimit) {
      severity.overboost += (p.boost - gasketLimit) * 0.11
      if (p.boost > gasketLimit + 8) severity.catastrophic ??= 'overboost'
    }
    if (p.rpm > spec.mechanicalRedline) {
      severity.overrev += (p.rpm - spec.mechanicalRedline) / 90
      if (p.rpm > spec.mechanicalRedline + 380) severity.catastrophic ??= 'overrev'
    }
    if (p.egt > 980) {
      severity.heat += (p.egt - 980) / 120
      if (p.egt > 1150) severity.catastrophic ??= 'heat'
    }
    heat = clamp(heat + 0.12 + p.boost * 0.016, 0, 32)
  }

  const total = severity.knock + severity.lean + severity.overboost + severity.overrev + severity.heat
  const wear = r1(0.35 + Math.min(48, total))
  const failed = Boolean(severity.catastrophic) || conditionBefore - wear <= 0
  const conditionAfter = failed ? 0 : Math.max(0, r1(conditionBefore - wear))
  const failure: FailureId | null = failed
    ? severity.catastrophic ?? dominantFailure(severity)
    : null
  const p = peak(points)
  const boostPeak = Math.max(...points.map(point => point.boost))
  const afrMin = Math.min(...points.map(point => point.afr))
  const afrMax = Math.max(...points.map(point => point.afr))
  const knockPeak = Math.max(...points.map(point => point.knock))
  const egtPeak = Math.max(...points.map(point => point.egt))
  return {
    points,
    peakHp: p.hp,
    peakHpRpm: p.hpRpm,
    peakTorque: p.torque,
    peakTorqueRpm: p.torqueRpm,
    redline: points[points.length - 1]?.rpm ?? ecu.revLimit,
    boostPeak: r1(boostPeak),
    afrMin: r1(afrMin),
    afrMax: r1(afrMax),
    knockPeak: r1(knockPeak),
    egtPeak,
    conditionBefore,
    conditionAfter,
    failure,
    valid: !failed,
    at: Date.now(),
  }
}

function dominantFailure(severity: Severity): FailureId {
  const pairs: [FailureId, number][] = [
    ['knock', severity.knock],
    ['lean', severity.lean],
    ['overboost', severity.overboost],
    ['overrev', severity.overrev],
    ['heat', severity.heat],
  ]
  return pairs.sort((a, b) => b[1] - a[1])[0][0]
}

export function pullGrade(result: DynoResult, config: EngineConfig): { grade: string; text: string; level: 'ok' | 'warn' | 'bad' } {
  if (!result.valid) {
    const phrase: Record<FailureId, string> = {
      knock: 'Detonation cracked the piston crown.',
      lean: 'Lean running burned an exhaust valve.',
      overboost: 'Boost lifted the head gasket.',
      overrev: 'Valve float met piston. The engine is done.',
      heat: 'Heat soak seized the top end.',
    }
    return { grade: 'FAILED', text: phrase[result.failure ?? 'knock'], level: 'bad' }
  }
  if (result.knockPeak > 35 || result.afrMax > (config.fuel === 'e85' ? 9.6 : 14.2)) {
    return { grade: 'EDGE', text: 'It survived, but the log is ugly. Fix the mixture or pull timing before the next run.', level: 'warn' }
  }
  if (result.conditionAfter < result.conditionBefore - 4) {
    return { grade: 'HARD', text: 'A lot of condition disappeared in one pull. Something is unhappy.', level: 'warn' }
  }
  return { grade: 'CLEAN', text: 'Clean pull. Mixture, timing and boost stayed inside the safe window.', level: 'ok' }
}

export function chargeCoolerLabel(config: EngineConfig): string {
  return INTERCOOLERS[config.parts.intercooler].name
}

export function fuelCostHint(config: EngineConfig): string {
  return `${FUELS[config.fuel].short} · ${FUELS[config.fuel].octane} RON`
}

export function dynoSummaryLine(result: DynoResult): string {
  if (!result.valid) return 'Engine failed during the pull'
  return `${result.peakHp} hp @ ${result.peakHpRpm} · ${result.peakTorque} Nm @ ${result.peakTorqueRpm}`
}
