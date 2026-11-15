import { FAULTS, bodyById } from './data'
import { defaultEcu } from './ecu'
import { engineCost, engineSpec, salvageEngine } from './engine'
import type { Build, ChassisConfig, EngineConfig, FaultId } from './types'

let buildCounter = 0

export function defaultChassis(): ChassisConfig {
  return {
    tires: 'street',
    suspension: 'stock',
    brakes: 'stock',
    gearbox: 'five',
    weight: 'full',
  }
}

export function makeBuild(bodyId: string, engine: EngineConfig, name?: string): Build {
  const body = bodyById(bodyId)
  buildCounter += 1
  return {
    id: `build-${Date.now().toString(36)}-${buildCounter}`,
    name: name ?? engine.name,
    bodyId: body.id,
    engine: structuredClone(engine),
    ecu: defaultEcu(engine),
    paint: { color: body.defaultPaint, finish: 'gloss' },
    wheels: { style: 'steel', size: 17 },
    stance: 0,
    aero: 'none',
    interior: 'full',
    chassis: defaultChassis(),
    condition: 100,
  }
}

export function cloneBuild(build: Build): Build {
  return structuredClone(build)
}

export function repairCost(build: Build): number {
  const base = engineCost(build.engine)
  return Math.round(180 + base * 0.24 * (1 - build.condition / 100))
}

export function rebuildCost(build: Build): number {
  return Math.round(420 + engineCost(build.engine) * 0.34)
}

export function faultRepairCost(faults: FaultId[] | undefined): number {
  return (faults ?? []).reduce((sum, fault) => sum + FAULTS[fault].repair, 0)
}

export function conditionLabel(condition: number): { text: string; level: 'ok' | 'warn' | 'bad' } {
  if (condition <= 0) return { text: 'Seized', level: 'bad' }
  if (condition < 25) return { text: 'Critical', level: 'bad' }
  if (condition < 55) return { text: 'Tired', level: 'warn' }
  if (condition < 80) return { text: 'Used', level: 'warn' }
  return { text: 'Healthy', level: 'ok' }
}

export function engineLabel(build: Build): string {
  const spec = engineSpec(build.engine)
  return `${spec.layoutName} · ${spec.displacementL.toFixed(2)} L · ${spec.inductionName}`
}

export function startingBuild(): Build {
  const build = makeBuild('kei', salvageEngine(), 'Project KT-3')
  build.condition = 58
  build.paint = { color: '#c59a52', finish: 'satin' }
  build.chassis.tires = 'street'
  return build
}

export function sandboxStartingBuild(): Build {
  const build = makeBuild('supercar', {
    layout: 'v8',
    name: 'Sandbox Twin-Turbo',
    bore: 88,
    stroke: 82,
    compression: 9,
    induction: 'twinTurbo',
    fuel: 'race',
    parts: { head: 3, cams: 3, intake: 2, exhaust: 3, injectors: 4, pump: 3, internals: 3, valves: 2, gasket: 2, intercooler: 2 },
  }, 'SC-12 Prototype')
  build.condition = 96
  build.paint = { color: '#d8922f', finish: 'metallic' }
  build.wheels = { style: 'turbofan', size: 19 }
  build.aero = 'full'
  build.interior = 'stripped'
  build.chassis = { tires: 'semi', suspension: 'race', brakes: 'race', gearbox: 'dct', weight: 'carbon' }
  return build
}