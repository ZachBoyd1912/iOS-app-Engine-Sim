import { CAMS, FUELS, GASKETS, HEADS, INDUCTIONS, INTERCOOLERS, INJECTORS, LAYOUTS, PUMPS } from './data'
import { engineSpec } from './engine'
import type { EngineConfig } from './types'

const clamp = (v: number, min: number, max: number) => Math.min(max, Math.max(min, v))
const smoothstep = (a: number, b: number, x: number) => {
  const t = clamp((x - a) / (b - a), 0, 1)
  return t * t * (3 - 2 * t)
}

/** Physical volumetric efficiency at wide-open throttle, before any fault. */
export function veAt(config: EngineConfig, rpm: number): number {
  const spec = engineSpec(config)
  const layout = LAYOUTS[config.layout]
  const cam = CAMS[config.parts.cams]
  const head = HEADS[config.parts.head]
  const rotary = layout.rotors > 0
  const peakRpm = spec.camPeakRpm
  const sigma = 2400 + cam.duration * 4.2 + config.parts.head * 80
  const low = clamp(0.60 - cam.overlap * 0.004 + (head.flow - 0.94) * 0.28 + (rotary ? 0.1 : 0), 0.40, 0.76)
  const peak = spec.peakVe
  const gauss = Math.exp(-Math.pow((rpm - peakRpm) / sigma, 2))
  let ve = low + (peak - low) * (0.32 + 0.68 * gauss)
  ve *= smoothstep(800, 2400, rpm)
  if (rpm > peakRpm) {
    const span = Math.max(2500, spec.mechanicalRedline - peakRpm)
    const falloff = 0.34 - (cam.peakOffset / 1900) * 0.14
    ve -= Math.pow(clamp((rpm - peakRpm) / span, 0, 1.2), 1.6) * falloff
  }
  if (rotary) ve += smoothstep(4500, 9000, rpm) * 0.08
  return clamp(ve, 0.32, 1.3)
}

export function loadAt(throttle: number, boostPsi: number): number {
  return clamp(20 + 80 * throttle + Math.max(0, boostPsi) * 3.6, 20, 180)
}

export function boostAt(
  config: EngineConfig,
  rpm: number,
  throttle: number,
  targetPsi: number,
  chargeTempC: number,
): number {
  const induction = INDUCTIONS[config.induction]
  const spec = engineSpec(config)
  if (induction.maxBoost <= 0 || throttle < 0.04) return 0
  const target = clamp(targetPsi, 0, induction.maxBoost)
  const spool = induction.linear
    ? 0.22 + 0.78 * clamp(rpm / Math.max(4500, spec.mechanicalRedline), 0, 1)
    : 1 / (1 + Math.exp(-(rpm - induction.spoolRpm) / 430))
  const throttleFactor = 0.10 + 0.90 * throttle
  const heatDerate = clamp(1 - Math.max(0, chargeTempC - 48) * 0.0018, 0.72, 1)
  let psi = target * spool * throttleFactor * heatDerate
  if (config.faults?.includes('stuckWastegate')) psi = Math.min(induction.maxBoost, psi * 1.45 + 0.5)
  return clamp(psi, 0, induction.maxBoost)
}

export function chargeTempAt(config: EngineConfig, boostPsi: number, heatSoak: number): number {
  const cooling = INTERCOOLERS[config.parts.intercooler].cooling
  const compressionHeat = Math.max(0, boostPsi) * 6.1
  return clamp(22 + Math.max(0, heatSoak) + compressionHeat * (1 - cooling * 0.85), 12, 165)
}

export function safeAdvance(config: EngineConfig, boostPsi: number, chargeTempC: number): number {
  const fuel = FUELS[config.fuel]
  const base = 29 + fuel.timingBias
  return clamp(
    base
      - Math.max(0, boostPsi) * 0.95
      - Math.max(0, chargeTempC - 25) * 0.105
      - Math.max(0, config.compression - 9.5) * 0.8,
    3,
    34,
  )
}

export function mbtAdvance(config: EngineConfig, rpm: number, boostPsi: number): number {
  const spec = engineSpec(config)
  const cam = CAMS[config.parts.cams]
  return clamp(
    24 + 7 * clamp(rpm / Math.max(4500, spec.mechanicalRedline), 0, 1)
      - (Math.max(0, boostPsi) / 14.7) * 5
      + cam.overlap * 0.03,
    5,
    35,
  )
}

export function knockIndex(
  config: EngineConfig,
  advance: number,
  boostPsi: number,
  chargeTempC: number,
  actualAfr: number,
  targetAfr: number,
): number {
  const safe = safeAdvance(config, boostPsi, chargeTempC)
  const over = Math.max(0, advance - safe)
  const lean = Math.max(0, actualAfr / Math.max(1, targetAfr) - 1.015) * 145
  const gasket = GASKETS[config.parts.gasket].boostLimit
  const overboost = Math.max(0, boostPsi - gasket) * 2.8
  const heat = Math.max(0, chargeTempC - 88) * 0.32
  return clamp(over * 4.4 + lean + overboost + heat, 0, 100)
}

export function afrPowerFactor(actual: number, target: number): number {
  const ratio = actual / Math.max(0.1, target)
  if (ratio < 1) return clamp(1 - (1 - ratio) * 0.48, 0.82, 1)
  return clamp(1 - (ratio - 1) * 1.15, 0.62, 1)
}

export function airflowGps(
  config: EngineConfig,
  rpm: number,
  throttle: number,
  ve: number,
  boostPsi: number,
  chargeTempC: number,
): number {
  const spec = engineSpec(config)
  const pressureRatio = (14.7 + Math.max(0, boostPsi)) / 14.7
  const density = 1.184 * (293 / (273 + chargeTempC))
  const airLoad = 0.055 + 0.945 * clamp(throttle, 0, 1)
  return Math.max(0, spec.displacementL * (Math.max(600, rpm) / 2) / 60 * density * ve * pressureRatio * airLoad)
}

export function injectorCapacityGps(config: EngineConfig): number {
  const spec = engineSpec(config)
  const cc = INJECTORS[config.parts.injectors].cc
  return (cc * spec.cylinders * FUELS[config.fuel].density) / 60
}

export function pumpCapacityGps(config: EngineConfig): number {
  return (PUMPS[config.parts.pump].lph * FUELS[config.fuel].density) / 3.6
}

export function pumpHealthFactor(config: EngineConfig, demandedGps: number): number {
  const capacity = pumpCapacityGps(config)
  if (!config.faults?.includes('weakPump')) return 1
  const stress = demandedGps / Math.max(0.1, capacity)
  return clamp(1 - Math.max(0, stress - 0.42) * 1.65, 0.42, 1)
}

export function leakFactor(config: EngineConfig, rpm: number): number {
  if (!config.faults?.includes('vacLeak')) return 1
  return 1 + 0.12 * smoothstep(1800, 4200, rpm)
}

export function misfireFactor(config: EngineConfig, rpm: number): number {
  if (!config.faults?.includes('burntValve')) return 1
  return (1 - 0.18) * (rpm > 4400 ? 1 - 0.07 * smoothstep(4400, 6500, rpm) : 1)
}

export function egtAt(
  config: EngineConfig,
  rpm: number,
  boostPsi: number,
  actualAfr: number,
  targetAfr: number,
  heatSoak: number,
): number {
  const lean = Math.max(0, actualAfr / Math.max(1, targetAfr) - 1)
  return clamp(
    480 + (rpm / Math.max(4000, engineSpec(config).mechanicalRedline)) * 340 + Math.max(0, boostPsi) * 7 + lean * 520 + heatSoak * 1.3,
    350,
    1200,
  )
}
