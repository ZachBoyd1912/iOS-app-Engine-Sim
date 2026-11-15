import type { App } from '../../app'
import { engineLabel } from '../../sim/builds'
import { esc, dynoChart, icon, num, tachSvg } from '../components'
import { consoleHead, tag, type View } from './shared'

export function dynoView(app: App): View {
  const build = app.activeBuild()
  const run = app.dynoRun()
  const points = run.points.length ? run.points : build.dyno?.points ?? app.curve(build)
  const cursor = run.points.length ? run.cursor : Math.max(0, points.length - 1)
  const point = points[cursor]
  const result = run.result ?? build.dyno ?? null
  const gate = app.canRun(build)
  const maxRpm = Math.max(8000, Math.ceil(build.ecu.revLimit / 1000) * 1000)
  const pulling = run.phase === 'pulling'
  const done = run.phase === 'done'
  const progress = pulling ? Math.min(100, (run.time / 5.4) * 100) : done ? 100 : 0
  const phase = pulling ? 'PULL IN PROGRESS' : run.phase === 'revving' ? 'FREE REV' : done ? 'RUN LOGGED' : 'READY TO STRAP'
  const tone = run.phase === 'done' && result && !result.valid ? 'bad' : pulling ? 'warn' : 'ok'

  const consoleHtml = `${consoleHead('DYNO CELL 01 / LOAD SWEEP', 'Prove the curve', `${engineLabel(build)} · ${build.bodyId.toUpperCase()} · ${num(build.condition, 1)}% condition`, tag(phase, tone))}
  <div class="console-scroll">
    ${!gate.ok ? `<div class="alert alert-bad">${icon('warning')}<div><b>Can’t run this build</b><span>${esc(gate.reason)}</span></div></div>` : ''}
    <div class="dyno-live">
      <div class="tach-wrap">${tachSvg(maxRpm, build.ecu.revLimit)}<div class="tach-digital"><span>RPM</span><b data-live="rpm">${num(app.live().rpm)}</b></div></div>
      <div class="dyno-figures">
        <div><span>POWER</span><b data-live="power">${point ? num(point.hp) : '—'}</b><em>hp</em></div>
        <div><span>TORQUE</span><b data-live="torque">${point ? num(point.torque) : '—'}</b><em>nm</em></div>
        <div><span>BOOST</span><b data-live="boost">${point ? num(point.boost, 1) : '—'}</b><em>psi</em></div>
        <div><span>AFR</span><b data-live="afr">${point ? num(point.afr, 1) : '—'}</b><em>ratio</em></div>
      </div>
    </div>
    <div class="telemetry-strip">
      <div><span>KNOCK</span><b data-live="knock">${point ? num(point.knock) : '—'}</b><i data-live-dot="knock"></i></div>
      <div><span>EGT</span><b data-live="egt">${point ? num(point.egt) : '—'}°</b></div>
      <div><span>DUTY</span><b data-live="duty">${point ? num(point.duty) : '—'}%</b></div>
      <div><span>LIMIT</span><b>${num(build.ecu.revLimit)}</b></div>
    </div>
    <div class="pull-progress"><i id="dyno-progress" style="width:${progress}%"></i><span>${pulling ? 'SWEEPING' : done ? 'COMPLETE' : 'IDLE'}</span></div>
    <div class="dyno-chart-wrap">${dynoChart(points, cursor)}</div>
    <div class="dyno-controls">
      <button type="button" class="btn btn-primary pedal-btn ${run.phase === 'revving' ? 'is-down' : ''}" data-hold="pedal" ${!gate.ok ? 'disabled' : ''}>${icon('gauge')} HOLD PEDAL</button>
      <button type="button" class="btn" data-action="run-dyno" ${!gate.ok || pulling ? 'disabled' : ''}>${icon('play')} ${pulling ? 'Pulling…' : 'Run pull'}</button>
    </div>
    <p class="control-hint"><kbd>R</kbd> start pull · hold <kbd>F</kbd> to free-rev · drag the car to orbit</p>
    ${result ? `<div class="result-strip ${result.valid ? '' : 'is-bad'}">
      <div><span>BEST LOGGED</span><b>${result.valid ? `${result.peakHp} hp` : 'FAILED'}</b><em>${result.valid ? `${result.peakTorque} Nm` : result.failure ?? 'unknown'}</em></div>
      <div><span>AFR WINDOW</span><b>${num(result.afrMin, 1)}–${num(result.afrMax, 1)}</b><em>${result.knockPeak > 60 ? 'knock detected' : 'clean'}</em></div>
      <div><span>CONDITION</span><b>${num(result.conditionAfter, 1)}%</b><em>${result.conditionAfter < result.conditionBefore ? 'wear logged' : 'no wear'}</em></div>
    </div>` : `<div class="empty-note"><b>No pull logged</b><span>The chart shows the estimated curve. A real pull applies load, heat and knock to the engine.</span></div>`}
    <div class="dyno-notes">
      ${point ? `<div><span>VE</span><b>${num(point.ve)}%</b></div><div><span>PUMP MARGIN</span><b>${num(point.pumpMargin)}%</b></div><div><span>TIMING</span><b>${num(point.timing, 1)}°</b></div>` : ''}
    </div>
  </div>
  <footer class="console-foot">
    <span class="foot-status"><i></i> ${pulling ? 'LOAD STEP ACTIVE' : 'ENGINE AT IDLE'}</span>
    <button type="button" class="text-btn" data-action="go-ecu">Open ECU ${icon('arrow')}</button>
    <button type="button" class="text-btn" data-action="go-test">Prove it ${icon('arrow')}</button>
  </footer>`

  const overlay = `<div class="dyno-overlay">
    <span class="dyno-cell">DYNO CELL 01</span>
    <div class="dyno-big"><b data-live="overlay-power">${point ? num(point.hp) : '—'}</b><span>WHP</span></div>
    <div class="dyno-small"><span data-live="overlay-torque">${point ? num(point.torque) : '—'} NM</span><span data-live="overlay-boost">${point ? num(point.boost, 1) : '—'} PSI</span></div>
  </div>
  <div class="stage-actions"><button type="button" class="stage-btn" data-action="go-ecu">${icon('ecu')} ECU</button></div>`

  return { console: consoleHtml, overlay, className: 'screen-dyno' }
}
