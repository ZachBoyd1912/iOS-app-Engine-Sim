import { SoundEngine } from './audio/sound'
import { HapticEngine } from './platform/haptics'
import { GameLoop } from './engine/loop'
import { Stage, type Quality } from './game/stage'
import { AERO, BODIES, BRAKES, FUELS, GEARBOXES, INDUCTIONS, SUSPENSIONS, TIRES, WEIGHT_REDUCTION, bodyById, partOption } from './sim/data'
import {
  acceptContract,
  abandonJob,
  contractResult,
  deliverJob,
  diagnoseJob,
  activeBuild as getActiveBuild,
  purchaseBody,
  recordBests,
  repairFault,
} from './sim/career'
import {
  engineCost,
  enginePresets,
  fitment,
  sanitizeEngine,
  upgradeCost,
} from './sim/engine'
import {
  autoBase,
  advanceTiming,
  defaultEcu,
  fixFuel,
  sanitizeEcu,
  setCell,
  smoothTable,
  targetBoostDefault,
} from './sim/ecu'
import { dynoPull, estimatePeak, pullGrade, torqueCurve } from './sim/performance'
import { GameStore } from './sim/save'
import { repairCost, rebuildCost } from './sim/builds'
import {
  createDragSim,
  dragResultFromSim,
  handlingResult,
  simulateDrag,
  stepDragSim,
  vehicleStats,
  type DragSim,
} from './sim/vehicle'
import type {
  AeroId,
  Build,
  ChassisConfig,
  DragRun,
  DragResult,
  DynoPoint,
  DynoResult,
  DynoRun,
  EngineConfig,
  FaultId,
  FuelId,
  GameState,
  HandlingResult,
  HandlingRun,
  InductionId,
  InteriorId,
  LayoutId,
  Mode,
  PaintFinish,
  PartSlot,
  Settings,
  WheelStyle,
} from './sim/types'
import { PART_SLOTS } from './sim/types'
import type { UI } from './ui/ui'
import type { ResultModal } from './ui/types'

export type Screen = 'title' | 'garage' | 'engine' | 'ecu' | 'dyno' | 'test' | 'shop' | 'jobs' | 'settings'
export type TestTab = 'drag' | 'handling'
export type Peak = { hp: number; hpRpm: number; torque: number; torqueRpm: number }

const clamp = (v: number, min: number, max: number) => Math.min(max, Math.max(min, v))

const idleDyno = (): DynoRun => ({ phase: 'idle', points: [], cursor: 0, rpm: 900, throttle: 0, time: 0, result: null })
const idleDrag = (): DragRun => ({
  phase: 'idle', treeTime: 0, elapsed: 0, distance: 0, speed: 0, rpm: 900, gear: 0,
  wheelspin: 0, shiftCount: 0, sixtyFt: null, zeroTo100: null, et: null, trapKmh: null,
  limiterTime: 0, reaction: null, result: null,
})
const idleHandling = (): HandlingRun => ({ phase: 'idle', time: 0, progress: 0, speed: 0, lateralG: 0, result: null })

export class App {
  readonly store: GameStore
  readonly stage: Stage
  readonly sound: SoundEngine
  readonly haptics: HapticEngine
  readonly loop: GameLoop
  state: GameState
  screen: Screen = 'title'
  testTab: TestTab = 'drag'
  engineDraft: EngineConfig | null = null
  draftBase: EngineConfig | null = null
  private stageKey = ''
  private ui: UI | null = null
  private dyno: DynoRun = idleDyno()
  private drag: DragRun = idleDrag()
  private handling: HandlingRun = idleHandling()
  private dragSim: DragSim | null = null
  private dragCurve: DynoPoint[] = []
  private shiftQueued = false
  private handlingDuration = 8
  private liveRpm = 900
  private liveLoad = 0
  private liveBoost = 0
  private freeRevThrottle = 0
  private cutaway = true
  private soundStarted = false
  private soundEngineKey = ''
  private draftTimer: number | null = null
  private peakCache = new Map<string, Peak>()
  private curveCache = new Map<string, DynoPoint[]>()
  private dragCache = new Map<string, ReturnType<typeof simulateDrag>>()
  private handlingCache = new Map<string, HandlingResult>()
  private firstFrame = true
  private simClock = 0

  constructor(store: GameStore, stage: Stage, sound: SoundEngine, haptics: HapticEngine = new HapticEngine(null)) {
    this.store = store
    this.stage = stage
    this.sound = sound
    this.haptics = haptics
    this.state = store.data
    this.applySettings()
    this.stage.setView('title')
    this.stage.setEngineCutaway(true)
    this.syncStage(true)
    this.loop = new GameLoop({
      step: dt => this.step(dt),
      render: (_alpha, frameSeconds) => this.render(frameSeconds),
    })
  }

  attachUI(ui: UI): void {
    this.ui = ui
    ui.render()
  }

  start(): void {
    this.loop.start()
  }

  dispose(): void {
    this.loop.stop()
    if (this.draftTimer !== null) window.clearTimeout(this.draftTimer)
    this.sound.stopEngine(0.2)
    this.stage.dispose()
  }

  // ─── read model ───────────────────────────────────────────────────────────

  activeBuild(): Build {
    return getActiveBuild(this.state)
  }

  activeJob(): GameState['job'] {
    return this.state.job
  }

  dynoRun(): DynoRun {
    return this.dyno
  }

  dragRun(): DragRun {
    return this.drag
  }

  handlingRun(): HandlingRun {
    return this.handling
  }

  live(): { rpm: number; load: number; boost: number; speed: number } {
    return { rpm: this.liveRpm, load: this.liveLoad, boost: this.liveBoost, speed: this.drag.speed }
  }

  fitmentFor(build: Build = this.activeBuild()) {
    return fitment(build.engine, build.bodyId)
  }

  peak(build: Build = this.activeBuild()): Peak {
    const key = JSON.stringify([build.engine, build.ecu])
    const cached = this.peakCache.get(key)
    if (cached) return cached
    const value = estimatePeak(build.engine, build.ecu)
    this.trimCache(this.peakCache)
    this.peakCache.set(key, value)
    return value
  }

  curve(build: Build = this.activeBuild()): DynoPoint[] {
    const key = JSON.stringify([build.engine, build.ecu])
    const cached = this.curveCache.get(key)
    if (cached) return cached
    const value = torqueCurve(build.engine, build.ecu, 52)
    this.trimCache(this.curveCache)
    this.curveCache.set(key, value)
    return value
  }

  stats(build: Build = this.activeBuild()) {
    const peak = this.peak(build)
    return { ...vehicleStats(build, peak.hp, peak.torque), peak }
  }

  estimatedDrag(build: Build = this.activeBuild()) {
    const key = this.resultKey(build)
    const cached = this.dragCache.get(key)
    if (cached) return cached
    const value = simulateDrag(build, this.curve(build))
    this.trimCache(this.dragCache)
    this.dragCache.set(key, value)
    return value
  }

  estimatedHandling(build: Build = this.activeBuild()) {
    const key = this.resultKey(build)
    const cached = this.handlingCache.get(key)
    if (cached) return cached
    const peak = this.peak(build)
    const value = handlingResult(build, peak.hp)
    this.trimCache(this.handlingCache)
    this.handlingCache.set(key, value)
    return value
  }

  canRun(build: Build = this.activeBuild()): { ok: boolean; reason: string } {
    if (build.condition <= 0) return { ok: false, reason: 'The engine is seized. Repair or rebuild it first.' }
    const fit = this.fitmentFor(build)
    if (!fit.fits) return { ok: false, reason: `The engine does not fit the ${bodyById(build.bodyId).name} (${fit.blocker} by ${fit.overByMm} mm).` }
    return { ok: true, reason: '' }
  }

  draftCost(): { diff: number; bench: number; total: number } {
    if (!this.engineDraft || !this.draftBase) return { diff: 0, bench: 0, total: 0 }
    const diff = Math.max(0, engineCost(this.engineDraft) - engineCost(this.draftBase))
    const changedHardware =
      this.engineDraft.layout !== this.draftBase.layout ||
      this.engineDraft.bore !== this.draftBase.bore ||
      this.engineDraft.stroke !== this.draftBase.stroke ||
      this.engineDraft.compression !== this.draftBase.compression
    const bench = changedHardware ? 450 : 0
    return { diff, bench, total: diff + bench }
  }

  partCost(slot: PartSlot, index: number): number {
    const current = this.activeBuild().engine
    const next = structuredClone(current)
    next.parts[slot] = index
    return upgradeCost(current, next)
  }

  isPartUnlocked(slot: PartSlot, index: number): boolean {
    return this.state.mode === 'sandbox' || partOption(slot, index).unlockRep <= this.state.rep
  }

  jobProgress() {
    const job = this.state.job
    if (!job) return null
    return contractResult(job.build, job.contract.target)
  }

  // ─── screens ─────────────────────────────────────────────────────────────

  setScreen(screen: Screen): void {
    if (screen === this.screen && !(screen === 'engine' && !this.engineDraft)) {
      this.ui?.render()
      return
    }
    if (this.screen === 'engine' && screen !== 'engine') this.discardDraft()
    this.screen = screen
    this.syncStage()
    this.stage.setView(this.viewForScreen())
    if (screen === 'engine') this.beginEngineDraft()
    if (screen === 'dyno') {
      this.dyno = idleDyno()
      this.freeRevThrottle = 0
    }
    if (screen === 'test') {
      this.stage.setView(this.testTab === 'drag' ? 'drag' : 'handling')
      this.stage.setMotion({
        speed: 0, wheelspin: 0, distance: this.testTab === 'drag' ? this.drag.distance : 0,
        handlingProgress: this.testTab === 'handling' ? this.handling.progress : 0,
      })
    }
    if (screen !== 'dyno' && screen !== 'test') this.stopSound()
    this.ui?.render()
  }

  goTitle(): void {
    this.screen = 'title'
    this.stopSound()
    this.syncStage()
    this.stage.setView('title')
    this.ui?.render()
  }

  startCareer(): void {
    this.state = { ...this.state, mode: 'career', introSeen: true }
    this.store.save(this.state)
    this.screen = 'garage'
    this.syncStage(true)
    this.stage.setView('garage')
    this.ui?.render()
  }

  startSandbox(): void {
    this.state = { ...this.state, mode: 'sandbox', introSeen: true }
    this.store.save(this.state)
    this.screen = 'garage'
    this.syncStage(true)
    this.stage.setView('garage')
    this.ui?.render()
  }

  setMode(mode: Mode): void {
    if (this.state.mode === mode) return
    if (this.screen === 'engine') this.discardDraft()
    this.state = { ...this.state, mode }
    this.store.save(this.state)
    this.screen = 'garage'
    this.syncStage(true)
    this.stage.setView('garage')
    this.sound.stopEngine(0.3)
    this.soundStarted = false
    this.ui?.render()
  }

  setTestTab(tab: TestTab): void {
    if (this.testTab === tab) return
    this.testTab = tab
    this.drag = idleDrag()
    this.dragSim = null
    this.handling = idleHandling()
    this.stage.setView(tab === 'drag' ? 'drag' : 'handling')
    this.stage.setMotion({ distance: 0, speed: 0, wheelspin: 0, handlingProgress: 0, squat: 0, roll: 0 })
    this.stage.setTree('idle')
    this.stage.setSmoke(0)
    this.stopSound()
    this.ui?.render()
  }

  private viewForScreen() {
    if (this.screen === 'title') return 'title' as const
    if (this.screen === 'engine') return 'engine' as const
    if (this.screen === 'ecu') return 'ecu' as const
    if (this.screen === 'dyno') return 'dyno' as const
    if (this.screen === 'test') return this.testTab === 'drag' ? ('drag' as const) : ('handling' as const)
    return 'garage' as const
  }

  // ─── stage sync ──────────────────────────────────────────────────────────

  private buildKey(build: Build): string {
    return JSON.stringify({
      id: build.id,
      bodyId: build.bodyId,
      engine: build.engine,
      paint: build.paint,
      wheels: build.wheels,
      stance: build.stance,
      aero: build.aero,
      interior: build.interior,
    })
  }

  private syncStage(force = false): void {
    const build = this.activeBuild()
    const key = this.buildKey(build)
    if (force || key !== this.stageKey) {
      this.stage.setBuild(build)
      this.stageKey = key
    } else {
      this.stage.setAppearance(build)
    }
    if (this.engineDraft && this.screen === 'engine') this.stage.setEngineDraft(this.engineDraft)
  }

  private scheduleDraftStage(): void {
    if (this.draftTimer !== null) window.clearTimeout(this.draftTimer)
    this.draftTimer = window.setTimeout(() => {
      this.draftTimer = null
      if (this.engineDraft && this.screen === 'engine') this.stage.setEngineDraft(this.engineDraft)
    }, 130)
  }

  private rebuildStage(): void {
    this.syncStage(true)
    if (this.soundStarted) {
      this.sound.startEngine(this.activeBuild().engine)
      this.soundEngineKey = this.buildKey(this.activeBuild())
    }
  }

  // ─── build actions ───────────────────────────────────────────────────────

  beginEngineDraft(): void {
    if (this.engineDraft) return
    const engine = this.activeBuild().engine
    this.engineDraft = structuredClone(engine)
    this.draftBase = structuredClone(engine)
    this.stage.setEngineDraft(this.engineDraft)
  }

  discardDraft(): void {
    if (this.draftTimer !== null) window.clearTimeout(this.draftTimer)
    this.draftTimer = null
    this.engineDraft = null
    this.draftBase = null
    if (this.screen === 'engine') this.stage.setEngineDraft(this.activeBuild().engine)
  }

  revertDraft(): void {
    if (!this.draftBase) return
    this.engineDraft = structuredClone(this.draftBase)
    this.stage.setEngineDraft(this.engineDraft)
    this.ui?.render()
  }

  updateDraft(patch: Partial<EngineConfig>): void {
    if (!this.engineDraft) this.beginEngineDraft()
    if (!this.engineDraft) return
    this.engineDraft = sanitizeEngine({ ...this.engineDraft, ...patch } as EngineConfig)
    this.scheduleDraftStage()
    this.ui?.render()
  }

  setDraftName(name: string): void {
    this.updateDraft({ name: name.slice(0, 28) })
  }

  setDraftLayout(layout: LayoutId): void {
    if (!this.engineDraft) return
    const next = sanitizeEngine({ ...this.engineDraft, layout })
    const rotary = layout.startsWith('rotary')
    next.bore = clamp(next.bore, rotary ? 60 : 65, rotary ? 100 : 112)
    next.stroke = clamp(next.stroke, rotary ? 60 : 60, rotary ? 100 : 112)
    this.engineDraft = next
    this.scheduleDraftStage()
    this.ui?.render()
  }

  setDraftPart(slot: PartSlot, index: number): void {
    if (!this.engineDraft) return
    if (!this.isPartUnlocked(slot, index)) {
      this.toast('That part is still locked by reputation.', 'warn')
      return
    }
    const parts = { ...this.engineDraft.parts, [slot]: index }
    this.updateDraft({ parts })
  }

  setDraftInduction(induction: InductionId): void {
    if (this.state.mode !== 'sandbox' && INDUCTIONS[induction].unlockRep > this.state.rep) {
      this.toast(`${INDUCTIONS[induction].name} needs ${INDUCTIONS[induction].unlockRep} reputation.`, 'warn')
      return
    }
    this.updateDraft({ induction })
  }

  setDraftFuel(fuel: FuelId): void {
    if (this.state.mode !== 'sandbox' && FUELS[fuel].unlockRep > this.state.rep) {
      this.toast(`${FUELS[fuel].name} needs ${FUELS[fuel].unlockRep} reputation.`, 'warn')
      return
    }
    this.updateDraft({ fuel })
  }

  applyPreset(id: string): void {
    const preset = enginePresets().find(p => p.id === id)
    if (!preset) return
    if (this.state.mode !== 'sandbox') {
      const locked = PART_SLOTS.some(slot => {
        const index = preset.build.parts[slot]
        return index !== undefined && partOption(slot, index).unlockRep > this.state.rep
      })
      if (locked) {
        this.toast('Preset contains parts locked by reputation. Build it part by part or raise your rep.', 'warn')
        return
      }
      if (INDUCTIONS[preset.build.induction].unlockRep > this.state.rep) {
        this.toast('Preset induction is locked by reputation.', 'warn')
        return
      }
    }
    this.engineDraft = structuredClone(preset.build)
    this.stage.setEngineDraft(this.engineDraft)
    this.ui?.render()
  }

  applyDraft(): void {
    if (!this.engineDraft) return
    const cost = this.draftCost()
    const engine = sanitizeEngine(this.engineDraft)
    const current = this.activeBuild()
    const fit = fitment(engine, current.bodyId)
    if (!fit.fits) {
      this.toast(`Engine will not fit: ${fit.blocker} is over by ${fit.overByMm} mm.`, 'bad')
      return
    }
    const next = structuredClone(this.state)
    const build = getActiveBuild(next)
    const error = this.charge(next, cost.total)
    if (error) {
      this.toast(error, 'bad')
      return
    }
    const hardwareChanged =
      engine.layout !== build.engine.layout ||
      engine.bore !== build.engine.bore ||
      engine.stroke !== build.engine.stroke
    build.engine = engine
    build.ecu = hardwareChanged ? defaultEcu(engine) : sanitizeEcu(build.ecu, engine)
    this.clearResults(build)
    this.state = next
    this.store.save(next)
    this.engineDraft = structuredClone(engine)
    this.draftBase = structuredClone(engine)
    this.rebuildStage()
    this.soundStarted = false
    this.toast(`Build committed — $${cost.total.toLocaleString()} charged.`, 'ok')
    this.ui?.render()
  }

  installPart(slot: PartSlot, index: number): void {
    if (!this.isPartUnlocked(slot, index)) {
      this.toast('That part is still locked by reputation.', 'warn')
      return
    }
    const next = structuredClone(this.state)
    const build = getActiveBuild(next)
    const current = build.engine
    const candidate = structuredClone(current)
    candidate.parts[slot] = index
    const cost = upgradeCost(current, candidate)
    const error = this.charge(next, cost)
    if (error) {
      this.toast(error, 'bad')
      return
    }
    build.engine = sanitizeEngine(candidate)
    build.ecu = sanitizeEcu(build.ecu, build.engine)
    this.clearResults(build)
    this.state = next
    this.store.save(next)
    this.rebuildStage()
    this.soundStarted = false
    this.toast(`${partOption(slot, index).name} fitted.`, 'ok')
    this.ui?.render()
  }

  installInduction(induction: InductionId): void {
    if (this.state.mode !== 'sandbox' && INDUCTIONS[induction].unlockRep > this.state.rep) {
      this.toast(`Needs ${INDUCTIONS[induction].unlockRep} reputation.`, 'warn')
      return
    }
    const next = structuredClone(this.state)
    const build = getActiveBuild(next)
    const cost = Math.max(0, INDUCTIONS[induction].cost - INDUCTIONS[build.engine.induction].cost)
    const error = this.charge(next, cost)
    if (error) {
      this.toast(error, 'bad')
      return
    }
    build.engine = sanitizeEngine({ ...build.engine, induction })
    build.ecu = { ...sanitizeEcu(build.ecu, build.engine), boostTarget: targetBoostDefault(build.engine) }
    this.clearResults(build)
    this.state = next
    this.store.save(next)
    this.rebuildStage()
    this.soundStarted = false
    this.ui?.render()
  }

  installFuel(fuel: FuelId): void {
    if (this.state.mode !== 'sandbox' && FUELS[fuel].unlockRep > this.state.rep) {
      this.toast(`Needs ${FUELS[fuel].unlockRep} reputation.`, 'warn')
      return
    }
    const next = structuredClone(this.state)
    const build = getActiveBuild(next)
    const cost = Math.max(0, FUELS[fuel].cost - FUELS[build.engine.fuel].cost)
    const error = this.charge(next, cost)
    if (error) {
      this.toast(error, 'bad')
      return
    }
    build.engine = sanitizeEngine({ ...build.engine, fuel })
    build.ecu = { ...sanitizeEcu(build.ecu, build.engine), afr: FUELS[fuel].afrTarget }
    this.clearResults(build)
    this.state = next
    this.store.save(next)
    this.rebuildStage()
    this.soundStarted = false
    this.ui?.render()
  }

  installChassis(kind: keyof ChassisConfig, id: string): void {
    const tables = { tires: TIRES, suspension: SUSPENSIONS, brakes: BRAKES, gearbox: GEARBOXES, weight: WEIGHT_REDUCTION } as const
    const table = tables[kind] as Record<string, { cost: number }>
    const item = table[id]
    if (!item) return
    const next = structuredClone(this.state)
    const build = getActiveBuild(next)
    const error = this.charge(next, item.cost)
    if (error) {
      this.toast(error, 'bad')
      return
    }
    ;(build.chassis as unknown as Record<string, string>)[kind] = id
    delete build.drag
    delete build.handling
    this.state = next
    this.store.save(next)
    this.rebuildStage()
    this.ui?.render()
  }

  installAero(aero: AeroId): void {
    const next = structuredClone(this.state)
    const build = getActiveBuild(next)
    const error = this.charge(next, AERO[aero].cost)
    if (error) {
      this.toast(error, 'bad')
      return
    }
    build.aero = aero
    delete build.drag
    delete build.handling
    this.state = next
    this.store.save(next)
    this.rebuildStage()
    this.ui?.render()
  }

  installInterior(interior: InteriorId): void {
    const next = structuredClone(this.state)
    const build = getActiveBuild(next)
    build.interior = interior
    delete build.handling
    this.state = next
    this.store.save(next)
    this.rebuildStage()
    this.ui?.render()
  }

  setPaintColor(color: string): void {
    const next = structuredClone(this.state)
    getActiveBuild(next).paint = { ...getActiveBuild(next).paint, color }
    this.state = next
    this.store.save(next)
    this.stage.setAppearance(this.activeBuild())
    this.ui?.render()
  }

  setPaintFinish(finish: PaintFinish): void {
    const next = structuredClone(this.state)
    getActiveBuild(next).paint = { ...getActiveBuild(next).paint, finish }
    this.state = next
    this.store.save(next)
    this.stage.setAppearance(this.activeBuild())
    this.ui?.render()
  }

  setWheelStyle(style: WheelStyle): void {
    const next = structuredClone(this.state)
    getActiveBuild(next).wheels = { ...getActiveBuild(next).wheels, style }
    this.state = next
    this.store.save(next)
    this.rebuildStage()
    this.ui?.render()
  }

  setWheelSize(size: number): void {
    const next = structuredClone(this.state)
    const build = getActiveBuild(next)
    build.wheels = { ...build.wheels, size: clamp(Math.round(size), 14, 22) }
    delete build.drag
    delete build.handling
    this.state = next
    this.store.save(next)
    this.rebuildStage()
    this.ui?.render()
  }

  setStance(size: number): void {
    const next = structuredClone(this.state)
    getActiveBuild(next).stance = clamp(Math.round(size * 100) / 100, -1, 1)
    this.state = next
    this.store.save(next)
    this.stage.setAppearance(this.activeBuild())
    this.ui?.render()
  }

  buyBody(id: string): void {
    const result = purchaseBody(this.state, id)
    if (result.error) {
      this.toast(result.error, 'warn')
      return
    }
    this.state = result.state
    this.store.save(this.state)
    this.toast(`${bodyById(id).name} joined the shop.`, 'ok')
    this.ui?.render()
  }

  buyAndSelectBody(id: string): void {
    if (this.state.job) {
      this.toast('The customer body is fixed for an active job.', 'warn')
      return
    }
    const result = purchaseBody(this.state, id)
    if (result.error) {
      this.toast(result.error, 'warn')
      return
    }
    this.state = result.state
    this.selectBody(id)
    this.store.save(this.state)
  }

  selectBody(id: string): void {
    if (this.state.job) {
      this.toast('The customer body is fixed for an active job.', 'warn')
      return
    }
    const body = bodyById(id)
    if (this.state.mode !== 'sandbox' && !this.state.ownedBodies.includes(id)) {
      this.toast('Buy the body before fitting it to your project.', 'warn')
      return
    }
    if (this.state.mode === 'career' && body.unlockRep > this.state.rep) {
      this.toast(`${body.name} needs ${body.unlockRep} reputation.`, 'warn')
      return
    }
    const next = structuredClone(this.state)
    const build = getActiveBuild(next)
    const fit = fitment(build.engine, id)
    if (!fit.fits) {
      this.toast(`Engine does not fit ${body.name}: ${fit.blocker} over by ${fit.overByMm} mm.`, 'bad')
      return
    }
    build.bodyId = id
    build.paint = { ...build.paint, color: body.defaultPaint }
    delete build.drag
    delete build.handling
    this.state = next
    this.store.save(next)
    this.rebuildStage()
    this.ui?.render()
  }

  renameBuild(name: string): void {
    const next = structuredClone(this.state)
    getActiveBuild(next).name = name.slice(0, 36) || 'Untitled build'
    this.state = next
    this.store.save(next)
    this.ui?.render()
  }

  repairEngine(): void {
    const next = structuredClone(this.state)
    const build = getActiveBuild(next)
    if (build.condition >= 100) {
      this.toast('This engine is already at full condition.', 'warn')
      return
    }
    const error = this.charge(next, repairCost(build))
    if (error) {
      this.toast(error, 'bad')
      return
    }
    build.condition = 100
    this.clearResults(build)
    this.state = next
    this.store.save(next)
    this.rebuildStage()
    this.toast('Engine serviced. Condition restored to 100%.', 'ok')
    this.ui?.render()
  }

  rebuildEngine(): void {
    const next = structuredClone(this.state)
    const build = getActiveBuild(next)
    const error = this.charge(next, rebuildCost(build))
    if (error) {
      this.toast(error, 'bad')
      return
    }
    build.condition = 100
    this.clearResults(build)
    this.state = next
    this.store.save(next)
    this.rebuildStage()
    this.toast('Fresh rotating assembly built and fitted.', 'ok')
    this.ui?.render()
  }

  private clearResults(build: Build): void {
    delete build.dyno
    delete build.drag
    delete build.handling
  }

  // ─── ECU actions ─────────────────────────────────────────────────────────

  updateEcu(patch: Partial<Build['ecu']>): void {
    const next = structuredClone(this.state)
    const build = getActiveBuild(next)
    build.ecu = sanitizeEcu({ ...build.ecu, ...patch }, build.engine)
    this.clearResults(build)
    this.state = next
    this.store.save(next)
    this.ui?.render()
  }

  setMapCell(table: 'fuel' | 'ignition', row: number, col: number, value: number): void {
    const next = structuredClone(this.state)
    const build = getActiveBuild(next)
    build.ecu = setCell(build.ecu, table, row, col, value)
    this.clearResults(build)
    this.state = next
    this.store.save(next)
    this.ui?.render()
  }

  autoBaseMap(): void {
    const next = structuredClone(this.state)
    const build = getActiveBuild(next)
    build.ecu = autoBase(build.ecu, build.engine)
    this.clearResults(build)
    this.state = next
    this.store.save(next)
    this.toast('Base map rebuilt from the engine spec.', 'ok')
    this.ui?.render()
  }

  smoothMap(table: 'fuel' | 'ignition'): void {
    const next = structuredClone(this.state)
    const build = getActiveBuild(next)
    build.ecu = smoothTable(build.ecu, table)
    this.clearResults(build)
    this.state = next
    this.store.save(next)
    this.toast('Table smoothed. Neighbour cells pulled into line.', 'ok')
    this.ui?.render()
  }

  fixFuelMap(): void {
    const next = structuredClone(this.state)
    const build = getActiveBuild(next)
    build.ecu = fixFuel(build.ecu, build.engine)
    this.clearResults(build)
    this.state = next
    this.store.save(next)
    this.toast('Fuel table matched to physical airflow.', 'ok')
    this.ui?.render()
  }

  advanceTimingMap(): void {
    const next = structuredClone(this.state)
    const build = getActiveBuild(next)
    build.ecu = advanceTiming(build.ecu, build.engine)
    this.clearResults(build)
    this.state = next
    this.store.save(next)
    this.toast('Timing advanced toward MBT, inside the knock margin.', 'ok')
    this.ui?.render()
  }

  resetEcu(): void {
    const next = structuredClone(this.state)
    const build = getActiveBuild(next)
    build.ecu = defaultEcu(build.engine)
    this.clearResults(build)
    this.state = next
    this.store.save(next)
    this.toast('ECU reset to the base calibration.', 'ok')
    this.ui?.render()
  }

  // ─── dyno ────────────────────────────────────────────────────────────────

  startDynoPull(): void {
    const build = this.activeBuild()
    const gate = this.canRun(build)
    if (!gate.ok) {
      this.toast(gate.reason, 'bad')
      return
    }
    if (this.screen !== 'dyno') this.setScreen('dyno')
    const result = dynoPull(build.engine, build.ecu, build.condition)
    this.dyno = {
      phase: 'pulling',
      points: result.points,
      cursor: 0,
      rpm: result.points[0]?.rpm ?? 1000,
      throttle: 1,
      time: 0,
      result,
    }
    this.freeRevThrottle = 1
    this.ensureSound()
    this.sound.update(this.dyno.rpm, 1, result.points[0]?.boost ?? 0, false)
    this.ui?.render()
  }

  setPedal(on: boolean): void {
    if (this.screen !== 'dyno') this.setScreen('dyno')
    this.ensureSound()
    if (this.dyno.phase === 'pulling') return
    this.freeRevThrottle = on ? 1 : 0
    this.dyno.phase = on ? 'revving' : 'idle'
    this.dyno.throttle = on ? 1 : 0
    this.ui?.render()
  }

  toggleCutaway(): void {
    this.cutaway = !this.cutaway
    this.stage.setEngineCutaway(this.cutaway)
    this.ui?.render()
  }

  resetDyno(): void {
    this.dyno = idleDyno()
    this.freeRevThrottle = 0
    this.ui?.render()
  }

  private stepDyno(dt: number): void {
    if (this.dyno.phase === 'pulling') {
      this.dyno.time += dt
      const points = this.dyno.points
      const progress = clamp(this.dyno.time / 5.4, 0, 1)
      const cursor = Math.min(points.length - 1, Math.floor(progress * points.length))
      this.dyno.cursor = cursor
      const point = points[cursor]
      if (point) {
        this.dyno.rpm = point.rpm
        this.liveRpm = point.rpm
        this.liveLoad = 1
        this.liveBoost = point.boost
      }
      if (progress >= 1) this.finishDyno()
    } else if (this.dyno.phase === 'revving') {
      const limit = this.activeBuild().ecu.revLimit
      this.dyno.rpm = clamp(900 + this.freeRevThrottle * (limit - 900), 900, limit)
      this.liveRpm += (this.dyno.rpm - this.liveRpm) * (1 - Math.exp(-dt * 5))
      this.liveLoad = this.freeRevThrottle * 0.8
      this.liveBoost = this.freeRevThrottle * this.activeBuild().ecu.boostTarget * 0.75
    } else {
      this.liveRpm += (900 - this.liveRpm) * (1 - Math.exp(-dt * 3))
      this.liveLoad = 0
      this.liveBoost = 0
    }
    this.sound.update(this.liveRpm, this.liveLoad, this.liveBoost, this.liveRpm > this.activeBuild().ecu.revLimit - 45)
  }

  private finishDyno(): void {
    const result = this.dyno.result
    if (!result) return
    const next = structuredClone(this.state)
    const build = getActiveBuild(next)
    build.condition = result.conditionAfter
    build.dyno = result
    next.pulls += 1
    const recorded = recordBests(next, build)
    this.state = recorded
    this.store.save(recorded)
    this.dyno.phase = 'done'
    this.dyno.cursor = result.points.length - 1
    this.dyno.time = 5.4
    if (!result.valid) {
      this.sound.stopEngine(0.4)
      this.soundStarted = false
    }
    this.rebuildStage()
    this.ui?.render()
    this.ui?.showModal(this.dynoModal(result, build))
  }

  private dynoModal(result: DynoResult, build: Build): ResultModal {
    const grade = pullGrade(result, build.engine)
    return {
      kind: 'dyno',
      eyebrow: 'DYNO CELL 01 · LOAD SWEEP',
      title: result.valid ? `${result.peakHp} HP` : 'ENGINE FAILED',
      subtitle: result.valid
        ? `${result.peakTorque} Nm @ ${result.peakTorqueRpm} rpm · ${result.peakHpRpm} rpm peak power`
        : grade.text,
      badge: grade.grade,
      tone: grade.level,
      stats: [
        { label: 'Peak torque', value: `${result.peakTorque} Nm`, detail: `@ ${result.peakTorqueRpm} rpm` },
        { label: 'Boost', value: `${result.boostPeak.toFixed(1)} psi` },
        { label: 'AFR range', value: `${result.afrMin.toFixed(1)}–${result.afrMax.toFixed(1)}` },
        { label: 'Knock peak', value: `${result.knockPeak.toFixed(0)}`, detail: result.knockPeak > 60 ? 'danger' : 'clean' },
        { label: 'Condition', value: `${result.conditionBefore}% → ${result.conditionAfter}%` },
        { label: 'EGT peak', value: `${result.egtPeak} °C` },
      ],
      note: grade.text,
      actions: result.valid
        ? [{ label: 'Close', action: 'close-modal' }, { label: 'Open ECU', action: 'open-ecu' }, { label: 'Run again', action: 'run-dyno', primary: true }]
        : [{ label: 'Close', action: 'close-modal' }, { label: 'Open ECU', action: 'open-ecu' }, { label: 'Repair in shop', action: 'go-shop', primary: true }],
    }
  }

  // ─── drag strip ──────────────────────────────────────────────────────────

  stageDrag(): void {
    const build = this.activeBuild()
    const gate = this.canRun(build)
    if (!gate.ok) {
      this.toast(gate.reason, 'bad')
      return
    }
    if (this.screen !== 'test') this.setScreen('test')
    if (this.testTab !== 'drag') this.setTestTab('drag')
    this.drag = idleDrag()
    this.drag.phase = 'staging'
    this.drag.rpm = build.ecu.launchRpm
    this.dragSim = null
    this.dragCurve = this.curve(build)
    this.stage.setView('drag')
    this.stage.setMotion({ distance: 0, speed: 0, wheelspin: 0, squat: 0, roll: 0, steering: 0 })
    this.stage.setTree('idle')
    this.stage.setSmoke(0)
    this.ensureSound()
    this.ui?.render()
  }

  startTree(): void {
    if (this.drag.phase !== 'staging') return
    this.drag.phase = 'tree'
    this.drag.treeTime = 0
    this.stage.setTree('amber1')
    this.sound.ui('tree')
    this.ui?.render()
  }

  shiftDrag(): void {
    if (this.drag.phase === 'running') {
      this.shiftQueued = true
      this.sound.shiftCue()
      this.haptics.cue('shift')
      this.ui?.render()
    }
  }

  resetDrag(): void {
    this.drag = idleDrag()
    this.dragSim = null
    this.stage.setMotion({ distance: 0, speed: 0, wheelspin: 0, squat: 0, roll: 0, steering: 0 })
    this.stage.setView('drag')
    this.stage.setTree('idle')
    this.stage.setSmoke(0)
    this.ui?.render()
  }

  private stepDrag(dt: number): void {
    if (this.drag.phase === 'tree') {
      this.drag.treeTime += dt
      if (this.drag.treeTime > 0.55 && this.drag.treeTime <= 0.6) this.stage.setTree('amber1')
      if (this.drag.treeTime > 1.05 && this.drag.treeTime <= 1.1) this.stage.setTree('amber2')
      if (this.drag.treeTime > 1.55 && this.drag.treeTime <= 1.6) this.stage.setTree('amber3')
      if (this.drag.treeTime > 2.05) {
        this.drag.phase = 'running'
        this.drag.treeTime = 2.05
        this.stage.setTree('green')
        this.sound.ui('green')
        this.haptics.cue('launch')
        this.dragSim = createDragSim(this.activeBuild().ecu.launchRpm)
        this.dragCurve = this.curve(this.activeBuild())
        this.ui?.render()
      }
      this.liveRpm += (this.activeBuild().ecu.launchRpm - this.liveRpm) * (1 - Math.exp(-dt * 4))
      this.liveLoad = 0.25
      return
    }
    if (this.drag.phase !== 'running' || !this.dragSim) {
      if (this.drag.phase === 'finished') {
        this.liveRpm += (900 - this.liveRpm) * (1 - Math.exp(-dt * 3))
        this.liveLoad = 0
      }
      return
    }
    const build = this.activeBuild()
    const sim = stepDragSim(build, this.dragSim, dt, {
      throttle: 1,
      shiftUp: this.shiftQueued,
      autoShift: this.state.settings.autoShift,
    }, this.dragCurve)
    this.shiftQueued = false
    this.dragSim = sim
    this.drag.elapsed = sim.time
    this.drag.distance = sim.distance
    this.drag.speed = sim.speed
    this.drag.rpm = sim.rpm
    this.drag.gear = sim.gear
    this.drag.wheelspin = sim.wheelspin
    this.drag.shiftCount = sim.shiftCount
    this.drag.sixtyFt = sim.sixtyFt
    this.drag.zeroTo100 = sim.zeroTo100
    this.drag.limiterTime = sim.limiterTime
    this.liveRpm = sim.rpm
    this.liveLoad = 1
    this.liveBoost = this.boostAt(sim.rpm)
    this.stage.setMotion({
      distance: sim.distance,
      speed: sim.speed,
      wheelspin: sim.wheelspin,
      squat: clamp((sim.speed < 12 ? 1 : 0.35) + sim.wheelspin * 0.4, 0, 1),
      roll: 0,
      pitch: sim.speed < 8 ? 0.035 : 0,
    })
    this.stage.setSmoke(clamp(sim.wheelspin, 0, 1) * (sim.speed < 25 ? 1 : 0.2))
    this.sound.update(sim.rpm, 1, this.liveBoost, sim.rpm > build.ecu.revLimit - 45)
    if (sim.finished) this.finishDrag(sim)
    if (sim.time > 24 && !sim.finished) {
      this.finishDrag(sim, true)
    }
  }

  private boostAt(rpm: number): number {
    const points = this.dragCurve
    if (points.length === 0) return 0
    let best = points[0]
    for (const point of points) {
      if (Math.abs(point.rpm - rpm) < Math.abs(best.rpm - rpm)) best = point
    }
    return best.boost
  }

  private finishDrag(sim: DragSim, timedOut = false): void {
    const result = dragResultFromSim(sim)
    if (timedOut) result.valid = false
    const next = structuredClone(this.state)
    const build = getActiveBuild(next)
    build.drag = result
    build.condition = Math.max(0, Math.round((build.condition - (0.25 + sim.wheelspin * 0.9)) * 10) / 10)
    if (result.valid) {
      const recorded = recordBests(next, build)
      this.state = recorded
    } else {
      this.state = next
    }
    this.store.save(this.state)
    this.drag.phase = 'finished'
    this.drag.et = result.et
    this.drag.trapKmh = result.trapKmh
    this.drag.result = result
    this.drag.sixtyFt = result.sixtyFt
    this.drag.zeroTo100 = result.zeroTo100
    this.stage.setSmoke(0)
    this.stage.setTree('green')
    this.rebuildStage()
    this.ui?.render()
    this.ui?.showModal(this.dragModal(result))
  }

  private dragModal(result: DragResult): ResultModal {
    return {
      kind: 'drag',
      eyebrow: 'QUARTER MILE · 402.336 M',
      title: result.valid && result.et !== null ? `${result.et.toFixed(2)} S` : 'NO TIME',
      subtitle: result.valid
        ? result.trapKmh !== null ? `${result.trapKmh} km/h trap · ${result.sixtyFt.toFixed(2)} s to 60 ft` : 'Run incomplete'
        : 'The run did not complete the quarter mile.',
      badge: result.valid ? 'RUN LOGGED' : 'ABORTED',
      tone: result.valid ? 'ok' : 'bad',
      stats: [
        { label: '60 ft', value: `${result.sixtyFt.toFixed(2)} s` },
        { label: '0–100 km/h', value: result.zeroTo100 !== null ? `${result.zeroTo100.toFixed(2)} s` : '—' },
        { label: 'Trap speed', value: result.trapKmh !== null ? `${result.trapKmh} km/h` : '—' },
        { label: 'Top speed', value: `${result.topSpeed} km/h` },
        { label: 'Wheelspin', value: `${result.wheelspin.toFixed(2)}` },
        { label: 'Shifts', value: `${result.shifts}` },
      ],
      note: 'Manual shifts are free. The car leaves on the green; reaction time is not scored in this mode.',
      actions: [{ label: 'Close', action: 'close-modal' }, { label: 'Reset strip', action: 'reset-drag' }, { label: 'Run again', action: 'run-drag', primary: true }],
    }
  }

  // ─── handling ────────────────────────────────────────────────────────────

  startHandling(): void {
    const build = this.activeBuild()
    const gate = this.canRun(build)
    if (!gate.ok) {
      this.toast(gate.reason, 'bad')
      return
    }
    if (this.screen !== 'test') this.setScreen('test')
    if (this.testTab !== 'handling') this.setTestTab('handling')
    const peak = this.peak(build)
    const result = handlingResult(build, peak.hp)
    this.handling = {
      phase: 'running',
      time: 0,
      progress: 0,
      speed: 0,
      lateralG: 0,
      result,
    }
    this.handlingDuration = clamp(result.lap / 10, 5.5, 9.5)
    this.ensureSound()
    this.ui?.render()
  }

  private stepHandling(dt: number): void {
    if (this.handling.phase !== 'running' || !this.handling.result) {
      this.liveLoad = 0
      return
    }
    this.handling.time += dt
    this.handling.progress = clamp(this.handling.time / this.handlingDuration, 0, 1)
    const p = this.handling.progress
    const target = this.handling.result
    this.handling.speed = Math.round(target.speedTrap * (0.32 + 0.55 * Math.sin(Math.PI * p)) + 22)
    this.handling.lateralG = Math.round(target.lateralG * (0.65 + 0.35 * Math.sin(Math.PI * p)) * 100) / 100
    this.stage.setMotion({
      handlingProgress: p,
      speed: this.handling.speed / 3.6,
      steering: Math.sin(p * Math.PI * 4) * 0.32,
      roll: -clamp(this.handling.lateralG * 0.018, 0, 0.08),
      squat: 0,
      pitch: 0,
      wheelspin: 0,
    })
    this.liveRpm = clamp(2200 + this.handling.speed * 48, 1200, this.activeBuild().ecu.revLimit)
    this.liveLoad = 0.75
    this.liveBoost = this.boostAt(this.liveRpm)
    this.sound.update(this.liveRpm, this.liveLoad, this.liveBoost, false)
    if (p >= 1) {
      const next = structuredClone(this.state)
      const build = getActiveBuild(next)
      build.handling = target
      build.condition = Math.max(0, Math.round((build.condition - 0.7) * 10) / 10)
      const recorded = recordBests(next, build)
      this.state = recorded
      this.store.save(recorded)
      this.handling.phase = 'done'
      this.handling.progress = 1
      this.rebuildStage()
      this.ui?.render()
      this.ui?.showModal(this.handlingModal(target))
    }
  }

  private handlingModal(result: HandlingResult): ResultModal {
    return {
      kind: 'handling',
      eyebrow: 'HANDLING COURSE · 2.1 KM',
      title: `${result.lap.toFixed(2)} S`,
      subtitle: `${result.lateralG.toFixed(2)} g peak lateral · ${result.balance}`,
      badge: 'LAP LOGGED',
      tone: result.balance === 'Oversteer' ? 'warn' : 'ok',
      stats: [
        { label: 'Lateral grip', value: `${result.lateralG.toFixed(2)} g` },
        { label: 'Speed trap', value: `${result.speedTrap} km/h` },
        { label: 'Balance', value: result.balance },
        { label: 'Course', value: '2.1 km' },
      ],
      note: 'Balance is a computed tendency from drivetrain, mass and power-to-weight — not a tyre-pressure sim.',
      actions: [{ label: 'Close', action: 'close-modal' }, { label: 'Open chassis', action: 'go-shop' }, { label: 'Run again', action: 'run-handling', primary: true }],
    }
  }

  // ─── career ──────────────────────────────────────────────────────────────

  acceptJob(id: string): void {
    const result = acceptContract(this.state, id)
    if (result.error) {
      this.toast(result.error, 'warn')
      return
    }
    this.state = result.state
    this.store.save(this.state)
    this.screen = 'jobs'
    this.syncStage(true)
    this.stage.setView('garage')
    this.toast('Contract accepted. The customer car is in bay 03.', 'ok')
    this.ui?.render()
  }

  diagnose(): void {
    const result = diagnoseJob(this.state)
    if (result.error) {
      this.toast(result.error, 'warn')
      return
    }
    this.state = result.state
    this.store.save(this.state)
    this.toast(result.findings.length > 0 ? `Diagnosis logged: ${result.findings.length} fault${result.findings.length === 1 ? '' : 's'} found.` : 'Diagnosis complete. No faults found.', 'ok')
    this.ui?.render()
  }

  repairJobFault(fault: FaultId): void {
    const result = repairFault(this.state, fault)
    if (result.error) {
      this.toast(result.error, 'warn')
      return
    }
    this.state = result.state
    this.store.save(this.state)
    const build = this.activeBuild()
    this.clearResults(build)
    this.store.save(this.state)
    this.rebuildStage()
    this.toast('Fault repaired. The map and condition are untouched.', 'ok')
    this.ui?.render()
  }

  deliver(): void {
    const result = deliverJob(this.state)
    if (!result.outcome.ok) {
      this.toast(result.outcome.reason, 'bad')
      return
    }
    this.state = result.state
    this.store.save(this.state)
    this.sound.ui('cash')
    this.rebuildStage()
    this.ui?.render()
    this.ui?.showModal({
      kind: 'job',
      eyebrow: 'CONTRACT DELIVERED',
      title: `+$${result.outcome.payout.toLocaleString()}`,
      subtitle: result.outcome.reason,
      badge: `+${result.outcome.rep} REP`,
      tone: 'ok',
      stats: [
        { label: 'Cash paid', value: `$${result.outcome.payout.toLocaleString()}` },
        { label: 'Reputation', value: `+${result.outcome.rep}` },
        { label: 'Completed jobs', value: `${this.state.completedJobs}` },
      ],
      note: 'The board has another car on it. Take a breath first.',
      actions: [{ label: 'Back to bay', action: 'close-modal' }, { label: 'Contract board', action: 'go-jobs', primary: true }],
    })
  }

  abandon(): void {
    this.state = abandonJob(this.state)
    this.store.save(this.state)
    this.rebuildStage()
    this.toast('Contract abandoned. The bay is clear.', 'warn')
    this.ui?.render()
  }

  // ─── settings and reset ──────────────────────────────────────────────────

  updateSetting<K extends keyof Settings>(key: K, value: Settings[K]): void {
    this.state = { ...this.state, settings: { ...this.state.settings, [key]: value } }
    this.store.save(this.state)
    this.applySettings()
    this.ui?.render()
  }

  private applySettings(): void {
    const settings = this.state.settings
    this.sound.setVolumes(settings.engineVolume, settings.sfxVolume, settings.musicVolume)
    this.stage.setQuality(settings.quality as Quality)
    this.stage.setReducedMotion(settings.reducedMotion)
    this.haptics.enabled = settings.haptics
  }

  resetGame(): void {
    this.stopSound()
    this.state = this.store.reset()
    this.screen = 'title'
    this.engineDraft = null
    this.draftBase = null
    this.stageKey = ''
    this.syncStage(true)
    this.stage.setView('title')
    this.applySettings()
    this.ui?.render()
  }

  saveNow(): void {
    this.store.save(this.state)
  }

  toast(text: string, tone: 'ok' | 'warn' | 'bad' = 'ok'): void {
    if (tone !== 'ok') this.haptics.cue('warning')
    this.ui?.toast(text, tone)
  }

  // ─── step / render ───────────────────────────────────────────────────────

  private step(dt: number): void {
    this.simClock += dt
    this.stepLive(dt)
    if (this.screen === 'dyno') this.stepDyno(dt)
    else if (this.screen === 'test' && this.testTab === 'drag') this.stepDrag(dt)
    else if (this.screen === 'test' && this.testTab === 'handling') this.stepHandling(dt)
    if (this.screen !== 'dyno' && this.screen !== 'test') {
      this.liveRpm += (880 - this.liveRpm) * (1 - Math.exp(-dt * 2))
      this.liveLoad = 0
      this.liveBoost = 0
    }
    this.stage.setRpm(this.liveRpm, this.liveLoad, this.liveBoost)
  }

  private stepLive(dt: number): void {
    const build = this.activeBuild()
    let target = 880
    let load = 0
    let boost = 0
    let rate = 3
    if (this.screen === 'dyno') {
      if (this.dyno.phase === 'pulling') {
        target = this.dyno.rpm
        load = 1
        boost = this.dyno.points[this.dyno.cursor]?.boost ?? 0
        rate = 30
      } else if (this.dyno.phase === 'revving') {
        target = 900 + this.freeRevThrottle * (build.ecu.revLimit - 900)
        load = this.freeRevThrottle * 0.8
        boost = this.freeRevThrottle * build.ecu.boostTarget * 0.75
        rate = 7
      }
    } else if (this.screen === 'test' && this.testTab === 'drag') {
      if (this.drag.phase === 'staging' || this.drag.phase === 'tree') {
        target = build.ecu.launchRpm
        load = 0.22
        rate = 4
      } else if (this.drag.phase === 'running') {
        target = this.drag.rpm
        load = 1
        boost = this.boostAt(this.drag.rpm)
        rate = 30
      }
    } else if (this.screen === 'test' && this.testTab === 'handling' && this.handling.phase === 'running') {
      target = this.liveRpm
      load = 0.75
      rate = 20
    }
    if (this.dyno.phase === 'pulling' && this.screen === 'dyno') {
      this.liveRpm = target
    } else {
      this.liveRpm += (target - this.liveRpm) * (1 - Math.exp(-dt * rate))
    }
    this.liveLoad = load
    this.liveBoost = boost
    this.manageSound()
  }

  private manageSound(): void {
    const shouldRun = this.screen === 'dyno' || this.screen === 'test'
    if (shouldRun && !this.soundStarted) this.ensureSound()
    if (!shouldRun && this.soundStarted) this.stopSound()
    if (this.soundStarted && this.soundEngineKey !== this.buildKey(this.activeBuild())) {
      this.sound.startEngine(this.activeBuild().engine)
      this.soundEngineKey = this.buildKey(this.activeBuild())
    }
  }

  private ensureSound(): void {
    if (!this.soundStarted) {
      this.sound.startEngine(this.activeBuild().engine)
      this.soundStarted = true
      this.soundEngineKey = this.buildKey(this.activeBuild())
    }
  }

  private stopSound(): void {
    if (this.soundStarted) {
      this.sound.stopEngine(0.35)
      this.soundStarted = false
    }
  }

  private render(frameSeconds: number): void {
    if (this.firstFrame) {
      this.firstFrame = false
    }
    this.stage.update(Math.min(frameSeconds, 0.06))
    this.stage.render()
    this.sound.update(this.liveRpm, this.liveLoad, this.liveBoost, this.liveRpm > this.activeBuild().ecu.revLimit - 45)
    this.ui?.frame(frameSeconds)
  }

  private charge(state: GameState, cost: number): string | null {
    if (state.mode === 'sandbox' || cost <= 0) return null
    if (state.job) {
      if (state.job.spent + cost > state.job.contract.budget) {
        return `Customer budget would be exceeded by $${(state.job.spent + cost - state.job.contract.budget).toLocaleString()}.`
      }
      state.job.spent += cost
      return null
    }
    if (state.cash < cost) return `Not enough cash. Need $${(cost - state.cash).toLocaleString()} more.`
    state.cash -= cost
    return null
  }

  private resultKey(build: Build): string {
    return JSON.stringify([build.engine, build.ecu, build.bodyId, build.chassis, build.wheels, build.aero, build.interior])
  }

  private trimCache<T>(map: Map<string, T>): void {
    if (map.size > 24) {
      const first = map.keys().next().value
      if (first !== undefined) map.delete(first)
    }
  }

  // ─── UI helpers ──────────────────────────────────────────────────────────

  bodies() {
    return BODIES
  }

  enginePresetList() {
    return enginePresets()
  }

  faultsOfJob(): FaultId[] {
    return this.state.job?.build.engine.faults ?? []
  }

  jobFaultOpen(fault: FaultId): boolean {
    return this.faultsOfJob().includes(fault)
  }

  formatTime(seconds: number): string {
    const s = Math.max(0, seconds)
    return `${s.toFixed(2)}`
  }
}

export type { DynoResult, HandlingResult }
