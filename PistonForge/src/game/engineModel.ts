import * as THREE from 'three'
import { INDUCTIONS, LAYOUTS } from '../sim/data'
import { engineSpec } from '../sim/engine'
import type { EngineConfig } from '../sim/types'
import { labelTexture } from './sceneKit'

const clamp = (v: number, min: number, max: number) => Math.min(max, Math.max(min, v))
const DEG = Math.PI / 180

type PistonRig = {
  piston: THREE.Object3D
  rod: THREE.Object3D
  phase: number
  baseY: number
  travel: number
}

type ValveRig = {
  intake: THREE.Object3D
  exhaust: THREE.Object3D
  phase: number
  baseY: number
}

type CamRig = THREE.Object3D

type EngineMats = {
  cast: THREE.MeshStandardMaterial
  cut: THREE.MeshStandardMaterial
  machined: THREE.MeshStandardMaterial
  dark: THREE.MeshStandardMaterial
  black: THREE.MeshStandardMaterial
  rubber: THREE.MeshStandardMaterial
  copper: THREE.MeshStandardMaterial
  heat: THREE.MeshStandardMaterial
  amber: THREE.MeshStandardMaterial
  steel: THREE.MeshStandardMaterial
  glass: THREE.MeshStandardMaterial
}

export class EngineModel {
  readonly group = new THREE.Group()
  private readonly config: EngineConfig
  private readonly spec
  private readonly layout
  private readonly mats: EngineMats
  private crankshaft: THREE.Object3D | null = null
  private cams: CamRig[] = []
  private pistons: PistonRig[] = []
  private valves: ValveRig[] = []
  private turboWheel: THREE.Object3D | null = null
  private rotorRigs: { housing: THREE.Object3D; rotor: THREE.Object3D; phase: number }[] = []
  private cutMaterials: THREE.Material[] = []
  private cutaway = false
  private angle = 0
  private turboSpin = 0
  private badgeTexture: THREE.Texture | null = null
  private readonly clipPlane = new THREE.Plane(new THREE.Vector3(0, 0, -1), 0.015)

  constructor(config: EngineConfig) {
    this.config = config
    this.spec = engineSpec(config)
    this.layout = LAYOUTS[config.layout]
    this.mats = this.makeMaterials()
    this.group.name = `engine-${config.layout}`
    this.build()
  }

  private makeMaterials(): EngineMats {
    const cast = new THREE.MeshStandardMaterial({ color: 0x9aa2a2, roughness: 0.62, metalness: 0.22 })
    return {
      cast,
      cut: cast.clone(),
      machined: new THREE.MeshStandardMaterial({ color: 0xc7cbc5, roughness: 0.32, metalness: 0.55 }),
      dark: new THREE.MeshStandardMaterial({ color: 0x2a3033, roughness: 0.56, metalness: 0.62 }),
      black: new THREE.MeshStandardMaterial({ color: 0x121617, roughness: 0.7, metalness: 0.22 }),
      rubber: new THREE.MeshStandardMaterial({ color: 0x0c0f10, roughness: 0.94 }),
      copper: new THREE.MeshStandardMaterial({ color: 0x9f5b32, roughness: 0.31, metalness: 0.88 }),
      heat: new THREE.MeshStandardMaterial({ color: 0x6f6047, roughness: 0.96 }),
      amber: new THREE.MeshStandardMaterial({ color: 0xffb23e, roughness: 0.36, metalness: 0.3, emissive: 0x6b2e00, emissiveIntensity: 0.3 }),
      steel: new THREE.MeshStandardMaterial({ color: 0x929a9b, roughness: 0.46, metalness: 0.4 }),
      glass: new THREE.MeshStandardMaterial({ color: 0x243033, roughness: 0.22, metalness: 0.4, transparent: true, opacity: 0.5 }),
    }
  }

  private build(): void {
    const rotary = this.layout.rotors > 0
    if (rotary) {
      this.buildRotary()
    } else {
      this.buildPistonEngine()
    }
    this.buildAccessories()
    this.setCutaway(this.cutaway)
  }

  private buildPistonEngine(): void {
    const bore = this.config.bore / 1000
    const stroke = this.config.stroke / 1000
    const banks = this.layout.banks
    const perBank = banks === 2 ? this.spec.cylinders / 2 : this.spec.cylinders
    const spacing = Math.max(0.082, bore * 1.18)
    const blockL = Math.min(this.spec.envelopeMm.length / 1000 * 0.9, Math.max(0.3, spacing * (perBank - 1) + 0.19))
    const blockW = Math.max(0.16, bore * 1.7)
    const blockH = Math.max(0.24, stroke * 1.75 + 0.11)
    const oilH = 0.105
    const blockY = oilH + blockH / 2
    const headH = 0.058
    const headY = oilH + blockH + headH / 2
    const coverY = oilH + blockH + headH + 0.045
    const crankY = oilH + 0.09
    const crankR = clamp(stroke * 0.34, 0.024, 0.048)
    const rodLength = clamp(blockH * 0.58, 0.12, 0.2)

    // Common bottom end / crankcase
    const pan = new THREE.Mesh(new THREE.BoxGeometry(blockL * 0.82, oilH, blockW * 0.72), this.mats.cast)
    pan.position.y = oilH / 2
    pan.castShadow = true
    this.group.add(pan)
    const panLower = new THREE.Mesh(new THREE.BoxGeometry(blockL * 0.64, 0.035, blockW * 0.62), this.mats.black)
    panLower.position.y = 0.025
    this.group.add(panLower)
    for (let i = 0; i < 6; i += 1) {
      const rib = new THREE.Mesh(new THREE.BoxGeometry(blockL * 0.8, 0.012, 0.012), this.mats.dark)
      rib.position.set(0, oilH * 0.55, -blockW * 0.3 + i * (blockW * 0.12))
      this.group.add(rib)
    }

    // Crankshaft
    const crank = new THREE.Group()
    crank.position.set(0, crankY, 0)
    const shaft = new THREE.Mesh(new THREE.CylinderGeometry(0.024, 0.024, blockL * 0.94, 16), this.mats.machined)
    shaft.rotation.z = Math.PI / 2
    shaft.castShadow = true
    crank.add(shaft)
    const webGeo = new THREE.CylinderGeometry(0.052, 0.052, 0.012, 16)
    for (let i = 0; i < this.spec.cylinders; i += 1) {
      const x = this.cx(i, perBank, spacing)
      const web = new THREE.Mesh(webGeo, this.mats.machined)
      web.rotation.z = Math.PI / 2
      web.position.set(x, 0, 0)
      crank.add(web)
      const throwPin = new THREE.Mesh(new THREE.CylinderGeometry(0.018, 0.018, 0.018, 12), this.mats.steel)
      throwPin.rotation.z = Math.PI / 2
      throwPin.position.set(x, Math.cos((i * 180 + 90) * DEG) * crankR, Math.sin((i * 180 + 90) * DEG) * crankR)
      crank.add(throwPin)
    }
    this.group.add(crank)
    this.crankshaft = crank

    // Main block + head per bank
    const bankGroups: { group: THREE.Group; side: number }[] = []
    for (let bank = 0; bank < banks; bank += 1) {
      const bankGroup = new THREE.Group()
      const angle = banks === 2 ? (bank === 0 ? this.layout.bankAngle / 2 : -this.layout.bankAngle / 2) * DEG : 0
      bankGroup.rotation.x = angle
      bankGroup.position.y = 0
      this.group.add(bankGroup)
      bankGroups.push({ group: bankGroup, side: bank === 0 ? 1 : -1 })

      const block = new THREE.Mesh(new THREE.BoxGeometry(blockL, blockH, blockW), this.mats.cut)
      block.position.set(0, blockY, 0)
      block.castShadow = true
      block.receiveShadow = true
      bankGroup.add(block)

      const head = new THREE.Mesh(new THREE.BoxGeometry(blockL * 0.97, headH, blockW * 1.02), this.mats.cut)
      head.position.set(0, headY, 0)
      head.castShadow = true
      bankGroup.add(head)

      const cover = new THREE.Mesh(new THREE.BoxGeometry(blockL * 0.88, 0.07, blockW * 0.74), this.mats.black)
      cover.position.set(0, coverY, 0)
      cover.castShadow = true
      bankGroup.add(cover)
      for (let i = 0; i < 5; i += 1) {
        const rib = new THREE.Mesh(new THREE.BoxGeometry(blockL * 0.8, 0.008, 0.01), this.mats.amber)
        rib.position.set(0, coverY + 0.038, -blockW * 0.3 + i * blockW * 0.15)
        bankGroup.add(rib)
      }

      // Bores visible in cutaway
      for (let i = 0; i < perBank; i += 1) {
        const x = this.cx(i, perBank, spacing) - 0 // local X already centered
        const boreMesh = new THREE.Mesh(new THREE.CylinderGeometry(bore * 0.39, bore * 0.39, blockH * 0.88, 18, 1, true), this.mats.dark)
        boreMesh.position.set(x, blockY, 0)
        bankGroup.add(boreMesh)

        const pistonY = crankY + rodLength + crankR * Math.cos((i * 180) * DEG)
        const piston = new THREE.Group()
        const crown = new THREE.Mesh(new THREE.CylinderGeometry(bore * 0.37, bore * 0.37, 0.052, 18), this.mats.machined)
        crown.castShadow = true
        piston.add(crown)
        const skirt = new THREE.Mesh(new THREE.CylinderGeometry(bore * 0.34, bore * 0.36, 0.045, 18), this.mats.steel)
        skirt.position.y = -0.035
        piston.add(skirt)
        const ring = new THREE.Mesh(new THREE.TorusGeometry(bore * 0.35, 0.004, 4, 18), this.mats.dark)
        ring.rotation.x = Math.PI / 2
        ring.position.y = 0.025
        piston.add(ring)
        piston.position.set(x, pistonY, 0)
        bankGroup.add(piston)

        const rod = new THREE.Mesh(new THREE.BoxGeometry(0.018, rodLength, 0.012), this.mats.machined)
        rod.position.set(0, rodLength / 2, 0)
        const rodGroup = new THREE.Group()
        rodGroup.position.set(x, crankY, 0)
        rodGroup.add(rod)
        bankGroup.add(rodGroup)
        this.pistons.push({ piston, rod: rodGroup, phase: i * 180, baseY: pistonY, travel: crankR })
      }

      // valves, springs, cams
      for (let i = 0; i < perBank; i += 1) {
        const x = this.cx(i, perBank, spacing)
        const intake = this.makeValve(x, headY - headH * 0.15, -blockW * 0.18, bankGroup)
        const exhaust = this.makeValve(x, headY - headH * 0.15, blockW * 0.18, bankGroup)
        this.valves.push({ intake, exhaust, phase: i * 180, baseY: headY - headH * 0.15 })
      }

      const camIntake = this.makeCam(blockL * 0.8, coverY + 0.055, -blockW * 0.18)
      const camExhaust = this.makeCam(blockL * 0.8, coverY + 0.055, blockW * 0.18)
      bankGroup.add(camIntake, camExhaust)
      this.cams.push(camIntake, camExhaust)

      // headers: one pipe per cylinder on the outer side
      const headerPoints: THREE.Vector3[] = []
      for (let i = 0; i < perBank; i += 1) {
        const x = this.cx(i, perBank, spacing)
        const port = new THREE.Vector3(x, headY - 0.005, blockW * 0.52)
        const bend = new THREE.Vector3(x - 0.01, headY - 0.06, blockW * 0.72)
        headerPoints.push(port, bend)
      }
      if (headerPoints.length > 1) {
        const collector = new THREE.Vector3(perBank > 2 ? blockL * 0.3 : 0, blockY - 0.02, blockW * 0.82)
        for (let i = 0; i < perBank; i += 1) {
          const x = this.cx(i, perBank, spacing)
          const points = [
            new THREE.Vector3(x, headY, blockW * 0.45),
            new THREE.Vector3(x + (i - perBank / 2) * 0.008, headY - 0.05, blockW * 0.62),
            collector,
            new THREE.Vector3(blockL * 0.38, blockY - 0.06, blockW * 0.86),
          ]
          const tube = new THREE.Mesh(new THREE.TubeGeometry(new THREE.CatmullRomCurve3(points), 18, 0.018, 8, false), i % 2 ? this.mats.steel : this.mats.copper)
          tube.castShadow = true
          bankGroup.add(tube)
        }
      } else {
        const points = [
          new THREE.Vector3(0, headY, blockW * 0.45),
          new THREE.Vector3(0.02, headY - 0.08, blockW * 0.7),
          new THREE.Vector3(0.08, blockY, blockW * 0.85),
        ]
        const tube = new THREE.Mesh(new THREE.TubeGeometry(new THREE.CatmullRomCurve3(points), 16, 0.018, 8, false), this.mats.copper)
        bankGroup.add(tube)
      }
    }

    // Intake plenum and runners
    const plenumY = coverY + 0.1
    const plenum = new THREE.Mesh(new THREE.BoxGeometry(blockL * 0.78, 0.085, blockW * 0.75), this.mats.machined)
    plenum.position.set(0, plenumY, banks === 2 ? 0 : -blockW * 0.82)
    plenum.castShadow = true
    this.group.add(plenum)
    const throttle = new THREE.Mesh(new THREE.CylinderGeometry(0.045, 0.052, 0.07, 16), this.mats.dark)
    throttle.rotation.x = Math.PI / 2
    throttle.position.set(blockL * 0.36, plenumY + 0.02, banks === 2 ? -blockW * 0.82 : -blockW * 1.05)
    this.group.add(throttle)
    for (let i = 0; i < this.spec.cylinders; i += 1) {
      const x = banks === 2
        ? this.cx(i % (this.spec.cylinders / 2), this.spec.cylinders / 2, spacing)
        : this.cx(i, this.spec.cylinders, spacing)
      const side = banks === 2 ? (i < this.spec.cylinders / 2 ? 1 : -1) : 1
      const points = [
        new THREE.Vector3(x, plenumY, banks === 2 ? 0 : -blockW * 0.6),
        new THREE.Vector3(x, plenumY - 0.04, side * blockW * 0.38),
        new THREE.Vector3(x, headY + 0.04, side * blockW * 0.3),
      ]
      const runner = new THREE.Mesh(new THREE.TubeGeometry(new THREE.CatmullRomCurve3(points), 14, 0.023, 8, false), this.mats.machined)
      this.group.add(runner)
    }

    // Engine mount brackets
    for (const side of [-1, 1]) {
      const bracket = new THREE.Mesh(new THREE.BoxGeometry(0.09, 0.06, 0.035), this.mats.dark)
      bracket.position.set(-blockL * 0.2, oilH + 0.02, side * blockW * 1.05)
      this.group.add(bracket)
    }

    // Front pulley / damper and belt
    const crankPulley = new THREE.Mesh(new THREE.CylinderGeometry(0.075, 0.075, 0.045, 24), this.mats.dark)
    crankPulley.rotation.z = Math.PI / 2
    crankPulley.position.set(blockL * 0.51, crankY, 0)
    this.group.add(crankPulley)
    const pulleyRing = new THREE.Mesh(new THREE.TorusGeometry(0.062, 0.012, 6, 24), this.mats.steel)
    pulleyRing.rotation.y = Math.PI / 2
    pulleyRing.position.set(blockL * 0.51, crankY, 0)
    this.group.add(pulleyRing)
    for (const [x, y] of [[blockL * 0.44, coverY + 0.08], [blockL * 0.38, plenumY + 0.02]]) {
      const pulley = new THREE.Mesh(new THREE.CylinderGeometry(0.035, 0.035, 0.035, 18), this.mats.dark)
      pulley.rotation.z = Math.PI / 2
      pulley.position.set(x, y, -blockW * 0.3)
      this.group.add(pulley)
    }
    const belt = new THREE.Mesh(new THREE.TorusGeometry(0.105, 0.009, 5, 28), this.mats.rubber)
    belt.rotation.y = Math.PI / 2
    belt.position.set(blockL * 0.48, crankY + 0.04, 0)
    this.group.add(belt)

    this.buildTurbo(blockL, blockW, blockY, headY)
    this.buildBadge(coverY)

    // internal cast surfaces stay cuttable
    this.cutMaterials.push(this.mats.cut)
    this.cutMaterials.push(this.mats.cast)
  }

  private cx(index: number, count: number, spacing: number): number {
    return (index - (count - 1) / 2) * spacing
  }

  private makeValve(x: number, y: number, z: number, parent: THREE.Object3D): THREE.Object3D {
    const group = new THREE.Group()
    const stem = new THREE.Mesh(new THREE.CylinderGeometry(0.005, 0.005, 0.085, 8), this.mats.machined)
    stem.position.y = 0.02
    group.add(stem)
    const head = new THREE.Mesh(new THREE.CylinderGeometry(0.018, 0.022, 0.009, 10), this.mats.machined)
    head.position.y = -0.022
    group.add(head)
    const spring = new THREE.Mesh(new THREE.TorusGeometry(0.014, 0.003, 4, 10), this.mats.steel)
    spring.rotation.x = Math.PI / 2
    spring.position.y = 0.046
    group.add(spring)
    group.position.set(x, y, z)
    parent.add(group)
    return group
  }

  private makeCam(length: number, y: number, z: number): THREE.Object3D {
    const group = new THREE.Group()
    const shaft = new THREE.Mesh(new THREE.CylinderGeometry(0.012, 0.012, length, 12), this.mats.machined)
    shaft.rotation.z = Math.PI / 2
    group.add(shaft)
    const lobes = 4
    for (let i = 0; i < lobes; i += 1) {
      const lobe = new THREE.Mesh(new THREE.CylinderGeometry(0.026, 0.026, 0.018, 12), this.mats.steel)
      lobe.rotation.z = Math.PI / 2
      lobe.position.set((i - (lobes - 1) / 2) * length * 0.17, 0.015, 0)
      lobe.rotation.x = i * 0.8
      group.add(lobe)
    }
    group.position.set(0, y, z)
    return group
  }

  private buildTurbo(blockL: number, blockW: number, blockY: number, headY: number): void {
    const induction = INDUCTIONS[this.config.induction]
    if (induction.maxBoost <= 0) {
      if (this.config.induction === 'nitrous') {
        const bottle = new THREE.Mesh(new THREE.CylinderGeometry(0.055, 0.055, 0.28, 16), this.mats.amber)
        bottle.rotation.z = Math.PI / 2
        bottle.position.set(-blockL * 0.38, blockY, blockW * 0.9)
        this.group.add(bottle)
        const nozzle = new THREE.Mesh(new THREE.CylinderGeometry(0.008, 0.008, 0.18, 8), this.mats.copper)
        nozzle.rotation.z = Math.PI / 2
        nozzle.position.set(0, blockY + 0.02, blockW * 1.02)
        this.group.add(nozzle)
      }
      return
    }

    const turboGroup = new THREE.Group()
    const side = this.config.induction === 'twinTurbo' ? 1 : 1
    turboGroup.position.set(blockL * 0.38, blockY + 0.02, side * blockW * 1.08)
    const volute = new THREE.Mesh(new THREE.TorusGeometry(0.085, 0.048, 10, 24), this.mats.cast)
    volute.rotation.y = Math.PI / 2
    volute.castShadow = true
    turboGroup.add(volute)
    const housing = new THREE.Mesh(new THREE.CylinderGeometry(0.072, 0.072, 0.06, 20), this.mats.machined)
    housing.rotation.z = Math.PI / 2
    housing.position.x = -0.045
    turboGroup.add(housing)
    const wheel = new THREE.Group()
    const wheelDisc = new THREE.Mesh(new THREE.CylinderGeometry(0.045, 0.045, 0.014, 18), this.mats.steel)
    wheelDisc.rotation.z = Math.PI / 2
    wheel.add(wheelDisc)
    for (let i = 0; i < 9; i += 1) {
      const blade = new THREE.Mesh(new THREE.BoxGeometry(0.008, 0.04, 0.007), this.mats.steel)
      blade.position.set(0, 0.02, 0)
      blade.rotation.x = (i / 9) * Math.PI * 2
      wheel.add(blade)
    }
    wheel.position.x = -0.055
    turboGroup.add(wheel)
    this.turboWheel = wheel
    const wastegate = new THREE.Mesh(new THREE.CylinderGeometry(0.026, 0.026, 0.06, 12), this.mats.copper)
    wastegate.rotation.z = Math.PI / 2
    wastegate.position.set(0.02, 0.11, 0.02)
    turboGroup.add(wastegate)
    this.group.add(turboGroup)

    const downpipe = [
      new THREE.Vector3(blockL * 0.3, blockY - 0.05, blockW * 0.9),
      new THREE.Vector3(blockL * 0.34, blockY + 0.02, blockW * 1.0),
      new THREE.Vector3(blockL * 0.4, blockY + 0.06, blockW * 1.08),
    ]
    const pipe = new THREE.Mesh(new THREE.TubeGeometry(new THREE.CatmullRomCurve3(downpipe), 16, 0.028, 8, false), this.mats.heat)
    this.group.add(pipe)

    if (this.config.parts.intercooler > 0) {
      const cooler = new THREE.Mesh(new THREE.BoxGeometry(0.32, 0.16, 0.07), this.mats.machined)
      cooler.position.set(blockL * 0.42, blockY + 0.14, -blockW * 1.0)
      cooler.rotation.y = 0.12
      cooler.castShadow = true
      this.group.add(cooler)
      for (let i = 0; i < 7; i += 1) {
        const fin = new THREE.Mesh(new THREE.BoxGeometry(0.3, 0.005, 0.008), this.mats.dark)
        fin.position.set(blockL * 0.42, blockY + 0.07 + i * 0.022, -blockW * 1.04)
        this.group.add(fin)
      }
    }

    if (this.config.induction === 'supercharger') {
      const blower = new THREE.Mesh(new THREE.BoxGeometry(0.34, 0.15, 0.22), this.mats.machined)
      blower.position.set(0, headY + 0.14, 0)
      blower.castShadow = true
      this.group.add(blower)
      const pulley = new THREE.Mesh(new THREE.CylinderGeometry(0.055, 0.055, 0.04, 20), this.mats.dark)
      pulley.rotation.z = Math.PI / 2
      pulley.position.set(0.18, headY + 0.14, 0)
      this.group.add(pulley)
    }
  }

  private buildBadge(coverY: number): void {
    this.badgeTexture = labelTexture(this.config.name.slice(0, 22), {
      width: 512, height: 128, background: '#1c2123', color: '#ffb23e', border: true, sub: `${this.spec.displacementL.toFixed(1)} L · ${this.config.induction === 'na' ? 'NA' : INDUCTIONS[this.config.induction].short}`,
    })
    const material = new THREE.MeshBasicMaterial({ map: this.badgeTexture })
    const badge = new THREE.Mesh(new THREE.PlaneGeometry(0.21, 0.052), material)
    badge.position.set(0, coverY + 0.042, -0.001)
    badge.rotation.x = -Math.PI / 2
    badge.rotation.z = Math.PI
    this.group.add(badge)
  }

  private buildRotary(): void {
    const rotors = this.layout.rotors
    const width = this.config.bore / 1000 * 0.62
    const radius = Math.max(0.13, this.config.stroke / 1000 * 1.75)
    const housingDepth = 0.095
    const totalLength = rotors * 0.18 + 0.14
    const shaft = new THREE.Mesh(new THREE.CylinderGeometry(0.022, 0.022, totalLength, 16), this.mats.machined)
    shaft.rotation.z = Math.PI / 2
    shaft.position.set(0, 0.18, 0)
    this.group.add(shaft)
    for (let i = 0; i < rotors; i += 1) {
      const x = (i - (rotors - 1) / 2) * 0.2
      const housing = new THREE.Group()
      const shell = new THREE.Mesh(new THREE.CylinderGeometry(radius, radius, housingDepth, 28), this.mats.cast)
      shell.rotation.z = Math.PI / 2
      shell.position.set(x, 0.18, 0)
      shell.castShadow = true
      housing.add(shell)
      const rim = new THREE.Mesh(new THREE.TorusGeometry(radius * 0.9, 0.012, 6, 26), this.mats.dark)
      rim.rotation.y = Math.PI / 2
      rim.position.set(x, 0.18, 0)
      housing.add(rim)
      const rotor = new THREE.Group()
      const triangle = new THREE.Shape()
      for (let p = 0; p < 3; p += 1) {
        const a = (p / 3) * Math.PI * 2 - Math.PI / 2
        const px = Math.cos(a) * radius * 0.68
        const py = Math.sin(a) * radius * 0.68
        if (p === 0) triangle.moveTo(px, py)
        else triangle.lineTo(px, py)
      }
      triangle.closePath()
      const rotorMesh = new THREE.Mesh(new THREE.ExtrudeGeometry(triangle, { depth: width, bevelEnabled: true, bevelSize: 0.008, bevelThickness: 0.008, bevelSegments: 2 }), this.mats.machined)
      rotorMesh.rotation.z = Math.PI / 2
      rotorMesh.rotation.x = Math.PI / 2
      rotorMesh.position.set(x - width / 2, 0.18, 0)
      rotor.add(rotorMesh)
      const apex = new THREE.Mesh(new THREE.TorusGeometry(radius * 0.15, 0.006, 4, 12), this.mats.dark)
      apex.rotation.y = Math.PI / 2
      apex.position.set(x, 0.18, 0)
      rotor.add(apex)
      housing.add(rotor)
      this.group.add(housing)
      this.rotorRigs.push({ housing, rotor, phase: i * 1.3 })
    }
    const intake = new THREE.Mesh(new THREE.BoxGeometry(0.16, 0.1, 0.2), this.mats.black)
    intake.position.set(0.02, 0.27, -radius * 0.9)
    this.group.add(intake)
    const exhaust = new THREE.Mesh(new THREE.TubeGeometry(new THREE.CatmullRomCurve3([
      new THREE.Vector3(0.14, 0.18, radius * 0.8),
      new THREE.Vector3(0.24, 0.08, radius * 1.1),
      new THREE.Vector3(0.34, 0.02, radius * 1.1),
    ]), 18, 0.025, 8, false), this.mats.heat)
    this.group.add(exhaust)
    this.cutMaterials.push(this.mats.cut)
    this.buildTurbo(0.34, radius * 2, 0.18, 0.3)
  }

  private buildAccessories(): void {
    if (this.layout.rotors > 0) return
    const blockW = Math.max(0.16, this.config.bore / 1000 * 1.7)
    const alternator = new THREE.Mesh(new THREE.CylinderGeometry(0.045, 0.045, 0.08, 16), this.mats.dark)
    alternator.rotation.z = Math.PI / 2
    alternator.position.set(this.spec.envelopeMm.length / 1000 * 0.36, 0.25, -blockW * 0.95)
    this.group.add(alternator)
    const oilFilter = new THREE.Mesh(new THREE.CylinderGeometry(0.035, 0.035, 0.08, 16), this.mats.black)
    oilFilter.position.set(-0.05, 0.14, blockW * 0.78)
    this.group.add(oilFilter)
    const dipstick = new THREE.Mesh(new THREE.CylinderGeometry(0.006, 0.006, 0.14, 8), this.mats.amber)
    dipstick.position.set(-0.12, 0.26, -blockW * 0.7)
    this.group.add(dipstick)
    // wiring loom
    const loom = new THREE.Mesh(new THREE.TubeGeometry(new THREE.CatmullRomCurve3([
      new THREE.Vector3(0.22, 0.18, blockW * 0.5),
      new THREE.Vector3(0.28, 0.24, blockW * 0.7),
      new THREE.Vector3(0.14, 0.32, blockW * 0.8),
    ]), 14, 0.008, 6, false), this.mats.rubber)
    this.group.add(loom)
  }

  setCutaway(on: boolean): void {
    this.cutaway = on
    for (const material of this.cutMaterials) {
      material.clippingPlanes = on ? [this.clipPlane] : []
      material.clipShadows = on
      material.needsUpdate = true
    }
  }

  update(rpm: number, load: number, dt: number, boost = 0): void {
    const visualRps = clamp(rpm / 60, 0, 8)
    this.angle += visualRps * Math.PI * 2 * dt
    if (this.crankshaft) this.crankshaft.rotation.x = this.angle
    const crankR = clamp(this.config.stroke / 1000 * 0.34, 0.024, 0.048)
    for (const rig of this.pistons) {
      const phase = this.angle + rig.phase * DEG
      const y = rig.baseY + crankR * Math.cos(phase)
      rig.piston.position.y = y
      const dz = crankR * Math.sin(phase)
      const length = Math.sqrt(Math.pow(rig.baseY - (this.config.stroke / 1000) * 0.3, 2) + 0.001)
      rig.rod.position.y = y - length / 2
      rig.rod.rotation.x = Math.atan2(dz, Math.max(0.001, y - (this.config.stroke / 1000) * 0.3)) * 0.4
    }
    const camAngle = this.angle * 0.5
    for (const cam of this.cams) cam.rotation.x = camAngle
    for (const valve of this.valves) {
      const phase = this.angle + valve.phase * DEG
      const intakeLift = Math.max(0, Math.sin(phase)) * 0.018 * clamp(load, 0, 1)
      const exhaustLift = Math.max(0, Math.sin(phase + Math.PI)) * 0.016 * clamp(load, 0, 1)
      valve.intake.position.y = valve.baseY + intakeLift
      valve.exhaust.position.y = valve.baseY + exhaustLift
    }
    this.turboSpin += (rpm / 60) * dt * (0.4 + boost * 0.12)
    if (this.turboWheel) this.turboWheel.rotation.x = this.turboSpin
    for (const rotor of this.rotorRigs) {
      rotor.rotor.rotation.x = this.angle * 1.5 + rotor.phase
    }
  }

  dispose(): void {
    const geometries = new Set<THREE.BufferGeometry>()
    const materials = new Set<THREE.Material>()
    this.group.traverse(object => {
      const mesh = object as THREE.Mesh
      if (mesh.geometry) geometries.add(mesh.geometry)
      const mats = Array.isArray(mesh.material) ? mesh.material : mesh.material ? [mesh.material] : []
      for (const material of mats) materials.add(material)
    })
    for (const geometry of geometries) geometry.dispose()
    for (const material of materials) material.dispose()
    this.badgeTexture?.dispose()
    this.group.clear()
  }
}
