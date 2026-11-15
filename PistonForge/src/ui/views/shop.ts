import type { App } from '../../app'
import { AERO, BODIES, BRAKES, GEARBOXES, SUSPENSIONS, TIRES, WEIGHT_REDUCTION, partOption } from '../../sim/data'
import { PART_SLOTS, type PartSlot } from '../../sim/types'
import { carSilhouette, esc, icon, money, num } from '../components'
import { conditionLabel } from '../../sim/builds'
import type { UiState } from '../types'
import { consoleHead, tag, type View } from './shared'

const SLOT_LABEL: Record<PartSlot, string> = {
  head: 'Cylinder head',
  cams: 'Camshaft',
  intake: 'Intake',
  exhaust: 'Exhaust',
  injectors: 'Injectors',
  pump: 'Fuel pump',
  internals: 'Rotating assembly',
  valves: 'Valves & springs',
  gasket: 'Head gasket',
  intercooler: 'Charge cooling',
}

function effect(slot: PartSlot, index: number): string {
  const part = partOption(slot, index) as unknown as Record<string, unknown>
  const get = (key: string) => Number(part[key] ?? 0)
  switch (slot) {
    case 'head':
    case 'intake':
    case 'exhaust': return `Flow ${get('flow').toFixed(2)}×`
    case 'cams': return `${get('duration')}° duration · +${get('peakOffset')} rpm`
    case 'injectors': return `${get('cc')} cc/min`
    case 'pump': return `${get('lph')} l/h`
    case 'internals': return `${get('maxRpm')} rpm limit · ${get('strength').toFixed(2)}× strength`
    case 'valves': return `+${get('rpmAdd')} rpm before float`
    case 'gasket': return `Seals to ${get('boostLimit')} psi`
    case 'intercooler': return `${Math.round(get('cooling') * 100)}% charge cooling`
    default: return ''
  }
}

function engineTab(app: App): string {
  const build = app.activeBuild()
  const cards = PART_SLOTS.map(slot => {
    const current = build.engine.parts[slot]
    const options = Array.from({ length: slot === 'head' ? 4 : slot === 'cams' ? 5 : slot === 'injectors' ? 5 : slot === 'pump' ? 4 : slot === 'internals' ? 4 : slot === 'valves' ? 3 : slot === 'gasket' ? 3 : slot === 'intercooler' ? 3 : 3 }, (_, index) => {
      const option = partOption(slot, index)
      const locked = !app.isPartUnlocked(slot, index)
      const fitted = index === current
      const cost = app.partCost(slot, index)
      return `<div class="part-option ${fitted ? 'is-fitted' : ''} ${locked ? 'is-locked' : ''}">
        <div class="part-option-copy"><b>${esc(option.name)}</b><span>${esc(effect(slot, index))}</span><em>${esc(option.desc)}</em></div>
        <div class="part-option-buy">${fitted ? tag('FITTED', 'ok') : locked ? tag(`${option.unlockRep} REP`, 'muted') : `<span>${cost > 0 ? money(cost) : 'Included'}</span><button type="button" class="mini-btn" data-action="install-part" data-slot="${slot}" data-index="${index}" ${locked ? 'disabled' : ''}>Fit</button>`}</div>
      </div>`
    }).join('')
    return `<details class="part-card" ${slot === 'head' || slot === 'cams' ? 'open' : ''}>
      <summary><div><span>${esc(SLOT_LABEL[slot])}</span><b>${esc(partOption(slot, current).name)}</b></div><em>${esc(effect(slot, current))}</em>${icon('arrow')}</summary>
      <div class="part-options">${options}</div>
    </details>`
  }).join('')
  return `<div class="shop-copy"><b>Engine hardware</b><span>Prices are fitted. Upgrades are charged once; swapping back does not refund labour.</span></div>${cards}`
}

function chassisTab(app: App): string {
  const build = app.activeBuild()
  const current = build.chassis
  const groups: { kind: 'tires' | 'suspension' | 'brakes' | 'gearbox' | 'weight'; label: string; table: Record<string, { name: string; cost: number; desc: string }>; value: string }[] = [
    { kind: 'tires', label: 'Tyres', table: TIRES, value: current.tires },
    { kind: 'suspension', label: 'Suspension', table: SUSPENSIONS, value: current.suspension },
    { kind: 'brakes', label: 'Brakes', table: BRAKES, value: current.brakes },
    { kind: 'gearbox', label: 'Gearbox', table: GEARBOXES, value: current.gearbox },
    { kind: 'weight', label: 'Interior weight', table: WEIGHT_REDUCTION, value: current.weight },
  ]
  const groupHtml = groups.map(group => {
    const rows = Object.entries(group.table).map(([id, item]) => {
      const active = id === group.value
      return `<div class="part-option ${active ? 'is-fitted' : ''}">
        <div class="part-option-copy"><b>${esc(item.name)}</b><em>${esc(item.desc)}</em></div>
        <div class="part-option-buy">${active ? tag('FITTED', 'ok') : `<span>${item.cost > 0 ? money(item.cost) : 'Included'}</span><button type="button" class="mini-btn" data-action="install-chassis" data-kind="${group.kind}" data-id="${id}" ${active ? 'disabled' : ''}>Fit</button>`}</div>
      </div>`
    }).join('')
    return `<details class="part-card" open><summary><div><span>${esc(group.label)}</span><b>${esc((group.table[group.value] as { name: string }).name)}</b></div><em>${esc((group.table[group.value] as { desc: string }).desc)}</em>${icon('arrow')}</summary><div class="part-options">${rows}</div></details>`
  }).join('')
  const aeroRows = Object.entries(AERO).map(([id, item]) => {
    const active = id === build.aero
    return `<div class="part-option ${active ? 'is-fitted' : ''}"><div class="part-option-copy"><b>${esc(item.name)}</b><em>${esc(item.desc)}</em><span>+${Math.round(item.downforce * 100)}% downforce · +${Math.round(item.drag * 100)} drag</span></div><div class="part-option-buy">${active ? tag('FITTED', 'ok') : `<span>${item.cost > 0 ? money(item.cost) : 'Included'}</span><button type="button" class="mini-btn" data-action="install-aero" data-id="${id}" ${active ? 'disabled' : ''}>Fit</button>`}</div></div>`
  }).join('')
  const interiorRows = (['full', 'stripped'] as const).map(id => {
    const active = build.interior === id
    return `<div class="part-option ${active ? 'is-fitted' : ''}"><div class="part-option-copy"><b>${id === 'full' ? 'Full interior' : 'Stripped / cage'}</b><em>${id === 'full' ? 'Carpet, rear seats, sound deadening. 0 kg saved.' : 'Rear interior out, cage in. 18 kg saved, more road noise.'}</em></div><div class="part-option-buy">${active ? tag('FITTED', 'ok') : `<span>Included</span><button type="button" class="mini-btn" data-action="install-interior" data-id="${id}">Fit</button>`}</div></div>`
  }).join('')
  return `<div class="shop-copy"><b>Chassis & driveline</b><span>These parts change the launch, the lap and the way the car puts power down.</span></div>${groupHtml}
    <details class="part-card" open><summary><div><span>Aero</span><b>${esc(AERO[build.aero].name)}</b></div><em>${esc(AERO[build.aero].desc)}</em>${icon('arrow')}</summary><div class="part-options">${aeroRows}</div></details>
    <details class="part-card" open><summary><div><span>Interior</span><b>${build.interior === 'full' ? 'Full interior' : 'Stripped / cage'}</b></div><em>Visual + mass</em>${icon('arrow')}</summary><div class="part-options">${interiorRows}</div></details>`
}

function bodiesTab(app: App): string {
  const state = app.state
  const build = app.activeBuild()
  return `<div class="shop-copy"><b>Body shells</b><span>${BODIES.length} original archetypes. Bay dimensions and mass are part of the engineering, not decoration.</span></div>
    <div class="body-shop-grid">${BODIES.map(item => {
      const active = item.id === build.bodyId
      const owned = state.mode === 'sandbox' || state.ownedBodies.includes(item.id)
      const unlocked = state.mode === 'sandbox' || item.unlockRep <= state.rep
      const fit = app.fitmentFor({ ...build, bodyId: item.id })
      const canSelect = !state.job && owned && fit.fits
      const canBuy = !state.job && !owned && unlocked
      return `<article class="body-shop-card ${active ? 'active' : ''}">
        ${carSilhouette(item)}
        <div class="body-shop-head"><b>${esc(item.name)}</b><span>${esc(item.subtitle)} · ${item.era}</span></div>
        <div class="body-shop-specs"><span>${num(item.length, 2)} m</span><span>${num(item.kerbKg)} kg</span><span>${item.drivetrain}</span></div>
        <div class="body-shop-bay"><span>BAY</span><b>${item.bay.length}×${item.bay.width}×${item.bay.height}</b><em>${item.bay.length >= 820 ? 'LONG' : 'COMPACT'}</em></div>
        <div class="body-shop-foot">${active ? tag('FITTED', 'ok') : !unlocked ? tag(`${item.unlockRep} REP`, 'muted') : !fit.fits ? tag('NO FIT', 'bad') : `<span class="body-price">${owned ? 'OWNED' : money(item.cost)}</span>`}
          ${!active ? (canSelect ? `<button type="button" class="mini-btn" data-action="select-body" data-id="${item.id}">Fit</button>` : canBuy ? `<button type="button" class="mini-btn" data-action="buy-select-body" data-id="${item.id}">Buy + fit</button>` : `<button type="button" class="mini-btn" disabled>${!unlocked ? 'Locked' : 'No fit'}</button>`) : ''}
        </div>
      </article>`
    }).join('')}</div>`
}

export function shopView(app: App, ui: UiState): View {
  const state = app.state
  const build = app.activeBuild()
  const condition = conditionLabel(build.condition)
  const tab = ui.shopTab
  const budget = state.job ? `${money(state.job.contract.budget - state.job.spent)} job budget left` : state.mode === 'sandbox' ? 'Sandbox · no charge' : `${money(state.cash)} cash`
  const content = tab === 'engine' ? engineTab(app) : tab === 'chassis' ? chassisTab(app) : bodiesTab(app)
  const consoleHtml = `${consoleHead('PARTS COUNTER / SHOP', tab === 'engine' ? 'Engine hardware' : tab === 'chassis' ? 'Chassis & driveline' : 'Body shells', `${budget} · ${condition.text}`, state.job ? tag('CUSTOMER BUDGET', 'warn') : '')}
  <div class="shop-tabs">
    <button type="button" data-action="shop-tab" data-tab="engine" class="${tab === 'engine' ? 'active' : ''}">${icon('engine')} Engine</button>
    <button type="button" data-action="shop-tab" data-tab="chassis" class="${tab === 'chassis' ? 'active' : ''}">${icon('gauge')} Chassis</button>
    <button type="button" data-action="shop-tab" data-tab="bodies" class="${tab === 'bodies' ? 'active' : ''}">${icon('garage')} Bodies</button>
  </div>
  <div class="console-scroll">${content}
    <div class="advice advice-info">${icon('shop')}<span>Parts fit instantly and invalidate the last proof until you re-run it. In sandbox, everything is unlocked and free.</span></div>
  </div>
  <footer class="console-foot">
    <span class="foot-status"><i></i> ${tab.toUpperCase()} COUNTER</span>
    <button type="button" class="text-btn" data-action="go-garage">Back to bay ${icon('arrow')}</button>
  </footer>`
  return { console: consoleHtml, overlay: `<div class="stage-plate"><span>PARTS COUNTER</span><b>${esc(build.name)}</b><em>${money(state.cash)} cash</em><em>${state.rep} reputation</em></div>`, className: 'screen-shop' }
}
