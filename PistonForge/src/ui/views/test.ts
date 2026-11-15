import type { App } from '../../app'
import { conditionLabel } from '../../sim/builds'
import { courseMapSvg, esc, icon, num } from '../components'
import { consoleHead, tag, type View } from './shared'

function treeLights(app: App): string {
  const run = app.dragRun()
  let active = -1
  if (run.phase === 'tree') active = run.treeTime > 1.55 ? 2 : run.treeTime > 1.05 ? 1 : run.treeTime > 0.55 ? 0 : -1
  if (run.phase === 'running' || run.phase === 'finished') active = 3
  const lights = ['amber', 'amber', 'amber', 'green']
  return `<div class="tree" id="drag-tree" aria-label="Christmas tree">
    ${lights.map((color, i) => `<i class="tree-light ${color} ${i === active ? 'on' : ''}" data-tree="${i}"></i>`).join('')}
  </div>`
}

export function testView(app: App): View {
  const build = app.activeBuild()
  const gate = app.canRun(build)
  const condition = conditionLabel(build.condition)
  const tab = app.testTab
  const drag = app.dragRun()
  const dragEstimate = app.estimatedDrag(build)
  const handlingEstimate = app.estimatedHandling(build)
  const handling = app.handlingRun()
  const peak = app.peak(build)

  const tabs = `<div class="test-tabs">
    <button type="button" data-action="test-tab" data-tab="drag" class="${tab === 'drag' ? 'active' : ''}">${icon('test')} Quarter mile</button>
    <button type="button" data-action="test-tab" data-tab="handling" class="${tab === 'handling' ? 'active' : ''}">${icon('gauge')} Handling course</button>
  </div>`

  const dragBody = `<div class="test-body">
    <div class="strip-status">
      ${treeLights(app)}
      <div class="strip-status-copy"><span>${drag.phase === 'idle' ? 'BAY / STAGING LANE' : drag.phase === 'staging' ? 'STAGED · HOLD LAUNCH' : drag.phase === 'tree' ? 'TREE COUNTING' : drag.phase === 'running' ? 'RUN LIVE' : 'RUN COMPLETE'}</span><b>${drag.phase === 'idle' ? `${num(dragEstimate.et ?? 0, 2)} s est.` : drag.phase === 'running' ? 'RUNNING' : drag.result?.valid ? `${drag.result.et?.toFixed(2)} s` : '—'}</b><em>${drag.phase === 'idle' ? `${num(dragEstimate.trapKmh ?? 0)} km/h trap estimate` : '402.336 m · 1/4 mile'}</em></div>
    </div>
    <div class="live-grid">
      <div><span>ELAPSED</span><b data-live="drag-elapsed">${drag.elapsed.toFixed(2)}</b><i>s</i></div>
      <div><span>SPEED</span><b data-live="drag-speed">${num(drag.speed * 3.6)}</b><i>km/h</i></div>
      <div><span>RPM</span><b data-live="drag-rpm">${num(drag.rpm)}</b><i>rpm</i></div>
      <div><span>GEAR</span><b data-live="drag-gear">${drag.gear > 0 ? drag.gear : 'N'}</b><i>of ${build.chassis.gearbox === 'five' ? 5 : build.chassis.gearbox === 'dct' ? 7 : 6}</i></div>
    </div>
    <div class="split-stats">
      <div><span>60 FT</span><b data-live="drag-sixty">${drag.sixtyFt ? drag.sixtyFt.toFixed(2) : '—'}</b><em>s</em></div>
      <div><span>0–100</span><b data-live="drag-zero">${drag.zeroTo100 ? drag.zeroTo100.toFixed(2) : '—'}</b><em>s</em></div>
      <div><span>WHEELSPIN</span><b data-live="drag-wheelspin">${num(drag.wheelspin, 2)}</b><em>slip</em></div>
      <div><span>SHIFTS</span><b data-live="drag-shifts">${drag.shiftCount}</b><em>made</em></div>
    </div>
    <div class="run-controls">
      <button type="button" class="btn btn-primary" data-action="stage-drag" ${!gate.ok ? 'disabled' : ''}>${icon('play')} ${drag.phase === 'idle' ? 'Stage car' : 'Re-stage'}</button>
      <button type="button" class="btn" data-action="start-tree" ${drag.phase !== 'staging' ? 'disabled' : ''}>Start tree</button>
      <button type="button" class="btn shift-btn" data-action="shift-drag" ${drag.phase !== 'running' ? 'disabled' : ''}>Shift <kbd>SPACE</kbd></button>
      <button type="button" class="btn btn-ghost" data-action="reset-drag">Reset</button>
    </div>
    <p class="control-hint">${app.state.settings.autoShift ? 'Auto-shift is on. The box shifts at the limiter; press Shift to grab the next gear early.' : 'Auto-shift is off. Press SPACE at the shift light.'} The tree goes green after 2.0 s.</p>
    ${drag.result ? `<div class="result-strip ${drag.result.valid ? '' : 'is-bad'}">
      <div><span>LAST RUN</span><b>${drag.result.valid && drag.result.et !== null ? `${drag.result.et.toFixed(2)} s` : 'ABORTED'}</b><em>${drag.result.trapKmh ?? '—'} km/h trap</em></div>
      <div><span>BEST ET</span><b>${app.state.bests.et > 0 ? `${app.state.bests.et.toFixed(2)} s` : '—'}</b><em>${app.state.bests.trap > 0 ? `${app.state.bests.trap} km/h` : 'no record'}</em></div>
    </div>` : `<div class="empty-note"><b>Run it for real</b><span>Launch, wheelspin, gearing and tyre grip are simulated from the build. No traction control.</span></div>`}
    ${!gate.ok ? `<div class="alert alert-bad">${icon('warning')}<div><b>Strip locked</b><span>${esc(gate.reason)}</span></div></div>` : ''}
    <div class="test-readout"><span>ESTIMATED ${num(dragEstimate.et ?? 0, 2)} s @ ${num(dragEstimate.trapKmh ?? 0)} km/h</span><span>${condition.text} · ${num(build.condition, 1)}%</span><span>${build.chassis.tires.toUpperCase()} · ${build.chassis.gearbox.toUpperCase()}</span></div>
  </div>`

  const handlingBody = `<div class="test-body">
    <div class="course-wrap">${courseMapSvg()}<div class="course-meta"><span>2.1 KM</span><b>${handling.phase === 'running' ? `${Math.round(handling.progress * 100)}%` : handling.result ? `${handling.result.lap.toFixed(2)} s` : '—'}</b><em>${handling.phase === 'running' ? 'LIVE LAP' : 'COURSE TIME'}</em></div></div>
    <div class="live-grid handling-grid">
      <div><span>SPEED</span><b data-live="handling-speed">${num(handling.speed)}</b><i>km/h</i></div>
      <div><span>LATERAL</span><b data-live="handling-g">${handling.lateralG.toFixed(2)}</b><i>g</i></div>
      <div><span>PROGRESS</span><b data-live="handling-progress">${Math.round(handling.progress * 100)}</b><i>%</i></div>
      <div><span>BALANCE</span><b data-live="handling-balance">${handling.result?.balance ?? '—'}</b><i>chassis</i></div>
    </div>
    <div class="split-stats">
      <div><span>EST. LAP</span><b>${handlingEstimate.lap.toFixed(2)}</b><em>s</em></div>
      <div><span>EST. GRIP</span><b>${handlingEstimate.lateralG.toFixed(2)}</b><em>g</em></div>
      <div><span>SPEED TRAP</span><b>${num(handlingEstimate.speedTrap)}</b><em>km/h</em></div>
      <div><span>POWER</span><b>${num(peak.hp)}</b><em>hp</em></div>
    </div>
    <div class="run-controls">
      <button type="button" class="btn btn-primary" data-action="run-handling" ${!gate.ok || handling.phase === 'running' ? 'disabled' : ''}>${icon('play')} ${handling.phase === 'running' ? 'Lap live…' : 'Run lap'}</button>
      <button type="button" class="btn btn-ghost" data-action="go-shop">Chassis</button>
    </div>
    <p class="control-hint">Balance is a computed tendency from drivetrain, mass, grip and power-to-weight. The car animates the actual course geometry.</p>
    ${handling.result ? `<div class="result-strip"><div><span>LAST LAP</span><b>${handling.result.lap.toFixed(2)} s</b><em>${handling.result.balance}</em></div><div><span>BEST LAP</span><b>${app.state.bests.lap > 0 ? `${app.state.bests.lap.toFixed(2)} s` : '—'}</b><em>${app.state.bests.lap > 0 ? 'logged' : 'no record'}</em></div></div>` : `<div class="empty-note"><b>One clean lap</b><span>Tyres, suspension, brakes and aero all change the number. So does the engine.</span></div>`}
    ${!gate.ok ? `<div class="alert alert-bad">${icon('warning')}<div><b>Course locked</b><span>${esc(gate.reason)}</span></div></div>` : ''}
    <div class="test-readout"><span>${build.chassis.tires.toUpperCase()} TYRES</span><span>${build.chassis.suspension.toUpperCase()} SUSPENSION</span><span>${build.aero.toUpperCase()} AERO</span></div>
  </div>`

  const consoleHtml = `${consoleHead('PROVING GROUNDS', tab === 'drag' ? 'Quarter mile' : 'Handling course', `${build.name} · ${num(peak.hp)} hp · ${condition.text}`, tag(gate.ok ? 'READY' : 'LOCKED', gate.ok ? 'ok' : 'bad'))}
  <div class="console-scroll">
    ${tabs}
    ${tab === 'drag' ? dragBody : handlingBody}
  </div>
  <footer class="console-foot">
    <span class="foot-status"><i></i> ${tab === 'drag' ? '1/4 MILE · 402.336 M' : '2.1 KM · TECHNICAL'}</span>
    <button type="button" class="text-btn" data-action="go-dyno">Dyno ${icon('arrow')}</button>
    <button type="button" class="text-btn" data-action="go-garage">Garage ${icon('arrow')}</button>
  </footer>`

  const overlay = tab === 'drag'
    ? `<div class="drag-overlay"><span>QUARTER MILE</span><b data-live="overlay-speed">${num(drag.speed * 3.6)}</b><em>KM/H</em><div><span data-live="overlay-elapsed">${drag.elapsed.toFixed(2)}</span><small>ELAPSED</small></div><div class="gear-big" data-live="overlay-gear">${drag.gear > 0 ? drag.gear : 'N'}</div></div>`
    : `<div class="dyno-overlay"><span class="dyno-cell">HANDLING COURSE</span><div class="dyno-big"><b data-live="overlay-handling">${Math.round(handling.progress * 100)}%</b><span>LAP</span></div><div class="dyno-small"><span>${handling.result ? `${handling.result.lap.toFixed(2)} S` : `${num(handlingEstimate.lap, 2)} S EST`}</span><span>${handling.result?.balance ?? handlingEstimate.balance}</span></div></div>`

  return { console: consoleHtml, overlay, className: 'screen-test' }
}
