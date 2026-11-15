import type { App } from '../../app'
import { PAINTS, WHEEL_STYLES, bodyById } from '../../sim/data'
import { conditionLabel, engineLabel, repairCost, rebuildCost } from '../../sim/builds'
import { reputationProgress } from '../../sim/career'
import { carSilhouette, conditionBar, esc, icon, money, num, statBlock } from '../components'
import { actionButton, consoleHead, overlayPlate, rangeRow, section, tag, type View } from './shared'

export function garageView(app: App): View {
  const state = app.state
  const build = app.activeBuild()
  const body = bodyById(build.bodyId)
  const peak = app.peak(build)
  const stats = app.stats(build)
  const fit = app.fitmentFor(build)
  const condition = conditionLabel(build.condition)
  const rep = reputationProgress(state.rep)
  const job = state.job
  const jobProgress = app.jobProgress()
  const runGate = app.canRun(build)
  const sandbox = state.mode === 'sandbox'

  const bodyCards = app.bodies().map(item => {
    const active = item.id === build.bodyId
    const owned = sandbox || state.ownedBodies.includes(item.id)
    const unlocked = sandbox || item.unlockRep <= state.rep
    const bodyFit = app.fitmentFor({ ...build, bodyId: item.id })
    const selectable = !job && !active && owned && unlocked && bodyFit.fits
    const buyable = !job && !active && !owned && unlocked
    const label = active ? 'Fitted' : owned ? 'In shop' : !unlocked ? `${item.unlockRep} rep` : money(item.cost)
    const action = active ? '' : selectable ? 'select-body' : buyable ? 'buy-select-body' : ''
    const cls = [active ? 'active' : '', !bodyFit.fits ? 'no-fit' : '', !owned && !unlocked ? 'locked' : ''].filter(Boolean).join(' ')
    return `<button type="button" class="body-card ${cls}" ${action ? `data-action="${action}" data-id="${item.id}"` : 'disabled'} title="${esc(item.name)} — ${esc(item.subtitle)}">
      ${carSilhouette(item)}
      <span class="body-card-name">${esc(item.name)}</span>
      <span class="body-card-sub">${esc(item.subtitle)}</span>
      <span class="body-card-meta">${num(item.length, 2)} m · ${num(item.kerbKg)} kg · ${item.drivetrain}</span>
      <span class="body-card-tag">${bodyFit.fits ? label : 'No fit'}</span>
    </button>`
  }).join('')

  const swatches = PAINTS.map(paint => `<button type="button" class="swatch ${build.paint.color.toLowerCase() === paint.hex.toLowerCase() ? 'active' : ''}" style="--swatch:${paint.hex}" data-action="paint-color" data-color="${paint.hex}" aria-label="${esc(paint.name)}" title="${esc(paint.name)}"><i></i></button>`).join('')

  const finishButtons = (['gloss', 'satin', 'matte', 'metallic'] as const).map(finish => `<button type="button" data-action="paint-finish" data-finish="${finish}" class="${build.paint.finish === finish ? 'active' : ''}" aria-pressed="${build.paint.finish === finish}">${finish}</button>`).join('')
  const wheelButtons = WHEEL_STYLES.map(wheel => `<button type="button" data-action="wheel-style" data-style="${wheel.id}" class="${build.wheels.style === wheel.id ? 'active' : ''}" aria-pressed="${build.wheels.style === wheel.id}">${esc(wheel.name)}</button>`).join('')

  const jobLine = job && jobProgress
    ? `<div class="job-banner">
        <div><span>${esc(job.contract.code)} · CUSTOMER CAR</span><b>${esc(job.contract.title)}</b><em>${esc(job.contract.customer)} · target ${esc(jobProgress.label)}</em></div>
        <button type="button" class="mini-btn" data-action="go-jobs">Open job</button>
      </div>`
    : ''

  const overlay = `${overlayPlate('BAY 03 / CURRENT BUILD', build.name, [body.name, engineLabel(build), `${peak.hp} hp est. · ${stats.mass} kg`])}
    <div class="stage-actions"><button type="button" class="stage-btn" data-action="go-engine">${icon('engine')} Open engine</button><button type="button" class="stage-btn" data-action="go-dyno">${icon('dyno')} Dyno</button></div>`

  const consoleHtml = `${consoleHead('BAY 03 / PROJECT', build.name, `${body.name} · ${engineLabel(build)}`, job ? tag('CONTRACT', 'warn') : sandbox ? tag('SANDBOX', 'info') : tag(rep.name.toUpperCase(), 'muted'))}
  <div class="console-scroll">
    ${jobLine}
    ${!fit.fits ? `<div class="alert alert-bad">${icon('warning')}<div><b>Engine does not fit this body</b><span>${fit.blocker} is over by ${fit.overByMm} mm. Repackage or choose a larger bay.</span></div></div>` : ''}
    <div class="hero-readout">
      <div><span>EST. PEAK POWER</span><b>${num(peak.hp)}<small>HP</small></b><em>@ ${num(peak.hpRpm)} rpm</em></div>
      <div><span>EST. PEAK TORQUE</span><b>${num(peak.torque)}<small>NM</small></b><em>@ ${num(peak.torqueRpm)} rpm</em></div>
    </div>
    <div class="stat-strip">
      ${statBlock('Power / weight', `${num(stats.powerToWeight, 1)}`, 'hp / tonne')}
      ${statBlock('Top speed', `${num(stats.topSpeed)}`, 'km/h est.')}
      ${statBlock('Drivetrain', body.drivetrain, body.enginePosition === 'mid' ? 'mid engine' : 'front engine')}
      ${statBlock('Gears', `${stats.gears}`, 'forward')}
    </div>
    ${section('BODY', `<div class="body-grid">${bodyCards}</div>`, `${app.bodies().length} archetypes · bay limits enforced`)}
    ${section('PAINT', `<div class="swatch-grid">${swatches}</div><div class="segmented finish-row" role="group" aria-label="Paint finish">${finishButtons}</div>`, PAINTS.find(p => p.hex.toLowerCase() === build.paint.color.toLowerCase())?.name ?? 'Custom')}
    ${section('WHEELS & STANCE', `<div class="segmented wheel-row" role="group" aria-label="Wheel style">${wheelButtons}</div>
      ${rangeRow({ label: 'Wheel diameter', value: build.wheels.size, min: 14, max: 22, step: 1, attrs: 'data-wheel-size', display: `${build.wheels.size}"` })}
      ${rangeRow({ label: 'Stance', value: build.stance, min: -1, max: 1, step: 0.05, attrs: 'data-stance', display: build.stance === 0 ? 'Neutral' : build.stance > 0 ? `Slammed ${Math.round(build.stance * 100)}%` : `Raised ${Math.round(-build.stance * 100)}%` })}
    `, 'Visual only')}
    ${section('CONDITION', `<div class="condition-head"><b class="condition-${condition.level}">${condition.text}</b><span>${num(build.condition, 1)}%</span></div>${conditionBar(build.condition)}
      <div class="row-actions">
        ${actionButton(`Service · ${money(repairCost(build))}`, 'repair-engine', { disabled: build.condition >= 100 || build.condition <= 0 })}
        ${actionButton(`Fresh build · ${money(rebuildCost(build))}`, 'rebuild-engine', { disabled: build.condition > 0, kind: 'danger' })}
      </div>
      <small class="fineprint">Condition falls with every pull and run. A seized engine cannot be run.</small>
    `, 'Wear is real')}
    <div class="action-grid">
      <button type="button" class="action-card" data-action="go-engine"><span>01</span>${icon('engine')}<b>Engine</b><em>Assemble / upgrade</em></button>
      <button type="button" class="action-card" data-action="go-ecu"><span>02</span>${icon('ecu')}<b>ECU</b><em>Fuel / ignition</em></button>
      <button type="button" class="action-card ${runGate.ok ? '' : 'is-disabled'}" data-action="go-dyno" ${runGate.ok ? '' : 'disabled'}><span>03</span>${icon('dyno')}<b>Dyno</b><em>Load sweep</em></button>
      <button type="button" class="action-card ${runGate.ok ? '' : 'is-disabled'}" data-action="go-test" ${runGate.ok ? '' : 'disabled'}><span>04</span>${icon('test')}<b>Prove it</b><em>Strip / course</em></button>
    </div>
    ${!runGate.ok && build.condition > 0 ? `<div class="alert alert-warn">${icon('warning')}<div><b>Proving grounds locked</b><span>${esc(runGate.reason)}</span></div></div>` : ''}
    <div class="record-strip">
      ${statBlock('Best power', state.bests.hp > 0 ? `${state.bests.hp} hp` : '—', '', 'small')}
      ${statBlock('Best 1/4', state.bests.et > 0 ? `${state.bests.et.toFixed(2)} s` : '—', '', 'small')}
      ${statBlock('Best lap', state.bests.lap > 0 ? `${state.bests.lap.toFixed(2)} s` : '—', '', 'small')}
    </div>
    ${job ? `<div class="budget-line"><span>Customer budget</span><b>${money(job.contract.budget - job.spent)} left</b><em>${money(job.spent)} spent</em></div>` : ''}
  </div>
  <footer class="console-foot">
    <span class="foot-status"><i></i> ${state.mode === 'career' ? 'CAREER SAVE' : 'SANDBOX SESSION'}</span>
    <span class="foot-rep">${rep.name} · ${state.rep} rep</span>
    <button type="button" class="text-btn" data-action="go-shop">Parts counter ${icon('arrow')}</button>
  </footer>`

  return { console: consoleHtml, overlay }
}
