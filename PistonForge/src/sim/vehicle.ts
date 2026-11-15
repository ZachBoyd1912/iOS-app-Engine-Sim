import {
  AERO,
  BRAKES,
  GEARBOXES,
  SUSPENSIONS,
  TIRES,
  WEIGHT_REDUCTION,
  bodyById,
} from './data'
import { engineSpec } from './engine'
import type { Build, DragResult, DynoPoint, HandlingResult } from './types'

const RHO = 1.225
const G = 9.81

const clamp = (v: number, min: number, max: number) => Math.min(max, Math.max(min, v))
const round = (v: number, places = 2) => {
  const f = 10 ** places
  return Math.round(v * f) / f
}

export function vehicleMass(build: Build): number {
  const body = bodyById(build.bodyId)
  const engine = engineSpec(build.engine)
  const reduction = WEIGHT_REDUCTION[build.chassis.weight].kg + (build.interior === 'stripped' ? 18 : 0)
  return Math.max(480, body.kerbKg + engine.massKg + 75 + 20 - reduction)
}

export function gearRatios(build: Build): number[] {
  const body = bodyById(build.bodyId)
  return GEARBOXES[build.chassis.gearbox].ratios ?? body.ratios
}

export function wheelRadius(build: Build): number {
  const body = bodyById(build.bodyId)
  return body.wheelRadius * (1 + (build.wheels.size - 17) * 0.012)
}

export function finalDrive(build: Build): number {
  return bodyById(build.bodyId).finalDrive
}

export function dragCdA(build: Build): number {
  const body = bodyById(build.bodyId)
  return body.cd * body.frontalArea + AERO[build.aero].drag * body.frontalArea
}

export function gripCoefficient(build: Build): number {
  const body = bodyById(build.bodyId)
  return body.grip * TIRES[build.chassis.tires].grip * SUSPENSIONS[build.chassis.suspension].handling * (1 + AERO[build.aero].downforce * 0.55)
}

export function driveWeightFactor(build: Build): number {
  const drivetrain = bodyById(build.bodyId).drivetrain
  return drivetrain === 'AWD' ? 0.94 : drivetrain === 'RWD' ? 0.66 : 0.54
}

export function estimateTopSpeed(build: Build, peakHp: number): number {
  const mass = vehicleMass(build)
  const powerW = Math.max(12, peakHp) * 745.7 * 0.84
  const cda = dragCdA(build)
  const rolling = 0.012 * mass * G
  let lo = 1
  let hi = 130
  for (let i = 0; i < 36; i += 1) {
    const v = (lo + hi) / 2
    const demand = 0.5 * RHO * cda * v * v * v + rolling * v
    if (demand > powerW) hi = v
    else lo = v
  }
  return Math.round(lo * 3.6)
}

export function torqueAt(points: DynoPoint[], rpm: number): number {
  if (points.length === 0) return 0
  if (rpm <= points[0].rpm) return points[0].torque
  for (let i = 0; i < points.length - 1; i += 1) {
    const a = points[i]
    const b = points[i + 1]
    if (rpm <= b.rpm) {
      const t = (rpm - a.rpm) / Math.max(1, b.rpm - a.rpm)
      return a.torque * (1 - t) + b.torque * t
    }
  }
  return points[points.length - 1].torque
}

export type DragSim = {
  time: number
  distance: number
  speed: number
  rpm: number
  gear: number
  wheelspin: number
  shiftTimer: number
  shiftCount: number
  sixtyFt: number | null
  zeroTo100: number | null
  et: number | null
  trapKmh: number | null
  topSpeed: number
  limiterTime: number
  finished: boolean
}

export function createDragSim(launchRpm: number): DragSim {
  return {
    time: 0,
    distance: 0,
    speed: 0,
    rpm: clamp(launchRpm, 1500, 7000),
    gear: 0,
    wheelspin: 0,
    shiftTimer: 0,
    shiftCount: 0,
    sixtyFt: null,
    zeroTo100: null,
    et: null,
    trapKmh: null,
    topSpeed: 0,
    limiterTime: 0,
    finished: false,
  }
}

export type DragInput = { throttle: number; shiftUp: boolean; autoShift: boolean }

export function stepDragSim(build: Build, sim: DragSim, dt: number, input: DragInput, curve: DynoPoint[]): DragSim {
  if (sim.finished) return sim
  const body = bodyById(build.bodyId)
  const mass = vehicleMass(build)
  const ratios = gearRatios(build)
  const fd = finalDrive(build)
  const radius = wheelRadius(build)
  const efficiency = body.drivetrain === 'AWD' ? 0.88 : body.drivetrain === 'RWD' ? 0.91 : 0.9
  const next = { ...sim }
  next.time += dt
  next.shiftTimer = Math.max(0, next.shiftTimer - dt)

  const gearCount = ratios.length
  const gearRatio = ratios[Math.min(next.gear, gearCount - 1)] ?? 1
  const wheelRpm = (next.speed / (2 * Math.PI * radius)) * 60 * gearRatio * fd
  const limiter = build.ecu.revLimit
  const mechanical = engineSpec(build.engine).mechanicalRedline
  const effectiveLimit = Math.min(limiter, mechanical + 200)

  if (next.shiftTimer <= 0) {
    const shouldAutoShift = input.autoShift && next.rpm > effectiveLimit * 0.965 && next.gear < gearCount - 1
    if ((input.shiftUp || shouldAutoShift) && next.gear < gearCount - 1) {
      next.gear += 1
      next.shiftCount += 1
      next.shiftTimer = build.chassis.gearbox === 'dct' ? 0.045 : 0.16
    }
  }

  if (next.shiftTimer > 0) {
    next.rpm = Math.max(900, (next.speed / (2 * Math.PI * radius)) * 60 * (ratios[next.gear] ?? 1) * fd)
    next.wheelspin = Math.max(0, next.wheelspin - dt * 2)
    next.distance += Math.max(0, next.speed) * dt
    return finishIfDone(next)
  }

  const launch = next.speed < 3.2 && input.throttle > 0.35
  const targetRpm = launch
    ? Math.max(build.ecu.launchRpm, wheelRpm)
    : Math.max(900, wheelRpm)
  const rpm = clamp(targetRpm, 850, effectiveLimit)
  next.rpm = rpm
  let torque = torqueAt(curve, rpm) * clamp(input.throttle, 0, 1)
  if (rpm >= limiter - 35) {
    torque *= 0.08
    next.limiterTime += dt
  }
  if (rpm > mechanical) torque *= 0.9

  const driveForce = (torque * gearRatio * fd * efficiency) / radius
  const downforce = 0.5 * RHO * dragCdA(build) * next.speed * next.speed * AERO[build.aero].downforce
  const normal = mass * G + downforce
  const traction = gripCoefficient(build) * normal * driveWeightFactor(build)
  const demandRatio = driveForce / Math.max(1, traction)
  const spinning = demandRatio > 1 && input.throttle > 0.4
  next.wheelspin = spinning
    ? clamp(Math.max(next.wheelspin, demandRatio - 1), 0, 1.4)
    : Math.max(0, next.wheelspin - dt * 2.5)

  if (spinning) {
    const slipRpm = Math.min(effectiveLimit, rpm + 900 + next.wheelspin * 2800)
    next.rpm = Math.max(rpm, slipRpm)
  }

  const force = Math.min(driveForce, traction)
  const aeroDrag = 0.5 * RHO * dragCdA(build) * next.speed * next.speed
  const rolling = 0.012 * normal
  const accel = (force - aeroDrag - rolling) / mass
  next.speed = Math.max(0, next.speed + accel * dt)
  next.distance += next.speed * dt
  next.topSpeed = Math.max(next.topSpeed, next.speed)

  if (next.sixtyFt === null && next.distance >= 18.288) next.sixtyFt = round(next.time, 2)
  if (next.zeroTo100 === null && next.speed * 3.6 >= 100) next.zeroTo100 = round(next.time, 2)
  return finishIfDone(next)
}

function finishIfDone(sim: DragSim): DragSim {
  if (sim.et === null && sim.distance >= 402.336) {
    sim.et = round(sim.time, 2)
    sim.trapKmh = Math.round(sim.speed * 3.6)
    sim.finished = true
  }
  return sim
}

export function dragResultFromSim(sim: DragSim): DragResult {
  return {
    sixtyFt: sim.sixtyFt ?? 99,
    zeroTo100: sim.zeroTo100,
    et: sim.et,
    trapKmh: sim.trapKmh,
    trapMph: sim.trapKmh !== null ? Math.round(sim.trapKmh * 0.621371) : null,
    topSpeed: Math.round(sim.topSpeed * 3.6),
    wheelspin: round(sim.wheelspin, 2),
    shifts: sim.shiftCount,
    valid: sim.et !== null,
    at: Date.now(),
  }
}

/** A perfect-shift reference run, used for estimates and career target previews. */
export function simulateDrag(build: Build, curve: DynoPoint[]): DragResult {
  let sim = createDragSim(build.ecu.launchRpm)
  for (let i = 0; i < 3600 && !sim.finished; i += 1) {
    sim = stepDragSim(build, sim, 0.01, { throttle: 1, shiftUp: false, autoShift: true }, curve)
  }
  return dragResultFromSim(sim)
}

export function handlingResult(build: Build, peakHp: number): HandlingResult {
  const body = bodyById(build.bodyId)
  const mass = vehicleMass(build)
  const grip = gripCoefficient(build)
  const downforce = AERO[build.aero].downforce
  const brake = BRAKES[build.chassis.brakes].score
  const powerKw = Math.max(20, peakHp) * 0.7457
  const cda = dragCdA(build)
  const rolling = 0.012 * mass * G
  let vMax = 30
  for (let i = 0; i < 30; i += 1) {
    const demand = 0.5 * RHO * cda * vMax * vMax * vMax + rolling * vMax
    if (demand > powerKw * 0.82) break
    vMax += 1.2
  }
  const cornerSpeed = Math.sqrt(grip * (1 + downforce * 0.8) * G * 58)
  const powerToWeight = peakHp / (mass / 1000)
  const accelPenalty = 1 + clamp(58 / Math.max(25, powerToWeight), 0.08, 0.65)
  const brakingFactor = 1 / (0.92 + brake * 0.075)
  const avg = vMax * 0.56 + cornerSpeed * 0.44
  const lap = (2100 / Math.max(12, avg)) * accelPenalty * brakingFactor
  const lateralG = grip * (1 + downforce * 0.8) * 0.98
  const balance: HandlingResult['balance'] =
    body.drivetrain === 'FWD' && powerToWeight > 190 ? 'Understeer'
      : body.drivetrain === 'RWD' && powerToWeight > 360 ? 'Oversteer'
        : powerToWeight > 420 && body.drivetrain === 'AWD' ? 'Neutral'
          : Math.abs(powerToWeight - 210) < 55 ? 'Neutral'
            : body.drivetrain === 'FWD' ? 'Understeer' : 'Neutral'
  return {
    lap: round(lap, 2),
    lateralG: round(lateralG, 2),
    balance,
    speedTrap: Math.round(vMax * 3.6 * 0.92),
    at: Date.now(),
  }
}

export function vehicleStats(build: Build, peakHp: number, peakTorque: number) {
  const body = bodyById(build.bodyId)
  const mass = vehicleMass(build)
  return {
    mass,
    powerToWeight: Math.round((peakHp / (mass / 1000)) * 10) / 10,
    topSpeed: estimateTopSpeed(build, peakHp),
    drivetrain: body.drivetrain,
    gears: gearRatios(build).length,
    torque: peakTorque,
    grip: Math.round(gripCoefficient(build) * 100) / 100,
  }
}

// keep the torque parameter intentional for callers that show the peak on the handling card
export function handlingSummary(result: HandlingResult, peakTorque: number): string {
  return `${result.lap.toFixed(2)} s · ${result.lateralG.toFixed(2)} g · ${peakTorque} Nm`
}
