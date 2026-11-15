/**
 * Shared, serializable simulation types. Nothing here imports Three.js or the DOM: the
 * workshop UI and 3D scene are both readers of these values.
 */

export const PART_SLOTS = [
  'head',
  'cams',
  'intake',
  'exhaust',
  'injectors',
  'pump',
  'internals',
  'valves',
  'gasket',
  'intercooler',
] as const
export type PartSlot = (typeof PART_SLOTS)[number]
export type PartSet = Record<PartSlot, number>

export type LayoutId =
  | 'i3'
  | 'i4'
  | 'i6'
  | 'v6'
  | 'v8'
  | 'v10'
  | 'v12'
  | 'flat4'
  | 'rotary2'
  | 'rotary3'

export type InductionId = 'na' | 'turboS' | 'turboM' | 'turboL' | 'twinTurbo' | 'supercharger' | 'nitrous'
export type FuelId = 'p95' | 'p98' | 'e85' | 'race'
export type FaultId = 'vacLeak' | 'weakPump' | 'stuckWastegate' | 'burntValve'
export type FailureId = 'knock' | 'lean' | 'overboost' | 'overrev' | 'heat'

export type EngineConfig = {
  layout: LayoutId
  /** Cylinder bore (or rotor width) in millimetres. */
  bore: number
  /** Piston stroke (or rotor radius reference) in millimetres. */
  stroke: number
  /** Static compression ratio. */
  compression: number
  parts: PartSet
  induction: InductionId
  fuel: FuelId
  /** Player-facing build name, shown on the engine plate. */
  name: string
  /** Injected faults only present on customer cars. */
  faults?: FaultId[]
}

export type EngineSpec = {
  layoutName: string
  cylinders: number
  rotors: number
  displacementCc: number
  displacementL: number
  boreStrokeRatio: number
  staticCompression: number
  mechanicalRedline: number
  envelopeMm: { length: number; width: number; height: number }
  massKg: number
  partsCost: number
  peakVe: number
  camPeakRpm: number
  inductionName: string
  fuelName: string
  warnings: string[]
}

export type EcuConfig = {
  /** Fuel table, rows = load bins, columns = RPM bins. Values are commanded VE %. */
  fuel: number[][]
  /** Ignition advance in crank degrees, same grid shape. */
  ignition: number[][]
  /** Target air/fuel ratio at wide-open throttle. */
  afr: number
  /** Wastegate/boost target in psi. Ignored for naturally aspirated builds. */
  boostTarget: number
  /** ECU rev limiter in RPM. */
  revLimit: number
  /** Launch-control hold RPM. */
  launchRpm: number
}

export type PaintFinish = 'gloss' | 'satin' | 'matte' | 'metallic'
export type WheelStyle = 'steel' | 'mesh' | 'split' | 'turbofan'
export type AeroId = 'none' | 'lip' | 'wing' | 'full'
export type InteriorId = 'full' | 'stripped'
export type TireId = 'street' | 'sport' | 'semi' | 'slick'
export type SuspensionId = 'stock' | 'coilover' | 'race'
export type BrakeId = 'stock' | 'sport' | 'race'
export type GearboxId = 'five' | 'sixClose' | 'sixTall' | 'dct'
export type WeightId = 'full' | 'strip' | 'carbon'

export type ChassisConfig = {
  tires: TireId
  suspension: SuspensionId
  brakes: BrakeId
  gearbox: GearboxId
  weight: WeightId
}

export type Drivetrain = 'FWD' | 'RWD' | 'AWD'

export type BodySpec = {
  id: string
  name: string
  subtitle: string
  era: string
  length: number
  width: number
  height: number
  wheelbase: number
  track: number
  bay: { length: number; width: number; height: number }
  kerbKg: number
  cd: number
  frontalArea: number
  drivetrain: Drivetrain
  /** Engine location used by the 3D model and fitment display. */
  enginePosition: 'front' | 'mid'
  grip: number
  brakeScore: number
  cost: number
  unlockRep: number
  ratios: number[]
  finalDrive: number
  wheelRadius: number
  defaultPaint: string
  accent: string
}

export type Build = {
  id: string
  name: string
  bodyId: string
  engine: EngineConfig
  ecu: EcuConfig
  paint: { color: string; finish: PaintFinish }
  wheels: { style: WheelStyle; size: number }
  /** -1 (raised) .. +1 (slammed). */
  stance: number
  aero: AeroId
  interior: InteriorId
  chassis: ChassisConfig
  /** 0–100. Wears with pulls and races; repaired in the shop. */
  condition: number
  dyno?: DynoResult
  drag?: DragResult
  handling?: HandlingResult
}

export type DynoPoint = {
  rpm: number
  hp: number
  torque: number
  boost: number
  afr: number
  timing: number
  knock: number
  egt: number
  ve: number
  duty: number
  pumpMargin: number
}

export type DynoResult = {
  points: DynoPoint[]
  peakHp: number
  peakHpRpm: number
  peakTorque: number
  peakTorqueRpm: number
  redline: number
  boostPeak: number
  afrMin: number
  afrMax: number
  knockPeak: number
  egtPeak: number
  conditionBefore: number
  conditionAfter: number
  failure: FailureId | null
  valid: boolean
  at: number
}

export type DragResult = {
  sixtyFt: number
  zeroTo100: number | null
  et: number | null
  trapKmh: number | null
  trapMph: number | null
  topSpeed: number
  wheelspin: number
  shifts: number
  valid: boolean
  at: number
}

export type HandlingResult = {
  lap: number
  lateralG: number
  balance: 'Understeer' | 'Neutral' | 'Oversteer'
  speedTrap: number
  at: number
}

export type ContractTarget =
  | { kind: 'power'; value: number }
  | { kind: 'et'; value: number }
  | { kind: 'lap'; value: number }
  | { kind: 'torque'; value: number }

export type Contract = {
  id: string
  code: string
  title: string
  customer: string
  brief: string
  bodyId: string
  engine: EngineConfig
  faults: FaultId[]
  target: ContractTarget
  /** Parts/repair budget, not paid to the player. */
  budget: number
  payout: number
  rep: number
  minRep: number
}

export type JobState = {
  contract: Contract
  build: Build
  diagnosed: boolean
  spent: number
}

export type Settings = {
  musicVolume: number
  engineVolume: number
  sfxVolume: number
  quality: 'low' | 'medium' | 'high'
  reducedMotion: boolean
  autoShift: boolean
}

export type Bests = {
  hp: number
  torque: number
  et: number
  trap: number
  lap: number
}

export type Mode = 'career' | 'sandbox'

export type GameState = {
  version: 1
  mode: Mode
  cash: number
  rep: number
  ownedBodies: string[]
  careerBuilds: Build[]
  careerActiveId: string
  sandboxBuild: Build
  job: JobState | null
  contracts: Contract[]
  completedContracts: string[]
  settings: Settings
  bests: Bests
  completedJobs: number
  pulls: number
  introSeen: boolean
}

/** Live drag-run state, owned by the app and advanced by the fixed step. */
export type DragPhase = 'idle' | 'staging' | 'tree' | 'running' | 'finished'
export type DragRun = {
  phase: DragPhase
  treeTime: number
  elapsed: number
  distance: number
  speed: number
  rpm: number
  gear: number
  wheelspin: number
  shiftCount: number
  sixtyFt: number | null
  zeroTo100: number | null
  et: number | null
  trapKmh: number | null
  limiterTime: number
  reaction: number | null
  result: DragResult | null
}

export type DynoPhase = 'idle' | 'revving' | 'pulling' | 'done'
export type DynoRun = {
  phase: DynoPhase
  points: DynoPoint[]
  cursor: number
  rpm: number
  throttle: number
  time: number
  result: DynoResult | null
}

export type HandlingPhase = 'idle' | 'running' | 'done'
export type HandlingRun = {
  phase: HandlingPhase
  time: number
  progress: number
  speed: number
  lateralG: number
  result: HandlingResult | null
}

export type FitmentResult = {
  fits: boolean
  bay: { length: number; width: number; height: number }
  engine: { length: number; width: number; height: number }
  blocker: 'length' | 'width' | 'height' | null
  overByMm: number
}