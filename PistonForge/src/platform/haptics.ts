/**
 * Haptic feedback, scaled by how important the event is.
 *
 * The game talks in cues ("shift", "launch", "failure"); this module decides what the phone
 * does about them. The driver is injected so the mapping and the throttle are unit tested
 * without a device. On the web the driver falls back to the Vibration API where it exists
 * (Android browsers) and does nothing where it does not (desktop, iOS Safari).
 */

export type HapticCue =
  /** Small: a control was pressed. */
  | 'tap'
  /** Small: a value changed (map cell, tab, part choice). */
  | 'select'
  /** Medium: a gear change on the strip. */
  | 'shift'
  /** Large: green light, the car leaves the line. */
  | 'launch'
  /** A good result: clean pull, logged run, contract paid. */
  | 'success'
  /** Something needs attention: knock, limiter, invalid choice. */
  | 'warning'
  /** Something broke: failed pull, dead engine. */
  | 'failure'

export type ImpactWeight = 'light' | 'medium' | 'heavy'
export type NotifyKind = 'success' | 'warning' | 'error'

export interface HapticDriver {
  impact(weight: ImpactWeight): Promise<void> | void
  notify(kind: NotifyKind): Promise<void> | void
  selection(): Promise<void> | void
}

type Plan = { kind: 'impact'; weight: ImpactWeight } | { kind: 'notify'; type: NotifyKind } | { kind: 'selection' }

export const CUE_PLAN: Record<HapticCue, Plan> = {
  tap: { kind: 'impact', weight: 'light' },
  select: { kind: 'selection' },
  shift: { kind: 'impact', weight: 'medium' },
  launch: { kind: 'impact', weight: 'heavy' },
  success: { kind: 'notify', type: 'success' },
  warning: { kind: 'notify', type: 'warning' },
  failure: { kind: 'notify', type: 'error' },
}

/** Small cues closer together than this are dropped so a dragged slider does not buzz. */
export const MIN_GAP_MS = 45

const ALWAYS_PLAY: ReadonlySet<HapticCue> = new Set(['launch', 'success', 'warning', 'failure'])

export class HapticEngine {
  enabled = true
  private lastAt = -Infinity

  constructor(
    private readonly driver: HapticDriver | null,
    private readonly now: () => number = () => performance.now(),
  ) {}

  /** Fire a cue. Never throws and never blocks: haptics are decoration, not game state. */
  cue(cue: HapticCue): void {
    if (!this.enabled || !this.driver) return
    const at = this.now()
    if (!ALWAYS_PLAY.has(cue) && at - this.lastAt < MIN_GAP_MS) return
    this.lastAt = at
    const plan = CUE_PLAN[cue]
    try {
      const done =
        plan.kind === 'impact' ? this.driver.impact(plan.weight)
        : plan.kind === 'notify' ? this.driver.notify(plan.type)
        : this.driver.selection()
      if (done && typeof done.then === 'function') done.then(undefined, () => {})
    } catch {
      // A missing Taptic Engine or a denied call must not reach the game.
    }
  }
}

/** Vibration API fallback for browsers that have it. Returns null where there is none. */
export function webVibrationDriver(nav: Pick<Navigator, 'vibrate'> | undefined = globalThis.navigator): HapticDriver | null {
  if (!nav || typeof nav.vibrate !== 'function') return null
  const buzz = (pattern: number | number[]) => { nav.vibrate(pattern) }
  return {
    impact: weight => buzz(weight === 'heavy' ? 28 : weight === 'medium' ? 16 : 8),
    notify: kind => buzz(kind === 'error' ? [30, 40, 30, 40, 60] : kind === 'warning' ? [20, 50, 20] : [12, 40, 24]),
    selection: () => buzz(5),
  }
}
