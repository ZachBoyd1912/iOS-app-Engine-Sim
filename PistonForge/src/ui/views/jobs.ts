import type { App } from '../../app'
import { FAULTS, bodyById } from '../../sim/data'
import { contractLock, contractResult, targetText } from '../../sim/career'
import { conditionLabel, engineLabel } from '../../sim/builds'
import { conditionBar, esc, icon, money, num } from '../components'
import type { UiState } from '../types'
import { actionButton, consoleHead, section, tag, type View } from './shared'

export function jobsView(app: App, _ui: UiState): View {
  const state = app.state
  const job = state.job
  const active = job
  const build = app.activeBuild()
  const condition = conditionLabel(build.condition)
  const progress = app.jobProgress()

  if (active) {
    const contract = active.contract
    const body = bodyById(contract.bodyId)
    const result = contractResult(active.build, contract.target)
    const faults = active.build.engine.faults ?? []
    const faultCards = faults.length === 0
      ? `<div class="advice advice-ok">${icon('check')}<span>No open faults. The engine is mechanically clean.</span></div>`
      : faults.map(fault => {
        const item = FAULTS[fault]
        const repairCost = item.repair
        return `<div class="fault-card"><div><span>${esc(item.short)}</span><b>${esc(item.name)}</b><em>${esc(item.symptom)}</em></div><div class="fault-buy"><span>${money(repairCost)}</span><button type="button" class="mini-btn" data-action="repair-fault" data-fault="${fault}" ${!active.diagnosed ? 'disabled' : ''}>Repair</button></div></div>`
      }).join('')

    const consoleHtml = `${consoleHead(`CONTRACT ${contract.code} / CUSTOMER BAY`, contract.title, `${contract.customer} · ${body.name} · ${engineLabel(active.build)}`, tag('IN PROGRESS', 'warn'))}
    <div class="console-scroll">
      <div class="job-brief"><span>THE BRIEF</span><p>${esc(contract.brief)}</p><em>Target: <b>${esc(targetText(contract.target))}</b></em></div>
      <div class="job-progress">
        <div class="job-target">
          <span>TARGET</span>
          <b class="${result.met ? 'is-ok' : 'is-pending'}">${esc(result.label)}</b>
          <em>${result.met ? 'Target met — ready to deliver' : 'Target not met yet'}</em>
        </div>
        <div class="job-budget">
          <span>CUSTOMER BUDGET</span>
          <b>${money(contract.budget - active.spent)} <small>left</small></b>
          <em>${money(active.spent)} of ${money(contract.budget)} spent</em>
          <div class="meter"><i style="width:${Math.min(100, (active.spent / contract.budget) * 100)}%"></i></div>
        </div>
      </div>
      <div class="job-cond">
        <div class="condition-head"><b class="condition-${condition.level}">${condition.text}</b><span>${num(active.build.condition, 1)}%</span></div>${conditionBar(active.build.condition)}
        <small>Customer repairs and build parts are charged to the budget. Payout is paid on delivery.</small>
      </div>
      ${section('DIAGNOSIS', active.diagnosed
        ? `<div class="diagnosed-head">${tag('DIAGNOSED', 'ok')}<span>${faults.length} open fault${faults.length === 1 ? '' : 's'}</span></div>${faultCards}`
        : `<div class="diagnose-box"><b>Undiagnosed complaint</b><span>The customer described a symptom. Put it on the ramp and read the data before ordering anything.</span>${actionButton('Run diagnostic · $60', 'diagnose', { primary: true })}</div>`, `Budget ${money(contract.budget - active.spent)}`) }
      <div class="action-grid job-actions">
        <button type="button" class="action-card" data-action="go-engine"><span>01</span>${icon('engine')}<b>Engine</b><em>Build spec</em></button>
        <button type="button" class="action-card" data-action="go-ecu"><span>02</span>${icon('ecu')}<b>ECU</b><em>Calibrate</em></button>
        <button type="button" class="action-card" data-action="go-dyno"><span>03</span>${icon('dyno')}<b>Dyno</b><em>Prove power</em></button>
        <button type="button" class="action-card" data-action="go-test"><span>04</span>${icon('test')}<b>Strip</b><em>Prove ET</em></button>
      </div>
      <div class="job-deliver">
        <button type="button" class="btn btn-primary wide-btn" data-action="deliver" ${!result.met || faults.length > 0 || build.condition <= 0 ? 'disabled' : ''}>Deliver to ${esc(contract.customer)} ${icon('arrow')}</button>
        <button type="button" class="btn btn-ghost wide-btn" data-action="abandon">Abandon contract</button>
      </div>
      <div class="advice advice-info">${icon('jobs')}<span>Deliver only when the target is met, the faults are closed and the engine is alive. Payout ${money(contract.payout)} · +${contract.rep} rep.</span></div>
    </div>
    <footer class="console-foot">
      <span class="foot-status"><i></i> CUSTOMER CAR · BUDGET LIVE</span>
      <button type="button" class="text-btn" data-action="go-jobs">Contract board ${icon('arrow')}</button>
      <button type="button" class="text-btn" data-action="go-garage">My garage ${icon('arrow')}</button>
    </footer>`
    return {
      console: consoleHtml,
      overlay: `<div class="stage-plate"><span>${esc(contract.code)} / CUSTOMER BAY</span><b>${esc(contract.title)}</b><em>${esc(contract.customer)}</em><em>${esc(progress?.label ?? 'No proof yet')}</em></div>`,
      className: 'screen-jobs',
    }
  }

  const contracts = state.contracts
  const cards = contracts.length === 0
    ? `<div class="empty-note"><b>Board clear</b><span>Every contract in the book has been delivered. The shop records are yours.</span></div>`
    : contracts.map(contract => {
      const lock = contractLock(state, contract)
      return `<article class="contract-card ${lock ? 'is-locked' : ''}">
        <div class="contract-top"><span>${esc(contract.code)}</span>${lock ? tag(lock.toUpperCase(), 'muted') : tag(money(contract.payout), 'ok')}</div>
        <h2>${esc(contract.title)}</h2>
        <p class="contract-customer">${esc(contract.customer)} · ${bodyById(contract.bodyId).name}</p>
        <p class="contract-brief">${esc(contract.brief)}</p>
        <div class="contract-specs">
          <div><span>TARGET</span><b>${esc(targetText(contract.target))}</b></div>
          <div><span>BUDGET</span><b>${money(contract.budget)}</b></div>
          <div><span>REP</span><b>+${contract.rep}</b></div>
          <div><span>FEE</span><b>${money(contract.payout)}</b></div>
        </div>
        <div class="contract-foot">${lock ? `<span class="lock-line">${icon('lock')} ${esc(lock)}</span>` : `<span>${contract.faults.length} fault${contract.faults.length === 1 ? '' : 's'} reported</span>`}
          <button type="button" class="mini-btn" data-action="accept-job" data-id="${contract.id}" ${lock ? 'disabled' : ''}>Accept</button>
        </div>
      </article>`
    }).join('')

  const consoleHtml = `${consoleHead('CONTRACT BOARD', 'Customer work', `${contracts.length} jobs open · ${state.completedJobs} delivered`, tag(state.mode === 'career' ? 'CAREER' : 'SANDBOX', 'info'))}
  <div class="console-scroll">
    <div class="board-intro"><p>Small jobs pay the rent. Big jobs build the reputation. Every car arrives with a complaint and a budget you cannot exceed.</p><span>DIAGNOSTIC $60 · BUDGET ENFORCED · REPUTATION GATES</span></div>
    <div class="contract-list">${cards}</div>
    ${state.completedContracts.length ? `<div class="completed-strip">${state.completedContracts.length} contract${state.completedContracts.length === 1 ? '' : 's'} delivered · records in the garage</div>` : ''}
    <div class="advice advice-info">${icon('jobs')}<span>Contracts run on the customer car. Your own project stays in the garage and is not touched by customer work.</span></div>
  </div>
  <footer class="console-foot">
    <span class="foot-status"><i></i> BAY 03 · ${state.completedJobs} JOBS DELIVERED</span>
    <button type="button" class="text-btn" data-action="go-garage">My garage ${icon('arrow')}</button>
  </footer>`

  return {
    console: consoleHtml,
    overlay: `<div class="stage-plate"><span>CONTRACT BOARD</span><b>${esc(build.name)}</b><em>${state.rep} reputation · ${money(state.cash)} cash</em><em>${contracts.length} open contracts</em></div>`,
    className: 'screen-jobs',
  }
}