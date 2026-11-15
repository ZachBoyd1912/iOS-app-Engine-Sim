import type { BodySpec, DynoPoint } from '../sim/types'

export const esc = (value: string): string =>
  value.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;')

export const money = (value: number): string => `$${Math.round(value).toLocaleString('en-US')}`
export const num = (value: number, digits = 0): string => value.toLocaleString('en-US', { minimumFractionDigits: digits, maximumFractionDigits: digits })
export const signed = (value: number, digits = 0): string => `${value >= 0 ? '+' : ''}${num(value, digits)}`
export const pct = (value: number): string => `${Math.round(value)}%`
export const clamp = (v: number, min: number, max: number) => Math.min(max, Math.max(min, v))

type IconName =
  | 'garage' | 'engine' | 'ecu' | 'dyno' | 'test' | 'shop' | 'jobs' | 'settings'
  | 'close' | 'arrow' | 'lock' | 'check' | 'warning' | 'sound' | 'play' | 'gauge' | 'plus' | 'minus' | 'flame' | 'bolt'

const PATHS: Record<IconName, string> = {
  garage: '<path d="M3 10.5 12 3l9 7.5V21H3V10.5Z"/><path d="M7.5 21v-7h9v7"/>',
  engine: '<path d="M4 10h3V7h6v3h3l2 3v5h-3v2H8v-2H4v-8Z"/><path d="M16 11h3v4h-3"/><path d="M9 14h3"/>',
  ecu: '<rect x="6" y="6" width="12" height="12" rx="2"/><path d="M9 2v4M15 2v4M9 18v4M15 18v4M2 9h4M2 15h4M18 9h4M18 15h4"/><path d="M10 10h4v4h-4z"/>',
  dyno: '<circle cx="7" cy="16" r="3"/><circle cx="17" cy="16" r="3"/><path d="M4 8h9l3 5h4"/><path d="M4 8v8"/>',
  test: '<path d="M5 21V3"/><path d="M5 4h12l-2 4 2 4H5"/>',
  shop: '<path d="M14.5 5.5a5 5 0 0 0-6.8 6.8L3 17l4 4 4.7-4.7a5 5 0 0 0 6.8-6.8l-3 3-3-3 3-3Z"/>',
  jobs: '<rect x="5" y="4" width="14" height="18" rx="2"/><path d="M9 4V2h6v2"/><path d="M9 10h6M9 14h6M9 18h4"/>',
  settings: '<circle cx="12" cy="12" r="3.3"/><path d="M12 2v3M12 19v3M2 12h3M19 12h3M4.9 4.9 7 7M17 17l2.1 2.1M19.1 4.9 17 7M7 17l-2.1 2.1"/>',
  close: '<path d="m6 6 12 12M18 6 6 18"/>',
  arrow: '<path d="m9 5 7 7-7 7"/>',
  lock: '<rect x="5" y="10" width="14" height="11" rx="2"/><path d="M8 10V7a4 4 0 0 1 8 0v3"/>',
  check: '<path d="m4 12 5 5L20 6"/>',
  warning: '<path d="M12 3 2.5 20h19L12 3Z"/><path d="M12 9v5M12 17.2v.1"/>',
  sound: '<path d="M4 9h4l5-4v14l-5-4H4V9Z"/><path d="M17 8a6 6 0 0 1 0 8M19.5 5.5a10 10 0 0 1 0 13"/>',
  play: '<path d="M8 5v14l11-7L8 5Z"/>',
  gauge: '<path d="M4 17a8 8 0 1 1 16 0"/><path d="m12 13 5-5"/><circle cx="12" cy="17" r="1.6"/>',
  plus: '<path d="M12 5v14M5 12h14"/>',
  minus: '<path d="M5 12h14"/>',
  flame: '<path d="M12 22c4 0 7-2.8 7-6.5 0-2.7-1.5-5-3.5-6.7-.4 2.1-1.5 3.3-2.8 4.1.2-3.6-1.7-6.9-4.7-8.9.2 3.1-.6 5.3-2 7.2C4.6 13 5 14.7 5 15.5 5 19.2 8 22 12 22Z"/>',
  bolt: '<path d="M13 2 4 14h7l-1 8 9-12h-7l1-8Z"/>',
}

export function icon(name: IconName, cls = ''): string {
  return `<svg class="ico ${cls}" viewBox="0 0 24 24" aria-hidden="true" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round">${PATHS[name]}</svg>`
}

export function markSvg(cls = ''): string {
  return `<svg class="brand-mark ${cls}" viewBox="0 0 40 40" aria-hidden="true">
    <circle cx="20" cy="20" r="16.5" fill="none" stroke="currentColor" stroke-width="2.6"/>
    <path d="M20 7.2v8.1" stroke="currentColor" stroke-width="4.4" stroke-linecap="round"/>
    <circle cx="24.8" cy="20.8" r="3" fill="currentColor"/>
    <path d="M23.2 22.7 12.2 31.4" stroke="currentColor" stroke-width="4.4" stroke-linecap="round"/>
    <path d="M20 7.2c4.2 0 7.6 2.2 9 5.4" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" opacity=".5"/>
  </svg>`
}

export function wordmark(compact = false): string {
  return `<span class="wordmark ${compact ? 'wordmark-compact' : ''}">${markSvg()}<span class="wordmark-type"><span>PISTON</span><b>FORGE</b></span></span>`
}

export function carSilhouette(body: BodySpec): string {
  const roof = clamp(9 + (body.height - 1.15) * 9, 8, 20)
  const roofFront = body.height > 1.9 ? 54 : body.enginePosition === 'mid' ? 50 : 48
  const roofRear = body.height > 1.9 ? 82 : 76
  return `<svg class="car-silhouette" viewBox="0 0 120 50" aria-hidden="true">
    <path class="car-body" d="M7 38 L7 29 Q8 25 14 24 L${roofFront - 20} ${roof + 4} Q${roofFront - 14} ${roof} ${roofFront - 6} ${roof} L${roofRear} ${roof} Q${roofRear + 5} ${roof} ${roofRear + 11} ${roof + 6} L108 25 Q114 26 114 31 L114 38 Z"/>
    <path class="car-window" d="M${roofFront - 14} ${roof + 5} L${roofRear} ${roof + 5} L${roofRear + 9} ${roof + 10} L${roofFront - 15} ${roof + 10} Z"/>
    <circle class="car-tyre" cx="28" cy="38" r="8.5"/>
    <circle class="car-rim" cx="28" cy="38" r="3.7"/>
    <circle class="car-tyre" cx="92" cy="38" r="8.5"/>
    <circle class="car-rim" cx="92" cy="38" r="3.7"/>
  </svg>`
}

const anglePoint = (cx: number, cy: number, radius: number, angle: number): [number, number] => {
  const rad = (angle * Math.PI) / 180
  return [cx + radius * Math.sin(rad), cy - radius * Math.cos(rad)]
}

export function tachSvg(maxRpm: number, redline: number): string {
  const cx = 100
  const cy = 102
  const radius = 72
  const start = -120
  const end = 120
  const arc = (from: number, to: number, r: number, stroke: string, width: number, extra = ''): string => {
    const [x1, y1] = anglePoint(cx, cy, r, from)
    const [x2, y2] = anglePoint(cx, cy, r, to)
    const large = to - from > 180 ? 1 : 0
    return `<path d="M${x1} ${y1} A${r} ${r} 0 ${large} 1 ${x2} ${y2}" fill="none" stroke="${stroke}" stroke-width="${width}" stroke-linecap="round" ${extra}/>`
  }
  const redAngle = start + (end - start) * clamp(redline / maxRpm, 0, 1)
  const ticks: string[] = []
  for (let rpm = 0; rpm <= maxRpm; rpm += 500) {
    const angle = start + (end - start) * (rpm / maxRpm)
    const major = rpm % 2000 === 0
    const [x1, y1] = anglePoint(cx, cy, radius - (major ? 14 : 8), angle)
    const [x2, y2] = anglePoint(cx, cy, radius - 1.5, angle)
    ticks.push(`<line x1="${x1}" y1="${y1}" x2="${x2}" y2="${y2}" stroke="${major ? '#d8d0b8' : '#5f665f'}" stroke-width="${major ? 2 : 1.2}"/>`)
    if (major) {
      const [tx, ty] = anglePoint(cx, cy, radius - 24, angle)
      ticks.push(`<text x="${tx}" y="${ty + 4}" text-anchor="middle" class="tach-num">${rpm / 1000 === 0 ? '0' : rpm / 1000}</text>`)
    }
  }
  return `<svg class="tach" viewBox="0 0 200 190" aria-hidden="true">
    <circle cx="${cx}" cy="${cy}" r="${radius + 8}" class="tach-face"/>
    ${arc(start, end, radius, '#2a3032', 9)}
    ${arc(redAngle, end, radius, '#ff4a3d', 9, 'opacity=".85"')}
    ${ticks.join('')}
    <text x="${cx}" y="${cy + 34}" text-anchor="middle" class="tach-label">RPM × 1000</text>
    <text x="${cx}" y="${cy + 54}" text-anchor="middle" class="tach-redline">LIMIT ${maxRpm.toLocaleString('en-US')}</text>
    <g id="tach-needle" transform="rotate(${start} ${cx} ${cy})">
      <line x1="${cx}" y1="${cy + 8}" x2="${cx}" y2="42" stroke="#ffb23e" stroke-width="3.2" stroke-linecap="round"/>
      <line x1="${cx}" y1="${cy + 8}" x2="${cx}" y2="42" stroke="#ff7a1a" stroke-width="1.2" stroke-linecap="round" opacity=".7"/>
    </g>
    <circle cx="${cx}" cy="${cy}" r="7" fill="#14191b" stroke="#ffb23e" stroke-width="2"/>
    <circle cx="${cx}" cy="${cy}" r="2.5" fill="#ffb23e"/>
  </svg>`
}

export function dynoChart(points: DynoPoint[], cursor: number): string {
  const width = 440
  const height = 190
  const left = 38
  const right = width - 18
  const top = 16
  const bottom = height - 28
  if (points.length === 0) {
    return `<svg class="dyno-chart" viewBox="0 0 ${width} ${height}"><text x="${width / 2}" y="${height / 2}" text-anchor="middle" class="chart-empty">No curve</text></svg>`
  }
  const maxHp = Math.max(100, ...points.map(p => p.hp)) * 1.14
  const maxTq = Math.max(100, ...points.map(p => p.torque)) * 1.14
  const minRpm = points[0].rpm
  const maxRpm = points[points.length - 1].rpm
  const x = (rpm: number) => left + ((rpm - minRpm) / Math.max(1, maxRpm - minRpm)) * (right - left)
  const yHp = (hp: number) => bottom - (hp / maxHp) * (bottom - top)
  const yTq = (tq: number) => bottom - (tq / maxTq) * (bottom - top)
  const hpPath = points.map((p, i) => `${i === 0 ? 'M' : 'L'}${x(p.rpm).toFixed(1)} ${yHp(p.hp).toFixed(1)}`).join(' ')
  const tqPath = points.map((p, i) => `${i === 0 ? 'M' : 'L'}${x(p.rpm).toFixed(1)} ${yTq(p.torque).toFixed(1)}`).join(' ')
  const grid: string[] = []
  for (let i = 0; i <= 4; i += 1) {
    const yy = top + ((bottom - top) / 4) * i
    grid.push(`<line x1="${left}" y1="${yy}" x2="${right}" y2="${yy}" class="chart-grid"/>`)
  }
  const rpmLabels = [1000, 3000, 5000, 7000, 9000].filter(r => r >= minRpm && r <= maxRpm)
  const labels = rpmLabels.map(r => `<text x="${x(r)}" y="${bottom + 15}" text-anchor="middle" class="chart-label">${r / 1000}k</text>`).join('')
  const cursorIndex = clamp(cursor, 0, points.length - 1)
  const reveal = points.length <= 1 ? right : x(points[cursorIndex].rpm)
  return `<svg class="dyno-chart" viewBox="0 0 ${width} ${height}" role="img" aria-label="Power and torque curve">
    <defs>
      <clipPath id="dyno-reveal"><rect id="dyno-reveal-rect" x="${left}" y="0" width="${Math.max(0, reveal - left)}" height="${height}"/></clipPath>
    </defs>
    ${grid.join('')}
    ${labels}
    <text x="${left}" y="${top - 3}" class="chart-label">HP</text>
    <text x="${right}" y="${top - 3}" text-anchor="end" class="chart-label">NM</text>
    <g clip-path="url(#dyno-reveal)">
      <path d="${hpPath}" class="chart-hp"/>
      <path d="${tqPath}" class="chart-tq"/>
    </g>
    <line id="dyno-cursor" x1="${reveal}" y1="${top}" x2="${reveal}" y2="${bottom}" class="chart-cursor"/>
    <circle id="dyno-dot-hp" cx="${x(points[cursorIndex].rpm)}" cy="${yHp(points[cursorIndex].hp)}" r="4" class="chart-dot-hp"/>
    <circle id="dyno-dot-tq" cx="${x(points[cursorIndex].rpm)}" cy="${yTq(points[cursorIndex].torque)}" r="4" class="chart-dot-tq"/>
    <g class="chart-legend"><line x1="${left}" y1="${height - 7}" x2="${left + 16}" y2="${height - 7}" class="chart-hp"/><text x="${left + 22}" y="${height - 4}" class="chart-label">Power</text><line x1="${left + 90}" y1="${height - 7}" x2="${left + 106}" y2="${height - 7}" class="chart-tq"/><text x="${left + 112}" y="${height - 4}" class="chart-label">Torque</text></g>
  </svg>`
}

export function courseMapSvg(): string {
  const points = [[0, 10], [52, 14], [92, 52], [88, 106], [48, 138], [-4, 134], [-48, 98], [-56, 48], [-28, 16]]
  const mapped = points.map(([x, z]) => [80 + x, 20 + z * 1.05])
  const d = mapped.map(([x, y], i) => `${i === 0 ? 'M' : 'L'}${x.toFixed(1)} ${y.toFixed(1)}`).join(' ') + ' Z'
  return `<svg class="course-map" viewBox="0 0 240 185" role="img" aria-label="Handling course layout">
    <path d="${d}" class="course-outline"/>
    <path id="course-path" d="${d}" class="course-line"/>
    <circle id="course-dot" cx="${mapped[0][0]}" cy="${mapped[0][1]}" r="5" class="course-dot"/>
    <text x="86" y="26" class="chart-label">START</text>
    <text x="136" y="120" class="chart-label">SWEEPS</text>
    <text x="20" y="116" class="chart-label">HAIRPIN</text>
  </svg>`
}

export function conditionBar(condition: number): string {
  const level = condition <= 0 ? 'bad' : condition < 55 ? 'warn' : 'ok'
  return `<div class="condition-bar ${level}"><i style="width:${clamp(condition, 0, 100)}%"></i></div>`
}

export function statBlock(label: string, value: string, detail = '', cls = ''): string {
  return `<div class="stat-block ${cls}"><span>${esc(label)}</span><b>${value}</b>${detail ? `<em>${esc(detail)}</em>` : ''}</div>`
}
