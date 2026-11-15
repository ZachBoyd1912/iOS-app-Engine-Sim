import type { App } from '../../app'
import { FUELS, INDUCTIONS, LAYOUTS, PART_TABLES } from '../../sim/data'
import { buildAdvice, engineSpec, fitment } from '../../sim/engine'
import type { EngineConfig, PartSlot } from '../../sim/types'
import { esc, icon, money, num } from '../components'
import type { UiState } from '../types'
import { consoleHead, rangeRow, section, selectControl, tag, type View } from './shared'

type PartLike = { name: string; short: string; cost: number; unlockRep: number; desc: string; [key: string]: unknown }

function partEffect(slot: PartSlot, option: PartLike): string {
  const get = (key: string) => Number(option[key] ?? 0)
  switch (slot) {
    case 'head': return `Flow ${get('flow').toFixed(2)}×`
    case 'cams': return `${get('duration')}° dur · +${get('peakOffset')} rpm`
    case 'intake':
    case 'exhaust': return `Flow ${get('flow').toFixed(2)}×`
    case 'injectors': return `${get('cc')} cc/min`
    case 'pump': return `${get('lph')} l/h`
    case 'internals': return `${get('maxRpm')} rpm · strength ${get('strength').toFixed(2)}×`
    case 'valves': return `+${get('rpmAdd')} rpm valve float`
    case 'gasket': return `${get('boostLimit')} psi boost limit`
    case 'intercooler': return `${Math.round(get('cooling') * 100)}% charge cooling`
    default: return ''
  }
}

function partSelect(app: App, draft: EngineConfig, slot: PartSlot, label: string): string {
  const options = PART_TABLES[slot] as unknown as readonly PartLike[]
  const current = draft.parts[slot]
  const currentOption = options[current]
  const choices = options.map((option, index) => {
    const locked = app.state.mode !== 'sandbox' && option.unlockRep > app.state.rep
    const suffix = index === current ? ' — fitted' : option.cost > 0 ? ` — ${money(option.cost)}` : ' — included'
    return { value: String(index), label: `${option.name}${suffix}${locked ? ' [LOCKED]' : ''}`, selected: index === current, disabled: locked }
  })
  return `<label class="field-row part-field">
    <span class="field-label">${esc(label)}</span>
    ${selectControl(`data-draft-part="${slot}"`, choices)}
    <small>${esc(currentOption?.desc ?? '')} <b class="effect">${esc(partEffect(slot, currentOption))}</b></small>
  </label>`
}

export function engineView(app: App, ui: UiState): View {
  const draft = app.engineDraft ?? app.activeBuild().engine
  const build = app.activeBuild()
  const spec = engineSpec(draft)
  const fit = fitment(draft, build.bodyId)
  const cost = app.draftCost()
  const advice = buildAdvice(draft)
  const presets = app.enginePresetList()
  const tab = ui.engineTab
  const sandbox = app.state.mode === 'sandbox'
  const job = app.state.job

  const layoutOptions = Object.values(LAYOUTS).map(layout => ({ value: layout.id, label: layout.name, selected: layout.id === draft.layout }))
  const fuelOptions = Object.values(FUELS).map(fuel => ({ value: fuel.id, label: `${fuel.name} · ${fuel.octane} RON${!sandbox && fuel.unlockRep > app.state.rep ? ' [LOCKED]' : ''}`, selected: fuel.id === draft.fuel, disabled: !sandbox && fuel.unlockRep > app.state.rep }))
  const inductionOptions = Object.values(INDUCTIONS).map(item => ({ value: item.id, label: `${item.name} · ${item.maxBoost > 0 ? `${item.maxBoost} psi` : item.nitrousHp > 0 ? `+${item.nitrousHp} hp` : 'linear'}${!sandbox && item.unlockRep > app.state.rep ? ' [LOCKED]' : ''}`, selected: item.id === draft.induction, disabled: !sandbox && item.unlockRep > app.state.rep }))

  const bottomTab = `<div class="engine-tab-body">
    ${selectControl('data-draft-layout', layoutOptions).replace('<select ', '<select class="big-select" aria-label="Engine layout" ')}
    <p class="spec-note">${esc(LAYOUTS[draft.layout].note)}</p>
    <div class="two-col">
      ${rangeRow({ label: 'Bore', value: draft.bore, min: 60, max: 115, step: 0.25, attrs: 'data-draft-slider="bore"', display: `${num(draft.bore, 2)} mm` })}
      ${rangeRow({ label: 'Stroke', value: draft.stroke, min: 60, max: 115, step: 0.25, attrs: 'data-draft-slider="stroke"', display: `${num(draft.stroke, 2)} mm` })}
    </div>
    ${rangeRow({ label: 'Compression', value: draft.compression, min: 7, max: 14, step: 0.1, attrs: 'data-draft-slider="compression"', display: `${num(draft.compression, 1)} : 1`, hint: 'Static ratio. Boost and fuel decide whether it survives.' })}
    ${partSelect(app, draft, 'internals', 'Rotating assembly')}
    ${partSelect(app, draft, 'gasket', 'Head gasket')}
  </div>`

  const headTab = `<div class="engine-tab-body">
    ${partSelect(app, draft, 'head', 'Cylinder head')}
    ${partSelect(app, draft, 'cams', 'Camshaft profile')}
    ${partSelect(app, draft, 'valves', 'Valves & springs')}
    <div class="spec-note"><b>CAM WINDOW</b> Peak volumetric efficiency lands around ${num(spec.camPeakRpm)} rpm. Valve float is modelled at the mechanical redline.</div>
  </div>`

  const airTab = `<div class="engine-tab-body">
    ${partSelect(app, draft, 'intake', 'Intake system')}
    ${partSelect(app, draft, 'exhaust', 'Exhaust system')}
    ${partSelect(app, draft, 'injectors', 'Injectors')}
    ${partSelect(app, draft, 'pump', 'Fuel pump')}
    <label class="field-row"><span class="field-label">Fuel</span>${selectControl('data-draft-fuel', fuelOptions)}<small>${esc(FUELS[draft.fuel].note)}</small></label>
    <div class="spec-note"><b>STOICH ${FUELS[draft.fuel].stoich.toFixed(1)} : 1</b> Target ${FUELS[draft.fuel].afrTarget.toFixed(1)} AFR at load. ${FUELS[draft.fuel].octane} RON.</div>
  </div>`

  const boostTab = `<div class="engine-tab-body">
    <label class="field-row"><span class="field-label">Induction</span>${selectControl('data-draft-induction', inductionOptions)}<small>${esc(INDUCTIONS[draft.induction].note)}</small></label>
    ${partSelect(app, draft, 'intercooler', 'Charge cooling')}
    <div class="boost-cards">
      <div><span>BOOST CEILING</span><b>${INDUCTIONS[draft.induction].maxBoost > 0 ? `${INDUCTIONS[draft.induction].maxBoost} psi` : draft.induction === 'nitrous' ? `+${INDUCTIONS[draft.induction].nitrousHp} hp` : 'N/A'}</b><em>${INDUCTIONS[draft.induction].linear ? 'instant' : INDUCTIONS[draft.induction].spoolRpm > 0 ? `${num(INDUCTIONS[draft.induction].spoolRpm)} rpm spool` : 'linear'}</em></div>
      <div><span>COMPRESSOR</span><b>${Math.round(INDUCTIONS[draft.induction].efficiency * 100)}%</b><em>adiabatic efficiency</em></div>
    </div>
    <div class="spec-note"><b>NO FREE BOOST</b> Higher targets need gasket headroom, fuel system headroom and ignition margin. The ECU is where it becomes real.</div>
  </div>`

  const fitRow = (label: string, value: number, bay: number) => {
    const over = value > bay
    return `<div class="fit-row ${over ? 'over' : ''}"><span>${label}</span><div class="fit-track"><i style="width:${Math.min(100, (value / bay) * 100)}%"></i></div><b>${value} / ${bay} mm</b></div>`
  }

  const warnings = [...spec.warnings.map(text => ({ level: 'warn' as const, text })), ...advice]
  const warningHtml = warnings.length
    ? `<div class="advice-list">${warnings.map(item => `<div class="advice advice-${item.level}">${icon(item.level === 'bad' ? 'warning' : 'bolt')}<span>${esc(item.text)}</span></div>`).join('')}</div>`
    : `<div class="advice advice-ok">${icon('check')}<span>No mechanical warnings. The spec is internally consistent.</span></div>`

  const consoleHtml = `${consoleHead('ASSEMBLY BENCH / DRAFT', 'Build an engine', `${LAYOUTS[draft.layout].name} · ${num(spec.displacementL, 1)} L · ${spec.cylinders}${spec.rotors ? ` / ${spec.rotors} rotors` : ' cylinders'}`, tag('DRAFT', 'warn'))}
  <div class="console-scroll">
    <label class="name-field"><span>BUILD NAME</span><input type="text" maxlength="28" value="${esc(draft.name)}" data-draft-name autocomplete="off" spellcheck="false"></label>
    <details class="preset-box" ${ui.enginePresetOpen ? 'open' : ''}>
      <summary>Start from a known combination <span>${presets.length} presets</span></summary>
      <div class="preset-list">
        ${presets.map(preset => `<button type="button" class="preset-card" data-action="preset" data-id="${preset.id}"><b>${esc(preset.name)}</b><span>${esc(preset.note)}</span></button>`).join('')}
      </div>
    </details>
    <div class="engine-tabs" role="tablist" aria-label="Engine sections">
      ${(['bottom', 'head', 'air', 'boost'] as const).map(item => `<button type="button" role="tab" data-action="engine-tab" data-tab="${item}" class="${tab === item ? 'active' : ''}" aria-selected="${tab === item}">${item === 'bottom' ? 'Bottom end' : item === 'head' ? 'Head & cam' : item === 'air' ? 'Air & fuel' : 'Boost'}</button>`).join('')}
    </div>
    ${tab === 'bottom' ? bottomTab : tab === 'head' ? headTab : tab === 'air' ? airTab : boostTab}
    <div class="spec-panel">
      <div class="spec-top"><span>ENGINE SPEC</span><b>${num(spec.displacementCc)} cc</b></div>
      <div class="spec-grid">
        <div><span>Redline</span><b>${num(spec.mechanicalRedline)}</b><em>rpm</em></div>
        <div><span>Mass</span><b>${num(spec.massKg)}</b><em>kg</em></div>
        <div><span>Bore / stroke</span><b>${num(spec.boreStrokeRatio, 2)}</b><em>ratio</em></div>
        <div><span>Parts</span><b>${money(spec.partsCost)}</b><em>list</em></div>
      </div>
      <div class="fit-head"><span>FITMENT · ${esc(build.bodyId.toUpperCase())}</span>${fit.fits ? tag('FITS', 'ok') : tag(`${fit.blocker?.toUpperCase()} OVER`, 'bad')}</div>
      ${fitRow('Length', spec.envelopeMm.length, fit.bay.length)}
      ${fitRow('Width', spec.envelopeMm.width, fit.bay.width)}
      ${fitRow('Height', spec.envelopeMm.height, fit.bay.height)}
    </div>
    ${section('NOTES', warningHtml, 'Simulation warnings')}
    <div class="advice advice-info">${icon('gauge')}<span>This is a draft. The engine on the stand updates as you work; nothing is charged until you commit.</span></div>
  </div>
  <footer class="console-foot engine-foot">
    <div class="cost-stack"><span>PARTS ${money(cost.diff)}</span><b>BENCH ${money(cost.bench)}</b><strong>${money(cost.total)}</strong></div>
    <div class="foot-actions">
      <button type="button" class="btn" data-action="revert-draft">Revert</button>
      <button type="button" class="btn btn-ghost" data-action="cancel-draft">Cancel</button>
      <button type="button" class="btn btn-primary" data-action="apply-draft" ${!fit.fits ? 'disabled' : ''}>Commit build</button>
    </div>
    ${job ? `<span class="foot-budget">JOB BUDGET ${money(job.contract.budget - job.spent)} left</span>` : ''}
  </footer>`

  const overlay = `<div class="stage-plate engine-plate"><span>ENGINE STAND / LIVE DRAFT</span><b>${esc(draft.name)}</b><em>${num(spec.displacementCc)} cc · ${num(spec.mechanicalRedline)} rpm</em><em>${esc(spec.inductionName)} · ${esc(spec.fuelName)}</em></div>
    <div class="engine-callouts"><span>CAM ${num(draft.parts.cams + 1)}</span><span>VE ${Math.round(spec.peakVe * 100)}%</span><span>${draft.faults?.length ? `${draft.faults.length} FAULT` : 'NO FAULTS'}</span></div>
    <div class="stage-actions"><button type="button" class="stage-btn" data-action="toggle-cutaway">${icon('engine')} Cutaway</button></div>`

  return { console: consoleHtml, overlay, className: 'screen-engine' }
}
