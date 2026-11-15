import type { App, Screen } from '../app'
import { reputationProgress } from '../sim/career'
import { bodyById } from '../sim/data'
import { engineLabel } from '../sim/builds'
import type { AeroId, InteriorId, PaintFinish, PartSlot, WheelStyle } from '../sim/types'
import { esc, icon, money, num, wordmark } from './components'
import type { ResultAction, ResultModal, UiState } from './types'
import { ecuView } from './views/ecu'
import { dynoView } from './views/dyno'
import { engineView } from './views/engine'
import { garageView } from './views/garage'
import { jobsView } from './views/jobs'
import { settingsView } from './views/settings'
import { shopView } from './views/shop'
import { testView } from './views/test'
import { titleView } from './views/title'
import type { View } from './views/shared'

const SCREEN_LABEL: Record<Screen, string> = {
  title: 'Title',
  garage: 'Garage',
  engine: 'Engine bench',
  ecu: 'ECU calibration',
  dyno: 'Dyno cell',
  test: 'Proving grounds',
  shop: 'Parts counter',
  jobs: 'Contract board',
  settings: 'Settings',
}

const NAV: { screen: Screen; label: string; icon: 'garage' | 'engine' | 'ecu' | 'dyno' | 'test' | 'shop' | 'jobs' }[] = [
  { screen: 'garage', label: 'Garage', icon: 'garage' },
  { screen: 'engine', label: 'Engine', icon: 'engine' },
  { screen: 'ecu', label: 'ECU', icon: 'ecu' },
  { screen: 'dyno', label: 'Dyno', icon: 'dyno' },
  { screen: 'test', label: 'Prove it', icon: 'test' },
  { screen: 'shop', label: 'Parts', icon: 'shop' },
  { screen: 'jobs', label: 'Jobs', icon: 'jobs' },
]

export class UI {
  readonly root: HTMLElement
  readonly state: UiState = {
    engineTab: 'bottom',
    shopTab: 'engine',
    mapKind: 'fuel',
    selectedRow: 5,
    selectedCol: 4,
    modal: null,
    toast: null,
    showJobDetails: false,
    enginePresetOpen: false,
  }
  private suppressRender = false
  private holdingPedal = false
  private liveCache = new Map<string, string>()
  private scrollTop = 0

  constructor(private readonly app: App, root: HTMLElement) {
    this.root = root
    this.root.addEventListener('click', event => this.onClick(event))
    this.root.addEventListener('input', event => this.onInput(event))
    this.root.addEventListener('change', event => this.onChange(event))
    this.root.addEventListener('pointerdown', event => this.onPointerDown(event))
    document.addEventListener('pointerup', () => this.onPointerUp())
    document.addEventListener('pointercancel', () => this.onPointerUp())
    document.addEventListener('keydown', event => this.onKeyDown(event))
    document.addEventListener('keyup', event => this.onKeyUp(event))
    this.render()
  }

  render(): void {
    if (this.suppressRender) return
    const activeScroll = this.root.querySelector<HTMLElement>('.console-scroll')
    if (activeScroll) this.scrollTop = activeScroll.scrollTop
    this.liveCache.clear()
    const screen = this.app.screen
    let view: View
    if (screen === 'title') {
      this.root.innerHTML = `${titleView(this.app)}<div class="toast-stack"></div>`
      this.root.classList.add('is-title')
      this.root.dataset.screen = 'title'
      document.title = `Piston Forge — ${this.app.activeBuild().name}`
      this.frame(0)
      return
    }
    this.root.classList.remove('is-title')
    if (screen === 'engine') view = engineView(this.app, this.state)
    else if (screen === 'ecu') view = ecuView(this.app, this.state)
    else if (screen === 'dyno') view = dynoView(this.app)
    else if (screen === 'test') view = testView(this.app)
    else if (screen === 'shop') view = shopView(this.app, this.state)
    else if (screen === 'jobs') view = jobsView(this.app, this.state)
    else if (screen === 'settings') view = settingsView(this.app)
    else view = garageView(this.app)
    const shell = this.shell(screen, view)
    this.root.innerHTML = `${shell}<div class="toast-stack"></div>${this.state.modal ? this.modalHtml(this.state.modal) : ''}`
    this.root.dataset.screen = screen
    document.title = `Piston Forge — ${SCREEN_LABEL[screen]}`
    const nextScroll = this.root.querySelector<HTMLElement>('.console-scroll')
    if (nextScroll) nextScroll.scrollTop = this.scrollTop
    this.frame(0)
  }

  toast(text: string, tone: 'ok' | 'warn' | 'bad' = 'ok'): void {
    let stack = this.root.querySelector<HTMLElement>('.toast-stack')
    if (!stack) {
      stack = document.createElement('div')
      stack.className = 'toast-stack'
      this.root.append(stack)
    }
    while (stack.childElementCount >= 3) stack.firstElementChild?.remove()
    const el = document.createElement('div')
    el.className = `toast toast-${tone}`
    el.innerHTML = `${icon(tone === 'bad' || tone === 'warn' ? 'warning' : 'check')}<span>${esc(text)}</span>`
    stack.append(el)
    window.setTimeout(() => {
      el.classList.add('is-leaving')
      window.setTimeout(() => el.remove(), 260)
    }, 4200)
  }

  showModal(modal: ResultModal): void {
    this.state.modal = modal
    this.app.sound.ui(modal.tone === 'bad' ? 'error' : 'confirm')
    this.app.haptics.cue(modal.tone === 'bad' ? 'failure' : modal.tone === 'warn' ? 'warning' : 'success')
    this.render()
  }

  closeModal(): void {
    if (!this.state.modal) return
    this.state.modal = null
    this.render()
  }

  private shell(screen: Screen, view: View): string {
    const app = this.app
    const state = app.state
    const rep = reputationProgress(state.rep)
    const job = state.job
    const wallet = job
      ? `<span>JOB BUDGET</span><b>${money(job.contract.budget - job.spent)}</b>`
      : `<span>${state.mode === 'sandbox' ? 'SANDBOX' : 'CASH'}</span><b>${state.mode === 'sandbox' ? 'UNLIMITED' : money(state.cash)}</b>`
    const mode = `<div class="mode-switch" role="group" aria-label="Game mode">
      <button type="button" data-action="mode-career" class="${state.mode === 'career' ? 'active' : ''}" ${state.mode === 'career' ? 'aria-current="true"' : ''}>Career</button>
      <button type="button" data-action="mode-sandbox" class="${state.mode === 'sandbox' ? 'active' : ''}" ${state.mode === 'sandbox' ? 'aria-current="true"' : ''}>Sandbox</button>
    </div>`
    const nav = NAV.map(item => {
      const active = screen === item.screen || (item.screen === 'test' && screen === 'test')
      const badge = item.screen === 'jobs' && job ? '<i class="nav-badge"></i>' : ''
      return `<button type="button" class="rail-item ${active ? 'active' : ''}" data-action="go-${item.screen}" ${active ? 'aria-current="page"' : ''} title="${item.label}">${icon(item.icon)}<span>${item.label}</span>${badge}</button>`
    }).join('')
    return `<div class="shell ${view.className ?? ''}">
      <header class="topbar">
        <button type="button" class="brand-btn" data-action="go-title" aria-label="Piston Forge title">${wordmark(true)}</button>
        <div class="topbar-screen"><span>BAY 03 / WORKSHOP OS</span><b>${SCREEN_LABEL[screen]}</b></div>
        <div class="topbar-right">
          ${mode}
          <div class="wallet ${job ? 'is-job' : ''}">${wallet}</div>
          <div class="rep-pill" title="${rep.name} · ${state.rep} reputation"><b>${num(state.rep)}</b><span>REP</span></div>
          <button type="button" class="icon-btn" data-action="go-settings" aria-label="Settings">${icon('settings')}</button>
        </div>
      </header>
      <nav class="rail" aria-label="Workshop sections">${nav}<div class="rail-gap"></div><button type="button" class="rail-item ${screen === 'settings' ? 'active' : ''}" data-action="go-settings" ${screen === 'settings' ? 'aria-current="page"' : ''}>${icon('settings')}<span>Setup</span></button></nav>
      <main class="workspace">
        <section class="console" aria-label="${SCREEN_LABEL[screen]}">${view.console}</section>
        <div class="stage-overlay">${view.overlay}<div class="stage-hint">DRAG TO ORBIT · SCROLL TO ZOOM</div></div>
        <div class="car-caption"><span>${esc(bodyById(app.activeBuild().bodyId).name)}</span><em>${esc(engineLabel(app.activeBuild()))}</em></div>
      </main>
    </div>`
  }

  private modalHtml(modal: ResultModal): string {
    return `<div class="modal-backdrop" data-action="close-modal">
      <div class="modal-panel modal-${modal.tone}" role="dialog" aria-modal="true" aria-labelledby="modal-title" data-modal-panel>
        <button type="button" class="modal-close" data-action="close-modal" aria-label="Close">${icon('close')}</button>
        <p class="modal-eyebrow">${esc(modal.eyebrow)}</p>
        ${modal.badge ? `<span class="modal-badge badge-${modal.tone}">${esc(modal.badge)}</span>` : ''}
        <h2 id="modal-title">${esc(modal.title)}</h2>
        ${modal.subtitle ? `<p class="modal-sub">${esc(modal.subtitle)}</p>` : ''}
        <div class="modal-stats">${modal.stats.map(stat => `<div><span>${esc(stat.label)}</span><b>${esc(stat.value)}</b>${stat.detail ? `<em>${esc(stat.detail)}</em>` : ''}</div>`).join('')}</div>
        ${modal.note ? `<p class="modal-note">${esc(modal.note)}</p>` : ''}
        <div class="modal-actions">${modal.actions.map(action => this.modalAction(action)).join('')}</div>
      </div>
    </div>`
  }

  private modalAction(action: ResultAction): string {
    return `<button type="button" class="btn ${action.primary ? 'btn-primary' : ''}" data-action="${action.action}">${esc(action.label)}</button>`
  }

  private go(screen: Screen): void {
    this.app.setScreen(screen)
  }

  private onClick(event: MouseEvent): void {
    const target = (event.target as HTMLElement).closest<HTMLElement>('[data-action]')
    if (!target || target.hasAttribute('disabled')) return
    if ((event.target as HTMLElement).closest('[data-modal-panel]') && target.dataset.action === 'close-modal') {
      // backdrop click only; the panel's own close button is handled below
    }
    const action = target.dataset.action ?? ''
    this.app.sound.unlock()
    if (action !== 'confirm-reset') this.app.sound.ui(action === 'deliver' ? 'confirm' : 'click')
    this.app.haptics.cue('tap')
    const data = target.dataset
    switch (action) {
      case 'start-career': this.app.startCareer(); break
      case 'start-sandbox': this.app.startSandbox(); break
      case 'go-title': this.app.goTitle(); break
      case 'go-garage': this.app.setScreen('garage'); break
      case 'go-engine': this.app.setScreen('engine'); break
      case 'go-ecu': this.app.setScreen('ecu'); break
      case 'go-dyno': this.app.setScreen('dyno'); break
      case 'go-test': this.app.setScreen('test'); break
      case 'go-shop': this.state.shopTab = 'engine'; this.app.setScreen('shop'); break
      case 'go-jobs': this.app.setScreen('jobs'); break
      case 'go-settings': this.app.setScreen('settings'); break
      case 'mode-career': this.app.setMode('career'); break
      case 'mode-sandbox': this.app.setMode('sandbox'); break
      case 'select-body': if (data.id) this.app.selectBody(data.id); break
      case 'buy-body': if (data.id) this.app.buyBody(data.id); break
      case 'buy-select-body': if (data.id) this.app.buyAndSelectBody(data.id); break
      case 'paint-color': if (data.color) this.app.setPaintColor(data.color); break
      case 'paint-finish': if (data.finish) this.app.setPaintFinish(data.finish as PaintFinish); break
      case 'wheel-style': if (data.style) this.app.setWheelStyle(data.style as WheelStyle); break
      case 'repair-engine': this.app.repairEngine(); break
      case 'rebuild-engine': this.app.rebuildEngine(); break
      case 'engine-tab': if (data.tab) { this.state.engineTab = data.tab as UiState['engineTab']; this.render() } break
      case 'preset': if (data.id) this.app.applyPreset(data.id); break
      case 'apply-draft': this.app.applyDraft(); break
      case 'cancel-draft': this.app.discardDraft(); this.go('garage'); break
      case 'revert-draft': this.app.revertDraft(); break
      case 'toggle-cutaway': this.app.toggleCutaway(); break
      case 'map-kind': if (data.kind) { this.state.mapKind = data.kind as UiState['mapKind']; this.render() } break
      case 'map-cell': this.state.selectedRow = Number(data.row ?? 0); this.state.selectedCol = Number(data.col ?? 0); this.render(); break
      case 'set-cell': {
        const input = this.root.querySelector<HTMLInputElement>('#cell-value')
        if (input && data) this.app.setMapCell(this.state.mapKind, this.state.selectedRow, this.state.selectedCol, Number(input.value))
        break
      }
      case 'map-tool': if (data.tool) this.handleMapTool(data.tool); break
      case 'run-dyno': this.app.startDynoPull(); break
      case 'reset-dyno': this.app.resetDyno(); break
      case 'test-tab': if (data.tab) this.app.setTestTab(data.tab as 'drag' | 'handling'); break
      case 'stage-drag': this.app.stageDrag(); break
      case 'start-tree': this.app.startTree(); break
      case 'shift-drag': this.app.shiftDrag(); break
      case 'reset-drag': this.app.resetDrag(); break
      case 'run-handling': this.app.startHandling(); break
      case 'shop-tab': if (data.tab) { this.state.shopTab = data.tab as UiState['shopTab']; this.render() } break
      case 'install-part': if (data.slot && data.index !== undefined) this.app.installPart(data.slot as PartSlot, Number(data.index)); break
      case 'install-chassis': if (data.kind && data.id) this.app.installChassis(data.kind as keyof import('../sim/types').ChassisConfig, data.id); break
      case 'install-aero': if (data.id) this.app.installAero(data.id as AeroId); break
      case 'install-interior': if (data.id) this.app.installInterior(data.id as InteriorId); break
      case 'accept-job': if (data.id) this.app.acceptJob(data.id); break
      case 'diagnose': this.app.diagnose(); break
      case 'repair-fault': if (data.fault) this.app.repairJobFault(data.fault as import('../sim/types').FaultId); break
      case 'deliver': this.app.deliver(); break
      case 'abandon': this.app.abandon(); break
      case 'set-quality': if (data.value) this.app.updateSetting('quality', data.value as 'low' | 'medium' | 'high'); break
      case 'toggle-setting': {
        const key = data.key as 'reducedMotion' | 'autoShift' | 'haptics'
        if (key) this.app.updateSetting(key, !this.app.state.settings[key])
        break
      }
      case 'open-reset': this.showModal({
        kind: 'confirm', eyebrow: 'DESTRUCTIVE ACTION', title: 'Reset all progress?', subtitle: 'Career cash, reputation, every build, record and setting will be wiped from this device.',
        badge: 'NO UNDO', tone: 'bad', stats: [
          { label: 'Cash', value: money(this.app.state.cash) },
          { label: 'Jobs', value: `${this.app.state.completedJobs}` },
          { label: 'Builds', value: `${this.app.state.careerBuilds.length + 1}` },
        ], note: 'Sandbox and career both return to the first bay.', actions: [{ label: 'Keep progress', action: 'close-modal' }, { label: 'Reset everything', action: 'confirm-reset', primary: true }],
      }); break
      case 'confirm-reset': this.state.modal = null; this.app.resetGame(); break
      case 'close-modal': this.closeModal(); break
      default: this.handleModalAction(action); break
    }
  }

  private handleMapTool(tool: string): void {
    if (tool === 'base') this.app.autoBaseMap()
    else if (tool === 'smooth') this.app.smoothMap(this.state.mapKind)
    else if (tool === 'fixfuel') this.app.fixFuelMap()
    else if (tool === 'timing') this.app.advanceTimingMap()
    else if (tool === 'reset') this.app.resetEcu()
  }

  private handleModalAction(action: string): void {
    if (!this.state.modal) {
      this.go(action.replace('go-', '') as Screen)
      return
    }
    this.state.modal = null
    switch (action) {
      case 'run-dyno': this.app.startDynoPull(); break
      case 'reset-drag': this.app.resetDrag(); this.app.setScreen('test'); break
      case 'run-drag': this.app.setScreen('test'); this.app.setTestTab('drag'); this.app.stageDrag(); break
      case 'run-handling': this.app.startHandling(); break
      case 'open-ecu': this.go('ecu'); break
      case 'go-shop': this.go('shop'); break
      case 'go-jobs': this.go('jobs'); break
      default: this.go('garage')
    }
    this.render()
  }

  private onInput(event: Event): void {
    const input = event.target as HTMLInputElement
    if (input.tagName !== 'INPUT' || input.type !== 'range') return
    this.suppressRender = true
    this.app.sound.unlock()
    const draftKey = input.dataset.draftSlider
    const ecuKey = input.dataset.ecuRange
    const settingKey = input.dataset.settingRange
    const wheel = input.dataset.wheelSize !== undefined
    const stance = input.dataset.stance !== undefined
    if (draftKey) this.app.updateDraft({ [draftKey]: input.valueAsNumber } as never)
    else if (ecuKey) this.app.updateEcu({ [ecuKey]: input.valueAsNumber } as never)
    else if (settingKey) this.app.updateSetting(settingKey as 'engineVolume' | 'sfxVolume' | 'musicVolume', input.valueAsNumber)
    else if (wheel) this.app.setWheelSize(input.valueAsNumber)
    else if (stance) this.app.setStance(input.valueAsNumber)
    this.updateRangeOutput(input)
    const fill = ((input.valueAsNumber - Number(input.min)) / Math.max(1, Number(input.max) - Number(input.min))) * 100
    input.style.setProperty('--fill', `${fill}%`)
  }

  private updateRangeOutput(input: HTMLInputElement): void {
    const output = input.closest('.range-row')?.querySelector('output')
    if (!output) return
    const value = input.valueAsNumber
    if (input.dataset.draftSlider === 'bore' || input.dataset.draftSlider === 'stroke') output.textContent = `${num(value, 2)} mm`
    else if (input.dataset.draftSlider === 'compression') output.textContent = `${num(value, 1)} : 1`
    else if (input.dataset.ecuRange === 'afr') output.textContent = num(value, 1)
    else if (input.dataset.ecuRange === 'boostTarget') output.textContent = `${num(value, 1)} psi`
    else if (input.dataset.ecuRange === 'revLimit' || input.dataset.ecuRange === 'launchRpm') output.textContent = `${num(value)} rpm`
    else if (input.dataset.settingRange) output.textContent = `${Math.round(value * 100)}%`
    else if (input.dataset.wheelSize !== undefined) output.textContent = `${value}"`
    else if (input.dataset.stance !== undefined) output.textContent = value === 0 ? 'Neutral' : value > 0 ? `Slammed ${Math.round(value * 100)}%` : `Raised ${Math.round(-value * 100)}%`
  }

  private onChange(event: Event): void {
    const target = event.target as HTMLInputElement | HTMLSelectElement
    if (target.tagName === 'INPUT' && (target as HTMLInputElement).type === 'range') {
      this.suppressRender = false
      this.render()
      return
    }
    if (target instanceof HTMLInputElement) {
      if (target.dataset.draftName !== undefined) this.app.setDraftName(target.value)
      if (target.dataset.buildName !== undefined) this.app.renameBuild(target.value)
      return
    }
    if (target instanceof HTMLSelectElement) {
      const slot = target.dataset.draftPart as PartSlot | undefined
      if (slot) this.app.setDraftPart(slot, Number(target.value))
      else if (target.dataset.draftLayout) this.app.setDraftLayout(target.value as import('../sim/types').LayoutId)
      else if (target.dataset.draftFuel) this.app.setDraftFuel(target.value as import('../sim/types').FuelId)
      else if (target.dataset.draftInduction) this.app.setDraftInduction(target.value as import('../sim/types').InductionId)
    }
  }

  private onPointerDown(event: PointerEvent): void {
    this.app.sound.unlock()
    const hold = (event.target as HTMLElement).closest<HTMLElement>('[data-hold="pedal"]')
    if (hold) {
      event.preventDefault()
      this.holdingPedal = true
      this.app.setPedal(true)
      hold.classList.add('is-down')
      try { hold.setPointerCapture(event.pointerId) } catch { /* ignore */ }
    }
  }

  private onPointerUp(): void {
    if (!this.holdingPedal) return
    this.holdingPedal = false
    this.app.setPedal(false)
    this.root.querySelector('.pedal-btn')?.classList.remove('is-down')
  }

  private onKeyDown(event: KeyboardEvent): void {
    const target = event.target as HTMLElement
    const typing = target.matches('input, select, textarea')
    if (event.code === 'Escape') {
      if (this.state.modal) { event.preventDefault(); this.closeModal() }
      return
    }
    if (typing) return
    this.app.sound.unlock()
    if (this.app.screen === 'dyno') {
      if (event.code === 'KeyR' && !event.repeat) { event.preventDefault(); this.app.startDynoPull() }
      if (event.code === 'KeyF' && !event.repeat) { event.preventDefault(); this.holdingPedal = true; this.app.setPedal(true) }
    }
    if (this.app.screen === 'test' && this.app.testTab === 'drag') {
      if (event.code === 'Space') {
        event.preventDefault()
        if (this.app.dragRun().phase === 'staging') this.app.startTree()
        else if (this.app.dragRun().phase === 'running') this.app.shiftDrag()
      }
    }
  }

  private onKeyUp(event: KeyboardEvent): void {
    if (event.code === 'KeyF' && this.holdingPedal) {
      this.holdingPedal = false
      this.app.setPedal(false)
    }
  }

  frame(dt: number): void {
    void dt
    if (this.app.screen === 'dyno') this.frameDyno()
    if (this.app.screen === 'test' && this.app.testTab === 'drag') this.frameDrag()
    if (this.app.screen === 'test' && this.app.testTab === 'handling') this.frameHandling()
  }

  private setText(key: string, value: string): void {
    if (this.liveCache.get(key) === value) return
    this.liveCache.set(key, value)
    for (const el of this.root.querySelectorAll<HTMLElement>(`[data-live="${key}"]`)) el.textContent = value
  }

  private frameDyno(): void {
    const app = this.app
    const build = app.activeBuild()
    const run = app.dynoRun()
    const points = run.points.length ? run.points : build.dyno?.points ?? app.curve(build)
    const cursor = run.points.length ? Math.min(points.length - 1, run.cursor) : Math.max(0, points.length - 1)
    const point = points[cursor]
    const rpm = run.phase === 'pulling' ? run.rpm : app.live().rpm
    const maxRpm = Math.max(8000, Math.ceil(build.ecu.revLimit / 1000) * 1000)
    const needle = this.root.querySelector<SVGGElement>('#tach-needle')
    if (needle) needle.setAttribute('transform', `rotate(${-120 + Math.min(1, rpm / maxRpm) * 240} 100 102)`)
    this.setText('rpm', num(rpm))
    if (point) {
      this.setText('power', num(point.hp))
      this.setText('torque', num(point.torque))
      this.setText('boost', num(point.boost, 1))
      this.setText('afr', num(point.afr, 1))
      this.setText('knock', num(point.knock))
      this.setText('egt', `${num(point.egt)}°`)
      this.setText('duty', `${num(point.duty)}%`)
      this.setText('overlay-power', num(point.hp))
      this.setText('overlay-torque', `${num(point.torque)} NM`)
      this.setText('overlay-boost', `${num(point.boost, 1)} PSI`)
      const cursorX = 38 + ((point.rpm - points[0].rpm) / Math.max(1, points[points.length - 1].rpm - points[0].rpm)) * (422 - 38)
      const rect = this.root.querySelector<SVGRectElement>('#dyno-reveal-rect')
      if (rect) rect.setAttribute('width', String(Math.max(0, cursorX - 38)))
      const line = this.root.querySelector<SVGLineElement>('#dyno-cursor')
      if (line) {
        line.setAttribute('x1', String(cursorX)); line.setAttribute('x2', String(cursorX))
      }
      const maxHp = Math.max(100, ...points.map(p => p.hp)) * 1.14
      const maxTq = Math.max(100, ...points.map(p => p.torque)) * 1.14
      const dotHp = this.root.querySelector<SVGCircleElement>('#dyno-dot-hp')
      const dotTq = this.root.querySelector<SVGCircleElement>('#dyno-dot-tq')
      if (dotHp) {
        dotHp.setAttribute('cx', String(cursorX))
        dotHp.setAttribute('cy', String(162 - (point.hp / maxHp) * 146))
      }
      if (dotTq) {
        dotTq.setAttribute('cx', String(cursorX))
        dotTq.setAttribute('cy', String(162 - (point.torque / maxTq) * 146))
      }
    }
    const progress = run.phase === 'pulling' ? Math.min(100, (run.time / 5.4) * 100) : run.phase === 'done' ? 100 : 0
    const bar = this.root.querySelector<HTMLElement>('#dyno-progress')
    if (bar) bar.style.width = `${progress}%`
    this.root.querySelector('.pedal-btn')?.classList.toggle('is-down', run.phase === 'revving')
  }

  private frameDrag(): void {
    const app = this.app
    const drag = app.dragRun()
    this.setText('drag-elapsed', drag.elapsed.toFixed(2))
    this.setText('drag-speed', num(drag.speed * 3.6))
    this.setText('drag-rpm', num(drag.rpm))
    this.setText('drag-gear', drag.gear > 0 ? String(drag.gear) : 'N')
    this.setText('drag-sixty', drag.sixtyFt ? drag.sixtyFt.toFixed(2) : '—')
    this.setText('drag-zero', drag.zeroTo100 ? drag.zeroTo100.toFixed(2) : '—')
    this.setText('drag-wheelspin', num(drag.wheelspin, 2))
    this.setText('drag-shifts', String(drag.shiftCount))
    this.setText('overlay-speed', num(drag.speed * 3.6))
    this.setText('overlay-elapsed', drag.elapsed.toFixed(2))
    this.setText('overlay-gear', drag.gear > 0 ? String(drag.gear) : 'N')
    let active = -1
    if (drag.phase === 'tree') active = drag.treeTime > 1.55 ? 2 : drag.treeTime > 1.05 ? 1 : drag.treeTime > 0.55 ? 0 : -1
    if (drag.phase === 'running' || drag.phase === 'finished') active = 3
    for (const light of this.root.querySelectorAll<HTMLElement>('[data-tree]')) {
      light.classList.toggle('on', Number(light.dataset.tree) === active)
    }
  }

  private frameHandling(): void {
    const app = this.app
    const handling = app.handlingRun()
    this.setText('handling-speed', num(handling.speed))
    this.setText('handling-g', handling.lateralG.toFixed(2))
    this.setText('handling-progress', String(Math.round(handling.progress * 100)))
    this.setText('handling-balance', handling.result?.balance ?? '—')
    this.setText('overlay-handling', `${Math.round(handling.progress * 100)}%`)
    const dot = this.root.querySelector<SVGCircleElement>('#course-dot')
    const path = this.root.querySelector<SVGPathElement>('#course-path')
    if (dot && path) {
      const length = path.getTotalLength()
      const p = path.getPointAtLength(Math.min(1, Math.max(0, handling.progress)) * length)
      dot.setAttribute('cx', String(p.x))
      dot.setAttribute('cy', String(p.y))
    }
  }
}
