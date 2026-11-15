import type { App } from '../../app'
import { esc, markSvg, money, num } from '../components'

export function titleView(app: App): string {
  const state = app.state
  const build = app.activeBuild()
  const bests = state.bests
  const hasBests = bests.hp > 0 || bests.et > 0 || bests.lap > 0
  return `<div class="title-view">
    <div class="title-gradient"></div>
    <div class="title-top">
      <span class="title-brand">${markSvg()}<span>PISTON <b>FORGE</b></span></span>
      <button class="icon-btn" data-action="go-settings" aria-label="Settings"><svg viewBox="0 0 24 24" aria-hidden="true"><circle cx="12" cy="12" r="3.2"/><path d="M12 2v3M12 19v3M2 12h3M19 12h3M4.9 4.9 7 7M17 17l2.1 2.1M19.1 4.9 17 7M7 17l-2.1 2.1"/></svg></button>
    </div>
    <div class="title-copy">
      <p class="title-kicker"><span class="title-rule"></span>ENGINE BUILDING · REMAPPING · PROVING GROUNDS</p>
      <h1 class="title-wordmark"><span>PISTON</span><b>FORGE</b></h1>
      <p class="title-tagline">Build it. Map it. Prove it.</p>
      <p class="title-lede">A workshop for people who care about airflow, fuel and the moment a build finally holds together.</p>
      <div class="title-actions">
        <button class="title-action title-action-primary" data-action="start-career">
          <span>${state.introSeen ? 'Continue career' : 'Enter career'}</span>
          <small>BAY 03 · ${money(state.cash)} · ${esc(build.name)}</small>
        </button>
        <button class="title-action" data-action="start-sandbox">
          <span>Sandbox</span>
          <small>EVERYTHING UNLOCKED · NO BILL</small>
        </button>
      </div>
      <div class="title-best ${hasBests ? '' : 'is-empty'}">
        <span>SHOP RECORDS</span>
        <dl>
          <div><dt>BEST POWER</dt><dd>${bests.hp > 0 ? `${num(bests.hp)} <small>HP</small>` : '—'}</dd></div>
          <div><dt>BEST ET</dt><dd>${bests.et > 0 ? `${bests.et.toFixed(2)} <small>S</small>` : '—'}</dd></div>
          <div><dt>BEST LAP</dt><dd>${bests.lap > 0 ? `${bests.lap.toFixed(2)} <small>S</small>` : '—'}</dd></div>
        </dl>
      </div>
    </div>
    <div class="title-foot">
      <span>9 BODY ARCHETYPES · 10 ENGINE LAYOUTS · 1 DYNO</span>
      <span>NO ACCOUNTS · LOCAL SAVE · ORIGINAL BUILD</span>
      <span>v0.1 / BAY 03</span>
    </div>
  </div>`
}