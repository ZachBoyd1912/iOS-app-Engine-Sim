import type {
  AeroId,
  BodySpec,
  BrakeId,
  Contract,
  Drivetrain,
  EcuConfig,
  EngineConfig,
  FaultId,
  FuelId,
  GearboxId,
  InductionId,
  LayoutId,
  PartSet,
  PartSlot,
  SuspensionId,
  TireId,
  WeightId,
  WheelStyle,
} from './types'
import { PART_SLOTS } from './types'

// ─── Engine layouts ───────────────────────────────────────────────────────────

export type LayoutSpec = {
  id: LayoutId
  name: string
  cylinders: number
  rotors: number
  banks: 1 | 2
  bankAngle: number
  firingOrder: string
  /** Crank angle of each exhaust pulse over one complete cycle. */
  pulseAngles: number[]
  /** 720° for a four-stroke piston engine, 360° for a rotary. */
  cycleDeg: number
  /** Relative smoothness used by idle quality and sound. */
  smoothness: number
  note: string
}

export const LAYOUTS: Record<LayoutId, LayoutSpec> = {
  i3: {
    id: 'i3', name: 'Inline-3', cylinders: 3, rotors: 0, banks: 1, bankAngle: 0,
    firingOrder: '1-3-2', pulseAngles: [0, 240, 480], cycleDeg: 720, smoothness: 0.72,
    note: 'Light and compact. An off-beat triple with a character all its own.',
  },
  i4: {
    id: 'i4', name: 'Inline-4', cylinders: 4, rotors: 0, banks: 1, bankAngle: 0,
    firingOrder: '1-3-4-2', pulseAngles: [0, 180, 360, 540], cycleDeg: 720, smoothness: 0.86,
    note: 'The default tuner’s engine. Cheap to build, easy to fit, happy to rev.',
  },
  i6: {
    id: 'i6', name: 'Inline-6', cylinders: 6, rotors: 0, banks: 1, bankAngle: 0,
    firingOrder: '1-5-3-6-2-4', pulseAngles: [0, 120, 240, 360, 480, 600], cycleDeg: 720, smoothness: 1,
    note: 'Perfectly balanced. Long, heavy, and capable of huge smooth power.',
  },
  v6: {
    id: 'v6', name: 'V6', cylinders: 6, rotors: 0, banks: 2, bankAngle: 60,
    firingOrder: '1-4-2-5-3-6', pulseAngles: [0, 120, 240, 360, 480, 600], cycleDeg: 720, smoothness: 0.9,
    note: 'Short enough for a transverse bay, with a hard-edged V6 snarl.',
  },
  v8: {
    id: 'v8', name: 'V8 · crossplane', cylinders: 8, rotors: 0, banks: 2, bankAngle: 90,
    firingOrder: '1-8-7-2-6-5-4-3', pulseAngles: [0, 90, 180, 270, 360, 450, 540, 630], cycleDeg: 720, smoothness: 0.82,
    note: 'Crossplane crank. Uneven bank pulses give the classic burble.',
  },
  v10: {
    id: 'v10', name: 'V10', cylinders: 10, rotors: 0, banks: 2, bankAngle: 72,
    firingOrder: '1-10-9-4-3-8-7-2-5-6', pulseAngles: [0, 72, 144, 216, 288, 360, 432, 504, 576, 648], cycleDeg: 720, smoothness: 0.92,
    note: 'A screaming, tightly packed ten. Hard to fit, glorious to hear.',
  },
  v12: {
    id: 'v12', name: 'V12', cylinders: 12, rotors: 0, banks: 2, bankAngle: 60,
    firingOrder: '1-12-5-8-3-10-6-7-2-11-4-9', pulseAngles: [0, 60, 120, 180, 240, 300, 360, 420, 480, 540, 600, 660], cycleDeg: 720, smoothness: 1,
    note: 'The long engine. Twelve cylinders, twelve throttle plates, one seamless pull.',
  },
  flat4: {
    id: 'flat4', name: 'Flat-4', cylinders: 4, rotors: 0, banks: 2, bankAngle: 180,
    firingOrder: '1-3-2-4', pulseAngles: [0, 180, 360, 540], cycleDeg: 720, smoothness: 0.68,
    note: 'Boxer rumble with a low centre of gravity. Unequal headers do the rest.',
  },
  rotary2: {
    id: 'rotary2', name: '2-rotor rotary', cylinders: 2, rotors: 2, banks: 1, bankAngle: 0,
    firingOrder: 'R1-R2', pulseAngles: [0, 180], cycleDeg: 360, smoothness: 0.7,
    note: 'No pistons, no valves. Two rotors, a spinning triangle, and a banshee wail.',
  },
  rotary3: {
    id: 'rotary3', name: '3-rotor rotary', cylinders: 3, rotors: 3, banks: 1, bankAngle: 0,
    firingOrder: 'R1-R2-R3', pulseAngles: [0, 120, 240], cycleDeg: 360, smoothness: 0.82,
    note: 'Three rotors. More displacement, more heat, more top-end scream.',
  },
}

// ─── Fuel ────────────────────────────────────────────────────────────────────

export type FuelSpec = {
  id: FuelId
  name: string
  short: string
  octane: number
  energy: number
  density: number
  stoich: number
  afrTarget: number
  cost: number
  unlockRep: number
  timingBias: number
  cooling: number
  colour: string
  note: string
}

export const FUELS: Record<FuelId, FuelSpec> = {
  p95: {
    id: 'p95', name: '95 RON pump', short: '95', octane: 95, energy: 43.5, density: 0.745, stoich: 14.7,
    afrTarget: 12.8, cost: 0, unlockRep: 0, timingBias: 0, cooling: 0, colour: '#d9a441',
    note: 'Cheap and everywhere. Sensitive to timing and boost.',
  },
  p98: {
    id: 'p98', name: '98 RON pump', short: '98', octane: 98, energy: 43.5, density: 0.755, stoich: 14.7,
    afrTarget: 12.6, cost: 120, unlockRep: 0, timingBias: 1.5, cooling: 0, colour: '#e6bf6a',
    note: 'A little more knock margin. The safe default for a turbo build.',
  },
  e85: {
    id: 'e85', name: 'E85 ethanol', short: 'E85', octane: 105, energy: 29.2, density: 0.785, stoich: 9.8,
    afrTarget: 8.5, cost: 220, unlockRep: 60, timingBias: 6, cooling: 2, colour: '#9ccc65',
    note: 'Charge cooling and huge knock headroom, but it drinks 30% more fuel.',
  },
  race: {
    id: 'race', name: '102 race fuel', short: 'RACE', octane: 102, energy: 43.8, density: 0.780, stoich: 14.6,
    afrTarget: 12.4, cost: 460, unlockRep: 140, timingBias: 3.5, cooling: 0.5, colour: '#87c7ff',
    note: 'Consistent, expensive, and happy with aggressive ignition.',
  },
}

// ─── Induction ───────────────────────────────────────────────────────────────

export type InductionSpec = {
  id: InductionId
  name: string
  short: string
  cost: number
  unlockRep: number
  maxBoost: number
  spoolRpm: number
  efficiency: number
  linear: boolean
  nitrousHp: number
  note: string
}

export const INDUCTIONS: Record<InductionId, InductionSpec> = {
  na: { id: 'na', name: 'Naturally aspirated', short: 'NA', cost: 0, unlockRep: 0, maxBoost: 0, spoolRpm: 0, efficiency: 1, linear: false, nitrousHp: 0, note: 'Linear response and the cleanest throttle.' },
  turboS: { id: 'turboS', name: 'Turbo · small frame', short: 'T-S', cost: 1100, unlockRep: 0, maxBoost: 9, spoolRpm: 2400, efficiency: 0.72, linear: false, nitrousHp: 0, note: 'Quick spool, modest ceiling. Perfect for a hot hatch.' },
  turboM: { id: 'turboM', name: 'Turbo · medium frame', short: 'T-M', cost: 2200, unlockRep: 30, maxBoost: 16, spoolRpm: 3200, efficiency: 0.76, linear: false, nitrousHp: 0, note: 'The all-rounder. Lag is noticeable, the mid-range is worth it.' },
  turboL: { id: 'turboL', name: 'Turbo · large frame', short: 'T-L', cost: 3600, unlockRep: 100, maxBoost: 25, spoolRpm: 4200, efficiency: 0.78, linear: false, nitrousHp: 0, note: 'Nothing, nothing, everything. Needs revs and a strong gasket.' },
  twinTurbo: { id: 'twinTurbo', name: 'Twin turbo', short: 'TT', cost: 5600, unlockRep: 150, maxBoost: 24, spoolRpm: 2600, efficiency: 0.80, linear: false, nitrousHp: 0, note: 'Two small turbos beat one big one everywhere except the bill.' },
  supercharger: { id: 'supercharger', name: 'Positive-displacement supercharger', short: 'SC', cost: 3900, unlockRep: 60, maxBoost: 11, spoolRpm: 0, efficiency: 0.70, linear: true, nitrousHp: 0, note: 'Instant boost from idle. It costs crank horsepower to make horsepower.' },
  nitrous: { id: 'nitrous', name: 'Nitrous oxide', short: 'NOS', cost: 1300, unlockRep: 40, maxBoost: 0, spoolRpm: 0, efficiency: 1, linear: false, nitrousHp: 90, note: 'A bottle-fed shove at wide-open throttle. Use it or lose the bottle.' },
}

// ─── Component catalogue ─────────────────────────────────────────────────────

export type BasePart = { name: string; short: string; cost: number; unlockRep: number; desc: string }

export type HeadPart = BasePart & { flow: number }
export const HEADS: HeadPart[] = [
  { name: 'Stock casting', short: 'STK', cost: 0, unlockRep: 0, flow: 0.94, desc: 'As the factory made it. Small ports, soft seats.' },
  { name: 'Pocket-ported', short: 'P1', cost: 650, unlockRep: 0, flow: 1.02, desc: 'Clean up the bowls and gasket match. Good value.' },
  { name: 'Stage 2 port', short: 'P2', cost: 1450, unlockRep: 30, flow: 1.10, desc: 'Bigger valves and a proper valve job.' },
  { name: 'CNC race head', short: 'CNC', cost: 2800, unlockRep: 120, flow: 1.18, desc: 'Flowed on a bench, not a guess. Needs revs to pay.' },
]

export type CamPart = BasePart & { duration: number; peakOffset: number; overlap: number }
export const CAMS: CamPart[] = [
  { name: 'Stock cam', short: 'STK', cost: 0, unlockRep: 0, duration: 228, peakOffset: 0, overlap: 0, desc: 'Quiet idle, strong vacuum, no surprises.' },
  { name: 'Mild street cam', short: 'M1', cost: 380, unlockRep: 0, duration: 240, peakOffset: 450, overlap: 4, desc: 'A little lope, a little more top end.' },
  { name: 'Sport cam', short: 'S2', cost: 850, unlockRep: 0, duration: 258, peakOffset: 900, overlap: 12, desc: 'The usual first real cam. Idle starts to rock.' },
  { name: 'Race cam', short: 'R3', cost: 1800, unlockRep: 80, duration: 280, peakOffset: 1400, overlap: 22, desc: 'Lumpy, loud, and only happy above 4,000 rpm.' },
  { name: 'Pro race cam', short: 'P4', cost: 3200, unlockRep: 200, duration: 300, peakOffset: 1900, overlap: 34, desc: 'Maximum lift. Street manners are somebody else’s problem.' },
]

export type FlowPart = BasePart & { flow: number }
export const INTAKES: FlowPart[] = [
  { name: 'Stock airbox', short: 'STK', cost: 0, unlockRep: 0, flow: 0.95, desc: 'Quiet, restrictive, and free.' },
  { name: 'Performance intake', short: 'P1', cost: 420, unlockRep: 0, flow: 1.03, desc: 'Less restriction, more induction noise.' },
  { name: 'Race intake', short: 'R2', cost: 980, unlockRep: 60, flow: 1.10, desc: 'Short runners and a large filter. Loud at full load.' },
]

export const EXHAUSTS: FlowPart[] = [
  { name: 'Stock exhaust', short: 'STK', cost: 0, unlockRep: 0, flow: 0.94, desc: 'Quiet. Costs power at the top end.' },
  { name: 'Sport system', short: 'S1', cost: 650, unlockRep: 0, flow: 1.02, desc: '2.5-inch pipe and a better muffler.' },
  { name: 'Race system', short: 'R2', cost: 1400, unlockRep: 40, flow: 1.09, desc: '3-inch, mandrel bends, no drone at cruise.' },
  { name: 'Straight pipe', short: 'S3', cost: 2400, unlockRep: 150, flow: 1.14, desc: 'Maximum flow. Your neighbours will file a report.' },
]

export type InjectorPart = BasePart & { cc: number }
export const INJECTORS: InjectorPart[] = [
  { name: '220 cc/min', short: '220', cost: 0, unlockRep: 0, cc: 220, desc: 'Stock. Runs out of duty quickly.' },
  { name: '440 cc/min', short: '440', cost: 320, unlockRep: 0, cc: 440, desc: 'The first upgrade for any real build.' },
  { name: '750 cc/min', short: '750', cost: 680, unlockRep: 30, cc: 750, desc: 'Enough for a mild turbo four.' },
  { name: '1,000 cc/min', short: '1K', cost: 1100, unlockRep: 90, cc: 1000, desc: 'Big power, clean idle with the right dead time.' },
  { name: '1,300 cc/min', short: '1K3', cost: 1800, unlockRep: 180, cc: 1300, desc: 'Race injectors. Idle quality is a negotiation.' },
]

export type PumpPart = BasePart & { lph: number }
export const PUMPS: PumpPart[] = [
  { name: '190 l/h in-tank', short: '190', cost: 0, unlockRep: 0, lph: 190, desc: 'Fine for a stock engine. Not for boost.' },
  { name: '255 l/h in-tank', short: '255', cost: 280, unlockRep: 0, lph: 255, desc: 'The standard upgrade. Supports most street builds.' },
  { name: '340 l/h in-tank', short: '340', cost: 620, unlockRep: 40, lph: 340, desc: 'More headroom for E85 and bigger turbos.' },
  { name: '450 l/h surge tank', short: '450', cost: 1200, unlockRep: 120, lph: 450, desc: 'A proper fuel system. No pressure drop in a long pull.' },
]

export type InternalsPart = BasePart & { maxRpm: number; strength: number; massFactor: number }
export const INTERNALS: InternalsPart[] = [
  { name: 'Cast pistons, stock rods', short: 'CAST', cost: 0, unlockRep: 0, maxRpm: 6500, strength: 0.85, massFactor: 1, desc: 'Cheap and fine — until it isn’t.' },
  { name: 'Forged rods', short: 'ROD', cost: 950, unlockRep: 0, maxRpm: 7200, strength: 1, massFactor: 1.02, desc: 'The first insurance policy against boost.' },
  { name: 'Forged pistons + rods', short: 'FORG', cost: 2100, unlockRep: 70, maxRpm: 8000, strength: 1.2, massFactor: 1.04, desc: 'Lower compression, stronger ring lands, peace of mind.' },
  { name: 'Billet crank + rods', short: 'BILL', cost: 4200, unlockRep: 180, maxRpm: 9000, strength: 1.45, massFactor: 1.08, desc: 'For the build that lives at the limiter.' },
]

export type ValvePart = BasePart & { rpmAdd: number }
export const VALVES: ValvePart[] = [
  { name: 'Stock valves', short: 'STK', cost: 0, unlockRep: 0, rpmAdd: 0, desc: 'Soft springs. Valve float arrives early.' },
  { name: 'Upgraded springs', short: 'SPR', cost: 480, unlockRep: 0, rpmAdd: 400, desc: 'Stiffer springs and lighter retainers.' },
  { name: 'Sodium-filled race valves', short: 'RACE', cost: 1100, unlockRep: 80, rpmAdd: 800, desc: 'Survives heat and revs. Expensive to replace.' },
]

export type GasketPart = BasePart & { boostLimit: number }
export const GASKETS: GasketPart[] = [
  { name: 'Stock composite gasket', short: 'STK', cost: 0, unlockRep: 0, boostLimit: 10, desc: 'Will lift a head if you get greedy.' },
  { name: 'MLS gasket', short: 'MLS', cost: 320, unlockRep: 0, boostLimit: 18, desc: 'Multi-layer steel. The usual answer to boost.' },
  { name: 'Copper + O-ring', short: 'CU', cost: 780, unlockRep: 90, boostLimit: 28, desc: 'Race sealing. Requires a careful deck.' },
]

export type IntercoolerPart = BasePart & { cooling: number }
export const INTERCOOLERS: IntercoolerPart[] = [
  { name: 'No intercooler', short: '—', cost: 0, unlockRep: 0, cooling: 0, desc: 'Charge temperature climbs with boost.' },
  { name: 'Air-to-air', short: 'A2A', cost: 680, unlockRep: 0, cooling: 0.55, desc: 'Front-mount core. Simple and effective.' },
  { name: 'Air-to-water', short: 'A2W', cost: 1600, unlockRep: 80, cooling: 0.8, desc: 'Short pipes, stable temperatures. More plumbing.' },
]

export const PART_TABLES = {
  head: HEADS,
  cams: CAMS,
  intake: INTAKES,
  exhaust: EXHAUSTS,
  injectors: INJECTORS,
  pump: PUMPS,
  internals: INTERNALS,
  valves: VALVES,
  gasket: GASKETS,
  intercooler: INTERCOOLERS,
} as const

export function partOption(slot: PartSlot, index: number): BasePart {
  const list: readonly BasePart[] = PART_TABLES[slot]
  return list[Math.max(0, Math.min(list.length - 1, index))]
}

export function emptyParts(): PartSet {
  return Object.fromEntries(PART_SLOTS.map(slot => [slot, 0])) as PartSet
}

// ─── Car bodies ──────────────────────────────────────────────────────────────

export const BODIES: BodySpec[] = [
  {
    id: 'kei', name: 'KT-3 Kei', subtitle: 'City hatch', era: '1994',
    length: 3.4, width: 1.48, height: 1.55, wheelbase: 2.45, track: 1.3,
    bay: { length: 620, width: 520, height: 620 }, kerbKg: 760, cd: 0.36, frontalArea: 1.55,
    drivetrain: 'FWD', enginePosition: 'front', grip: 0.82, brakeScore: 0.8,
    cost: 0, unlockRep: 0, ratios: [3.4, 2.1, 1.45, 1.05, 0.82], finalDrive: 4.1, wheelRadius: 0.28,
    defaultPaint: '#c59a52', accent: '#5d4a2a',
  },
  {
    id: 'hotHatch', name: 'HX-2 Hot Hatch', subtitle: 'Three-door tuner', era: '1998',
    length: 4.05, width: 1.75, height: 1.42, wheelbase: 2.6, track: 1.5,
    bay: { length: 700, width: 600, height: 660 }, kerbKg: 1180, cd: 0.32, frontalArea: 2.05,
    drivetrain: 'FWD', enginePosition: 'front', grip: 0.95, brakeScore: 0.9,
    cost: 3900, unlockRep: 0, ratios: [3.3, 2.05, 1.45, 1.1, 0.88, 0.72], finalDrive: 4.3, wheelRadius: 0.32,
    defaultPaint: '#d9d9d4', accent: '#202326',
  },
  {
    id: 'sedan', name: 'S4 Sport Sedan', subtitle: 'Four-door sleeper', era: '2004',
    length: 4.72, width: 1.82, height: 1.43, wheelbase: 2.85, track: 1.57,
    bay: { length: 760, width: 640, height: 700 }, kerbKg: 1580, cd: 0.29, frontalArea: 2.2,
    drivetrain: 'RWD', enginePosition: 'front', grip: 0.99, brakeScore: 1.0,
    cost: 11000, unlockRep: 30, ratios: [3.2, 2.0, 1.42, 1.08, 0.85, 0.7], finalDrive: 3.7, wheelRadius: 0.34,
    defaultPaint: '#25313b', accent: '#9aa6ae',
  },
  {
    id: 'coupe', name: 'C6 Coupé', subtitle: 'Rear-drive grand tourer', era: '2001',
    length: 4.45, width: 1.86, height: 1.32, wheelbase: 2.7, track: 1.6,
    bay: { length: 780, width: 650, height: 680 }, kerbKg: 1420, cd: 0.31, frontalArea: 2.0,
    drivetrain: 'RWD', enginePosition: 'front', grip: 1.02, brakeScore: 1.05,
    cost: 14500, unlockRep: 60, ratios: [3.1, 1.95, 1.38, 1.05, 0.82, 0.67], finalDrive: 3.9, wheelRadius: 0.34,
    defaultPaint: '#6b1f26', accent: '#201314',
  },
  {
    id: 'muscle', name: 'M8 Muscle', subtitle: 'Big-block boulevard', era: '1969',
    length: 4.95, width: 1.94, height: 1.38, wheelbase: 2.95, track: 1.66,
    bay: { length: 860, width: 720, height: 760 }, kerbKg: 1720, cd: 0.34, frontalArea: 2.3,
    drivetrain: 'RWD', enginePosition: 'front', grip: 0.88, brakeScore: 0.7,
    cost: 18000, unlockRep: 90, ratios: [2.9, 1.85, 1.3, 1.0, 0.78, 0.64], finalDrive: 3.55, wheelRadius: 0.35,
    defaultPaint: '#1d2d24', accent: '#c7b06b',
  },
  {
    id: 'supercar', name: 'SC-12 Supercar', subtitle: 'Mid-engine wedge', era: '2018',
    length: 4.55, width: 2.0, height: 1.15, wheelbase: 2.65, track: 1.7,
    bay: { length: 820, width: 760, height: 620 }, kerbKg: 1450, cd: 0.31, frontalArea: 2.0,
    drivetrain: 'RWD', enginePosition: 'mid', grip: 1.22, brakeScore: 1.35,
    cost: 48000, unlockRep: 240, ratios: [3.0, 1.9, 1.42, 1.12, 0.9, 0.76, 0.66], finalDrive: 3.7, wheelRadius: 0.34,
    defaultPaint: '#c9a227', accent: '#121212',
  },
  {
    id: 'pickup', name: 'P4 Pickup', subtitle: 'Workhorse with a secret', era: '2012',
    length: 5.4, width: 1.98, height: 1.85, wheelbase: 3.3, track: 1.68,
    bay: { length: 860, width: 760, height: 780 }, kerbKg: 2100, cd: 0.42, frontalArea: 2.9,
    drivetrain: 'AWD', enginePosition: 'front', grip: 0.92, brakeScore: 0.85,
    cost: 16000, unlockRep: 120, ratios: [3.6, 2.3, 1.65, 1.25, 1.0, 0.82], finalDrive: 3.9, wheelRadius: 0.38,
    defaultPaint: '#3a474d', accent: '#161a1c',
  },
  {
    id: 'van', name: 'V2 Cargo Van', subtitle: 'Rolling workshop', era: '2007',
    length: 5.05, width: 1.98, height: 2.25, wheelbase: 3.0, track: 1.66,
    bay: { length: 780, width: 700, height: 820 }, kerbKg: 1900, cd: 0.40, frontalArea: 3.1,
    drivetrain: 'FWD', enginePosition: 'front', grip: 0.84, brakeScore: 0.75,
    cost: 14000, unlockRep: 140, ratios: [3.5, 2.2, 1.55, 1.18, 0.94, 0.78], finalDrive: 4.0, wheelRadius: 0.34,
    defaultPaint: '#d7d4c7', accent: '#9a3b2d',
  },
  {
    id: 'offroader', name: 'OR-4 Off-Roader', subtitle: 'Boxy trail weapon', era: '1988',
    length: 4.65, width: 1.95, height: 2.0, wheelbase: 2.75, track: 1.64,
    bay: { length: 820, width: 720, height: 780 }, kerbKg: 2000, cd: 0.46, frontalArea: 2.7,
    drivetrain: 'AWD', enginePosition: 'front', grip: 0.9, brakeScore: 0.78,
    cost: 17000, unlockRep: 100, ratios: [3.8, 2.4, 1.7, 1.28, 1.05, 0.86], finalDrive: 4.1, wheelRadius: 0.38,
    defaultPaint: '#5b6b45', accent: '#2c3124',
  },
]

export function bodyById(id: string): BodySpec {
  return BODIES.find(body => body.id === id) ?? BODIES[0]
}

// ─── Chassis upgrades ────────────────────────────────────────────────────────

export const TIRES: Record<TireId, { name: string; short: string; grip: number; cost: number; desc: string }> = {
  street: { name: 'Street compound', short: 'ST', grip: 0.85, cost: 0, desc: 'Cheap, quiet, and easy to overdrive.' },
  sport: { name: 'Sport tyre', short: 'SP', grip: 1.0, cost: 650, desc: 'The first upgrade that makes a car stick.' },
  semi: { name: 'Semi-slick', short: 'SS', grip: 1.18, cost: 1400, desc: 'Track-day grip. Noticeably firmer.' },
  slick: { name: 'Race slick', short: 'SL', grip: 1.32, cost: 2600, desc: 'Maximum dry grip. Don’t go out in the rain.' },
}

export const SUSPENSIONS: Record<SuspensionId, { name: string; handling: number; cost: number; desc: string }> = {
  stock: { name: 'Stock suspension', handling: 1.0, cost: 0, desc: 'Soft, tall, and designed for groceries.' },
  coilover: { name: 'Coilover kit', handling: 1.08, cost: 1200, desc: 'Adjustable height and damping.' },
  race: { name: 'Race suspension', handling: 1.15, cost: 2800, desc: 'Stiff springs, solid mounts, relentless grip.' },
}

export const BRAKES: Record<BrakeId, { name: string; score: number; cost: number; desc: string }> = {
  stock: { name: 'Stock brakes', score: 1.0, cost: 0, desc: 'Fine for one stop. Then they’re hot.' },
  sport: { name: 'Sport brakes', score: 1.1, cost: 900, desc: 'Bigger discs, better pads, more confidence.' },
  race: { name: 'Race brakes', score: 1.18, cost: 2200, desc: 'Six-piston calipers and ducting.' },
}

export const GEARBOXES: Record<GearboxId, { name: string; ratios: number[] | null; shift: number; cost: number; desc: string }> = {
  five: { name: '5-speed manual', ratios: null, shift: 1, cost: 0, desc: 'Light, simple, and slow to shift.' },
  sixClose: { name: '6-speed close ratio', ratios: [3.4, 2.2, 1.62, 1.25, 1.0, 0.82], shift: 1.04, cost: 900, desc: 'Keeps the engine on the cam. Busy on the motorway.' },
  sixTall: { name: '6-speed tall', ratios: [3.2, 1.95, 1.4, 1.08, 0.86, 0.7], shift: 1.02, cost: 1100, desc: 'Long legs for big power and top speed.' },
  dct: { name: '7-speed dual clutch', ratios: [3.3, 2.1, 1.55, 1.2, 0.97, 0.82, 0.68], shift: 1.18, cost: 3200, desc: 'Millisecond shifts, launch control, no excuses.' },
}

export const WEIGHT_REDUCTION: Record<WeightId, { name: string; kg: number; cost: number; desc: string }> = {
  full: { name: 'Full interior', kg: 0, cost: 0, desc: 'Carpets, seats, sound deadening, the lot.' },
  strip: { name: 'Street strip', kg: 40, cost: 600, desc: 'Rear seats out, lightweight battery, less glass.' },
  carbon: { name: 'Carbon / track spec', kg: 90, cost: 2400, desc: 'Composite panels, no interior, one seat.' },
}

export const AERO: Record<AeroId, { name: string; downforce: number; drag: number; cost: number; desc: string }> = {
  none: { name: 'No aero', downforce: 0, drag: 0, cost: 0, desc: 'Slippery and clean.' },
  lip: { name: 'Front lip + skirts', downforce: 0.04, drag: 0.006, cost: 550, desc: 'A little front-end bite.' },
  wing: { name: 'Rear wing', downforce: 0.09, drag: 0.018, cost: 1200, desc: 'More rear grip, more drag.' },
  full: { name: 'Full aero package', downforce: 0.17, drag: 0.042, cost: 3200, desc: 'Splitter, wing and diffuser. Committed.' },
}

export const PAINTS = [
  { name: 'Forge Amber', hex: '#d8922f' },
  { name: 'Gunmetal', hex: '#535b5f' },
  { name: 'Oxblood', hex: '#6b1f26' },
  { name: 'Forest', hex: '#1d2d24' },
  { name: 'Ice White', hex: '#e7e3d8' },
  { name: 'Midnight', hex: '#11161b' },
  { name: 'Acid', hex: '#b7c832' },
  { name: 'Copper', hex: '#9a5a36' },
  { name: 'Primer', hex: '#8c8b83' },
  { name: 'Sand', hex: '#c5aa78' },
  { name: 'Signal Blue', hex: '#1e5c8f' },
  { name: 'Matte Black', hex: '#1b1b1b' },
]

export const WHEEL_STYLES: { id: WheelStyle; name: string }[] = [
  { id: 'steel', name: 'Steel' },
  { id: 'mesh', name: 'Mesh' },
  { id: 'split', name: 'Split 5' },
  { id: 'turbofan', name: 'Turbofan' },
]

export const DRIVETRAIN_LABEL: Record<Drivetrain, string> = {
  FWD: 'Front-wheel drive',
  RWD: 'Rear-wheel drive',
  AWD: 'All-wheel drive',
}

// ─── Faults ──────────────────────────────────────────────────────────────────

export const FAULTS: Record<FaultId, { name: string; short: string; symptom: string; repair: number; effect: string }> = {
  vacLeak: {
    name: 'Unmetered vacuum leak', short: 'VAC',
    symptom: 'Idle hangs, fuel trims climb positive, and the top end runs leaner than the table says.',
    repair: 180,
    effect: 'Adds 12% uncommanded air above 2,500 rpm; commanded fuel goes lean.',
  },
  weakPump: {
    name: 'Weak fuel pump', short: 'PUMP',
    symptom: 'Fuel pressure falls away on a long pull. Duty looks sane until the engine leans out up top.',
    repair: 360,
    effect: 'Fuel supply collapses above 75% demand, forcing a lean condition.',
  },
  stuckWastegate: {
    name: 'Stuck wastegate', short: 'BOOST',
    symptom: 'Boost runs past the target and keeps climbing. The ECU cannot cut what the gate will not release.',
    repair: 450,
    effect: 'Actual boost exceeds the target by up to 45%, triggering overboost.',
  },
  burntValve: {
    name: 'Burnt exhaust valve', short: 'VALVE',
    symptom: 'One cylinder is down on compression. Rough idle, uneven EGT, and a distinct miss.',
    repair: 900,
    effect: 'Cuts 18% of airflow and adds a misfire above 4,500 rpm.',
  },
}

// ─── Contracts ───────────────────────────────────────────────────────────────

function engine(
  layout: LayoutId,
  bore: number,
  stroke: number,
  compression: number,
  induction: InductionId,
  fuel: FuelId,
  parts: Partial<PartSet>,
  name: string,
  faults: FaultId[] = [],
): EngineConfig {
  return {
    layout, bore, stroke, compression, induction, fuel, name, faults,
    parts: { ...emptyParts(), ...parts },
  }
}

export const CONTRACT_TEMPLATES: Contract[] = [
  {
    id: 'hatch-heart', code: 'C-014', title: 'Hatchback Heartbeat',
    customer: 'Mara Quinn', brief: 'A tidy 2.0 hatch that falls on its face above 5,000 rpm. Fix the fuel supply, make it pull cleanly to the limiter, then prove 130 hp on the dyno.',
    bodyId: 'hotHatch',
    engine: engine('i4', 86, 86, 10.5, 'na', 'p98', { head: 1, cams: 1, intake: 1, exhaust: 1, injectors: 1 }, 'Customer 2.0 I4', ['weakPump']),
    faults: ['weakPump'], target: { kind: 'power', value: 130 }, budget: 900, payout: 1800, rep: 25, minRep: 0,
  },
  {
    id: 'kei-cup', code: 'C-021', title: 'Kei Cup Ringer',
    customer: 'Hiro Sato', brief: 'A 660 cc triple for the shop’s little track toy. The boost gauge goes past the mark and the engine cuts. Target is 60 hp — reliably.',
    bodyId: 'kei',
    engine: engine('i3', 61, 75, 9.0, 'turboS', 'p98', { head: 1, cams: 1, injectors: 1, pump: 1, gasket: 1, intercooler: 1, internals: 1 }, 'Customer 660 turbo', ['stuckWastegate']),
    faults: ['stuckWastegate'], target: { kind: 'power', value: 60 }, budget: 700, payout: 1400, rep: 15, minRep: 10,
  },
  {
    id: 'turbo-taxi', code: 'C-037', title: 'Turbo Taxi',
    customer: 'Dee Walsh', brief: 'A 2.0 turbo sedan with a lean top end and a lazy idle. Find the leak, sort the fuel, and hand back 230 hp with headroom.',
    bodyId: 'sedan',
    engine: engine('i4', 86, 86, 9.0, 'turboM', 'p98', { head: 1, cams: 1, intake: 1, exhaust: 1, injectors: 2, pump: 1, internals: 1, valves: 1, gasket: 1, intercooler: 1 }, 'Customer 2.0 turbo', ['vacLeak']),
    faults: ['vacLeak'], target: { kind: 'power', value: 230 }, budget: 1400, payout: 2800, rep: 40, minRep: 30,
  },
  {
    id: 'van-man', code: 'C-049', title: 'Van Man',
    customer: 'Big Tom', brief: 'The shop van needs to tow and still surprise people. 3.0 turbo six, 290 hp, no fuel pressure drop at the top of a pull.',
    bodyId: 'van',
    engine: engine('i6', 84, 90, 9.2, 'turboS', 'p98', { head: 1, cams: 1, intake: 1, exhaust: 1, injectors: 2, pump: 1, internals: 1, valves: 1, gasket: 1, intercooler: 1 }, 'Customer 3.0 turbo six', ['weakPump']),
    faults: ['weakPump'], target: { kind: 'power', value: 290 }, budget: 1500, payout: 3400, rep: 55, minRep: 60,
  },
  {
    id: 'overboost', code: 'C-063', title: 'The Overboost',
    customer: 'Lena Voss', brief: 'A 2.8 straight six that makes boost it was never meant to make. Fix the gate, keep the 380 hp, and don’t let it lift a head.',
    bodyId: 'coupe',
    engine: engine('i6', 86, 80, 8.8, 'turboM', 'p98', { head: 2, cams: 2, intake: 1, exhaust: 2, injectors: 3, pump: 2, internals: 2, valves: 1, gasket: 2, intercooler: 2 }, 'Customer 2.8 turbo six', ['stuckWastegate']),
    faults: ['stuckWastegate'], target: { kind: 'power', value: 380 }, budget: 1800, payout: 3800, rep: 70, minRep: 70,
  },
  {
    id: 'muscle-rescue', code: 'C-078', title: 'Muscle Rescue',
    customer: 'Cal Booker', brief: 'A 6.2 V8 with a dead hole and a bad attitude. Fix the valve, tune it for pump fuel, and get it over 470 hp without a knock.',
    bodyId: 'muscle',
    engine: engine('v8', 103.25, 92, 10.8, 'na', 'p98', { head: 1, cams: 2, intake: 1, exhaust: 2, injectors: 2, pump: 1, internals: 1, valves: 1 }, 'Customer 6.2 V8', ['burntValve']),
    faults: ['burntValve'], target: { kind: 'power', value: 470 }, budget: 2600, payout: 5200, rep: 90, minRep: 90,
  },
  {
    id: 'supercar-clinic', code: 'C-101', title: 'Supercar Clinic',
    customer: 'A. Byrne', brief: 'A 4.0 twin-turbo V8, low mileage, someone else’s map. Two faults, one very large bill. Deliver 800 hp with the engine alive.',
    bodyId: 'supercar',
    engine: engine('v8', 88, 82, 9.0, 'twinTurbo', 'race', { head: 3, cams: 3, intake: 2, exhaust: 3, injectors: 4, pump: 3, internals: 3, valves: 2, gasket: 2, intercooler: 2 }, 'Customer 4.0 twin-turbo V8', ['vacLeak', 'weakPump']),
    faults: ['vacLeak', 'weakPump'], target: { kind: 'power', value: 800 }, budget: 6000, payout: 12000, rep: 190, minRep: 220,
  },
]

export const REP_TIERS = [
  { name: 'Rookie', at: 0 },
  { name: 'Apprentice', at: 50 },
  { name: 'Journeyman', at: 140 },
  { name: 'Master', at: 300 },
  { name: 'Legend', at: 550 },
]

export function repTier(rep: number): { name: string; at: number; next: number | null } {
  let current = REP_TIERS[0]
  for (const tier of REP_TIERS) if (rep >= tier.at) current = tier
  const next = REP_TIERS.find(tier => tier.at > rep)?.at ?? null
  return { name: current.name, at: current.at, next }
}

// ─── Defaults ────────────────────────────────────────────────────────────────

export const DEFAULT_FUEL_TARGET: Record<FuelId, number> = {
  p95: FUELS.p95.afrTarget,
  p98: FUELS.p98.afrTarget,
  e85: FUELS.e85.afrTarget,
  race: FUELS.race.afrTarget,
}

export const EMPTY_ECU: EcuConfig = {
  fuel: [],
  ignition: [],
  afr: 12.6,
  boostTarget: 0,
  revLimit: 6800,
  launchRpm: 3200,
}

export function isRotary(config: EngineConfig): boolean {
  return LAYOUTS[config.layout].rotors > 0
}
