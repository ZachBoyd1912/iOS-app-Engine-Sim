import type { Screen } from '../../app'
import type { Tip } from '../../sim/tutorial'
import { esc } from '../components'

export type View = { console: string; overlay: string; className?: string }

/**
 * Next-step card for career mode. The primary button is left out on the screen the action
 * leads to, so the card never points at where the player already is.
 */
export function tipCard(tip: Tip, screen: Screen): string {
  const primary = tip.action === `go-${screen}`
    ? ''
    : `<button type="button" class="btn btn-primary tip-primary" data-action="${tip.action}">${esc(tip.actionLabel)}</button>`
  return `<aside class="tip-card" aria-label="Next step">
    <span class="tip-kicker">NEXT STEP</span>
    <b class="tip-title">${esc(tip.title)}</b>
    <p class="tip-body">${esc(tip.body)}</p>
    <div class="tip-actions">${primary}<button type="button" class="tip-hide" data-action="hide-tips">Hide tips</button></div>
  </aside>`
}

export function consoleHead(kicker: string, title: string, sub: string, right = ''): string {
  return `<header class="console-head">
    <div class="console-kicker"><span class="lamp"></span>${esc(kicker)}${right}</div>
    <h1>${esc(title)}</h1>
    <p class="console-sub">${esc(sub)}</p>
  </header>`
}

export function panelLabel(label: string, hint = ''): string {
  return `<div class="panel-label"><span>${esc(label)}</span>${hint ? `<em>${esc(hint)}</em>` : ''}</div>`
}

export function section(label: string, content: string, hint = ''): string {
  return `<section class="console-section">${panelLabel(label, hint)}${content}</section>`
}

export function rangeRow(options: {
  label: string
  value: number
  min: number
  max: number
  step: number
  attrs: string
  display: string
  hint?: string
  disabled?: boolean
}): string {
  const fill = ((options.value - options.min) / Math.max(1, options.max - options.min)) * 100
  return `<label class="range-row ${options.disabled ? 'is-disabled' : ''}">
    <span class="range-head"><span>${esc(options.label)}</span><output>${esc(options.display)}</output></span>
    <input type="range" ${options.attrs} min="${options.min}" max="${options.max}" step="${options.step}" value="${options.value}" style="--fill:${fill}%" ${options.disabled ? 'disabled' : ''}>
    ${options.hint ? `<small>${esc(options.hint)}</small>` : ''}
  </label>`
}

export function segmented(options: { label: string; items: { value: string; label: string; active: boolean; attrs: string }[]; hint?: string }): string {
  return `<div class="segmented-row">
    <span class="field-label">${esc(options.label)}</span>
    <div class="segmented" role="group" aria-label="${esc(options.label)}">
      ${options.items.map(item => `<button type="button" class="${item.active ? 'active' : ''}" aria-pressed="${item.active}" ${item.attrs}>${esc(item.label)}</button>`).join('')}
    </div>
    ${options.hint ? `<small>${esc(options.hint)}</small>` : ''}
  </div>`
}

export function field(label: string, control: string, hint = ''): string {
  return `<label class="field-row"><span class="field-label">${esc(label)}</span>${control}${hint ? `<small>${esc(hint)}</small>` : ''}</label>`
}

export function tag(text: string, tone: 'ok' | 'warn' | 'bad' | 'info' | 'muted' = 'info'): string {
  return `<span class="tag tag-${tone}">${esc(text)}</span>`
}

export function meter(value: number, max: number, tone: 'ok' | 'warn' | 'bad' = 'ok'): string {
  const width = Math.max(0, Math.min(100, (value / Math.max(1, max)) * 100))
  return `<div class="meter ${tone}"><i style="width:${width}%"></i></div>`
}

export function overlayPlate(kicker: string, title: string, details: string[]): string {
  return `<div class="stage-plate">
    <span>${esc(kicker)}</span>
    <b>${esc(title)}</b>
    ${details.map(detail => `<em>${esc(detail)}</em>`).join('')}
  </div>`
}

export function selectControl(attrs: string, options: { value: string; label: string; selected: boolean; disabled?: boolean }[]): string {
  return `<select ${attrs}>${options.map(option => `<option value="${esc(option.value)}" ${option.selected ? 'selected' : ''} ${option.disabled ? 'disabled' : ''}>${esc(option.label)}</option>`).join('')}</select>`
}

export function actionButton(label: string, action: string, options: { primary?: boolean; disabled?: boolean; attrs?: string; kind?: string } = {}): string {
  return `<button type="button" class="btn ${options.primary ? 'btn-primary' : ''} ${options.kind ?? ''}" data-action="${action}" ${options.attrs ?? ''} ${options.disabled ? 'disabled' : ''}>${label}</button>`
}