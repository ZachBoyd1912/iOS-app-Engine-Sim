import {
  CAMS,
  EXHAUSTS,
  FUELS,
  GASKETS,
  HEADS,
  INDUCTIONS,
  INTAKES,
  INTERCOOLERS,
  INJECTORS,
  INTERNALS,
  LAYOUTS,
  PUMPS,
  VALVES,
  bodyById,
  emptyParts,
  partOption,
} from './data'
import type { BodySpec, EngineConfig, EngineSpec, FitmentResult, PartSlot } from './types'
import { PART_SLOTS } from './types'

const clamp = (v: number, min: number, max: number) => Math.min(max, Math.max(min, v))

export function defaultEngine(layout: EngineConfig['layout'] = 'i4', name = 'Forge 2.0'): EngineConfig {
  const spec = LAYOUTS[layout]
  return {
    layout,
    name,
    bore: spec.rotors ? 80 : 86,
    stroke: spec.rotors ? 75 : 86,
    compression: 10.5,
    induction: 'na',
    fuel: 'p98',
    parts: emptyParts(),
  }
}

export function salvageEngine(): EngineConfig {
  return {
    layout: 'i4',
    name: 'Salvage 1.6',
    bore: 78,
    stroke: 82,
    compression: 9.5,
    induction: 'na',
    fuel: 'p95',
    parts: emptyParts(),
  }
}

export function enginePresets(): { id: string; name: string; note: string; build: EngineConfig }[] {
  const preset = (id: string, name: string, note: string, build: EngineConfig) => ({ id, name, note, build })
  return [
    preset('salvage', 'Salvage 1.6', 'The free engine in the corner. Stock, tired, and ready to learn on.', salvageEngine()),
    preset('street', 'Street 2.0', 'Mild cams and a ported head. Reliable NA power.', {
      ...defaultEngine('i4', 'Street 2.0'),
      parts: { ...emptyParts(), head: 1, cams: 2, intake: 1, exhaust: 1, injectors: 1, pump: 1, internals: 1 },
      fuel: 'p98',
    }),
    preset('turbo', 'Turbo Four', '2.0 litres, medium turbo, forged rods. The first big step.', {
      ...defaultEngine('i4', 'Turbo Four'),
      compression: 9.0,
      induction: 'turboM',
      fuel: 'p98',
      parts: { ...emptyParts(), head: 2, cams: 2, intake: 1, exhaust: 2, injectors: 2, pump: 2, internals: 2, valves: 1, gasket: 1, intercooler: 1 },
    }),
    preset('screamer', 'Screamer I6', 'A long, smooth, high-revving naturally aspirated six.', {
      ...defaultEngine('i6', 'Screamer I6'),
      bore: 86,
      stroke: 80,
      compression: 11.2,
      fuel: 'race',
      parts: { ...emptyParts(), head: 2, cams: 3, intake: 2, exhaust: 2, injectors: 2, pump: 2, internals: 2, valves: 1 },
    }),
    preset('bigblock', 'Big Block V8', 'Cubic inches, crossplane noise, and torque everywhere.', {
      ...defaultEngine('v8', 'Big Block V8'),
      bore: 103.25,
      stroke: 92,
      compression: 10.8,
      fuel: 'p98',
      parts: { ...emptyParts(), head: 2, cams: 2, intake: 1, exhaust: 2, injectors: 2, pump: 1, internals: 1, valves: 1 },
    }),
    preset('twinturbo', 'Twin-Turbo V8', 'A 4.0 V8 with two turbos and a very large bill.', {
      ...defaultEngine('v8', 'Twin-Turbo V8'),
      bore: 88,
      stroke: 82,
      compression: 9.0,
      induction: 'twinTurbo',
      fuel: 'race',
      parts: { ...emptyParts(), head: 3, cams: 3, intake: 2, exhaust: 3, injectors: 4, pump: 3, internals: 3, valves: 2, gasket: 2, intercooler: 2 },
    }),
    preset('rotary', 'Rotary Screamer', 'Two rotors, a large port and a turbo. Heat is the enemy.', {
      ...defaultEngine('rotary2', 'Rotary Screamer'),
      bore: 80,
      stroke: 75,
      compression: 9.0,
      induction: 'turboM',
      fuel: 'p98',
      parts: { ...emptyParts(), head: 2, cams: 2, intake: 2, exhaust: 2, injectors: 2, pump: 2, internals: 2, gasket: 1, intercooler: 1 },
    }),
  ]
}

export function sanitizeEngine(input: EngineConfig): EngineConfig {
  const layout = LAYOUTS[input.layout] ? input.layout : 'i4'
  const rotary = LAYOUTS[layout].rotors > 0
  const parts = { ...emptyParts() }
  for (const slot of PART_SLOTS) {
    const list = partTable(slot)
    parts[slot] = clamp(Math.round(input.parts?.[slot] ?? 0), 0, list.length - 1)
  }
  return {
    layout,
    name: (input.name || 'Untitled build').slice(0, 28),
    bore: clamp(Number.isFinite(input.bore) ? input.bore : 86, rotary ? 60 : 65, rotary ? 100 : 112),
    stroke: clamp(Number.isFinite(input.stroke) ? input.stroke : 86, rotary ? 60 : 60, rotary ? 100 : 112),
    compression: clamp(Number.isFinite(input.compression) ? input.compression : 10.5, 6.5, 14.5),
    induction: INDUCTIONS[input.induction] ? input.induction : 'na',
    fuel: FUELS[input.fuel] ? input.fuel : 'p98',
    parts,
    ...(input.faults?.length ? { faults: input.faults.slice(0, 4) } : {}),
  }
}

function partTable(slot: PartSlot): readonly { cost: number }[] {
  switch (slot) {
    case 'head': return HEADS
    case 'cams': return CAMS
    case 'intake': return INTAKES
    case 'exhaust': return EXHAUSTS
    case 'injectors': return INJECTORS
    case 'pump': return PUMPS
    case 'internals': return INTERNALS
    case 'valves': return VALVES
    case 'gasket': return GASKETS
    case 'intercooler': return INTERCOOLERS
  }
}

export function engineCost(config: EngineConfig): number {
  let sum = INDUCTIONS[config.induction].cost + FUELS[config.fuel].cost
  for (const slot of PART_SLOTS) sum += partOption(slot, config.parts[slot]).cost
  return Math.round(sum)
}

export function upgradeCost(current: EngineConfig, next: EngineConfig): number {
  return Math.max(0, engineCost(next) - engineCost(current))
}

export function engineSpec(config: EngineConfig): EngineSpec {
  const layout = LAYOUTS[config.layout]
  const rotary = layout.rotors > 0
  const cylinders = rotary ? layout.rotors : layout.cylinders
  const head = HEADS[config.parts.head]
  const cam = CAMS[config.parts.cams]
  const intake = INTAKES[config.parts.intake]
  const exhaust = EXHAUSTS[config.parts.exhaust]
  const internals = INTERNALS[config.parts.internals]
  const valves = VALVES[config.parts.valves]
  const gasket = GASKETS[config.parts.gasket]
  const intercooler = INTERCOOLERS[config.parts.intercooler]
  const induction = INDUCTIONS[config.induction]

  const displacementCc = rotary
    ? 654 * cylinders * (config.bore / 80) * Math.pow(config.stroke / 75, 2)
    : (Math.PI / 4) * config.bore * config.bore * config.stroke * cylinders / 1000
  const displacementL = displacementCc / 1000

  const toneLimit = rotary ? 9200 : 9000
  const pistonLimit = rotary ? toneLimit : Math.round((24 * 60) / (2 * (config.stroke / 1000)))
  const mechanicalRedline = Math.round(clamp(Math.min(internals.maxRpm + valves.rpmAdd, pistonLimit), 4800, toneLimit) / 50) * 50

  const deck = config.stroke * 1.35 + 175
  const bankSpan = layout.banks === 2 ? Math.abs(Math.sin((layout.bankAngle * Math.PI) / 360)) * deck * 2 : config.bore * 1.65
  const perBank = rotary ? 1 : layout.banks === 2 ? cylinders / 2 : cylinders
  const blockLength = rotary
    ? cylinders * config.bore * 1.5 + 190
    : config.bore * perBank * 1.14 + 230
  const turboPad = config.induction === 'na' || config.induction === 'nitrous' ? 0 : config.induction === 'twinTurbo' ? 110 : 85
  const blowerPad = config.induction === 'supercharger' ? 105 : 0

  const envelope = {
    length: Math.round(blockLength + turboPad * 0.6 + (intercooler.cooling > 0 ? 40 : 0)),
    width: Math.round(Math.max(config.bore * 1.9 + 150, bankSpan + config.bore + 120) + turboPad * 0.35),
    height: Math.round((layout.banks === 2 ? deck * 0.78 : deck) + config.bore * 0.8 + 150 + blowerPad + turboPad * 0.2),
  }

  const baseMass = rotary ? 32 + displacementL * 34 : 26 + displacementL * 45
  const layoutMass = layout.banks === 2 ? 18 : layout.cylinders >= 6 ? 12 : 0
  const inductionMass = induction.maxBoost > 0 ? (config.induction === 'twinTurbo' ? 34 : 24) : config.induction === 'supercharger' ? 30 : 0
  const massKg = Math.round((baseMass + layoutMass + inductionMass + (intercooler.cooling > 0 ? 11 : 0)) * internals.massFactor + gasket.boostLimit * 0.15)

  const peakVe = 0.93
    + (head.flow - 0.94) * 0.45
    + (intake.flow - 0.95) * 0.35
    + (exhaust.flow - 0.94) * 0.35
    + (cam.duration - 228) * 0.0007
  const camPeakRpm = Math.round(
    3600 + cam.peakOffset + config.parts.head * 100 + (layout.cylinders >= 8 ? 100 : 0) + (layout.rotors > 0 ? 2600 : 0),
  )

  const warnings: string[] = []
  const maxBoost = induction.maxBoost
  if (maxBoost > gasket.boostLimit) warnings.push(`Turbo can make ${maxBoost} psi but the ${gasket.name.toLowerCase()} is rated to ${gasket.boostLimit} psi.`)
  if (maxBoost > 0 && intercooler.cooling === 0) warnings.push('No intercooler: charge temperatures will climb and knock margin will shrink.')
  if (config.fuel === 'e85' && (INJECTORS[config.parts.injectors].cc < 750 || PUMPS[config.parts.pump].lph < 255)) warnings.push('E85 needs at least 750 cc injectors and a 255 l/h pump to avoid running dry.')
  if (config.compression >= 11.5 && maxBoost > 0) warnings.push('High static compression with boost leaves almost no knock margin. Consider lower compression or race fuel.')
  if (camPeakRpm > mechanicalRedline - 400) warnings.push(`The cam wants ${camPeakRpm} rpm but the valvetrain is only safe to ${mechanicalRedline} rpm.`)
  if (mechanicalRedline < 6000) warnings.push('Low mechanical redline: the bottom end will limit the build.')
  if (config.compression > 12.5 && config.fuel === 'p95') warnings.push('95 RON will not support this much compression without knock.')
  if (displacementL > 6.5 && layout.cylinders < 8) warnings.push('Very large displacement for this cylinder count. Expect heat and packaging problems.')

  return {
    layoutName: layout.name,
    cylinders,
    rotors: layout.rotors,
    displacementCc: Math.round(displacementCc),
    displacementL: Math.round(displacementL * 100) / 100,
    boreStrokeRatio: Math.round((config.bore / config.stroke) * 1000) / 1000,
    staticCompression: config.compression,
    mechanicalRedline,
    envelopeMm: envelope,
    massKg,
    partsCost: engineCost(config),
    peakVe: Math.round(peakVe * 1000) / 1000,
    camPeakRpm,
    inductionName: induction.name,
    fuelName: FUELS[config.fuel].name,
    warnings,
  }
}

export function fitment(config: EngineConfig, bodyId: string): FitmentResult {
  const body: BodySpec = bodyById(bodyId)
  const spec = engineSpec(config)
  const dimensions: Array<['length' | 'width' | 'height', number, number]> = [
    ['length', spec.envelopeMm.length, body.bay.length],
    ['width', spec.envelopeMm.width, body.bay.width],
    ['height', spec.envelopeMm.height, body.bay.height],
  ]
  const over = dimensions.filter(([, e, b]) => e > b)
  const worst = over.sort((a, b) => b[1] - b[2] - (a[1] - a[2]))[0]
  return {
    fits: over.length === 0,
    bay: body.bay,
    engine: spec.envelopeMm,
    blocker: worst?.[0] ?? null,
    overByMm: worst ? Math.round(worst[1] - worst[2]) : 0,
  }
}

/** Recommendations shown beneath the builder's sliders. */
export function buildAdvice(config: EngineConfig): { level: 'ok' | 'warn' | 'bad'; text: string }[] {
  const spec = engineSpec(config)
  const advice: { level: 'ok' | 'warn' | 'bad'; text: string }[] = []
  const bsr = spec.boreStrokeRatio
  if (bsr < 0.82) advice.push({ level: 'warn', text: 'Very undersquare (long stroke): strong low-end, limited safe RPM.' })
  else if (bsr > 1.12) advice.push({ level: 'warn', text: 'Very oversquare (short stroke): revs freely, but torque will feel thin low down.' })
  else advice.push({ level: 'ok', text: 'Bore/stroke ratio is in a healthy range for a flexible engine.' })

  if (spec.mechanicalRedline < 6500) advice.push({ level: 'warn', text: 'The stock bottom end limits the redline. Forged internals unlock more.' })
  if (config.parts.injectors === 0 && (INDUCTIONS[config.induction].maxBoost > 0 || engineSpec(config).displacementL > 2.5)) {
    advice.push({ level: 'bad', text: 'Stock 220 cc injectors will run out of duty. Fit larger injectors before the dyno.' })
  }
  if (config.parts.pump === 0 && (INDUCTIONS[config.induction].maxBoost > 0 || FUELS[config.fuel].id === 'e85')) {
    advice.push({ level: 'bad', text: 'The stock pump cannot support this fuel/boost combination.' })
  }
  if (config.parts.gasket === 0 && INDUCTIONS[config.induction].maxBoost > 10) {
    advice.push({ level: 'bad', text: 'Stock head gasket below the turbo’s ceiling: fit an MLS gasket.' })
  }
  if (config.parts.intercooler === 0 && INDUCTIONS[config.induction].maxBoost >= 9) {
    advice.push({ level: 'warn', text: 'Without an intercooler, repeated pulls will heat-soak and knock.' })
  }
  if (config.parts.cams >= 3 && spec.mechanicalRedline < 7500) {
    advice.push({ level: 'warn', text: 'A race cam needs RPM the valvetrain cannot safely deliver.' })
  }
  if (FUELS[config.fuel].octane < 98 && config.compression > 11) {
    advice.push({ level: 'warn', text: 'High compression on 95 RON is asking for knock. Use 98 or race fuel.' })
  }
  return advice
}
