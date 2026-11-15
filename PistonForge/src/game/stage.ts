import * as THREE from 'three'
import { bodyById } from '../sim/data'
import { engineSpec } from '../sim/engine'
import type { Build, EngineConfig } from '../sim/types'
import { CarModel } from './carModel'
import { createDynoScene, type DynoScene } from './dynoScene'
import { EngineModel } from './engineModel'
import { createSharedAssets, disposeShared, type SharedAssets } from './sceneKit'
import { createHandlingScene, createStripScene, type HandlingScene, type StripScene } from './stripScene'
import { createWorkshop, type Workshop } from './workshop'

export type StageView = 'title' | 'garage' | 'engine' | 'ecu' | 'dyno' | 'drag' | 'handling'
export type TreeState = 'idle' | 'amber1' | 'amber2' | 'amber3' | 'green'
export type Quality = 'low' | 'medium' | 'high'

export type StageMotion = {
  speed: number
  wheelspin: number
  steering: number
  squat: number
  roll: number
  pitch: number
  distance: number
  handlingProgress: number
  rollerSpeed: number
}

type CameraState = {
  target: THREE.Vector3
  theta: number
  phi: number
  radius: number
}

const clamp = (v: number, min: number, max: number) => Math.min(max, Math.max(min, v))

export class Stage {
  readonly renderer: THREE.WebGLRenderer
  readonly camera: THREE.PerspectiveCamera
  private readonly canvas: HTMLCanvasElement
  private readonly assets: SharedAssets
  private readonly workshop: Workshop
  private readonly dyno: DynoScene
  private readonly strip: StripScene
  private readonly handling: HandlingScene
  private activeScene: THREE.Scene
  private car: CarModel | null = null
  private engine: EngineModel | null = null
  private build: Build | null = null
  private view: StageView = 'title'
  private cutaway = true
  private readonly cam: CameraState = { target: new THREE.Vector3(0, 0.8, 0), theta: 0.65, phi: 1.2, radius: 8 }
  private readonly desired: CameraState = { target: new THREE.Vector3(0, 0.8, 0), theta: 0.65, phi: 1.2, radius: 8 }
  private snapCamera = true
  private rpm = 0
  private load = 0
  private boost = 0
  private motion: StageMotion = {
    speed: 0, wheelspin: 0, steering: 0, squat: 0, roll: 0, pitch: 0,
    distance: 0, handlingProgress: 0, rollerSpeed: 0,
  }
  private quality: Quality = 'high'
  private reducedMotion = false
  private mobile = false
  private dragging = false
  private readonly pointers = new Map<number, { x: number; y: number }>()
  private pinchDistance = 0
  private idleTime = 0
  private elapsed = 0
  private resizeObserver: ResizeObserver | null = null
  private disposed = false
  private readonly onPointerDown: (event: PointerEvent) => void
  private readonly onPointerMove: (event: PointerEvent) => void
  private readonly onPointerUp: (event: PointerEvent) => void
  private readonly onWheel: (event: WheelEvent) => void
  private readonly onContextMenu: (event: Event) => void
  private readonly onResize: () => void
  /** True between the browser taking the GPU context away and giving it back. */
  private contextLost = false
  private readonly onContextLost = (event: Event) => {
    // Without preventDefault the browser never restores the context.
    event.preventDefault()
    this.contextLost = true
  }
  private readonly onContextRestored = () => {
    // three.js re-uploads geometry and textures on the next draw; shadow maps need a nudge.
    this.contextLost = false
    this.renderer.shadowMap.needsUpdate = true
    this.onResize()
  }

  constructor(canvas: HTMLCanvasElement) {
    this.canvas = canvas
    this.renderer = new THREE.WebGLRenderer({
      canvas,
      antialias: true,
      powerPreference: 'high-performance',
      alpha: false,
      stencil: false,
    })
    this.renderer.setClearColor(0x0b0e10, 1)
    this.renderer.outputColorSpace = THREE.SRGBColorSpace
    this.renderer.toneMapping = THREE.ACESFilmicToneMapping
    this.renderer.toneMappingExposure = 1.08
    this.renderer.shadowMap.enabled = true
    this.renderer.shadowMap.type = THREE.PCFSoftShadowMap
    this.renderer.localClippingEnabled = true
    this.renderer.info.autoReset = true

    this.camera = new THREE.PerspectiveCamera(41, 1, 0.08, 480)
    this.assets = createSharedAssets(this.renderer)
    this.workshop = createWorkshop(this.assets.materials)
    this.dyno = createDynoScene(this.assets.materials)
    this.strip = createStripScene(this.assets.materials)
    this.handling = createHandlingScene(this.assets.materials)
    this.activeScene = this.workshop.scene
    for (const scene of [this.workshop.scene, this.dyno.scene, this.strip.scene, this.handling.scene]) {
      if (this.assets.envMap) scene.environment = this.assets.envMap
      ;(scene as THREE.Scene & { environmentIntensity?: number }).environmentIntensity = 0.7
    }

    this.onPointerDown = (event) => this.pointerDown(event)
    this.onPointerMove = (event) => this.pointerMove(event)
    this.onPointerUp = (event) => this.pointerUp(event)
    this.onWheel = (event) => this.wheel(event)
    this.onContextMenu = (event) => event.preventDefault()
    this.onResize = () => this.resize()
    canvas.addEventListener('pointerdown', this.onPointerDown)
    canvas.addEventListener('pointermove', this.onPointerMove)
    canvas.addEventListener('pointerup', this.onPointerUp)
    canvas.addEventListener('pointercancel', this.onPointerUp)
    canvas.addEventListener('wheel', this.onWheel, { passive: false })
    canvas.addEventListener('contextmenu', this.onContextMenu)
    window.addEventListener('resize', this.onResize)
    // Phones reclaim the GPU when the app sits in the background or memory runs short.
    canvas.addEventListener('webglcontextlost', this.onContextLost)
    canvas.addEventListener('webglcontextrestored', this.onContextRestored)
    if (typeof ResizeObserver !== 'undefined') {
      this.resizeObserver = new ResizeObserver(() => this.resize())
      this.resizeObserver.observe(canvas)
    }
    this.mobile = window.matchMedia('(max-width: 820px)').matches
    this.resize()
    this.setView('title')
  }

  setBuild(build: Build): void {
    this.build = build
    if (this.car) {
      this.car.group.removeFromParent()
      this.car.dispose()
      this.car = null
    }
    this.car = new CarModel(build)
    this.activeScene.add(this.car.group)
    this.setEngineDraft(build.engine)
    this.present()
  }

  setEngineDraft(config: EngineConfig): void {
    if (this.engine) {
      this.engine.group.removeFromParent()
      this.engine.dispose()
      this.engine = null
    }
    this.engine = new EngineModel(config)
    this.attachEngine()
    this.engine.setCutaway(this.cutaway && (this.view === 'engine' || this.view === 'ecu' || this.view === 'title'))
  }

  setAppearance(build: Build): void {
    this.build = build
    if (!this.car) return
    this.car.setPaint(build.paint.color, build.paint.finish)
    this.car.setStance(build.stance)
  }

  setView(view: StageView): void {
    const previous = this.view
    this.view = view
    this.activeScene = this.sceneFor(view)
    if (this.car) this.activeScene.add(this.car.group)
    this.attachEngine()
    this.present()
    this.applyPreset(true)
    if (previous !== view) this.idleTime = 0
    this.engine?.setCutaway(this.cutaway && (view === 'engine' || view === 'ecu' || view === 'title'))
  }

  setEngineCutaway(on: boolean): void {
    this.cutaway = on
    this.engine?.setCutaway(on && (this.view === 'engine' || this.view === 'ecu' || this.view === 'title'))
  }

  private sceneFor(view: StageView): THREE.Scene {
    if (view === 'dyno') return this.dyno.scene
    if (view === 'drag') return this.strip.scene
    if (view === 'handling') return this.handling.scene
    return this.workshop.scene
  }

  private attachEngine(): void {
    if (!this.engine) return
    const standView = this.view === 'engine' || this.view === 'ecu' || this.view === 'title'
    if (standView) {
      this.workshop.standMount.add(this.engine.group)
      this.engine.group.position.set(0, 0, 0)
      this.engine.group.rotation.set(0, 0, 0)
      this.engine.group.scale.setScalar(1)
      this.engine.group.visible = true
      return
    }
    if (!this.car || !this.build) return
    this.car.engineMount.add(this.engine.group)
    const spec = engineSpec(this.build.engine)
    const bay = bodyById(this.build.bodyId).bay
    const fit = Math.min(bay.length / spec.envelopeMm.length, bay.width / spec.envelopeMm.width, bay.height / spec.envelopeMm.height)
    this.engine.group.scale.setScalar(clamp(fit * 0.86, 0.42, 1))
    this.engine.group.position.set(0, 0, 0)
    this.engine.group.rotation.set(0, 0, 0)
    this.engine.group.visible = false
  }

  private present(): void {
    if (!this.car) return
    this.car.group.visible = this.view !== 'engine' && this.view !== 'ecu'
    if (this.view === 'engine' || this.view === 'ecu') {
      this.car.group.position.set(0, 0, 0)
      return
    }
    const progress = clamp(this.motion.handlingProgress, 0, 1)
    if (this.view === 'dyno') {
      this.car.group.position.set(0, this.dyno.carY, 0)
      this.car.group.rotation.set(0, 0, 0)
    } else if (this.view === 'drag') {
      this.car.group.position.set(0, 0.02, this.motion.distance)
      this.car.group.rotation.set(0, 0, 0)
    } else if (this.view === 'handling') {
      const point = this.handling.curve.getPointAt(progress)
      const tangent = this.handling.curve.getTangentAt(progress)
      this.car.group.position.set(point.x, 0.02, point.z)
      this.car.group.rotation.set(0, Math.atan2(tangent.x, tangent.z), 0)
    } else {
      this.car.group.position.set(0, 0, 0)
      this.car.group.rotation.set(0, 0, 0)
    }
  }

  private applyPreset(snap: boolean): void {
    const mobile = this.mobile
    let target = new THREE.Vector3(0, 0.75, 0)
    let radius = 6.4
    let theta = 0.62
    let phi = 1.16
    switch (this.view) {
      case 'title':
        target = new THREE.Vector3(0.35, 0.78, 0)
        radius = mobile ? 8.4 : 8.8
        theta = 0.7
        phi = 1.22
        break
      case 'garage':
        target = new THREE.Vector3(mobile ? 0 : -0.48, 0.72, 0)
        radius = mobile ? 6.6 : 7.3
        theta = 0.6
        phi = 1.17
        break
      case 'engine':
        target = new THREE.Vector3(2.4, 0.98, 0.95)
        radius = mobile ? 2.35 : 2.8
        theta = 0.78
        phi = 1.12
        break
      case 'ecu':
        target = new THREE.Vector3(2.4, 0.98, 0.95)
        radius = mobile ? 2.5 : 3.0
        theta = 0.82
        phi = 1.1
        break
      case 'dyno':
        target = new THREE.Vector3(mobile ? 0 : -0.48, 0.82, 0)
        radius = mobile ? 6.8 : 7.3
        theta = 0.63
        phi = 1.13
        break
      case 'drag':
        target = new THREE.Vector3(0, 0.68, 0)
        radius = mobile ? 7.4 : 8.2
        theta = 1.04
        phi = 1.14
        break
      case 'handling':
        target = new THREE.Vector3(0, 0.65, 0)
        radius = mobile ? 16 : 18
        theta = 0.68
        phi = 0.74
        break
    }
    this.desired.target.copy(target)
    this.desired.radius = radius
    this.desired.theta = theta
    this.desired.phi = phi
    if (snap) this.snapCamera = true
  }

  setRpm(rpm: number, load: number, boost = 0): void {
    this.rpm = clamp(rpm, 0, 10000)
    this.load = clamp(load, 0, 1)
    this.boost = Math.max(0, boost)
  }

  setMotion(next: Partial<StageMotion>): void {
    this.motion = { ...this.motion, ...next }
    if (this.view === 'drag' || this.view === 'dyno' || this.view === 'handling') this.present()
  }

  setTree(state: TreeState): void {
    this.strip.setTree(state)
  }

  setSmoke(amount: number): void {
    this.strip.setSmoke(amount)
  }

  setQuality(quality: Quality): void {
    this.quality = quality
    this.applyQuality()
  }

  setReducedMotion(reduced: boolean): void {
    this.reducedMotion = reduced
  }

  setMobile(mobile: boolean): void {
    this.mobile = mobile
    this.applyPreset(true)
  }

  private applyQuality(): void {
    const ratio = this.quality === 'high' ? 1.8 : this.quality === 'medium' ? 1.3 : 1
    this.renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, ratio))
    this.renderer.shadowMap.enabled = this.quality !== 'low'
    this.resize()
  }

  resize(): void {
    if (this.disposed) return
    const width = Math.max(1, this.canvas.clientWidth)
    const height = Math.max(1, this.canvas.clientHeight)
    this.renderer.setSize(width, height, false)
    const aspect = width / height
    this.camera.aspect = aspect
    this.camera.fov = height > width ? 47 : 41
    this.camera.updateProjectionMatrix()
    const mobile = window.matchMedia('(max-width: 820px)').matches
    if (mobile !== this.mobile) {
      this.mobile = mobile
      this.applyPreset(false)
    }
  }

  update(dt: number): void {
    this.elapsed += dt
    this.workshop.update(dt)
    this.dyno.update(dt, this.motion.rollerSpeed)
    this.strip.update(dt)
    if (this.car) {
      this.car.update(dt, {
        speed: this.motion.speed,
        wheelspin: this.motion.wheelspin,
        steer: this.motion.steering,
        squat: this.motion.squat,
        roll: this.motion.roll,
        pitch: this.motion.pitch,
      })
    }
    this.engine?.update(this.rpm, this.load, dt, this.boost)
    this.updateCamera(dt)
  }

  private updateCamera(dt: number): void {
    if (!this.car) return
    if (this.view === 'drag') {
      this.desired.target.set(this.car.group.position.x, this.car.group.position.y + 0.68, this.car.group.position.z)
      this.desired.radius = this.mobile ? 7.4 : 8.2
    } else if (this.view === 'handling') {
      this.desired.target.set(this.car.group.position.x, this.car.group.position.y + 0.65, this.car.group.position.z)
    } else if (this.view === 'dyno') {
      this.desired.target.set(this.mobile ? 0 : -0.8, this.dyno.carY + 0.36, 0)
    }

    if (!this.dragging) {
      this.idleTime += dt
      const orbitView = this.view === 'title' || this.view === 'garage'
      if (orbitView && !this.reducedMotion && this.idleTime > 3) {
        this.desired.theta += dt * (this.view === 'title' ? 0.055 : 0.025)
      }
    }

    if (this.snapCamera) {
      this.cam.target.copy(this.desired.target)
      this.cam.radius = this.desired.radius
      this.cam.theta = this.desired.theta
      this.cam.phi = this.desired.phi
      this.snapCamera = false
    } else {
      const follow = 1 - Math.exp(-dt * (this.view === 'drag' || this.view === 'handling' ? 4.5 : 6.5))
      this.cam.target.lerp(this.desired.target, follow)
      this.cam.radius += (this.desired.radius - this.cam.radius) * follow
      this.cam.theta += (this.desired.theta - this.cam.theta) * follow
      this.cam.phi += (this.desired.phi - this.cam.phi) * follow
    }

    const sinPhi = Math.sin(this.cam.phi)
    const position = new THREE.Vector3(
      this.cam.target.x + this.cam.radius * sinPhi * Math.sin(this.cam.theta),
      this.cam.target.y + this.cam.radius * Math.cos(this.cam.phi),
      this.cam.target.z + this.cam.radius * sinPhi * Math.cos(this.cam.theta),
    )
    if (!this.reducedMotion) {
      const intensity = this.view === 'dyno' ? this.rpm / 9000 : this.view === 'drag' ? this.motion.speed / 90 : 0
      const shake = intensity * 0.008
      position.x += Math.sin(this.elapsed * 47) * shake
      position.y += Math.cos(this.elapsed * 61) * shake * 0.6
    }
    this.camera.position.copy(position)
    this.camera.lookAt(this.cam.target)
  }

  render(): void {
    if (this.contextLost) return
    this.renderer.render(this.activeScene, this.camera)
  }

  private pointerDown(event: PointerEvent): void {
    this.canvas.setPointerCapture?.(event.pointerId)
    this.pointers.set(event.pointerId, { x: event.clientX, y: event.clientY })
    this.dragging = true
    this.idleTime = 0
    if (this.pointers.size === 2) {
      const [a, b] = [...this.pointers.values()]
      this.pinchDistance = Math.hypot(a.x - b.x, a.y - b.y)
    }
  }

  private pointerMove(event: PointerEvent): void {
    const previous = this.pointers.get(event.pointerId)
    if (!previous) return
    const dx = event.clientX - previous.x
    const dy = event.clientY - previous.y
    this.pointers.set(event.pointerId, { x: event.clientX, y: event.clientY })
    if (this.pointers.size >= 2) {
      const [a, b] = [...this.pointers.values()]
      const distance = Math.hypot(a.x - b.x, a.y - b.y)
      if (this.pinchDistance > 0) {
        const scale = this.pinchDistance / Math.max(1, distance)
        this.desired.radius = clamp(this.desired.radius * clamp(scale, 0.92, 1.08), 0.9, 32)
        this.cam.radius = this.desired.radius
      }
      this.pinchDistance = distance
      return
    }
    if (!this.dragging) return
    this.desired.theta -= dx * 0.0055
    this.desired.phi = clamp(this.desired.phi + dy * 0.0042, 0.28, 1.46)
    this.cam.theta = this.desired.theta
    this.cam.phi = this.desired.phi
  }

  private pointerUp(event: PointerEvent): void {
    this.pointers.delete(event.pointerId)
    if (this.pointers.size === 0) this.dragging = false
    this.pinchDistance = 0
    this.idleTime = 0
  }

  private wheel(event: WheelEvent): void {
    event.preventDefault()
    const factor = Math.exp(event.deltaY * 0.0011)
    this.desired.radius = clamp(this.desired.radius * factor, 0.9, 32)
    this.cam.radius = this.desired.radius
  }

  dispose(): void {
    this.disposed = true
    this.canvas.removeEventListener('pointerdown', this.onPointerDown)
    this.canvas.removeEventListener('pointermove', this.onPointerMove)
    this.canvas.removeEventListener('pointerup', this.onPointerUp)
    this.canvas.removeEventListener('pointercancel', this.onPointerUp)
    this.canvas.removeEventListener('wheel', this.onWheel)
    this.canvas.removeEventListener('contextmenu', this.onContextMenu)
    window.removeEventListener('resize', this.onResize)
    this.canvas.removeEventListener('webglcontextlost', this.onContextLost)
    this.canvas.removeEventListener('webglcontextrestored', this.onContextRestored)
    this.resizeObserver?.disconnect()
    this.car?.dispose()
    this.car = null
    this.engine?.dispose()
    this.engine = null
    this.workshop.dispose()
    this.dyno.dispose()
    this.strip.dispose()
    this.handling.dispose()
    disposeShared(this.assets)
    this.renderer.dispose()
  }
}
