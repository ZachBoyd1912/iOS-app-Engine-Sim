import * as THREE from 'three'

const clamp = (v: number, min: number, max: number) => Math.min(max, Math.max(min, v))

export type MaterialSet = {
  concrete: THREE.MeshStandardMaterial
  wall: THREE.MeshStandardMaterial
  steelDark: THREE.MeshStandardMaterial
  steel: THREE.MeshStandardMaterial
  aluminium: THREE.MeshStandardMaterial
  machined: THREE.MeshStandardMaterial
  rubber: THREE.MeshStandardMaterial
  glass: THREE.MeshPhysicalMaterial
  amber: THREE.MeshStandardMaterial
  amberGlow: THREE.MeshBasicMaterial
  cyanGlow: THREE.MeshBasicMaterial
  redGlow: THREE.MeshBasicMaterial
  whiteGlow: THREE.MeshBasicMaterial
  brass: THREE.MeshStandardMaterial
  copper: THREE.MeshStandardMaterial
  blackPlastic: THREE.MeshStandardMaterial
  heatWrap: THREE.MeshStandardMaterial
  wood: THREE.MeshStandardMaterial
  hazard: THREE.MeshStandardMaterial
  grid: THREE.MeshBasicMaterial
}

export type SharedAssets = {
  materials: MaterialSet
  floorTexture: THREE.Texture
  wallTexture: THREE.Texture
  gridTexture: THREE.Texture
  hazardTexture: THREE.Texture
  envMap: THREE.Texture | null
  envTarget: THREE.WebGLRenderTarget | null
}

export function createSharedAssets(renderer: THREE.WebGLRenderer): SharedAssets {
  const floorTexture = concreteTexture()
  const wallTexture = wallTextureMake()
  const gridTexture = blueprintTexture()
  const hazardTexture = hazardTextureMake()
  const env = makeEnvironment(renderer)

  const materials: MaterialSet = {
    concrete: new THREE.MeshStandardMaterial({ map: floorTexture, color: 0x9a9a90, roughness: 0.96, metalness: 0.04 }),
    wall: new THREE.MeshStandardMaterial({ map: wallTexture, color: 0x7e827f, roughness: 0.92 }),
    steelDark: new THREE.MeshStandardMaterial({ color: 0x1b2023, roughness: 0.52, metalness: 0.6 }),
    steel: new THREE.MeshStandardMaterial({ color: 0x4b5459, roughness: 0.45, metalness: 0.72 }),
    aluminium: new THREE.MeshStandardMaterial({ color: 0x9aa2a3, roughness: 0.48, metalness: 0.75 }),
    machined: new THREE.MeshStandardMaterial({ color: 0xc4c8c4, roughness: 0.28, metalness: 0.9 }),
    rubber: new THREE.MeshStandardMaterial({ color: 0x111314, roughness: 0.92 }),
    glass: new THREE.MeshPhysicalMaterial({ color: 0x121a1d, roughness: 0.06, metalness: 0.2, clearcoat: 1, clearcoatRoughness: 0.06, transparent: true, opacity: 0.92 }),
    amber: new THREE.MeshStandardMaterial({ color: 0xffb23e, roughness: 0.4, metalness: 0.3, emissive: 0xff8a1a, emissiveIntensity: 0.25 }),
    amberGlow: new THREE.MeshBasicMaterial({ color: 0xffb23e, toneMapped: false }),
    cyanGlow: new THREE.MeshBasicMaterial({ color: 0x65e3d3, toneMapped: false }),
    redGlow: new THREE.MeshBasicMaterial({ color: 0xff4a3d, toneMapped: false }),
    whiteGlow: new THREE.MeshBasicMaterial({ color: 0xfff4de, toneMapped: false }),
    brass: new THREE.MeshStandardMaterial({ color: 0xa88544, roughness: 0.32, metalness: 0.9 }),
    copper: new THREE.MeshStandardMaterial({ color: 0x9f5b32, roughness: 0.35, metalness: 0.85 }),
    blackPlastic: new THREE.MeshStandardMaterial({ color: 0x171a1b, roughness: 0.68, metalness: 0.12 }),
    heatWrap: new THREE.MeshStandardMaterial({ color: 0x7d6c50, roughness: 0.95 }),
    wood: new THREE.MeshStandardMaterial({ color: 0x5a422c, roughness: 0.85 }),
    hazard: new THREE.MeshStandardMaterial({ map: hazardTexture, roughness: 0.7 }),
    grid: new THREE.MeshBasicMaterial({ map: gridTexture, transparent: true, opacity: 0.75, depthWrite: false }),
  }

  return { materials, floorTexture, wallTexture, gridTexture, hazardTexture, envMap: env.texture, envTarget: env.target }
}

export function disposeShared(assets: SharedAssets): void {
  for (const material of Object.values(assets.materials)) {
    const maps = [material.map].filter(Boolean) as THREE.Texture[]
    for (const map of maps) map.dispose()
    material.dispose()
  }
  assets.floorTexture.dispose()
  assets.wallTexture.dispose()
  assets.gridTexture.dispose()
  assets.hazardTexture.dispose()
  assets.envMap?.dispose()
  assets.envTarget?.dispose()
}

export function setupLighting(scene: THREE.Scene, mode: 'workshop' | 'dyno' | 'strip' | 'handling' = 'workshop'): THREE.Group {
  const group = new THREE.Group()
  const hemi = new THREE.HemisphereLight(0x9bb0bc, 0x241d16, mode === 'strip' ? 1.0 : 0.6)
  group.add(hemi)

  const key = new THREE.DirectionalLight(mode === 'strip' ? 0xfff1d4 : 0xffd9a3, mode === 'strip' ? 2.8 : 2.1)
  key.position.set(5, 8, 4)
  key.castShadow = true
  key.shadow.mapSize.set(2048, 2048)
  key.shadow.camera.near = 0.5
  key.shadow.camera.far = 28
  key.shadow.camera.left = -9
  key.shadow.camera.right = 9
  key.shadow.camera.top = 9
  key.shadow.camera.bottom = -9
  key.shadow.bias = -0.0008
  group.add(key)

  const fill = new THREE.DirectionalLight(0x6fa6bc, 0.7)
  fill.position.set(-6, 4, -5)
  group.add(fill)

  const rim = new THREE.PointLight(0x65e3d3, 8, 12, 2)
  rim.position.set(-2.4, 2.4, -3.2)
  group.add(rim)

  if (mode === 'workshop') {
    for (const x of [-4.5, 0, 4.5]) {
      const strip = new THREE.PointLight(0xffdfb2, 5.5, 8, 2)
      strip.position.set(x, 3.5, 1.2)
      group.add(strip)
    }
  } else if (mode === 'dyno') {
    const cell = new THREE.PointLight(0xffb23e, 10, 9, 2)
    cell.position.set(2.2, 2.8, 1)
    group.add(cell)
    const cool = new THREE.PointLight(0x65e3d3, 7, 8, 2)
    cool.position.set(-2.5, 2.2, -2)
    group.add(cool)
  } else if (mode === 'strip') {
    const tower = new THREE.PointLight(0xfff2dc, 6, 14, 2)
    tower.position.set(2, 4, 2)
    group.add(tower)
  }

  scene.add(group)
  return group
}

export function boxMesh(
  width: number,
  height: number,
  depth: number,
  material: THREE.Material,
  x = 0,
  y = 0,
  z = 0,
  cast = true,
  receive = true,
): THREE.Mesh {
  const mesh = new THREE.Mesh(new THREE.BoxGeometry(width, height, depth), material)
  mesh.position.set(x, y, z)
  mesh.castShadow = cast
  mesh.receiveShadow = receive
  return mesh
}

export function cylMesh(
  radius: number,
  height: number,
  material: THREE.Material,
  x = 0,
  y = 0,
  z = 0,
  radialSegments = 20,
  openEnded = false,
): THREE.Mesh {
  const mesh = new THREE.Mesh(new THREE.CylinderGeometry(radius, radius, height, radialSegments, 1, openEnded), material)
  mesh.position.set(x, y, z)
  mesh.castShadow = true
  mesh.receiveShadow = true
  return mesh
}

export function tubeMesh(points: THREE.Vector3[], radius: number, material: THREE.Material, tubularSegments = 28): THREE.Mesh {
  const curve = new THREE.CatmullRomCurve3(points)
  const geometry = new THREE.TubeGeometry(curve, tubularSegments, radius, 8, false)
  const mesh = new THREE.Mesh(geometry, material)
  mesh.castShadow = true
  mesh.receiveShadow = true
  return mesh
}

export function planeMesh(width: number, height: number, material: THREE.Material, x = 0, y = 0, z = 0): THREE.Mesh {
  const mesh = new THREE.Mesh(new THREE.PlaneGeometry(width, height), material)
  mesh.position.set(x, y, z)
  mesh.receiveShadow = true
  return mesh
}

export function roundedRectShape(width: number, height: number, radius: number): THREE.Shape {
  const shape = new THREE.Shape()
  const w = width / 2
  const h = height / 2
  const r = Math.min(radius, Math.min(w, h))
  shape.moveTo(-w + r, -h)
  shape.lineTo(w - r, -h)
  shape.quadraticCurveTo(w, -h, w, -h + r)
  shape.lineTo(w, h - r)
  shape.quadraticCurveTo(w, h, w - r, h)
  shape.lineTo(-w + r, h)
  shape.quadraticCurveTo(-w, h, -w, h - r)
  shape.lineTo(-w, -h + r)
  shape.quadraticCurveTo(-w, -h, -w + r, -h)
  return shape
}

export function disposeObject(root: THREE.Object3D): void {
  root.traverse(object => {
    const mesh = object as THREE.Mesh
    if (mesh.geometry) mesh.geometry.dispose()
    const materials = Array.isArray(mesh.material) ? mesh.material : mesh.material ? [mesh.material] : []
    for (const material of materials) {
      const map = (material as THREE.MeshStandardMaterial).map
      map?.dispose()
      material.dispose()
    }
  })
}

export function setShadows(root: THREE.Object3D, cast: boolean, receive: boolean): void {
  root.traverse(object => {
    if (object instanceof THREE.Mesh) {
      object.castShadow = cast
      object.receiveShadow = receive
    }
  })
}

export function labelTexture(text: string, options: { color?: string; background?: string; sub?: string; width?: number; height?: number; border?: boolean } = {}): THREE.CanvasTexture {
  const width = options.width ?? 512
  const height = options.height ?? 128
  const canvas = document.createElement('canvas')
  canvas.width = width
  canvas.height = height
  const ctx = canvas.getContext('2d')!
  ctx.fillStyle = options.background ?? '#14191b'
  ctx.fillRect(0, 0, width, height)
  if (options.border !== false) {
    ctx.strokeStyle = '#ffb23e'
    ctx.lineWidth = 4
    ctx.strokeRect(7, 7, width - 14, height - 14)
  }
  ctx.fillStyle = options.color ?? '#ffb23e'
  ctx.textAlign = 'center'
  ctx.textBaseline = 'middle'
  const size = options.sub ? height * 0.3 : height * 0.38
  ctx.font = `700 ${size}px "ManusCC0", system-ui, sans-serif`
  ctx.fillText(text.toUpperCase(), width / 2, options.sub ? height * 0.42 : height / 2)
  if (options.sub) {
    ctx.fillStyle = '#b7b0a2'
    ctx.font = `500 ${height * 0.17}px "ManusCC0", system-ui, sans-serif`
    ctx.fillText(options.sub.toUpperCase(), width / 2, height * 0.74)
  }
  const texture = new THREE.CanvasTexture(canvas)
  texture.colorSpace = THREE.SRGBColorSpace
  texture.anisotropy = 4
  return texture
}

export function signMesh(text: string, width: number, height: number, x: number, y: number, z: number, rotationY = 0, sub?: string): THREE.Mesh {
  const texture = labelTexture(text, { sub, width: 512, height: 160 })
  const material = new THREE.MeshBasicMaterial({ map: texture })
  const mesh = new THREE.Mesh(new THREE.PlaneGeometry(width, height), material)
  mesh.position.set(x, y, z)
  mesh.rotation.y = rotationY
  return mesh
}

export function makeParticles(count: number, color: number, size: number, spread: number, height: number): THREE.Points {
  const positions = new Float32Array(count * 3)
  for (let i = 0; i < count; i += 1) {
    positions[i * 3] = (Math.random() - 0.5) * spread
    positions[i * 3 + 1] = Math.random() * height
    positions[i * 3 + 2] = (Math.random() - 0.5) * spread
  }
  const geometry = new THREE.BufferGeometry()
  geometry.setAttribute('position', new THREE.BufferAttribute(positions, 3))
  const material = new THREE.PointsMaterial({ color, size, transparent: true, opacity: 0.45, depthWrite: false })
  const points = new THREE.Points(geometry, material)
  return points
}

export function updateParticles(points: THREE.Points, dt: number, spread: number, height: number): void {
  const position = points.geometry.getAttribute('position') as THREE.BufferAttribute
  const array = position.array as Float32Array
  for (let i = 0; i < array.length; i += 3) {
    array[i + 1] += dt * 0.15
    if (array[i + 1] > height) {
      array[i + 1] = 0
      array[i] = (Math.random() - 0.5) * spread
      array[i + 2] = (Math.random() - 0.5) * spread
    }
  }
  position.needsUpdate = true
}

// ─── Procedural textures ──────────────────────────────────────────────────────

function concreteTexture(): THREE.CanvasTexture {
  const size = 512
  const canvas = document.createElement('canvas')
  canvas.width = canvas.height = size
  const ctx = canvas.getContext('2d')!
  ctx.fillStyle = '#63635b'
  ctx.fillRect(0, 0, size, size)
  for (let i = 0; i < 7000; i += 1) {
    const shade = 70 + Math.random() * 70
    ctx.fillStyle = `rgba(${shade},${shade},${shade - 4},${0.06 + Math.random() * 0.2})`
    ctx.fillRect(Math.random() * size, Math.random() * size, 1 + Math.random() * 3, 1 + Math.random() * 3)
  }
  for (let i = 0; i < 26; i += 1) {
    ctx.strokeStyle = `rgba(30,31,29,${0.08 + Math.random() * 0.15})`
    ctx.lineWidth = 1 + Math.random() * 2
    ctx.beginPath()
    let x = Math.random() * size
    let y = Math.random() * size
    ctx.moveTo(x, y)
    for (let j = 0; j < 5; j += 1) {
      x += (Math.random() - 0.5) * 48
      y += Math.random() * 26
      ctx.lineTo(x, y)
    }
    ctx.stroke()
  }
  for (let i = 0; i < 10; i += 1) {
    const gradient = ctx.createRadialGradient(Math.random() * size, Math.random() * size, 2, 0, 0, 40)
    gradient.addColorStop(0, 'rgba(20,18,14,0.16)')
    gradient.addColorStop(1, 'rgba(20,18,14,0)')
    ctx.fillStyle = gradient
    ctx.fillRect(0, 0, size, size)
  }
  const texture = new THREE.CanvasTexture(canvas)
  texture.wrapS = texture.wrapT = THREE.RepeatWrapping
  texture.repeat.set(4, 4)
  texture.colorSpace = THREE.SRGBColorSpace
  texture.anisotropy = 8
  return texture
}

function wallTextureMake(): THREE.CanvasTexture {
  const width = 512
  const height = 512
  const canvas = document.createElement('canvas')
  canvas.width = width
  canvas.height = height
  const ctx = canvas.getContext('2d')!
  ctx.fillStyle = '#3f4443'
  ctx.fillRect(0, 0, width, height)
  for (let x = 0; x < width; x += 32) {
    ctx.fillStyle = x % 64 === 0 ? 'rgba(20,24,24,0.35)' : 'rgba(90,95,92,0.10)'
    ctx.fillRect(x, 0, 2, height)
  }
  for (let i = 0; i < 120; i += 1) {
    ctx.fillStyle = `rgba(20,20,18,${Math.random() * 0.12})`
    ctx.fillRect(Math.random() * width, Math.random() * height, 2 + Math.random() * 8, 2 + Math.random() * 20)
  }
  const texture = new THREE.CanvasTexture(canvas)
  texture.wrapS = texture.wrapT = THREE.RepeatWrapping
  texture.repeat.set(6, 2)
  texture.colorSpace = THREE.SRGBColorSpace
  return texture
}

function blueprintTexture(): THREE.CanvasTexture {
  const size = 512
  const canvas = document.createElement('canvas')
  canvas.width = canvas.height = size
  const ctx = canvas.getContext('2d')!
  ctx.clearRect(0, 0, size, size)
  ctx.strokeStyle = 'rgba(101,227,211,0.17)'
  ctx.lineWidth = 1
  for (let i = 0; i <= size; i += 32) {
    ctx.beginPath()
    ctx.moveTo(i, 0)
    ctx.lineTo(i, size)
    ctx.stroke()
  }
  for (let i = 0; i <= size; i += 32) {
    ctx.beginPath()
    ctx.moveTo(0, i)
    ctx.lineTo(size, i)
    ctx.stroke()
  }
  ctx.strokeStyle = 'rgba(101,227,211,0.4)'
  ctx.lineWidth = 2
  ctx.strokeRect(4, 4, size - 8, size - 8)
  const texture = new THREE.CanvasTexture(canvas)
  texture.wrapS = texture.wrapT = THREE.RepeatWrapping
  texture.repeat.set(2, 2)
  return texture
}

function hazardTextureMake(): THREE.CanvasTexture {
  const size = 256
  const canvas = document.createElement('canvas')
  canvas.width = canvas.height = size
  const ctx = canvas.getContext('2d')!
  ctx.fillStyle = '#161718'
  ctx.fillRect(0, 0, size, size)
  ctx.strokeStyle = '#e8a13a'
  ctx.lineWidth = 22
  for (let i = -size; i < size * 2; i += 64) {
    ctx.beginPath()
    ctx.moveTo(i, 0)
    ctx.lineTo(i + size, size)
    ctx.stroke()
  }
  const texture = new THREE.CanvasTexture(canvas)
  texture.wrapS = texture.wrapT = THREE.RepeatWrapping
  texture.repeat.set(3, 1)
  texture.colorSpace = THREE.SRGBColorSpace
  return texture
}

function makeEnvironment(renderer: THREE.WebGLRenderer): { texture: THREE.Texture | null; target: THREE.WebGLRenderTarget | null } {
  try {
    const width = 1024
    const height = 512
    const canvas = document.createElement('canvas')
    canvas.width = width
    canvas.height = height
    const ctx = canvas.getContext('2d')!
    const sky = ctx.createLinearGradient(0, 0, 0, height)
    sky.addColorStop(0, '#12191c')
    sky.addColorStop(0.45, '#3d4750')
    sky.addColorStop(0.58, '#20272a')
    sky.addColorStop(1, '#090b0c')
    ctx.fillStyle = sky
    ctx.fillRect(0, 0, width, height)
    const strips = [
      { x: 60, y: 100, w: 280, h: 18, color: '#fff2d8' },
      { x: 480, y: 70, w: 240, h: 12, color: '#ffd6a0' },
      { x: 800, y: 120, w: 180, h: 16, color: '#cde7f2' },
      { x: 220, y: 200, w: 160, h: 8, color: '#ffb23e' },
      { x: 720, y: 210, w: 200, h: 7, color: '#65e3d3' },
    ]
    for (const strip of strips) {
      const glow = ctx.createLinearGradient(strip.x, strip.y, strip.x, strip.y + strip.h * 4)
      glow.addColorStop(0, strip.color)
      glow.addColorStop(0.25, `${strip.color}55`)
      glow.addColorStop(1, 'rgba(0,0,0,0)')
      ctx.fillStyle = glow
      ctx.fillRect(strip.x, strip.y, strip.w, strip.h * 4)
      ctx.fillStyle = strip.color
      ctx.fillRect(strip.x, strip.y, strip.w, strip.h)
    }
    const texture = new THREE.CanvasTexture(canvas)
    texture.mapping = THREE.EquirectangularReflectionMapping
    texture.colorSpace = THREE.SRGBColorSpace
    const pmrem = new THREE.PMREMGenerator(renderer)
    const target = pmrem.fromEquirectangular(texture)
    pmrem.dispose()
    texture.dispose()
    return { texture: target.texture, target }
  } catch {
    return { texture: null, target: null }
  }
}

export function clampNumber(v: number, min: number, max: number): number {
  return clamp(v, min, max)
}