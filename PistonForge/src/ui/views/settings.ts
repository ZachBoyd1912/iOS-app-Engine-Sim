import type { App } from '../../app'
import { money, num } from '../components'
import { consoleHead, rangeRow, section, type View } from './shared'

export function settingsView(app: App): View {
  const settings = app.state.settings
  const qualityButtons = (['low', 'medium', 'high'] as const).map(level => `<button type="button" data-action="set-quality" data-value="${level}" class="${settings.quality === level ? 'active' : ''}" aria-pressed="${settings.quality === level}">${level}</button>`).join('')
  const toggle = (key: 'reducedMotion' | 'autoShift' | 'haptics', label: string, hint: string) => `<div class="toggle-row"><div><b>${label}</b><small>${hint}</small></div><button type="button" class="switch ${settings[key] ? 'on' : ''}" data-action="toggle-setting" data-key="${key}" aria-pressed="${settings[key]}" aria-label="${label}"><i></i></button></div>`

  const consoleHtml = `${consoleHead('SETTINGS / WORKSHOP', 'Machine settings', 'Audio, display and driving assists. Saved locally.', '')}
  <div class="console-scroll">
    ${section('AUDIO', `
      ${rangeRow({ label: 'Engine', value: settings.engineVolume, min: 0, max: 1, step: 0.05, attrs: 'data-setting-range="engineVolume"', display: `${Math.round(settings.engineVolume * 100)}%`, hint: 'Procedural combustion, turbo and limiter.' })}
      ${rangeRow({ label: 'Interface SFX', value: settings.sfxVolume, min: 0, max: 1, step: 0.05, attrs: 'data-setting-range="sfxVolume"', display: `${Math.round(settings.sfxVolume * 100)}%` })}
      ${rangeRow({ label: 'Music', value: settings.musicVolume, min: 0, max: 1, step: 0.05, attrs: 'data-setting-range="musicVolume"', display: `${Math.round(settings.musicVolume * 100)}%`, hint: 'No music is loaded in this build. The bus is reserved.' })}
    `)}
    ${section('DISPLAY', `
      <div class="segmented-row"><span class="field-label">Render quality</span><div class="segmented" role="group" aria-label="Render quality">${qualityButtons}</div><small>Lower quality disables shadows and caps pixel ratio.</small></div>
      ${toggle('reducedMotion', 'Reduced motion', 'Disables camera shake and auto orbit.')}
      ${toggle('haptics', 'Vibration', 'Taps on shifts, launches and results. Phones only.')}
    `)}
    ${section('DRIVING', `
      ${toggle('autoShift', 'Automatic shifting', 'The drag car shifts at the limiter. Turn off for manual launches.')}
      <div class="info-grid"><div><span>MODE</span><b>${app.state.mode.toUpperCase()}</b></div><div><span>SAVE</span><b>LOCAL</b></div><div><span>CASH</span><b>${money(app.state.cash)}</b></div><div><span>REP</span><b>${num(app.state.rep)}</b></div></div>
    `)}
    ${section('DATA', `<p class="settings-copy">One local save holds your career, sandbox build, records and settings. There are no accounts and no cloud saves. Clearing site data removes the shop.</p>
      <button type="button" class="btn btn-danger wide-btn" data-action="open-reset">Reset all progress</button>`)}
    ${section('ABOUT', `<p class="settings-copy"><b>Piston Forge</b> is an original engine-building and tuning sandbox. All car bodies, engine geometry, workshop assets and audio are authored procedurally for this build; no third-party models or recordings are used. The simulation is intentionally opinionated, not a manufacturer service manual.</p><p class="settings-copy small">Built with Three.js. Desktop and touch input. English only. v0.1.</p>`)}
  </div>
  <footer class="console-foot">
    <span class="foot-status"><i></i> AUTO-SAVE ON</span>
    <button type="button" class="text-btn" data-action="go-garage">Back to bay</button>
  </footer>`
  return { console: consoleHtml, overlay: '', className: 'screen-settings' }
}