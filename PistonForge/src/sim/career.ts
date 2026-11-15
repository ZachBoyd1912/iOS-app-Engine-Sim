import {
  BODIES,
  CONTRACT_TEMPLATES,
  FAULTS,
  bodyById,
} from './data'
import { makeBuild, sandboxStartingBuild, startingBuild } from './builds'
import type { BodySpec, Build, Contract, ContractTarget, GameState } from './types'

export const STARTING_CASH = 4800
export const DIAGNOSTIC_FEE = 60

export function defaultSettings(): GameState['settings'] {
  return {
    musicVolume: 0.35,
    engineVolume: 0.8,
    sfxVolume: 0.7,
    quality: 'high',
    reducedMotion: false,
    autoShift: true,
    haptics: true,
    tips: true,
  }
}

export function defaultState(): GameState {
  const career = startingBuild()
  return {
    version: 1,
    mode: 'career',
    cash: STARTING_CASH,
    rep: 0,
    ownedBodies: ['kei'],
    careerBuilds: [career],
    careerActiveId: career.id,
    sandboxBuild: sandboxStartingBuild(),
    job: null,
    contracts: CONTRACT_TEMPLATES.map(contract => structuredClone(contract)),
    completedContracts: [],
    settings: defaultSettings(),
    bests: { hp: 0, torque: 0, et: 0, trap: 0, lap: 0 },
    completedJobs: 0,
    pulls: 0,
    introSeen: false,
  }
}

export function activeBuild(state: GameState): Build {
  if (state.mode === 'sandbox') return state.sandboxBuild
  if (state.job) return state.job.build
  return state.careerBuilds.find(build => build.id === state.careerActiveId) ?? state.careerBuilds[0]
}

export function activeCareerBuild(state: GameState): Build {
  return state.careerBuilds.find(build => build.id === state.careerActiveId) ?? state.careerBuilds[0]
}

export function ownedBody(state: GameState, bodyId: string): boolean {
  return state.mode === 'sandbox' || state.ownedBodies.includes(bodyId)
}

export function unlockedBody(state: GameState, body: BodySpec): boolean {
  return state.mode === 'sandbox' || body.unlockRep <= state.rep
}

export function availableContracts(state: GameState): Contract[] {
  return state.contracts.filter(contract => !state.completedContracts.includes(contract.id))
}

export function contractLock(state: GameState, contract: Contract): string | null {
  if (state.completedContracts.includes(contract.id)) return 'Completed'
  if (state.rep < contract.minRep) return `Needs ${contract.minRep} rep`
  return null
}

export function targetText(target: ContractTarget): string {
  switch (target.kind) {
    case 'power': return `${target.value} hp or more`
    case 'torque': return `${target.value} Nm or more`
    case 'et': return `${target.value.toFixed(2)} s quarter mile or quicker`
    case 'lap': return `${target.value.toFixed(1)} s lap or quicker`
  }
}

export function acceptContract(state: GameState, contractId: string): { state: GameState; error?: string } {
  if (state.mode !== 'career') return { state, error: 'Contracts are only available in career mode.' }
  if (state.job) return { state, error: 'Finish or abandon the current job first.' }
  const contract = state.contracts.find(c => c.id === contractId)
  if (!contract) return { state, error: 'That contract is no longer on the board.' }
  const lock = contractLock(state, contract)
  if (lock) return { state, error: lock }
  const next = structuredClone(state)
  const build = makeBuild(contract.bodyId, contract.engine, contract.title)
  build.condition = 76
  build.paint = { color: bodyById(contract.bodyId).defaultPaint, finish: 'satin' }
  build.chassis.tires = 'sport'
  build.chassis.suspension = 'coilover'
  next.job = {
    contract: structuredClone(contract),
    build,
    diagnosed: false,
    spent: 0,
  }
  return { state: next }
}

export function diagnoseJob(state: GameState): { state: GameState; findings: string[]; error?: string } {
  if (!state.job) return { state, findings: [], error: 'No active contract.' }
  if (state.job.diagnosed) {
    return { state, findings: state.job.build.engine.faults?.map(f => FAULTS[f].symptom) ?? [] }
  }
  if (state.job.spent + DIAGNOSTIC_FEE > state.job.contract.budget) {
    return { state, findings: [], error: 'Diagnostic fee would exceed the customer budget.' }
  }
  const next = structuredClone(state)
  if (next.job) {
    next.job.diagnosed = true
    next.job.spent += DIAGNOSTIC_FEE
  }
  return {
    state: next,
    findings: next.job?.build.engine.faults?.map(f => `${FAULTS[f].name}: ${FAULTS[f].symptom}`) ?? [],
  }
}

export function repairFault(state: GameState, fault: NonNullable<Build['engine']['faults']>[number]): { state: GameState; cost: number; error?: string } {
  if (!state.job) return { state, cost: 0, error: 'No active contract.' }
  if (!state.job.diagnosed) return { state, cost: 0, error: 'Diagnose the car before ordering parts.' }
  const cost = FAULTS[fault].repair
  if (state.job.spent + cost > state.job.contract.budget) return { state, cost, error: 'Repair would exceed the customer budget.' }
  const next = structuredClone(state)
  if (next.job) {
    next.job.build.engine.faults = (next.job.build.engine.faults ?? []).filter(f => f !== fault)
    next.job.spent += cost
  }
  return { state: next, cost }
}

export function abandonJob(state: GameState): GameState {
  const next = structuredClone(state)
  next.job = null
  return next
}

export function contractResult(build: Build, target: ContractTarget): { value: number | null; met: boolean; label: string } {
  switch (target.kind) {
    case 'power': {
      const value = build.dyno?.valid ? build.dyno.peakHp : null
      return { value, met: value !== null && value >= target.value, label: value === null ? 'No dyno pull' : `${value} hp` }
    }
    case 'torque': {
      const value = build.dyno?.valid ? build.dyno.peakTorque : null
      return { value, met: value !== null && value >= target.value, label: value === null ? 'No dyno pull' : `${value} Nm` }
    }
    case 'et': {
      const value = build.drag?.et ?? null
      return { value, met: value !== null && value <= target.value, label: value === null ? 'No strip run' : `${value.toFixed(2)} s` }
    }
    case 'lap': {
      const value = build.handling?.lap ?? null
      return { value, met: value !== null && value <= target.value, label: value === null ? 'No lap' : `${value.toFixed(2)} s` }
    }
  }
}

export type DeliveryOutcome = {
  ok: boolean
  reason: string
  payout: number
  rep: number
}

export function deliverJob(state: GameState): { state: GameState; outcome: DeliveryOutcome } {
  const fail = (reason: string): { state: GameState; outcome: DeliveryOutcome } => ({
    state,
    outcome: { ok: false, reason, payout: 0, rep: 0 },
  })
  if (!state.job) return fail('No active contract.')
  const job = state.job
  const build = job.build
  if (build.condition <= 0) return fail('The engine is dead. Rebuild it before delivery.')
  if ((build.engine.faults?.length ?? 0) > 0) return fail('The car still has unrepaired faults.')
  const check = contractResult(build, job.contract.target)
  if (!check.met) return fail(`Target not met (${check.label}). ${targetText(job.contract.target)} required.`)

  const next = structuredClone(state)
  next.job = null
  next.cash += job.contract.payout
  next.rep += job.contract.rep
  next.completedContracts.push(job.contract.id)
  next.completedJobs += 1
  next.contracts = next.contracts.filter(c => c.id !== job.contract.id)
  return {
    state: next,
    outcome: {
      ok: true,
      reason: `${job.contract.customer} collected the car.`,
      payout: job.contract.payout,
      rep: job.contract.rep,
    },
  }
}

export function purchaseBody(state: GameState, bodyId: string): { state: GameState; error?: string; cost: number } {
  const body = bodyById(bodyId)
  if (state.mode === 'sandbox') return { state, cost: 0 }
  if (state.ownedBodies.includes(bodyId)) return { state, cost: 0, error: 'Already in the shop.' }
  if (state.rep < body.unlockRep) return { state, cost: body.cost, error: `Needs ${body.unlockRep} reputation.` }
  if (state.cash < body.cost) return { state, cost: body.cost, error: `Need $${(body.cost - state.cash).toLocaleString()} more.` }
  const next = structuredClone(state)
  next.cash -= body.cost
  next.ownedBodies.push(bodyId)
  return { state: next, cost: body.cost }
}

export function recordBests(state: GameState, build: Build): GameState {
  const next = structuredClone(state)
  if (build.dyno?.valid) {
    next.bests.hp = Math.max(next.bests.hp, build.dyno.peakHp)
    next.bests.torque = Math.max(next.bests.torque, build.dyno.peakTorque)
  }
  if (build.drag?.valid) {
    if (build.drag.et !== null) next.bests.et = next.bests.et === 0 ? build.drag.et : Math.min(next.bests.et, build.drag.et)
    if (build.drag.trapKmh !== null) next.bests.trap = Math.max(next.bests.trap, build.drag.trapKmh)
  }
  if (build.handling) {
    next.bests.lap = next.bests.lap === 0 ? build.handling.lap : Math.min(next.bests.lap, build.handling.lap)
  }
  return next
}

export function reputationProgress(rep: number): { name: string; next: number | null; progress: number } {
  const tiers = [
    { name: 'Rookie', at: 0 },
    { name: 'Apprentice', at: 50 },
    { name: 'Journeyman', at: 140 },
    { name: 'Master', at: 300 },
    { name: 'Legend', at: 550 },
  ]
  let current = tiers[0]
  for (const tier of tiers) if (rep >= tier.at) current = tier
  const next = tiers.find(tier => tier.at > rep)?.at ?? null
  const span = next === null ? 1 : next - current.at
  return { name: current.name, next, progress: next === null ? 1 : (rep - current.at) / span }
}

export function bodyAvailability(state: GameState, body: BodySpec): { owned: boolean; unlocked: boolean; label: string } {
  const owned = state.ownedBodies.includes(body.id) || state.mode === 'sandbox'
  const unlocked = state.mode === 'sandbox' || state.rep >= body.unlockRep
  const label = owned ? 'In the shop' : !unlocked ? `${body.unlockRep} rep` : `$${body.cost.toLocaleString()}`
  return { owned, unlocked, label }
}

export function shopSummary(state: GameState): { bodies: number; locked: number } {
  return {
    bodies: state.ownedBodies.length,
    locked: BODIES.filter(body => state.rep < body.unlockRep).length,
  }
}
