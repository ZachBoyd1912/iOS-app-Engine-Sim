// Exports golden fixtures from the TypeScript simulation for the Swift port.
// Skipped in normal test runs. To regenerate:
//   EXPORT_FIXTURES=1 pnpm vitest run tests/export-fixtures.test.ts
// Output: ../Native/PistonForgeKit/Tests/PistonForgeKitTests/Fixtures/sim-golden.json (the Swift package's tests read it).
//
// Each case records the inputs (engine, ECU, body, condition) and the outputs the Swift
// code must reproduce. Timestamps (`at`) and build IDs are removed because they are not
// part of the model.
import { mkdirSync, writeFileSync } from 'node:fs'
import { it } from 'vitest'
import { CONTRACT_TEMPLATES } from '../src/sim/data'
import { enginePresets, engineSpec, fitment, salvageEngine, sanitizeEngine, engineCost } from '../src/sim/engine'
import { defaultEcu, sanitizeEcu } from '../src/sim/ecu'
import { dynoPull, estimatePeak, torqueCurve } from '../src/sim/performance'
import { makeBuild, startingBuild } from '../src/sim/builds'
import { simulateDrag, vehicleMass, estimateTopSpeed } from '../src/sim/vehicle'
import type { Build, EcuConfig, EngineConfig } from '../src/sim/types'

const OUT = '../Native/PistonForgeKit/Tests/PistonForgeKitTests/Fixtures/sim-golden.json'

function strip<T>(value: T): T {
  return JSON.parse(JSON.stringify(value, (key, v) => (key === 'at' || key === 'id' ? undefined : v)))
}

function caseFor(name: string, engine: EngineConfig, ecu: EcuConfig, bodyId: string, condition: number) {
  const build: Build = { ...makeBuild(bodyId, engine), ecu, condition }
  const dyno = dynoPull(engine, ecu, condition)
  return strip({
    name,
    input: { engine, ecu, bodyId, condition },
    spec: engineSpec(engine),
    cost: engineCost(engine),
    fitment: fitment(engine, bodyId),
    estimate: estimatePeak(engine, ecu),
    curve: torqueCurve(engine, ecu),
    dyno,
    mass: vehicleMass(build),
    topSpeed: estimateTopSpeed(build, dyno.peakHp),
    drag: simulateDrag(build, dyno.points),
  })
}

it.skipIf(!process.env.EXPORT_FIXTURES)('export golden fixtures', () => {
  const cases = []
  const start = startingBuild()
  cases.push(caseFor('starting-build', start.engine, start.ecu, start.bodyId, start.condition))
  for (const preset of enginePresets()) {
    const engine = sanitizeEngine(preset.build)
    cases.push(caseFor(`preset-${preset.id}`, engine, defaultEcu(engine), 'coupe', 100))
  }
  for (const contract of CONTRACT_TEMPLATES) {
    const engine = sanitizeEngine(contract.engine)
    cases.push(caseFor(`contract-${contract.id}`, engine, defaultEcu(engine), contract.bodyId, 76))
  }
  // The stale-map seizure (plan bug 3): kept as a fixture so the port reproduces the model
  // exactly before the fix changes it on purpose.
  const salvage = salvageEngine()
  for (const cams of [1, 2, 3]) {
    const engine = sanitizeEngine({ ...salvage, parts: { ...salvage.parts, cams } })
    cases.push(caseFor(`stale-map-cams-${cams}`, engine, sanitizeEcu(start.ecu, engine), start.bodyId, start.condition))
  }
  mkdirSync('../Native/PistonForgeKit/Tests/PistonForgeKitTests/Fixtures', { recursive: true })
  writeFileSync(OUT, JSON.stringify({ source: 'PistonForge TypeScript sim', cases }, null, 1) + '\n')
  console.log(`wrote ${cases.length} cases to ${OUT}`)
})
