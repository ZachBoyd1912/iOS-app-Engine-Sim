import * as THREE from 'three'
import type { MaterialSet } from './sceneKit'
import { boxMesh, disposeObject, labelTexture, makeParticles, setupLighting, signMesh, updateParticles } from './sceneKit'

export type Workshop = {
  scene: THREE.Scene
  standMount: THREE.Object3D
  update: (dt: number) => void
  dispose: () => void
}

export function createWorkshop(materials: MaterialSet): Workshop {
  const scene = new THREE.Scene()
  scene.background = new THREE.Color(0x090c0d)
  scene.fog = new THREE.FogExp2(0x090c0d, 0.022)
  setupLighting(scene, 'workshop')

  const floor = new THREE.Mesh(new THREE.PlaneGeometry(24, 18, 1, 1), materials.concrete)
  floor.rotation.x = -Math.PI / 2
  floor.receiveShadow = true
  scene.add(floor)

  // room shell
  const backWall = boxMesh(24, 6, 0.25, materials.wall, 0, 3, -8.8, false, true)
  scene.add(backWall)
  const leftWall = boxMesh(0.25, 6, 18, materials.wall, -11.8, 3, 0, false, true)
  scene.add(leftWall)
  const rightWall = boxMesh(0.25, 6, 18, materials.wall, 11.8, 3, 0, false, true)
  scene.add(rightWall)
  const ceiling = boxMesh(24, 0.22, 18, materials.steelDark, 0, 6.1, 0, false, true)
  scene.add(ceiling)

  // roof trusses
  for (let z = -7.5; z <= 7.5; z += 2.5) {
    const truss = boxMesh(23, 0.12, 0.12, materials.steel, 0, 5.3, z)
    scene.add(truss)
    for (const x of [-5.5, 0, 5.5]) {
      const drop = boxMesh(0.08, 0.9, 0.08, materials.steel, x, 5.75, z)
      scene.add(drop)
    }
  }

  // practical lights: fluorescent bars with real point lights already supplied by setupLighting
  for (const x of [-6.5, 0, 6.5]) {
    for (const z of [-3.5, 3.5]) {
      const housing = boxMesh(2.4, 0.07, 0.16, materials.steelDark, x, 4.85, z)
      scene.add(housing)
      const tube = boxMesh(2.32, 0.025, 0.1, materials.whiteGlow, x, 4.8, z, false, false)
      scene.add(tube)
    }
  }

  // roller shutter door
  const door = boxMesh(6.2, 4.5, 0.08, materials.steel, -4.2, 2.3, -8.62)
  scene.add(door)
  for (let i = 0; i < 18; i += 1) {
    const rib = boxMesh(6.15, 0.035, 0.04, materials.steelDark, -4.2, 0.18 + i * 0.24, -8.56, false, false)
    scene.add(rib)
  }
  const doorFrame = boxMesh(6.6, 4.9, 0.2, materials.steelDark, -4.2, 2.5, -8.7)
  scene.add(doorFrame)
  doorFrame.position.z = -8.75

  // high windows with dusk glow
  const windowMat = new THREE.MeshBasicMaterial({ color: 0x365668 })
  for (const x of [2.2, 6.4]) {
    const frame = boxMesh(3.1, 1.35, 0.18, materials.steelDark, x, 4.1, -8.55)
    scene.add(frame)
    const glass = boxMesh(2.9, 1.17, 0.02, windowMat, x, 4.1, -8.45, false, false)
    scene.add(glass)
    const bar = boxMesh(0.05, 1.2, 0.04, materials.steelDark, x, 4.1, -8.43)
    scene.add(bar)
  }
  windowMat.dispose()

  // signage
  const sign = signMesh('PISTON FORGE', 4.4, 1.25, 4.4, 4.9, -8.5, 0, 'BAY 03 · ENGINEERING')
  scene.add(sign)

  // blueprint panel
  const board = boxMesh(2.5, 1.7, 0.08, materials.steelDark, 8.6, 3.1, -8.4)
  scene.add(board)
  const blueprint = new THREE.Mesh(new THREE.PlaneGeometry(2.35, 1.55), materials.grid)
  blueprint.position.set(8.6, 3.1, -8.34)
  scene.add(blueprint)
  const sketch = new THREE.Group()
  const engineOutline = new THREE.LineSegments(
    new THREE.EdgesGeometry(new THREE.BoxGeometry(0.9, 0.65, 0.5)),
    new THREE.LineBasicMaterial({ color: 0x65e3d3, transparent: true, opacity: 0.6 }),
  )
  engineOutline.position.set(8.6, 3.05, -8.29)
  engineOutline.rotation.z = 0.08
  sketch.add(engineOutline)
  scene.add(sketch)

  // car bay markings
  const bayLineMaterial = new THREE.MeshBasicMaterial({ color: 0x8a6a2a })
  for (const [w, d, x, z] of [[5.9, 0.06, 0, 3.7], [5.9, 0.06, 0, -3.7], [0.06, 7.4, -2.95, 0], [0.06, 7.4, 2.95, 0]] as const) {
    const line = new THREE.Mesh(new THREE.PlaneGeometry(w, d), bayLineMaterial)
    line.rotation.x = -Math.PI / 2
    line.position.set(x, 0.006, z)
    scene.add(line)
  }
  const bayNumber = labelTexture('03', { background: '#0b0d0e', color: '#8a6a2a', border: false, width: 256, height: 256 })
  const bayNumberMesh = new THREE.Mesh(new THREE.PlaneGeometry(0.65, 0.65), new THREE.MeshBasicMaterial({ map: bayNumber, transparent: true }))
  bayNumberMesh.rotation.x = -Math.PI / 2
  bayNumberMesh.position.set(-2.5, 0.008, 2.8)
  scene.add(bayNumberMesh)

  // workbench on left wall
  const benchTop = boxMesh(4.6, 0.12, 1.1, materials.wood, -8.9, 0.95, -2.2)
  scene.add(benchTop)
  for (const z of [-2.7, -1.7]) {
    for (const x of [-10.3, -7.5]) {
      const leg = boxMesh(0.12, 0.95, 0.12, materials.steelDark, x, 0.48, z)
      scene.add(leg)
    }
  }
  const pegboard = boxMesh(4.4, 1.7, 0.06, materials.steelDark, -10.9, 2.6, -2.2)
  pegboard.rotation.y = Math.PI / 2
  scene.add(pegboard)
  for (let i = 0; i < 14; i += 1) {
    const tool = boxMesh(0.035, 0.26 + (i % 4) * 0.06, 0.05, materials.steel, -10.82, 2.9, -3.8 + i * 0.24, false, false)
    tool.rotation.y = Math.PI / 2
    scene.add(tool)
  }

  // tool chest
  const chest = boxMesh(1.6, 1.05, 0.72, materials.steelDark, -8.4, 0.53, 1.6)
  scene.add(chest)
  for (let i = 0; i < 6; i += 1) {
    const drawer = boxMesh(1.5, 0.13, 0.03, materials.steel, -8.4, 0.15 + i * 0.15, 1.98, false, false)
    scene.add(drawer)
    const handle = boxMesh(0.42, 0.018, 0.025, materials.amber, -8.4, 0.15 + i * 0.15, 2.0, false, false)
    scene.add(handle)
  }

  // tyre stacks and drums
  for (const [x, z] of [[-6.2, -5.6], [-5.2, -5.6], [7.8, -6.2]]) {
    for (let i = 0; i < 4; i += 1) {
      const tyre = new THREE.Mesh(new THREE.TorusGeometry(0.34, 0.14, 10, 28), materials.rubber)
      tyre.rotation.x = Math.PI / 2
      tyre.position.set(x, 0.15 + i * 0.24, z)
      tyre.castShadow = true
      scene.add(tyre)
    }
  }
  for (const [x, z, color] of [[-7.2, 4.8, 0x8a5a2b], [-6.5, 5.3, 0x283b49], [7.5, 4.2, 0x7d2a22]] as const) {
    const drum = new THREE.Mesh(new THREE.CylinderGeometry(0.3, 0.3, 0.88, 18), new THREE.MeshStandardMaterial({ color, roughness: 0.7, metalness: 0.4 }))
    drum.position.set(x, 0.44, z)
    drum.castShadow = true
    scene.add(drum)
  }

  // welding cart
  const welder = boxMesh(0.8, 0.45, 0.55, materials.amber, 7.8, 0.7, 2.4)
  scene.add(welder)
  for (const x of [7.45, 8.15]) {
    for (const z of [2.15, 2.65]) {
      const wheel = new THREE.Mesh(new THREE.CylinderGeometry(0.09, 0.09, 0.05, 12), materials.rubber)
      wheel.rotation.z = Math.PI / 2
      wheel.position.set(x, 0.1, z)
      scene.add(wheel)
    }
  }

  // engine stand
  const stand = new THREE.Group()
  const base = boxMesh(1.15, 0.1, 0.65, materials.steelDark, 0, 0.05, 0)
  stand.add(base)
  const post = boxMesh(0.16, 1.15, 0.16, materials.steel, 0, 0.62, -0.2)
  stand.add(post)
  const standHead = boxMesh(0.5, 0.18, 0.18, materials.steel, 0, 1.2, -0.2)
  stand.add(standHead)
  for (const side of [-1, 1]) {
    const arm = boxMesh(0.08, 0.08, 0.62, materials.steel, side * 0.28, 1.12, 0.05)
    stand.add(arm)
    const clamp = boxMesh(0.12, 0.18, 0.12, materials.steel, side * 0.28, 1.2, 0.35)
    stand.add(clamp)
  }
  const crank = new THREE.Mesh(new THREE.CylinderGeometry(0.11, 0.11, 0.05, 18), materials.steelDark)
  crank.rotation.z = Math.PI / 2
  crank.position.set(0.3, 1.2, -0.2)
  stand.add(crank)
  stand.position.set(2.4, 0, 0.6)
  scene.add(stand)

  // focused bay lamp over the engine stand
  const lampStem = boxMesh(0.035, 0.9, 0.035, materials.steelDark, 2.4, 4.35, 1.55, false, false)
  scene.add(lampStem)
  const lampShade = new THREE.Mesh(new THREE.ConeGeometry(0.26, 0.2, 20, 1, true), materials.steelDark)
  lampShade.position.set(2.4, 3.94, 1.55)
  scene.add(lampShade)
  const lampBulb = new THREE.Mesh(new THREE.SphereGeometry(0.075, 12, 8), materials.amberGlow)
  lampBulb.position.set(2.4, 3.9, 1.55)
  scene.add(lampBulb)
  const engineLight = new THREE.PointLight(0xffd39b, 26, 7, 1.8)
  engineLight.position.set(2.4, 3.78, 1.55)
  engineLight.castShadow = false
  scene.add(engineLight)

  const standMount = new THREE.Object3D()
  standMount.position.set(2.4, 0.62, 0.95)
  standMount.name = 'engine-stand-mount'
  scene.add(standMount)

  // loose engine parts as set dressing
  const block = boxMesh(0.52, 0.35, 0.36, materials.steelDark, -3.8, 0.18, -5.8)
  scene.add(block)
  const looseHead = boxMesh(0.46, 0.1, 0.3, materials.aluminium, -2.9, 0.06, -5.9)
  scene.add(looseHead)
  const piston = new THREE.Mesh(new THREE.CylinderGeometry(0.08, 0.08, 0.09, 14), materials.machined)
  piston.position.set(-2.3, 0.05, -5.4)
  scene.add(piston)

  // floor stains as simple transparent discs
  const stainMat = new THREE.MeshBasicMaterial({ color: 0x16130f, transparent: true, opacity: 0.55 })
  for (let i = 0; i < 7; i += 1) {
    const stain = new THREE.Mesh(new THREE.CircleGeometry(0.4 + Math.random() * 0.8, 18), stainMat)
    stain.rotation.x = -Math.PI / 2
    stain.position.set(-6 + Math.random() * 12, 0.004, -5 + Math.random() * 9)
    scene.add(stain)
  }

  const dust = makeParticles(140, 0xd7c8a8, 0.012, 14, 5)
  dust.position.y = 0.2
  scene.add(dust)

  const update = (dt: number) => {
    updateParticles(dust, dt, 14, 5)
  }

  const dispose = () => {
    disposeObject(scene)
    windowMat.dispose()
    bayLineMaterial.dispose()
    stainMat.dispose()
    scene.clear()
  }

  return { scene, standMount, update, dispose }
}
