import type { App } from '../../app'
import { bodyById } from '../../sim/data'
import { LOAD_BINS, RPM_BINS, displayAfrs, ecuWarnings, injectorHeadroom } from '../../sim/ecu'
import { conditionLabel, engineLabel } from '../../sim/builds'
import { esc, icon, num, pct } from '../components'
import type { UiState } from '../types'
import { consoleHead, rangeRow, section, tag, type View } from './shared'

export function ecuView(app: App, ui: UiState): View {
  const build = app.activeBuild()
  const ecu = build.ecu
  const engine = build.engine
  const body = bodyById(build.bodyId)
  const warnings = ecuWarnings(ecu, engine, body)
  const enabled = warnings.filter(w => w.level !== 'ok')
  const selectedRow = Math.max(0, Math.min(7, ui.selectedRow))
  const selectedCol = Math.max(0, Math.min(7, ui.selectedCol))
  const table = ui.mapKind === 'fuel' ? ecu.fuel : ecu.ignition
  const selectedValue = table[selectedRow]?.[selectedCol] ?? 0
  const fuelDisplay = displayAfrs(engine)
  const headroom = injectorHeadroom(engine)
  const condition = conditionLabel(build.condition)
  const boostLabel = engine.induction === 'na' ? 'N/A' : `${num(ecu.boostTarget, 1)} psi`

  const rows = [...LOAD_BINS.keys()].reverse()
  const mapRows = rows.map(row => {
    const values = table[row] ?? []
    const cells = RPM_BINS.map((_, col) => {
      const value = values[col] ?? 0
      const hot = ui.mapKind === 'fuel' ? value > 132 : value > 32
      const cold = ui.mapKind === 'fuel' ? value < 72 : value < 8
      const selected = row === selectedRow && col === selectedCol
      return `<td><button type="button" class="map-cell ${hot ? 'hot' : cold ? 'cold' : ''} ${selected ? 'selected' : ''}" data-action="map-cell" data-row="${row}" data-col="${col}" aria-label="Load ${LOAD_BINS[row]} percent, ${RPM_BINS[col]} rpm, ${value}">${num(value, 0)}</button></td>`
    }).join('')
    return `<tr><th>${LOAD_BINS[row]}%</th>${cells}</tr>`
  }).join('')

  const warningHtml = warnings.length
    ? warnings.map(w => `<div class="advice advice-${w.level}">${icon(w.level === 'bad' ? 'warning' : w.level === 'warn' ? 'bolt' : 'check')}<span>${esc(w.text)}</span></div>`).join('')
    : `<div class="advice advice-ok">${icon('check')}<span>No obvious calibration faults. The dyno will find the rest.</span></div>`

  const consoleHtml = `${consoleHead('CALIBRATION / STANDALONE ECU', 'Fuel & ignition', `${engineLabel(build)} · ${body.name}`, tag('UNSAVED MAP READY', 'muted'))}
  <div class="console-scroll">
    <div class="ecu-summary">
      <div><span>CONDITION</span><b class="condition-${condition.level}">${condition.text}</b><em>${num(build.condition, 1)}%</em></div>
      <div><span>TARGET AFR</span><b>${num(ecu.afr, 1)}</b><em>${fuelDisplay.label}</em></div>
      <div><span>INJECTOR DUTY</span><b>${pct(headroom)}</b><em>peak estimate</em></div>
      <div><span>REV LIMIT</span><b>${num(ecu.revLimit)}</b><em>rpm</em></div>
    </div>
    <div class="map-tabs">
      <button type="button" data-action="map-kind" data-kind="fuel" class="${ui.mapKind === 'fuel' ? 'active' : ''}">Fuel VE</button>
      <button type="button" data-action="map-kind" data-kind="ignition" class="${ui.mapKind === 'ignition' ? 'active' : ''}">Ignition</button>
      <span class="map-axis-label">LOAD % / RPM</span>
    </div>
    <div class="map-wrap">
      <table class="map-grid">
        <thead><tr><th class="corner">${ui.mapKind === 'fuel' ? 'VE' : '°'}</th>${RPM_BINS.map(rpm => `<th>${rpm / 1000}k</th>`).join('')}</tr></thead>
        <tbody>${mapRows}</tbody>
      </table>
    </div>
    <div class="cell-editor">
      <div class="cell-meta"><span>SELECTED CELL</span><b>${LOAD_BINS[selectedRow]}% load · ${num(RPM_BINS[selectedCol])} rpm</b><em>${ui.mapKind === 'fuel' ? 'Volumetric efficiency' : 'Ignition advance'} in ${ui.mapKind === 'fuel' ? '%' : '°'}</em></div>
      <div class="cell-input"><input id="cell-value" type="number" value="${selectedValue}" step="1" min="${ui.mapKind === 'fuel' ? 20 : -10}" max="${ui.mapKind === 'fuel' ? 220 : 45}" inputmode="numeric"><button type="button" class="btn btn-small" data-action="set-cell">Set cell</button></div>
    </div>
    <div class="map-tools">
      <button type="button" data-action="map-tool" data-tool="base">${icon('bolt')} Auto-base</button>
      <button type="button" data-action="map-tool" data-tool="smooth">Smooth</button>
      <button type="button" data-action="map-tool" data-tool="fixfuel">Match airflow</button>
      <button type="button" data-action="map-tool" data-tool="timing">Advance timing</button>
    </div>
    <div class="map-legend"><span class="legend-cold"></span>lean / retarded <span class="legend-hot"></span>rich / advanced <em>Tap a cell to edit</em></div>
    <div class="two-col target-grid">
      ${rangeRow({ label: 'Target AFR', value: ecu.afr, min: 8.5, max: 15, step: 0.1, attrs: 'data-ecu-range="afr"', display: num(ecu.afr, 1) })}
      ${rangeRow({ label: 'Boost target', value: ecu.boostTarget, min: 0, max: 30, step: 0.5, attrs: 'data-ecu-range="boostTarget"', display: boostLabel, disabled: engine.induction === 'na' })}
      ${rangeRow({ label: 'Rev limiter', value: ecu.revLimit, min: 4000, max: 9500, step: 100, attrs: 'data-ecu-range="revLimit"', display: `${num(ecu.revLimit)} rpm` })}
      ${rangeRow({ label: 'Launch control', value: ecu.launchRpm, min: 1500, max: 6000, step: 100, attrs: 'data-ecu-range="launchRpm"', display: `${num(ecu.launchRpm)} rpm` })}
    </div>
    ${section('CALIBRATION WARNINGS', warningHtml, `${enabled.length} active`)}
    <div class="advice advice-info">${icon('ecu')}<span>The map is a live calibration. Changing a cell invalidates the last dyno proof until you run again.</span></div>
    <button type="button" class="btn btn-primary wide-btn" data-action="go-dyno">Run on the dyno ${icon('arrow')}</button>
  </div>
  <footer class="console-foot">
    <span class="foot-status"><i></i> ${enabled.length ? `${enabled.length} warning${enabled.length === 1 ? '' : 's'}` : 'MAP CONSISTENT'}</span>
    <button type="button" class="text-btn" data-action="map-tool" data-tool="reset">Reset to base map</button>
  </footer>`

  const overlay = `<div class="stage-plate"><span>ENGINE STAND / CALIBRATION</span><b>${esc(engine.name)}</b><em>${num(ecu.revLimit)} rpm limit · ${boostLabel} boost</em><em>${esc(fuelDisplay.label)}</em></div>
    <div class="stage-actions"><button type="button" class="stage-btn" data-action="go-engine">${icon('engine')} Rebuild engine</button><button type="button" class="stage-btn" data-action="toggle-cutaway">${icon('gauge')} Cutaway</button></div>`

  return { console: consoleHtml, overlay }
}
