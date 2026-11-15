import type { GameState } from './types'

/**
 * First-run next-step coach for career mode. Every rule is derived from GameState, so no
 * progress is saved for it. Pure: no DOM, no three.js.
 */

export type TipId = 'first-pull' | 'first-run' | 'first-contract' | 'deliver-contract'
export type Tip = { id: TipId; title: string; body: string; action: string; actionLabel: string }

const COPY: Record<TipId, Omit<Tip, 'id'>> = {
  'first-pull': {
    title: 'Log a dyno pull',
    body: 'Press Run pull to measure the engine as it is built.',
    action: 'go-dyno',
    actionLabel: 'Open dyno',
  },
  'first-run': {
    title: 'Prove it at the strip',
    body: 'Press Stage car, then Start tree, to run the quarter mile.',
    action: 'go-test',
    actionLabel: 'Open Prove it',
  },
  'first-contract': {
    title: 'Take a customer car',
    body: 'Press Accept on a contract from the board.',
    action: 'go-jobs',
    actionLabel: 'Open jobs',
  },
  'deliver-contract': {
    title: 'Deliver the car',
    body: 'Press Deliver once the target is met and no faults are left.',
    action: 'go-jobs',
    actionLabel: 'Open job',
  },
}

function tipFor(id: TipId): Tip {
  return { id, ...COPY[id] }
}

/** The one next step to show, or null when no coach card should appear. */
export function nextTip(state: GameState): Tip | null {
  if (state.mode !== 'career') return null
  if (state.settings.tips === false) return null
  if (state.completedJobs > 0) return null
  if (state.pulls === 0) return tipFor('first-pull')
  const hasDragResult = state.bests.et !== 0 || state.careerBuilds.some(build => build.drag !== undefined)
  if (!hasDragResult) return tipFor('first-run')
  if (state.job === null) return tipFor('first-contract')
  return tipFor('deliver-contract')
}
