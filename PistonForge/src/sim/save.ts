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
/** Last save that loaded cleanly. Used when the main save is missing or unreadable. */
export const BACKUP_KEY = `${SAVE_KEY}.bak`
/** A save written by a newer build than this one is parked here, never overwritten. */
export const NEWER_KEY = `${SAVE_KEY}.newer`
/** Schema version this build reads and writes. Bump it together with a MIGRATIONS entry. */
export const SAVE_VERSION = 1

type RawSave = Record<string, unknown>

/**
 * Upgrade steps, keyed by the version they upgrade FROM. `MIGRATIONS[1]` turns a version-1
 * save into version 2, and so on. Each step is a pure function. Empty while there is only
 * one schema version; the chain and its tests are in place so the first format change after
 * launch cannot strand players' saves.
 */
export const MIGRATIONS: Record<number, (data: RawSave) => RawSave> = {}

export type DecodedSave =
  | { status: 'ok'; data: RawSave }
  /** Nothing stored. */
  | { status: 'empty' }
  /** Stored text is not a save this game can read. */
  | { status: 'corrupt' }
  /** Written by a newer build; this build must not guess at it. */
  | { status: 'newer'; version: number }

/** Parse stored text and bring it up to the current schema version. Never throws. */
export function decodeSave(raw: string | null, migrations: Record<number, (data: RawSave) => RawSave> = MIGRATIONS, target = SAVE_VERSION): DecodedSave {
  if (raw === null || raw === '') return { status: 'empty' }
  let data: RawSave
  try {
    const parsed: unknown = JSON.parse(raw)
    if (!parsed || typeof parsed !== 'object' || Array.isArray(parsed)) return { status: 'corrupt' }
    data = parsed as RawSave
  } catch {
    return { status: 'corrupt' }
  }
  let version = data.version
  if (typeof version !== 'number' || !Number.isInteger(version) || version < 1) return { status: 'corrupt' }
  if (version > target) return { status: 'newer', version }
  while (version < target) {
    const step = migrations[version]
    if (!step) return { status: 'corrupt' }
    try {
      data = step(structuredClone(data))
    } catch {
      return { status: 'corrupt' }
    }
    version += 1
    data.version = version
  }
  return { status: 'ok', data }
}
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
  const decoded = decodeSave(raw)
  if (decoded.status !== 'ok') return base
  const data = decoded.data

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
    haptics: settingsRaw.haptics !== false,
    tips: settingsRaw.tips !== false,
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

/** How the save was found when the game started. */
export type LoadStatus =
  /** No save anywhere: a first launch. */
  | 'fresh'
  /** The main save loaded normally. */
  | 'loaded'
  /** The main save was missing or unreadable and the backup was used. */
  | 'recovered'
  /** The main save was unreadable and there was no usable backup; progress started over. */
  | 'lost'
  /** The main save came from a newer build. It was set aside untouched and a new game started. */
  | 'newer'

export class GameStore {
  data: GameState
  readonly loadStatus: LoadStatus

  constructor(private readonly storage: Pick<Storage, 'getItem' | 'setItem' | 'removeItem'> | undefined = safeStorage()) {
    const raw = this.read(SAVE_KEY)
    const main = decodeSave(raw)
    if (main.status === 'ok') {
      // Keep the last save that is known to load, so one bad write cannot cost the career.
      if (this.read(BACKUP_KEY) !== raw) this.write(BACKUP_KEY, raw as string)
      this.data = parseState(raw)
      this.loadStatus = 'loaded'
      return
    }
    if (main.status === 'newer') {
      this.write(NEWER_KEY, raw as string)
      this.data = parseState(null)
      this.loadStatus = 'newer'
      return
    }
    const backupRaw = this.read(BACKUP_KEY)
    if (decodeSave(backupRaw).status === 'ok') {
      this.data = parseState(backupRaw)
      this.write(SAVE_KEY, backupRaw as string)
      this.loadStatus = 'recovered'
      return
    }
    this.data = parseState(null)
    this.loadStatus = main.status === 'empty' ? 'fresh' : 'lost'
  }

  private read(key: string): string | null {
    try {
      return this.storage?.getItem(key) ?? null
    } catch {
      return null
    }
  }

  private write(key: string, value: string): void {
    try {
      this.storage?.setItem(key, value)
    } catch {
      // Private browsing or quota: the session keeps working in memory.
    }
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
      this.storage?.removeItem(BACKUP_KEY)
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