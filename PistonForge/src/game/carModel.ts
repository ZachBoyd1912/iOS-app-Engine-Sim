import * as THREE from 'three'
import { bodyById } from '../sim/data'
import { wheelRadius } from '../sim/vehicle'
import type { Build, PaintFinish, WheelStyle } from '../sim/types'
import { labelTexture } from './sceneKit'

const clamp = (v: number, min: number, max: number) => Math.min(max, Math.max(min, v))

type CarMotion = {
  speed: number
  wheelspin?: number
  steer?: number
  squat?: number
  roll?: number
  pitch?: number
}

type BodyProfile = {
  noseY: number
  hoodFrontY: number
  hoodBackY: number
  windshieldX: number
  roofFrontX: number
  roofRearX: number
  roofY: number
  rearGlassX: number
  deckY: number
  tailY: number
  cabinWidth: number
}

const PROFILES: Record<string, BodyProfile> = {
  kei: { noseY: 0.27, hoodFrontY: 0.46, hoodBackY: 0.52, windshieldX: 0.24, roofFrontX: 0.18, roofRearX: -0.38, roofY: 1.0, rearGlassX: -0.44, deckY: 0.6, tailY: 0.55, cabinWidth: 0.8 },
  hotHatch: { noseY: 0.24, hoodFrontY: 0.4, hoodBackY: 0.46, windshieldX: 0.2, roofFrontX: 0.1, roofRearX: -0.36, roofY: 0.98, rearGlassX: -0.43, deckY: 0.6, tailY: 0.54, cabinWidth: 0.82 },
  sedan: { noseY: 0.24, hoodFrontY: 0.36, hoodBackY: 0.41, windshieldX: 0.14, roofFrontX: 0.02, roofRearX: -0.28, roofY: 0.98, rearGlassX: -0.39, deckY: 0.46, tailY: 0.42, cabinWidth: 0.82 },
  coupe: { noseY: 0.22, hoodFrontY: 0.33, hoodBackY: 0.38, windshieldX: 0.17, roofFrontX: 0.02, roofRearX: -0.32, roofY: 0.9, rearGlassX: -0.44, deckY: 0.42, tailY: 0.37, cabinWidth: 0.78 },
  muscle: { noseY: 0.25, hoodFrontY: 0.4, hoodBackY: 0.45, windshieldX: 0.1, roofFrontX: 0.0, roofRearX: -0.26, roofY: 0.92, rearGlassX: -0.37, deckY: 0.44, tailY: 0.4, cabinWidth: 0.82 },
  supercar: { noseY: 0.19, hoodFrontY: 0.28, hoodBackY: 0.31, windshieldX: 0.23, roofFrontX: 0.05, roofRearX: -0.23, roofY: 0.76, rearGlassX: -0.37, deckY: 0.35, tailY: 0.34, cabinWidth: 0.72 },
  pickup: { noseY: 0.26, hoodFrontY: 0.45, hoodBackY: 0.5, windshieldX: 0.12, roofFrontX: 0.02, roofRearX: -0.26, roofY: 1.0, rearGlassX: -0.3, deckY: 0.52, tailY: 0.52, cabinWidth: 0.84 },
  van: { noseY: 0.3, hoodFrontY: 0.48, hoodBackY: 0.53, windshieldX: 0.33, roofFrontX: 0.27, roofRearX: -0.46, roofY: 1.0, rearGlassX: -0.48, deckY: 0.95, tailY: 0.95, cabinWidth: 0.9 },
  offroader: { noseY: 0.26, hoodFrontY: 0.44, hoodBackY: 0.5, windshieldX: 0.2, roofFrontX: 0.12, roofRearX: -0.41, roofY: 1.0, rearGlassX: -0.45, deckY: 0.6, tailY: 0.58, cabinWidth: 0.88 },
}

type ModelMats = {
  paint: THREE.MeshPhysicalMaterial
  trim: THREE.MeshStandardMaterial
  rubber: THREE.MeshStandardMaterial
  glass: THREE.MeshPhysicalMaterial
  chrome: THREE.MeshStandardMaterial
  rim: THREE.MeshStandardMaterial
  brake: THREE.MeshStandardMaterial
  light: THREE.MeshBasicMaterial
  tail: THREE.MeshBasicMaterial
  amber: THREE.MeshStandardMaterial
  dark: THREE.MeshStandardMaterial
  interior: THREE.MeshStandardMaterial
  plate: THREE.MeshBasicMaterial
}

export class CarModel {
  readonly group = new THREE.Group()
  readonly bodyGroup = new THREE.Group()
  readonly engineMount = new THREE.Object3D()
  private readonly build: Build
  private readonly body = bodyById('kei')
  private readonly mats: ModelMats
  private wheels: { steer: THREE.Group; spin: THREE.Group; front: boolean }[] = []
  private wheelRadius = 0.32
  private baseBodyY = 0
  private plateTexture: THREE.Texture | null = null

  constructor(build: Build) {
    this.build = build
    this.body = bodyById(build.bodyId)
    this.mats = this.makeMaterials(build)
    this.wheelRadius = wheelRadius(build)
    this.group.name = `car-${build.bodyId}`
    this.bodyGroup.name = 'body'
    this.group.add(this.bodyGroup)
    this.buildBody()
    this.buildWheels()
    this.buildDetails()
    this.buildInterior()
    this.placeEngineMount()
    this.baseBodyY = 0.015 - build.stance * 0.038
    this.bodyGroup.position.y = this.baseBodyY
    // The body is authored with its length along +X; the gameplay root drives along +Z.
    const visual = new THREE.Group()
    visual.name = 'vehicle-visual'
    visual.rotation.y = -Math.PI / 2
    for (const child of [...this.group.children]) visual.add(child)
    this.group.add(visual)
  }

  private makeMaterials(build: Build): ModelMats {
    const finish = build.paint.finish
    const paint = new THREE.MeshPhysicalMaterial({
      color: new THREE.Color(build.paint.color),
      metalness: finish === 'metallic' ? 0.82 : finish === 'matte' ? 0.22 : 0.5,
      roughness: finish === 'matte' ? 0.72 : finish === 'satin' ? 0.38 : 0.24,
      clearcoat: finish === 'matte' ? 0.05 : finish === 'satin' ? 0.45 : 1,
      clearcoatRoughness: finish === 'metallic' ? 0.16 : 0.08,
      envMapIntensity: 1.25,
    })
    return {
      paint,
      trim: new THREE.MeshStandardMaterial({ color: 0x111416, roughness: 0.72, metalness: 0.18 }),
      rubber: new THREE.MeshStandardMaterial({ color: 0x0d0f10, roughness: 0.94 }),
      glass: new THREE.MeshPhysicalMaterial({ color: 0x0b1418, metalness: 0.1, roughness: 0.04, clearcoat: 1, transparent: true, opacity: 0.88, side: THREE.DoubleSide, envMapIntensity: 1.8 }),
      chrome: new THREE.MeshStandardMaterial({ color: 0xb8c0c2, roughness: 0.18, metalness: 0.95 }),
      rim: new THREE.MeshStandardMaterial({
        color: build.wheels.style === 'steel' ? 0x333a3c : build.wheels.style === 'split' ? 0xa88544 : 0x9da6a8,
        roughness: build.wheels.style === 'steel' ? 0.55 : 0.26,
        metalness: 0.85,
      }),
      brake: new THREE.MeshStandardMaterial({ color: 0x525b5e, roughness: 0.4, metalness: 0.75 }),
      light: new THREE.MeshBasicMaterial({ color: 0xfff1d1, toneMapped: false }),
      tail: new THREE.MeshBasicMaterial({ color: 0xff4438, toneMapped: false }),
      amber: new THREE.MeshStandardMaterial({ color: 0xffb23e, emissive: 0xff7a1a, emissiveIntensity: 0.5, roughness: 0.35 }),
      dark: new THREE.MeshStandardMaterial({ color: 0x15191a, roughness: 0.76 }),
      interior: new THREE.MeshStandardMaterial({ color: 0x1a1c1d, roughness: 0.9 }),
      plate: new THREE.MeshBasicMaterial({ map: (() => { this.plateTexture = labelTexture('PISTON FORGE', { background: '#d8d0b8', color: '#141718', border: false, width: 256, height: 64 }); return this.plateTexture })() }),
    }
  }

  private buildBody(): void {
    const p = PROFILES[this.body.id] ?? PROFILES.hotHatch
    const L = this.body.length
    const H = this.body.height
    const W = this.body.width
    const wb = this.body.wheelbase
    const r = this.wheelRadius
    const bottom = clamp(r * 0.8, 0.13, H * 0.22)
    const archR = r * 1.08
    const shape = new THREE.Shape()
    const xRear = -L / 2
    const xFront = L / 2

    shape.moveTo(xRear, bottom)
    shape.lineTo(-wb / 2 - archR, bottom)
    shape.absarc(-wb / 2, bottom, archR, Math.PI, 0, true)
    shape.lineTo(wb / 2 - archR, bottom)
    shape.absarc(wb / 2, bottom, archR, Math.PI, 0, true)
    shape.lineTo(xFront, bottom)
    shape.lineTo(xFront, H * 0.2)
    shape.quadraticCurveTo(xFront, H * p.noseY, xFront - L * 0.04, H * p.noseY)
    shape.lineTo(L * 0.38, H * p.hoodFrontY)
    shape.quadraticCurveTo(L * 0.24, H * p.hoodBackY, L * p.windshieldX, H * p.hoodBackY)
    shape.quadraticCurveTo(L * (p.windshieldX + 0.02), H * p.roofY, L * p.roofFrontX, H * p.roofY)
    shape.lineTo(L * p.roofRearX, H * p.roofY)
    shape.quadraticCurveTo(L * (p.roofRearX - 0.03), H * p.roofY, L * p.rearGlassX, H * p.deckY)
    shape.lineTo(-L * 0.4, H * p.deckY)
    shape.quadraticCurveTo(-L * 0.47, H * p.tailY, xRear + L * 0.015, H * p.tailY)
    shape.lineTo(xRear, H * 0.21)
    shape.closePath()

    const geometry = new THREE.ExtrudeGeometry(shape, {
      depth: W * 0.94,
      bevelEnabled: true,
      bevelSegments: 3,
      bevelSize: 0.035,
      bevelThickness: 0.035,
      curveSegments: 20,
    })
    geometry.translate(0, 0, -W * 0.47)
    const bodyMesh = new THREE.Mesh(geometry, this.mats.paint)
    bodyMesh.castShadow = true
    bodyMesh.receiveShadow = true
    this.bodyGroup.add(bodyMesh)

    // rocker / sill, adds a planted lower edge between the arches
    const sill = new THREE.Mesh(new THREE.BoxGeometry(wb - archR * 1.2, 0.09, W * 0.98), this.mats.trim)
    sill.position.set(0, bottom + 0.015, 0)
    sill.castShadow = true
    this.bodyGroup.add(sill)

    // wheel-arch flares
    for (const x of [-wb / 2, wb / 2]) {
      for (const z of [-W / 2 + 0.02, W / 2 - 0.02]) {
        const arch = new THREE.Mesh(new THREE.TorusGeometry(archR, 0.036, 6, 24, Math.PI), this.mats.trim)
        arch.position.set(x, bottom, z)
        arch.castShadow = true
        arch.rotation.z = 0
        this.bodyGroup.add(arch)
      }
    }

    // window openings
    const windowShape = new THREE.Shape()
    const belt = H * p.hoodBackY + 0.04
    windowShape.moveTo(L * p.windshieldX * 0.97, belt)
    windowShape.lineTo(L * p.roofFrontX, H * p.roofY - 0.035)
    windowShape.lineTo(L * p.roofRearX, H * p.roofY - 0.035)
    windowShape.lineTo(L * p.rearGlassX * 0.96, H * p.deckY + 0.035)
    windowShape.closePath()
    const windowGeometry = new THREE.ExtrudeGeometry(windowShape, { depth: 0.012, bevelEnabled: false })
    for (const side of [-1, 1]) {
      const windowMesh = new THREE.Mesh(windowGeometry, this.mats.glass)
      windowMesh.position.set(0, 0, side * (W / 2 - 0.012))
      windowMesh.scale.z = side
      this.bodyGroup.add(windowMesh)
    }

    // windshield and rear glass
    this.bodyGroup.add(this.glassQuad(
      new THREE.Vector3(L * (p.windshieldX * 0.96), belt, -W * 0.4),
      new THREE.Vector3(L * (p.windshieldX * 0.96), belt, W * 0.4),
      new THREE.Vector3(L * p.roofFrontX, H * p.roofY - 0.02, W * 0.37),
      new THREE.Vector3(L * p.roofFrontX, H * p.roofY - 0.02, -W * 0.37),
    ))
    this.bodyGroup.add(this.glassQuad(
      new THREE.Vector3(L * p.roofRearX, H * p.roofY - 0.02, -W * 0.37),
      new THREE.Vector3(L * p.roofRearX, H * p.roofY - 0.02, W * 0.37),
      new THREE.Vector3(L * p.rearGlassX * 0.96, H * p.deckY + 0.04, W * 0.38),
      new THREE.Vector3(L * p.rearGlassX * 0.96, H * p.deckY + 0.04, -W * 0.38),
    ))

    // B-pillars
    for (const side of [-1, 1]) {
      const pillar = new THREE.Mesh(new THREE.BoxGeometry(0.055, H * 0.26, 0.02), this.mats.trim)
      pillar.position.set(L * (p.roofFrontX + p.roofRearX) / 2, H * (p.roofY + p.hoodBackY) / 2 + 0.02, side * (W / 2 - 0.002))
      this.bodyGroup.add(pillar)
    }

    if (this.body.id === 'pickup') {
      const bedLength = L * 0.34
      for (const side of [-1, 1]) {
        const wall = new THREE.Mesh(new THREE.BoxGeometry(bedLength, H * 0.11, 0.07), this.mats.paint)
        wall.position.set(-L * 0.33, H * 0.57, side * W * 0.42)
        this.bodyGroup.add(wall)
      }
      const tailgate = new THREE.Mesh(new THREE.BoxGeometry(0.06, H * 0.12, W * 0.82), this.mats.paint)
      tailgate.position.set(-L * 0.48, H * 0.57, 0)
      this.bodyGroup.add(tailgate)
    }
  }

  private glassQuad(a: THREE.Vector3, b: THREE.Vector3, c: THREE.Vector3, d: THREE.Vector3): THREE.Mesh {
    const geometry = new THREE.BufferGeometry()
    const vertices = new Float32Array([
      a.x, a.y, a.z, b.x, b.y, b.z, c.x, c.y, c.z,
      a.x, a.y, a.z, c.x, c.y, c.z, d.x, d.y, d.z,
    ])
    geometry.setAttribute('position', new THREE.BufferAttribute(vertices, 3))
    geometry.computeVertexNormals()
    const mesh = new THREE.Mesh(geometry, this.mats.glass)
    return mesh
  }

  private buildWheels(): void {
    const wb = this.body.wheelbase
    const track = this.body.track
    const r = this.wheelRadius
    const sizeFactor = 1 + (this.build.wheels.size - 17) * 0.012
    const width = clamp(0.2 + this.build.wheels.size * 0.006, 0.18, 0.34)

    for (const front of [true, false]) {
      for (const side of [-1, 1]) {
        const steer = new THREE.Group()
        steer.position.set(front ? wb / 2 : -wb / 2, r, side * track / 2)
        const spin = new THREE.Group()
        steer.add(spin)
        this.group.add(steer)

        const tire = new THREE.Mesh(new THREE.CylinderGeometry(r * sizeFactor, r * sizeFactor, width, 26), this.mats.rubber)
        tire.rotation.x = Math.PI / 2
        tire.castShadow = true
        tire.receiveShadow = true
        spin.add(tire)

        for (const zSide of [-1, 1]) {
          const sidewall = new THREE.Mesh(new THREE.TorusGeometry(r * sizeFactor * 0.88, 0.018, 6, 26), this.mats.rubber)
          sidewall.position.z = zSide * width / 2
          spin.add(sidewall)
        }

        const rim = new THREE.Mesh(new THREE.CylinderGeometry(r * 0.64, r * 0.64, width * 0.78, 26), this.mats.rim)
        rim.rotation.x = Math.PI / 2
        rim.position.z = 0.005
        spin.add(rim)

        const hub = new THREE.Mesh(new THREE.CylinderGeometry(r * 0.16, r * 0.16, width * 1.02, 16), this.mats.chrome)
        hub.rotation.x = Math.PI / 2
        spin.add(hub)

        const disc = new THREE.Mesh(new THREE.CylinderGeometry(r * 0.55, r * 0.55, 0.028, 26), this.mats.brake)
        disc.rotation.x = Math.PI / 2
        disc.position.z = -0.02
        spin.add(disc)

        const caliper = new THREE.Mesh(new THREE.BoxGeometry(r * 0.2, r * 0.42, 0.07), this.mats.amber)
        caliper.position.set(r * 0.27, 0, -0.02)
        spin.add(caliper)

        const spokeCount = this.build.wheels.style === 'split' ? 5 : this.build.wheels.style === 'mesh' ? 10 : this.build.wheels.style === 'steel' ? 0 : 7
        for (let i = 0; i < spokeCount; i += 1) {
          const angle = (i / spokeCount) * Math.PI * 2
          const spoke = new THREE.Mesh(new THREE.BoxGeometry(r * 0.5, this.build.wheels.style === 'split' ? 0.075 : 0.04, 0.055), this.mats.rim)
          spoke.position.set(Math.cos(angle) * r * 0.36, Math.sin(angle) * r * 0.36, this.build.wheels.style === 'turbofan' ? 0.085 : 0.06)
          spoke.rotation.z = angle
          spin.add(spoke)
        }
        if (this.build.wheels.style === 'steel') {
          const cover = new THREE.Mesh(new THREE.CylinderGeometry(r * 0.62, r * 0.62, 0.02, 26), this.mats.rim)
          cover.rotation.x = Math.PI / 2
          cover.position.z = 0.1
          spin.add(cover)
          const dark = new THREE.Mesh(new THREE.CylinderGeometry(r * 0.45, r * 0.45, 0.012, 16), this.mats.dark)
          dark.rotation.x = Math.PI / 2
          dark.position.z = 0.112
          spin.add(dark)
        }
        this.wheels.push({ steer, spin, front })
      }
    }
  }

  private buildDetails(): void {
    const L = this.body.length
    const W = this.body.width
    const H = this.body.height
    const p = PROFILES[this.body.id] ?? PROFILES.hotHatch
    const bottom = clamp(this.wheelRadius * 0.8, 0.13, H * 0.22)

    const frontBumper = new THREE.Mesh(new THREE.BoxGeometry(L * 0.08, H * 0.15, W * 0.94), this.mats.trim)
    frontBumper.position.set(L * 0.47, bottom + H * 0.06, 0)
    this.bodyGroup.add(frontBumper)
    const rearBumper = new THREE.Mesh(new THREE.BoxGeometry(L * 0.06, H * 0.14, W * 0.94), this.mats.trim)
    rearBumper.position.set(-L * 0.48, bottom + H * 0.06, 0)
    this.bodyGroup.add(rearBumper)

    const grille = new THREE.Mesh(new THREE.BoxGeometry(0.03, H * 0.09, W * 0.36), this.mats.dark)
    grille.position.set(L * 0.505, H * 0.22, 0)
    this.bodyGroup.add(grille)
    for (let i = 0; i < 3; i += 1) {
      const slat = new THREE.Mesh(new THREE.BoxGeometry(0.012, 0.012, W * 0.33), this.mats.chrome)
      slat.position.set(L * 0.522, H * 0.2 + i * 0.022, 0)
      this.bodyGroup.add(slat)
    }

    for (const side of [-1, 1]) {
      const headlight = new THREE.Mesh(new THREE.BoxGeometry(0.035, H * 0.055, W * 0.16), this.mats.light)
      headlight.position.set(L * 0.5, H * 0.27, side * W * 0.31)
      headlight.rotation.z = side * 0.03
      this.bodyGroup.add(headlight)
      const tail = new THREE.Mesh(new THREE.BoxGeometry(0.025, H * 0.045, W * 0.19), this.mats.tail)
      tail.position.set(-L * 0.5, H * 0.24, side * W * 0.31)
      this.bodyGroup.add(tail)
      const mirror = new THREE.Mesh(new THREE.BoxGeometry(0.08, 0.045, 0.12), this.mats.paint)
      mirror.position.set(L * (p.windshieldX - 0.02), H * p.hoodBackY + 0.04, side * W * 0.54)
      this.bodyGroup.add(mirror)
    }

    const plate = new THREE.Mesh(new THREE.PlaneGeometry(0.34, 0.09), this.mats.plate)
    plate.position.set(-L * 0.5 - 0.01, H * 0.17, 0)
    plate.rotation.y = -Math.PI / 2
    this.bodyGroup.add(plate)

    const exhaustCount = this.body.drivetrain === 'AWD' ? 2 : 1
    for (let i = 0; i < exhaustCount; i += 1) {
      const exhaust = new THREE.Mesh(new THREE.CylinderGeometry(0.045, 0.052, 0.22, 14, 1, true), this.mats.chrome)
      exhaust.rotation.z = Math.PI / 2
      exhaust.position.set(-L * 0.5 - 0.05, H * 0.14, (i - (exhaustCount - 1) / 2) * 0.22)
      this.bodyGroup.add(exhaust)
    }

    // aero package
    if (this.build.aero === 'lip' || this.build.aero === 'full') {
      const lip = new THREE.Mesh(new THREE.BoxGeometry(L * 0.12, 0.035, W * 0.96), this.mats.dark)
      lip.position.set(L * 0.46, bottom - 0.01, 0)
      this.bodyGroup.add(lip)
    }
    if (this.build.aero === 'wing' || this.build.aero === 'full') {
      const wing = new THREE.Mesh(new THREE.BoxGeometry(L * 0.055, 0.035, W * 0.78), this.mats.dark)
      wing.position.set(-L * 0.43, H * 0.68, 0)
      wing.rotation.z = this.build.aero === 'full' ? -0.12 : -0.07
      this.bodyGroup.add(wing)
      for (const side of [-1, 1]) {
        const support = new THREE.Mesh(new THREE.BoxGeometry(0.035, H * 0.18, 0.05), this.mats.dark)
        support.position.set(-L * 0.42, H * 0.58, side * W * 0.24)
        this.bodyGroup.add(support)
      }
    }
    if (this.build.aero === 'full') {
      const splitter = new THREE.Mesh(new THREE.BoxGeometry(L * 0.14, 0.028, W * 0.98), this.mats.dark)
      splitter.position.set(L * 0.47, bottom - 0.025, 0)
      this.bodyGroup.add(splitter)
      const diffuser = new THREE.Mesh(new THREE.BoxGeometry(L * 0.1, 0.035, W * 0.8), this.mats.dark)
      diffuser.position.set(-L * 0.47, bottom - 0.01, 0)
      diffuser.rotation.z = 0.12
      this.bodyGroup.add(diffuser)
    }
  }

  private buildInterior(): void {
    const L = this.body.length
    const W = this.body.width
    const H = this.body.height
    const seats = this.build.interior === 'stripped' ? 1 : 2
    for (let i = 0; i < seats; i += 1) {
      const z = (i - (seats - 1) / 2) * W * 0.26
      const seat = new THREE.Mesh(new THREE.BoxGeometry(0.34, 0.12, W * 0.2), this.mats.interior)
      seat.position.set(-L * 0.02, H * 0.34, z)
      this.bodyGroup.add(seat)
      const back = new THREE.Mesh(new THREE.BoxGeometry(0.12, H * 0.22, W * 0.2), this.mats.interior)
      back.position.set(-L * 0.1, H * 0.42, z)
      back.rotation.z = -0.15
      this.bodyGroup.add(back)
    }
    const dash = new THREE.Mesh(new THREE.BoxGeometry(0.16, H * 0.08, W * 0.65), this.mats.dark)
    dash.position.set(L * 0.18, H * 0.43, 0)
    this.bodyGroup.add(dash)
    const wheel = new THREE.Mesh(new THREE.TorusGeometry(0.13, 0.018, 6, 16), this.mats.dark)
    wheel.position.set(L * 0.08, H * 0.43, -W * 0.2)
    wheel.rotation.y = Math.PI / 2
    this.bodyGroup.add(wheel)

    if (this.build.interior === 'stripped') {
      for (const side of [-1, 1]) {
        const bar = new THREE.Mesh(new THREE.CylinderGeometry(0.018, 0.018, H * 0.38, 8), this.mats.amber)
        bar.rotation.z = 0.19
        bar.position.set(-L * 0.08, H * 0.52, side * W * 0.36)
        this.bodyGroup.add(bar)
      }
      const cross = new THREE.Mesh(new THREE.CylinderGeometry(0.018, 0.018, W * 0.72, 8), this.mats.amber)
      cross.rotation.x = Math.PI / 2
      cross.position.set(-L * 0.12, H * 0.7, 0)
      this.bodyGroup.add(cross)
    }
  }

  private placeEngineMount(): void {
    const front = this.body.enginePosition === 'front'
    const L = this.body.length
    const H = this.body.height
    this.engineMount.position.set(front ? L * 0.29 : -L * 0.08, H * 0.16, 0)
    this.engineMount.name = 'engine-mount'
    this.group.add(this.engineMount)
  }

  setPaint(color: string, finish: PaintFinish): void {
    this.mats.paint.color.set(color)
    this.mats.paint.metalness = finish === 'metallic' ? 0.82 : finish === 'matte' ? 0.22 : 0.5
    this.mats.paint.roughness = finish === 'matte' ? 0.72 : finish === 'satin' ? 0.38 : 0.24
    this.mats.paint.clearcoat = finish === 'matte' ? 0.05 : finish === 'satin' ? 0.45 : 1
    this.mats.paint.needsUpdate = true
  }

  setStance(stance: number): void {
    this.baseBodyY = 0.015 - clamp(stance, -1, 1) * 0.038
    this.bodyGroup.position.y = this.baseBodyY
  }

  setWheelStyle(style: WheelStyle): void {
    this.mats.rim.color.set(style === 'steel' ? 0x333a3c : style === 'split' ? 0xa88544 : 0x9da6a8)
    this.mats.rim.roughness = style === 'steel' ? 0.55 : 0.26
    this.mats.rim.metalness = 0.85
  }

  setSquat(amount: number): void {
    this.bodyGroup.position.y = this.baseBodyY - clamp(amount, 0, 1) * 0.035
  }

  setSteer(angle: number): void {
    for (const wheel of this.wheels) {
      if (wheel.front) wheel.steer.rotation.y = angle
    }
  }

  setRoll(amount: number): void {
    this.bodyGroup.rotation.x = clamp(amount, -0.12, 0.12)
  }

  setPitch(amount: number): void {
    this.bodyGroup.rotation.z = clamp(amount, -0.08, 0.08)
  }

  setBrakeLights(on: boolean): void {
    this.mats.tail.color.set(on ? 0xff1f15 : 0x7a1a15)
  }

  update(dt: number, motion: CarMotion): void {
    const spinRate = (motion.speed / Math.max(0.1, this.wheelRadius)) + (motion.wheelspin ?? 0) * 45
    for (const wheel of this.wheels) {
      wheel.spin.rotation.z -= spinRate * dt
    }
    this.setSteer(motion.steer ?? 0)
    this.setSquat(motion.squat ?? 0)
    this.setRoll(motion.roll ?? 0)
    this.setPitch(motion.pitch ?? 0)
  }

  get paintColor(): string {
    return this.build.paint.color
  }

  dispose(): void {
    this.group.traverse(object => {
      const mesh = object as THREE.Mesh
      mesh.geometry?.dispose()
    })
    for (const material of Object.values(this.mats)) material.dispose()
    this.plateTexture?.dispose()
    this.group.clear()
  }
}
