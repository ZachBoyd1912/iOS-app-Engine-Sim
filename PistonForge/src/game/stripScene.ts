import * as THREE from 'three'
import type { MaterialSet } from './sceneKit'
import { boxMesh, disposeObject, makeParticles, setupLighting, signMesh, updateParticles } from './sceneKit'

export type TreeState = 'idle' | 'amber1' | 'amber2' | 'amber3' | 'green'

export type StripScene = {
  scene: THREE.Scene
  setTree: (state: TreeState, red?: boolean) => void
  setSmoke: (amount: number) => void
  update: (dt: number) => void
  dispose: () => void
}

export function createStripScene(materials: MaterialSet): StripScene {
  const scene = new THREE.Scene()
  scene.background = new THREE.Color(0x121719)
  scene.fog = new THREE.FogExp2(0x121719, 0.006)
  setupLighting(scene, 'strip')

  const ground = new THREE.Mesh(new THREE.PlaneGeometry(220, 760), new THREE.MeshStandardMaterial({ color: 0x282c25, roughness: 1 }))
  ground.rotation.x = -Math.PI / 2
  ground.position.set(0, -0.02, 300)
  ground.receiveShadow = true
  scene.add(ground)

  const asphaltMat = new THREE.MeshStandardMaterial({ color: 0x252a2c, roughness: 0.96, metalness: 0.02 })
  const strip = new THREE.Mesh(new THREE.PlaneGeometry(16, 700), asphaltMat)
  strip.rotation.x = -Math.PI / 2
  strip.position.set(0, 0.005, 330)
  strip.receiveShadow = true
  scene.add(strip)

  const white = new THREE.MeshStandardMaterial({ color: 0xd8d4c4, roughness: 0.7 })
  const yellow = new THREE.MeshStandardMaterial({ color: 0xc59d3a, roughness: 0.7 })
  for (const x of [-7.7, 7.7]) {
    const edge = new THREE.Mesh(new THREE.PlaneGeometry(0.14, 700), white)
    edge.rotation.x = -Math.PI / 2
    edge.position.set(x, 0.008, 330)
    scene.add(edge)
  }
  for (let z = 10; z < 680; z += 12) {
    const dash = new THREE.Mesh(new THREE.PlaneGeometry(0.16, 3.6), yellow)
    dash.rotation.x = -Math.PI / 2
    dash.position.set(0, 0.009, z)
    scene.add(dash)
  }
  const startLine = new THREE.Mesh(new THREE.PlaneGeometry(15.6, 0.45), white)
  startLine.rotation.x = -Math.PI / 2
  startLine.position.set(0, 0.012, 0)
  scene.add(startLine)
  const burnout = new THREE.Mesh(new THREE.PlaneGeometry(7, 26), new THREE.MeshStandardMaterial({ color: 0x171b1b, roughness: 1 }))
  burnout.rotation.x = -Math.PI / 2
  burnout.position.set(0, 0.01, -14)
  scene.add(burnout)

  // guard rails and posts
  for (const x of [-9.2, 9.2]) {
    const rail = boxMesh(0.12, 0.18, 690, materials.steel, x, 0.65, 330, false, false)
    scene.add(rail)
    for (let z = 0; z < 680; z += 16) {
      const post = boxMesh(0.09, 0.65, 0.09, materials.steelDark, x, 0.33, z, false, true)
      scene.add(post)
    }
  }

  // timing tower
  const tower = new THREE.Group()
  tower.position.set(9.2, 0, 24)
  const towerBody = boxMesh(2.4, 6, 2.6, materials.steelDark, 0, 3, 0)
  tower.add(towerBody)
  const towerBand = boxMesh(2.5, 0.16, 2.7, materials.amber, 0, 5.1, 0)
  tower.add(towerBand)
  for (let i = 0; i < 4; i += 1) {
    const window = new THREE.Mesh(new THREE.PlaneGeometry(1.8, 0.45), materials.glass)
    window.position.set(-1.21, 2.2 + i * 0.7, 0)
    window.rotation.y = -Math.PI / 2
    tower.add(window)
  }
  const towerSign = signMesh('1/4 MILE', 2.0, 0.45, 9.2, 6.35, 23.2, 0)
  towerSign.rotation.y = -0.15
  scene.add(towerSign)
  scene.add(tower)

  // christmas tree
  const tree = new THREE.Group()
  tree.position.set(-4.8, 0, 3.5)
  const pole = boxMesh(0.18, 3.4, 0.18, materials.steelDark, 0, 1.7, 0)
  tree.add(pole)
  const treeHead = boxMesh(0.55, 1.4, 0.28, materials.blackPlastic, 0, 2.9, 0)
  tree.add(treeHead)
  const bulbMaterials: THREE.MeshBasicMaterial[] = []
  for (let i = 0; i < 4; i += 1) {
    const mat = new THREE.MeshBasicMaterial({ color: 0x3a2b14 })
    const bulb = new THREE.Mesh(new THREE.CylinderGeometry(0.12, 0.12, 0.08, 16), mat)
    bulb.rotation.x = Math.PI / 2
    bulb.position.set(-0.16, 3.35 - i * 0.26, 0.17)
    tree.add(bulb)
    bulbMaterials.push(mat)
  }
  for (const x of [-0.35, 0.35]) {
    const guard = boxMesh(0.06, 1.5, 0.06, materials.steel, x, 2.9, 0.08)
    tree.add(guard)
  }
  scene.add(tree)

  const towerFlood = new THREE.PointLight(0xfff1d4, 16, 30, 2)
  towerFlood.position.set(6.5, 7, 12)
  scene.add(towerFlood)

  // distant grandstands and city
  for (const side of [-1, 1]) {
    const stand = boxMesh(6, 3.2, 28, materials.steelDark, side * 24, 1.6, 75)
    scene.add(stand)
    for (let i = 0; i < 5; i += 1) {
      const row = boxMesh(5.2, 0.12, 24, materials.steel, side * 24, 0.9 + i * 0.32, 75, false, false)
      scene.add(row)
    }
  }
  const cityMat = new THREE.MeshBasicMaterial({ color: 0x1a2427 })
  for (let i = 0; i < 34; i += 1) {
    const h = 8 + Math.random() * 26
    const building = boxMesh(5 + Math.random() * 8, h, 5 + Math.random() * 8, cityMat, (Math.random() - 0.5) * 170, h / 2, 420 + Math.random() * 120, false, false)
    scene.add(building)
  }

  // flood lighting poles
  for (let z = 40; z < 500; z += 90) {
    for (const x of [-14, 14]) {
      const pole = boxMesh(0.2, 8.5, 0.2, materials.steelDark, x, 4.25, z, false, false)
      scene.add(pole)
      const lamp = boxMesh(1.2, 0.25, 0.45, materials.whiteGlow, x, 8.4, z, false, false)
      scene.add(lamp)
      const light = new THREE.PointLight(0xffeed4, 9, 30, 2)
      light.position.set(x, 8.0, z)
      scene.add(light)
    }
  }

  // starting line crew barriers
  for (const x of [-11.2, 11.2]) {
    const barrier = boxMesh(0.4, 0.9, 3.2, materials.amber, x, 0.45, 5)
    scene.add(barrier)
  }

  const smoke = makeParticles(120, 0xc7c2b8, 0.09, 2.4, 2.2)
  smoke.position.set(0, 0.2, 0)
  smoke.visible = false
  const smokeMat = smoke.material as THREE.PointsMaterial
  smokeMat.opacity = 0.32
  scene.add(smoke)

  let smokeLevel = 0
  const setTree = (state: TreeState, red = false) => {
    const active = state === 'green' ? 4 : state === 'amber3' ? 3 : state === 'amber2' ? 2 : state === 'amber1' ? 1 : 0
    bulbMaterials.forEach((mat, index) => {
      if (red && index === 0) mat.color.set(0xff2f24)
      else if (index < 3) mat.color.set(index < active ? 0xffb23e : 0x3a2b14)
      else mat.color.set(active >= 4 ? 0x55ff75 : 0x123a1b)
    })
  }
  setTree('idle')

  const setSmoke = (amount: number) => {
    smokeLevel = amount
    smoke.visible = amount > 0.02
    smokeMat.opacity = 0.1 + amount * 0.3
  }

  const update = (dt: number) => {
    if (smoke.visible) {
      updateParticles(smoke, dt * (1 + smokeLevel * 2), 2.4, 2.2)
      smoke.position.z = Math.max(0, smoke.position.z + dt * 1.2)
    }
  }

  const dispose = () => {
    disposeObject(scene)
    asphaltMat.dispose()
    white.dispose()
    yellow.dispose()
    cityMat.dispose()
    smokeMat.dispose()
    scene.clear()
  }

  return { scene, setTree, setSmoke, update, dispose }
}

export type HandlingScene = {
  scene: THREE.Scene
  curve: THREE.CatmullRomCurve3
  setStart: () => void
  dispose: () => void
}

export function createHandlingScene(materials: MaterialSet): HandlingScene {
  const scene = new THREE.Scene()
  scene.background = new THREE.Color(0x11171a)
  scene.fog = new THREE.FogExp2(0x11171a, 0.0045)
  setupLighting(scene, 'handling')

  const ground = new THREE.Mesh(new THREE.PlaneGeometry(260, 220), new THREE.MeshStandardMaterial({ color: 0x2b3127, roughness: 1 }))
  ground.rotation.x = -Math.PI / 2
  ground.receiveShadow = true
  scene.add(ground)

  const points = [
    new THREE.Vector3(0, 0, 10),
    new THREE.Vector3(52, 0, 14),
    new THREE.Vector3(92, 0, 52),
    new THREE.Vector3(88, 0, 106),
    new THREE.Vector3(48, 0, 138),
    new THREE.Vector3(-4, 0, 134),
    new THREE.Vector3(-48, 0, 98),
    new THREE.Vector3(-56, 0, 48),
    new THREE.Vector3(-28, 0, 16),
  ]
  const curve = new THREE.CatmullRomCurve3(points, true, 'centripetal', 0.5)
  const roadWidth = 7.2
  const segments = 240
  const positions: number[] = []
  const indices: number[] = []
  for (let i = 0; i < segments; i += 1) {
    const t = i / segments
    const point = curve.getPointAt(t)
    const tangent = curve.getTangentAt(t).normalize()
    const normal = new THREE.Vector3(-tangent.z, 0, tangent.x).normalize()
    const left = point.clone().addScaledVector(normal, roadWidth / 2)
    const right = point.clone().addScaledVector(normal, -roadWidth / 2)
    positions.push(left.x, 0.01, left.z, right.x, 0.01, right.z)
  }
  for (let i = 0; i < segments; i += 1) {
    const next = (i + 1) % segments
    const a = i * 2
    const b = i * 2 + 1
    const c = next * 2
    const d = next * 2 + 1
    indices.push(a, c, b, b, c, d)
  }
  const roadGeo = new THREE.BufferGeometry()
  roadGeo.setAttribute('position', new THREE.Float32BufferAttribute(positions, 3))
  roadGeo.setIndex(indices)
  roadGeo.computeVertexNormals()
  const asphalt = new THREE.MeshStandardMaterial({ color: 0x252b2d, roughness: 0.96 })
  const road = new THREE.Mesh(roadGeo, asphalt)
  road.receiveShadow = true
  scene.add(road)

  // white edge lines
  for (const offset of [-roadWidth / 2 + 0.12, roadWidth / 2 - 0.12]) {
    const pts: THREE.Vector3[] = []
    for (let i = 0; i <= 180; i += 1) {
      const t = i / 180
      const p = curve.getPointAt(t)
      const tangent = curve.getTangentAt(t).normalize()
      const normal = new THREE.Vector3(-tangent.z, 0, tangent.x).normalize()
      pts.push(p.clone().addScaledVector(normal, offset).setY(0.025))
    }
    const geo = new THREE.BufferGeometry().setFromPoints(pts)
    const line = new THREE.Line(geo, new THREE.LineBasicMaterial({ color: 0xd8d4c4 }))
    scene.add(line)
  }

  // curbs
  const curbRed = new THREE.MeshStandardMaterial({ color: 0xa3372a, roughness: 0.7 })
  const curbWhite = materials.steel
  for (let i = 0; i < 120; i += 1) {
    const t = i / 120
    const p = curve.getPointAt(t)
    const tangent = curve.getTangentAt(t).normalize()
    const normal = new THREE.Vector3(-tangent.z, 0, tangent.x).normalize()
    for (const side of [-1, 1]) {
      const curb = boxMesh(0.35, 0.06, 1.2, i % 2 ? curbRed : curbWhite, p.x + normal.x * side * (roadWidth / 2 + 0.25), 0.035, p.z + normal.z * side * (roadWidth / 2 + 0.25), false, true)
      curb.rotation.y = Math.atan2(tangent.x, tangent.z)
      scene.add(curb)
    }
  }

  // start gantry
  const gantry = new THREE.Group()
  for (const x of [-4.4, 4.4]) {
    const leg = boxMesh(0.2, 4.2, 0.2, materials.steelDark, x, 2.1, 0)
    gantry.add(leg)
  }
  const beam = boxMesh(9.2, 0.22, 0.24, materials.steelDark, 0, 4.1, 0)
  gantry.add(beam)
  const banner = signMesh('PISTON FORGE · HANDLING', 5.4, 0.6, 0, 4.1, 0, 0)
  gantry.add(banner)
  gantry.position.set(0, 0, 10)
  scene.add(gantry)

  // marshal posts and cones
  for (let i = 0; i < 18; i += 1) {
    const t = (i / 18 + 0.02) % 1
    const p = curve.getPointAt(t)
    const tangent = curve.getTangentAt(t).normalize()
    const normal = new THREE.Vector3(-tangent.z, 0, tangent.x).normalize()
    for (const side of [-1, 1]) {
      const cone = new THREE.Mesh(new THREE.ConeGeometry(0.16, 0.48, 10), materials.amber)
      cone.position.set(p.x + normal.x * side * (roadWidth / 2 + 1.1), 0.24, p.z + normal.z * side * (roadWidth / 2 + 1.1))
      scene.add(cone)
    }
  }
  for (const [x, z] of [[-70, 100], [98, 80], [50, 160]]) {
    const hut = boxMesh(3, 2.2, 2.4, materials.steelDark, x, 1.1, z)
    scene.add(hut)
    const roof = boxMesh(3.2, 0.18, 2.6, materials.amber, x, 2.2, z)
    scene.add(roof)
  }

  const tireWallMat = materials.rubber
  for (let i = 0; i < 10; i += 1) {
    const tyre = new THREE.Mesh(new THREE.TorusGeometry(0.34, 0.14, 8, 18), tireWallMat)
    tyre.rotation.x = Math.PI / 2
    tyre.position.set(-62 + i * 0.7, 0.14, 128)
    scene.add(tyre)
  }

  const setStart = () => { /* reserved for start-light sequences */ }

  const dispose = () => {
    disposeObject(scene)
    asphalt.dispose()
    curbRed.dispose()
    scene.clear()
  }

  return { scene, curve, setStart, dispose }
}
