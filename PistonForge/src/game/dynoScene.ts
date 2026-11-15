import * as THREE from 'three'
import type { MaterialSet } from './sceneKit'
import { boxMesh, disposeObject, labelTexture, setupLighting, signMesh } from './sceneKit'

export type DynoScene = {
  scene: THREE.Scene
  carY: number
  rollers: THREE.Object3D[]
  update: (dt: number, rollerSpeed: number) => void
  dispose: () => void
}

export function createDynoScene(materials: MaterialSet): DynoScene {
  const scene = new THREE.Scene()
  scene.background = new THREE.Color(0x080a0b)
  scene.fog = new THREE.FogExp2(0x080a0b, 0.04)
  setupLighting(scene, 'dyno')

  const floor = new THREE.Mesh(new THREE.PlaneGeometry(14, 12), materials.concrete)
  floor.rotation.x = -Math.PI / 2
  floor.receiveShadow = true
  scene.add(floor)

  const back = boxMesh(14, 5.5, 0.2, materials.wall, 0, 2.75, -5.9, false, true)
  scene.add(back)
  const left = boxMesh(0.2, 5.5, 12, materials.wall, -6.9, 2.75, 0, false, true)
  scene.add(left)
  const right = boxMesh(0.2, 5.5, 12, materials.wall, 6.9, 2.75, 0, false, true)
  scene.add(right)
  const ceiling = boxMesh(14, 0.16, 12, materials.steelDark, 0, 5.4, 0, false, true)
  scene.add(ceiling)

  // floor bed and roller frame
  const bed = boxMesh(4.4, 0.18, 5.4, materials.steelDark, 0, 0.09, -0.2)
  scene.add(bed)
  const hazardStrip = new THREE.Mesh(new THREE.PlaneGeometry(4.6, 0.35), materials.hazard)
  hazardStrip.rotation.x = -Math.PI / 2
  hazardStrip.position.set(0, 0.185, -2.85)
  scene.add(hazardStrip)

  const rollers: THREE.Object3D[] = []
  for (const z of [-1.75, -1.05]) {
    const roller = new THREE.Group()
    const drum = new THREE.Mesh(new THREE.CylinderGeometry(0.18, 0.18, 2.35, 28), materials.machined)
    drum.rotation.z = Math.PI / 2
    drum.castShadow = true
    roller.add(drum)
    for (let i = 0; i < 10; i += 1) {
      const groove = new THREE.Mesh(new THREE.TorusGeometry(0.181, 0.008, 4, 24, Math.PI), materials.steelDark)
      groove.rotation.y = Math.PI / 2
      groove.position.x = -1.0 + i * 0.22
      roller.add(groove)
    }
    roller.position.set(0, 0.28, z)
    scene.add(roller)
    rollers.push(roller)
    for (const x of [-1.28, 1.28]) {
      const bearing = boxMesh(0.18, 0.2, 0.3, materials.steel, x, 0.22, z)
      scene.add(bearing)
    }
  }

  for (const x of [-1.25, 1.25]) {
    const post = boxMesh(0.1, 0.4, 0.1, materials.steel, x, 0.2, 1.45)
    scene.add(post)
    const pad = boxMesh(0.22, 0.06, 0.22, materials.amber, x, 0.43, 1.45)
    scene.add(pad)
    const foot = boxMesh(0.5, 0.05, 0.5, materials.steelDark, x, 0.025, 1.45)
    scene.add(foot)
  }

  // straps
  const strapMat = new THREE.MeshStandardMaterial({ color: 0x243a2f, roughness: 0.9 })
  for (const [x, z, tx, tz] of [[-1.0, 1.2, -2.5, 2.4], [1.0, 1.2, 2.5, 2.4], [-1.0, -1.3, -2.5, -2.5], [1.0, -1.3, 2.5, -2.5]] as const) {
    const strap = new THREE.Mesh(new THREE.TubeGeometry(new THREE.CatmullRomCurve3([
      new THREE.Vector3(x, 0.35, z),
      new THREE.Vector3(x + (tx - x) * 0.3, 0.15, z + (tz - z) * 0.3),
      new THREE.Vector3(tx, 0.12, tz),
    ]), 14, 0.035, 6, false), strapMat)
    scene.add(strap)
    const anchor = boxMesh(0.3, 0.08, 0.3, materials.amber, tx, 0.04, tz)
    scene.add(anchor)
  }
  // tidy straps are handed to the scene and disposed with it
  scene.userData.strapMat = strapMat

  // extraction fan
  const fanGroup = new THREE.Group()
  fanGroup.position.set(0, 3.2, -5.6)
  const fanRing = new THREE.Mesh(new THREE.TorusGeometry(0.95, 0.12, 10, 36), materials.steelDark)
  fanGroup.add(fanRing)
  const fanBlades = new THREE.Group()
  for (let i = 0; i < 6; i += 1) {
    const blade = new THREE.Mesh(new THREE.BoxGeometry(0.85, 0.06, 0.42), materials.steel)
    blade.position.set(0.38, 0, 0)
    blade.rotation.z = (i / 6) * Math.PI * 2
    fanBlades.add(blade)
  }
  fanGroup.add(fanBlades)
  const guard = new THREE.Mesh(new THREE.TorusGeometry(0.8, 0.02, 4, 36), materials.steel)
  fanGroup.add(guard)
  scene.add(fanGroup)

  // monitor bank: cyan trace screens
  const screenMat = new THREE.MeshBasicMaterial({ color: 0x0b2420 })
  const screenGlow = new THREE.MeshBasicMaterial({ color: 0x65e3d3 })
  const screenGroup = new THREE.Group()
  for (let i = 0; i < 3; i += 1) {
    const housing = boxMesh(0.9, 0.6, 0.08, materials.steelDark, 0, 0, 0)
    housing.position.set(-1.2 + i * 1.1, 2.1, -5.55)
    screenGroup.add(housing)
    const screen = new THREE.Mesh(new THREE.PlaneGeometry(0.8, 0.5), screenMat)
    screen.position.set(-1.2 + i * 1.1, 2.1, -5.5)
    screenGroup.add(screen)
    for (let y = 0; y < 6; y += 1) {
      const trace = new THREE.Mesh(new THREE.PlaneGeometry(0.5 + Math.random() * 0.2, 0.003), screenGlow)
      trace.position.set(-1.2 + i * 1.1, 1.93 + y * 0.06, -5.49)
      screenGroup.add(trace)
    }
  }
  scene.add(screenGroup)

  // dyno control console
  const consoleBody = boxMesh(0.9, 1.0, 0.55, materials.steelDark, -3.1, 0.55, -3.0)
  scene.add(consoleBody)
  const consoleTop = boxMesh(0.95, 0.08, 0.6, materials.steel, -3.1, 1.08, -3.0)
  scene.add(consoleTop)

  const sign = signMesh('DYNO CELL 01', 3.6, 0.8, 3.7, 3.8, -5.82, 0, 'LOAD · SWEEP · LOG')
  scene.add(sign)
  const warning = signMesh('HOT EXHAUST', 2.2, 0.5, -4.4, 2.0, -5.82, 0)
  scene.add(warning)

  // extraction ducting
  const duct = new THREE.Mesh(new THREE.CylinderGeometry(0.34, 0.34, 2.2, 18, 1, true), materials.steel)
  duct.rotation.z = Math.PI / 2
  duct.position.set(2.4, 4.0, -5.2)
  scene.add(duct)

  // tool cart and extinguisher
  const cart = boxMesh(0.9, 0.8, 0.55, materials.amber, 3.3, 0.42, 1.7)
  scene.add(cart)
  const extinguisher = new THREE.Mesh(new THREE.CylinderGeometry(0.12, 0.12, 0.5, 14), new THREE.MeshStandardMaterial({ color: 0x8b1c16, roughness: 0.5, metalness: 0.2 }))
  extinguisher.position.set(4.1, 0.3, -4.5)
  scene.add(extinguisher)

  const tyreStack = new THREE.Mesh(new THREE.TorusGeometry(0.34, 0.14, 10, 26), materials.rubber)
  tyreStack.rotation.x = Math.PI / 2
  tyreStack.position.set(4.6, 0.16, 3.3)
  scene.add(tyreStack)

  const labelTex = labelTexture('PF-01', { width: 256, height: 80, background: '#151a1c', color: '#65e3d3', border: false })
  const labelPlane = new THREE.Mesh(new THREE.PlaneGeometry(0.7, 0.22), new THREE.MeshBasicMaterial({ map: labelTex }))
  labelPlane.position.set(3.3, 0.8, 1.98)
  scene.add(labelPlane)

  const update = (dt: number, rollerSpeed: number) => {
    for (const roller of rollers) roller.rotation.x += rollerSpeed * dt * 0.62
    fanBlades.rotation.z += dt * 2.2
  }

  const dispose = () => {
    disposeObject(scene)
    strapMat.dispose()
    screenMat.dispose()
    screenGlow.dispose()
    labelTex.dispose()
    scene.clear()
  }

  return { scene, carY: 0.46, rollers, update, dispose }
}
