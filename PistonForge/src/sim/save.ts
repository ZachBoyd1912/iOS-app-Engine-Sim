import {
  AERO,
  BODIES,
  BRAKES,
  CONTRACT_TEMPLATES,
  FUELS,
  GEARBOXES,
  INDUCTIONS,
  SUSPENSIONS,
  TIRES,
  WEIGHT_REDUCTION,
  bodyById,
} from './data'
import { defaultState } from './career'
import { makeBuild, sandboxStartingBuild, startingBuild } from './builds'
import { sanitizeEngine } from './engine'
import { sanitizeEcu } from './ecu'
import type {
  Build,
  Contract,
  DynoResult,
  DragResult,
  GameState,
  HandlingResult,
  JobState,
  PaintFinish,
  WheelStyle,
} from './types'

export const SAVE_KEY = 'pistonforge.save.v1'
const clamp = (v: number, min: number, max: number) => Math.min(max, Math.max(min, v))
const num = (v: unknown, fallback: number): number => (typeof v === 'number' && Number.isFinite(v) ? v : fallback)

function sanitizeBuild(raw: unknown, fallback: Build): Build {
  if (!raw || typeof raw !== 'object') return structuredClone(fallback)
  const r = raw as Partial<Build>
  const body = BODIES.some(b => b.id === r.bodyId) ? String(r.bodyId) : fallback.bodyId
  const engine = sanitizeEngine({ ...fallback.engine, ...(r.engine ?? {}) })
  const finish = ['gloss', 'satin', 'matte', 'metallic'].includes(String(r.paint?.finish)) ? (r.paint?.finish as PaintFinish) : fallback.paint.finish
  const colour = typeof r.paint?.color === 'string' && /^#[0-9a-f]{6}$/i.test(r.paint.color) ? r.paint.color : fallback.paint.color
  const wheelStyle = ['steel', 'mesh', 'split', 'turbofan'].includes(String(r.wheels?.style)) ? (r.wheels?.style as WheelStyle) : fallback.wheels.style
  return {
    id: typeof r.id === 'string' ? r.id : fallback.id,
    name: typeof r.name === 'string' ? r.name.slice(0, 36) : fallback.name,
    bodyId: body,
    engine,
    ecu: sanitizeEcu(r.ecu, engine),
    paint: { color: colour, finish },
    wheels: { style: wheelStyle, size: clamp(num(r.wheels?.size, fallback.wheels.size), 14, 22) },
    stance: clamp(num(r.stance, 0), -1, 1),
    aero: Object.keys(AERO).includes(String(r.aero)) ? r.aero as Build['aero'] : fallback.aero,
    interior: r.interior === 'stripped' ? 'stripped' : 'full',
    chassis: {
      tires: Object.keys(TIRES).includes(String(r.chassis?.tires)) ? r.chassis!.tires! : fallback.chassis.tires,
      suspension: Object.keys(SUSPENSIONS).includes(String(r.chassis?.suspension)) ? r.chassis!.suspension! : fallback.chassis.suspension,
      brakes: Object.keys(BRAKES).includes(String(r.chassis?.brakes)) ? r.chassis!.brakes! : fallback.chassis.brakes,
      gearbox: Object.keys(GEARBOXES).includes(String(r.chassis?.gearbox)) ? r.chassis!.gearbox! : fallback.chassis.gearbox,
      weight: Object.keys(WEIGHT_REDUCTION).includes(String(r.chassis?.weight)) ? r.chassis!.weight! : fallback.chassis.weight,
    },
    condition: clamp(num(r.condition, fallback.condition), 0, 100),
    ...(validDyno(r.dyno) ? { dyno: r.dyno } : {}),
    ...(validDrag(r.drag) ? { drag: r.drag } : {}),
    ...(validHandling(r.handling) ? { handling: r.handling } : {}),
  }
}

function validDyno(value: unknown): value is DynoResult {
  const v = value as DynoResult
  return !!v && typeof v === 'object' && Array.isArray(v.points) && Number.isFinite(v.peakHp) && Number.isFinite(v.peakTorque)
}

function validDrag(value: unknown): value is DragResult {
  const v = value as DragResult
  return !!v && typeof v === 'object' && Number.isFinite(v.topSpeed) && typeof v.valid === 'boolean'
}

function validHandling(value: unknown): value is HandlingResult {
  const v = value as HandlingResult
  return !!v && typeof v === 'object' && Number.isFinite(v.lap) && Number.isFinite(v.lateralG)
}

function sanitizeContract(raw: unknown): Contract | null {
  if (!raw || typeof raw !== 'object') return null
  const template = CONTRACT_TEMPLATES.find(c => c.id === (raw as Contract).id)
  if (!template) return null
  return structuredClone(template)
}

function sanitizeJob(raw: unknown): JobState | null {
  if (!raw || typeof raw !== 'object') return null
  const job = raw as JobState
  const contract = sanitizeContract(job.contract)
  if (!contract) return null
  const fallback = makeBuild(contract.bodyId, contract.engine, contract.title)
  return {
    contract,
    build: sanitizeBuild(job.build, fallback),
    diagnosed: job.diagnosed === true,
    spent: clamp(num(job.spent, 0), 0, contract.budget),
  }
}

export function parseState(raw: string | null): GameState {
  const base = defaultState()
  if (!raw) return base
  let data: Record<string, unknown>
  try {
    const parsed = JSON.parse(raw)
    if (!parsed || typeof parsed !== 'object' || Array.isArray(parsed)) return base
    data = parsed as Record<string, unknown>
  } catch {
    return base
  }
  if (data.version !== 1) return base

  const careerFallback = startingBuild()
  const builds = Array.isArray(data.careerBuilds)
    ? data.careerBuilds.slice(0, 12).map(build => sanitizeBuild(build, careerFallback))
    : [sanitizeBuild(undefined, careerFallback)]
  if (builds.length === 0) builds.push(sanitizeBuild(undefined, careerFallback))
  const activeId = builds.some(b => b.id === data.careerActiveId) ? String(data.careerActiveId) : builds[0].id
  const sandbox = sanitizeBuild(data.sandboxBuild, sandboxStartingBuild())
  const contracts = Array.isArray(data.contracts)
    ? data.contracts.map(sanitizeContract).filter((c): c is Contract => Boolean(c))
    : structuredClone(CONTRACT_TEMPLATES)
  const completed = Array.isArray(data.completedContracts)
    ? data.completedContracts.filter((id): id is string => typeof id === 'string')
    : []
  const owned = Array.isArray(data.ownedBodies)
    ? [...new Set(data.ownedBodies.filter((id): id is string => BODIES.some(b => b.id === id)))]
    : ['kei']
  if (!owned.includes('kei')) owned.push('kei')

  const settingsRaw = (data.settings ?? {}) as GameState['settings']
  const bestsRaw = (data.bests ?? {}) as GameState['bests']
  const settings: GameState['settings'] = {
    musicVolume: clamp(num(settingsRaw.musicVolume, base.settings.musicVolume), 0, 1),
    engineVolume: clamp(num(settingsRaw.engineVolume, base.settings.engineVolume), 0, 1),
    sfxVolume: clamp(num(settingsRaw.sfxVolume, base.settings.sfxVolume), 0, 1),
    quality: ['low', 'medium', 'high'].includes(String(settingsRaw.quality)) ? settingsRaw.quality : base.settings.quality,
    reducedMotion: settingsRaw.reducedMotion === true,
    autoShift: settingsRaw.autoShift !== false,
  }
  const job = sanitizeJob(data.job)

  return {
    version: 1,
    mode: data.mode === 'sandbox' ? 'sandbox' : 'career',
    cash: Math.max(0, Math.round(num(data.cash, base.cash))),
    rep: Math.max(0, Math.round(num(data.rep, base.rep))),
    ownedBodies: owned,
    careerBuilds: builds,
    careerActiveId: activeId,
    sandboxBuild: sandbox,
    job,
    contracts,
    completedContracts: completed,
    settings,
    bests: {
      hp: Math.max(0, num(bestsRaw.hp, 0)),
      torque: Math.max(0, num(bestsRaw.torque, 0)),
      et: Math.max(0, num(bestsRaw.et, 0)),
      trap: Math.max(0, num(bestsRaw.trap, 0)),
      lap: Math.max(0, num(bestsRaw.lap, 0)),
    },
    completedJobs: Math.max(0, Math.round(num(data.completedJobs, 0))),
    pulls: Math.max(0, Math.round(num(data.pulls, 0))),
    introSeen: data.introSeen === true,
  }
}

export class GameStore {
  data: GameState

  constructor(private readonly storage: Pick<Storage, 'getItem' | 'setItem' | 'removeItem'> | undefined = safeStorage()) {
    let raw: string | null = null
    try {
      raw = this.storage?.getItem(SAVE_KEY) ?? null
    } catch {
      raw = null
    }
    this.data = parseState(raw)
  }

  save(state: GameState): void {
    this.data = state
    try {
      this.storage?.setItem(SAVE_KEY, JSON.stringify(state))
    } catch {
      // Private browsing or quota: the session keeps working in memory.
    }
  }

  reset(): GameState {
    try {
      this.storage?.removeItem(SAVE_KEY)
    } catch {
      // ignore; an in-memory reset is still useful
    }
    this.data = defaultState()
    this.save(this.data)
    return this.data
  }
}

function safeStorage(): Pick<Storage, 'getItem' | 'setItem' | 'removeItem'> | undefined {
  try {
    return globalThis.localStorage
  } catch {
    return undefined
  }
}

export function validateBuildForSave(build: Build): Build {
  return sanitizeBuild(build, build)
}

export function isKnownBody(id: string): boolean {
  return BODIES.some(body => body.id === id)
}

export function isKnownFuel(id: string): boolean {
  return Object.keys(FUELS).includes(id)
}

export function isKnownInduction(id: string): boolean {
  return Object.keys(INDUCTIONS).includes(id)
}

export function bodyLabel(id: string): string {
  return bodyById(id).name
}