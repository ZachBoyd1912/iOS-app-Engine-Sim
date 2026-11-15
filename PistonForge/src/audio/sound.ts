import { LAYOUTS, INDUCTIONS, FUELS } from '../sim/data'
import type { EngineConfig } from '../sim/types'

const clamp = (v: number, min: number, max: number) => Math.min(max, Math.max(min, v))

type Voice = {
  config: EngineConfig
  oscillators: OscillatorNode[]
  gains: GainNode[]
  filter: BiquadFilterNode
  engineGain: GainNode
  limiterGain: GainNode
  noise: AudioBufferSourceNode
  noiseGain: GainNode
  noiseFilter: BiquadFilterNode
  turboOsc: OscillatorNode
  turboGain: GainNode
  turboFilter: BiquadFilterNode
  spoolNoise: AudioBufferSourceNode
  spoolGain: GainNode
  spoolFilter: BiquadFilterNode
  nodes: AudioNode[]
}

export class SoundEngine {
  private ctx: AudioContext | null = null
  private master: GainNode | null = null
  private engineBus: GainNode | null = null
  private sfxBus: GainNode | null = null
  private ambientBus: GainNode | null = null
  private voice: Voice | null = null
  private unlocked = false
  private failed = false
  private engineVolume = 0.8
  private sfxVolume = 0.7
  private musicVolume = 0.35
  private lastRpm = 0
  private lastLoad = 0
  private lastPopAt = 0
  private noiseBuffer: AudioBuffer | null = null
  private timers: number[] = []

  get available(): boolean {
    return !this.failed
  }

  async unlock(): Promise<void> {
    if (this.unlocked || this.failed) {
      await this.resume()
      return
    }
    try {
      const Ctor = window.AudioContext ?? (window as unknown as { webkitAudioContext?: typeof AudioContext }).webkitAudioContext
      if (!Ctor) {
        this.failed = true
        return
      }
      this.ctx = new Ctor()
      this.master = this.ctx.createGain()
      this.master.gain.value = 0.9
      this.master.connect(this.ctx.destination)
      this.engineBus = this.ctx.createGain()
      this.engineBus.gain.value = this.engineVolume
      this.engineBus.connect(this.master)
      this.sfxBus = this.ctx.createGain()
      this.sfxBus.gain.value = this.sfxVolume
      this.sfxBus.connect(this.master)
      this.ambientBus = this.ctx.createGain()
      this.ambientBus.gain.value = this.musicVolume * 0.16
      this.ambientBus.connect(this.master)
      this.noiseBuffer = this.makeNoise(this.ctx, 2)
      this.startAmbient()
      await this.ctx.resume()
      this.unlocked = true
    } catch {
      this.failed = true
    }
  }

  setVolumes(engine: number, sfx: number, music: number): void {
    this.engineVolume = clamp(engine, 0, 1)
    this.sfxVolume = clamp(sfx, 0, 1)
    this.musicVolume = clamp(music, 0, 1)
    if (!this.ctx) return
    this.engineBus?.gain.setTargetAtTime(this.engineVolume, this.ctx.currentTime, 0.08)
    this.sfxBus?.gain.setTargetAtTime(this.sfxVolume, this.ctx.currentTime, 0.08)
    this.ambientBus?.gain.setTargetAtTime(this.musicVolume * 0.16, this.ctx.currentTime, 0.2)
  }

  startEngine(config: EngineConfig): void {
    if (!this.ctx || !this.engineBus) return
    this.stopVoice(0.12)
    const ctx = this.ctx
    const pulseWave = this.makeFiringWave(ctx, config)
    const bodyWave = this.makeBodyWave(ctx, config)
    const engineGain = ctx.createGain()
    engineGain.gain.value = 0.0001
    const limiterGain = ctx.createGain()
    limiterGain.gain.value = 1
    const filter = ctx.createBiquadFilter()
    filter.type = 'lowpass'
    filter.frequency.value = 600
    filter.Q.value = 1.1
    filter.connect(limiterGain)
    limiterGain.connect(engineGain)
    engineGain.connect(this.engineBus)

    const osc1 = ctx.createOscillator()
    osc1.setPeriodicWave(pulseWave)
    const osc1Gain = ctx.createGain()
    osc1Gain.gain.value = 0.34
    osc1.connect(osc1Gain)
    osc1Gain.connect(filter)

    const osc2 = ctx.createOscillator()
    osc2.setPeriodicWave(bodyWave)
    const osc2Gain = ctx.createGain()
    osc2Gain.gain.value = 0.18
    osc2.connect(osc2Gain)
    osc2Gain.connect(filter)

    const rasp = ctx.createOscillator()
    rasp.type = 'sawtooth'
    const raspGain = ctx.createGain()
    raspGain.gain.value = 0.025
    rasp.connect(raspGain)
    raspGain.connect(filter)

    const noise = ctx.createBufferSource()
    noise.buffer = this.noiseBuffer
    noise.loop = true
    const noiseFilter = ctx.createBiquadFilter()
    noiseFilter.type = 'bandpass'
    noiseFilter.frequency.value = 700
    noiseFilter.Q.value = 0.7
    const noiseGain = ctx.createGain()
    noiseGain.gain.value = 0.02
    noise.connect(noiseFilter)
    noiseFilter.connect(noiseGain)
    noiseGain.connect(limiterGain)

    const turboOsc = ctx.createOscillator()
    turboOsc.type = 'sine'
    turboOsc.frequency.value = 1900
    const turboFilter = ctx.createBiquadFilter()
    turboFilter.type = 'bandpass'
    turboFilter.frequency.value = 2400
    turboFilter.Q.value = 2.2
    const turboGain = ctx.createGain()
    turboGain.gain.value = 0.0001
    turboOsc.connect(turboFilter)
    turboFilter.connect(turboGain)
    turboGain.connect(limiterGain)

    const spoolNoise = ctx.createBufferSource()
    spoolNoise.buffer = this.noiseBuffer
    spoolNoise.loop = true
    const spoolFilter = ctx.createBiquadFilter()
    spoolFilter.type = 'highpass'
    spoolFilter.frequency.value = 2200
    const spoolGain = ctx.createGain()
    spoolGain.gain.value = 0.0001
    spoolNoise.connect(spoolFilter)
    spoolFilter.connect(spoolGain)
    spoolGain.connect(limiterGain)

    for (const node of [osc1, osc2, rasp, noise, turboOsc, spoolNoise]) node.start()
    engineGain.gain.setTargetAtTime(0.16, ctx.currentTime, 0.18)
    this.voice = {
      config,
      oscillators: [osc1, osc2, rasp],
      gains: [osc1Gain, osc2Gain, raspGain],
      filter,
      engineGain,
      limiterGain,
      noise,
      noiseGain,
      noiseFilter,
      turboOsc,
      turboGain,
      turboFilter,
      spoolNoise,
      spoolGain,
      spoolFilter,
      nodes: [engineGain, limiterGain, filter, noiseGain, turboGain, spoolGain],
    }
    this.crankCue(ctx)
    this.lastRpm = 0
    this.lastLoad = 0
  }

  stopEngine(fade = 0.4): void {
    this.stopVoice(fade)
  }

  /** Freeze all audio. Called when the app goes to the background so the engine does not drone on. */
  suspend(): void {
    if (!this.ctx || this.ctx.state !== 'running') return
    void this.ctx.suspend().catch(() => {})
  }

  /**
   * Bring audio back after the app returns or after an interruption (a call, Siri).
   * iOS can refuse outside a touch; callers also retry from the next pointer event.
   */
  async resume(): Promise<void> {
    if (!this.ctx || !this.unlocked) return
    // iOS reports "interrupted" as well as the standard states.
    const state = this.ctx.state as string
    if (state === 'running' || state === 'closed') return
    try {
      await this.ctx.resume()
    } catch {
      // Still blocked: the next touch will try again.
    }
  }

  private stopVoice(fade: number): void {
    if (!this.ctx || !this.voice) return
    const ctx = this.ctx
    const voice = this.voice
    voice.engineGain.gain.cancelScheduledValues(ctx.currentTime)
    voice.engineGain.gain.setTargetAtTime(0.0001, ctx.currentTime, Math.max(0.03, fade / 3))
    const stopAt = ctx.currentTime + fade + 0.1
    for (const osc of [...voice.oscillators, voice.turboOsc]) {
      try { osc.stop(stopAt) } catch { /* already stopped */ }
    }
    for (const source of [voice.noise, voice.spoolNoise]) {
      try { source.stop(stopAt) } catch { /* already stopped */ }
    }
    this.voice = null
  }

  update(rpm: number, load: number, boost = 0, limiter = false): void {
    if (!this.ctx || !this.voice) return
    const ctx = this.ctx
    const voice = this.voice
    const layout = LAYOUTS[voice.config.layout]
    const cycle = layout.cycleDeg
    const firing = (rpm / 60) * (720 / cycle)
    const now = ctx.currentTime
    const smooth = 0.045
    voice.oscillators[0].frequency.setTargetAtTime(Math.max(4, firing / 2), now, smooth)
    voice.oscillators[1].frequency.setTargetAtTime(Math.max(8, firing), now, smooth)
    voice.oscillators[2].frequency.setTargetAtTime(Math.max(12, firing * 1.5), now, smooth)
    const cutoff = 260 + rpm * 0.28 + load * 1900
    voice.filter.frequency.setTargetAtTime(clamp(cutoff, 180, 7200), now, 0.08)
    voice.filter.Q.setTargetAtTime(0.8 + load * 1.2, now, 0.1)
    voice.noiseFilter.frequency.setTargetAtTime(420 + rpm * 0.32, now, 0.1)
    voice.noiseGain.gain.setTargetAtTime(0.008 + load * 0.055 + rpm * 0.000002, now, 0.1)
    const targetGain = 0.10 + load * 0.20 + clamp(rpm / 8500, 0, 1) * 0.08
    voice.engineGain.gain.setTargetAtTime(targetGain, now, 0.1)

    const induction = INDUCTIONS[voice.config.induction]
    const turboAmount = induction.maxBoost > 0 ? clamp(boost / Math.max(1, induction.maxBoost), 0, 1.2) : 0
    if (turboAmount > 0.02) {
      voice.turboOsc.frequency.setTargetAtTime(1500 + boost * 190 + rpm * 0.12, now, 0.08)
      voice.turboGain.gain.setTargetAtTime(turboAmount * 0.06, now, 0.12)
      voice.spoolFilter.frequency.setTargetAtTime(1800 + rpm * 0.4, now, 0.12)
      voice.spoolGain.gain.setTargetAtTime(turboAmount * 0.05, now, 0.12)
    } else {
      voice.turboGain.gain.setTargetAtTime(0.0001, now, 0.15)
      voice.spoolGain.gain.setTargetAtTime(0.0001, now, 0.15)
    }

    if (limiter) {
      const gate = Math.sin(performance.now() * 0.11) > 0 ? 1 : 0.18
      voice.limiterGain.gain.setTargetAtTime(gate, now, 0.008)
    } else {
      voice.limiterGain.gain.setTargetAtTime(1, now, 0.04)
    }

    if (this.lastLoad > 0.35 && load < 0.12 && this.lastRpm > 2800 && now - this.lastPopAt > 0.5) {
      this.lastPopAt = now
      this.schedulePops(ctx, voice, 3 + Math.floor(Math.random() * 4))
    }
    this.lastRpm = rpm
    this.lastLoad = load
  }

  private schedulePops(ctx: AudioContext, voice: Voice, count: number): void {
    for (let i = 0; i < count; i += 1) {
      const delay = i * (0.045 + Math.random() * 0.06)
      const source = ctx.createBufferSource()
      source.buffer = this.noiseBuffer
      const filter = ctx.createBiquadFilter()
      filter.type = 'bandpass'
      filter.frequency.value = 900 + Math.random() * 1300
      filter.Q.value = 1.4
      const gain = ctx.createGain()
      gain.gain.setValueAtTime(0.0001, ctx.currentTime + delay)
      gain.gain.exponentialRampToValueAtTime(0.07 + Math.random() * 0.06, ctx.currentTime + delay + 0.008)
      gain.gain.exponentialRampToValueAtTime(0.0001, ctx.currentTime + delay + 0.12)
      source.connect(filter)
      filter.connect(gain)
      gain.connect(voice.limiterGain)
      source.start(ctx.currentTime + delay)
      source.stop(ctx.currentTime + delay + 0.16)
    }
  }

  shiftCue(): void {
    if (!this.ctx || !this.sfxBus) return
    const ctx = this.ctx
    const t = ctx.currentTime
    const source = ctx.createBufferSource()
    source.buffer = this.noiseBuffer
    const filter = ctx.createBiquadFilter()
    filter.type = 'bandpass'
    filter.frequency.value = 1600
    filter.Q.value = 1.2
    const gain = ctx.createGain()
    gain.gain.setValueAtTime(0.06, t)
    gain.gain.exponentialRampToValueAtTime(0.0001, t + 0.09)
    source.connect(filter)
    filter.connect(gain)
    gain.connect(this.sfxBus)
    source.start(t)
    source.stop(t + 0.1)
    this.tone(110, 0.05, 0.028, 'square')
  }

  ui(kind: 'click' | 'confirm' | 'error' | 'cash' | 'tree' | 'green' | 'page'): void {
    switch (kind) {
      case 'click': this.tone(220, 0.035, 0.018, 'square'); break
      case 'confirm': this.tone(440, 0.07, 0.025, 'triangle', 0.02); this.tone(660, 0.09, 0.02, 'triangle', 0.08); break
      case 'error': this.tone(90, 0.15, 0.035, 'sawtooth'); break
      case 'cash': this.tone(880, 0.07, 0.025, 'sine', 0.02); this.tone(1320, 0.1, 0.02, 'sine', 0.1); break
      case 'tree': this.tone(420, 0.12, 0.04, 'square'); break
      case 'green': this.tone(760, 0.2, 0.05, 'square'); break
      case 'page': this.tone(160, 0.05, 0.012, 'sine'); break
    }
  }

  private tone(freq: number, duration: number, gainValue: number, type: OscillatorType, delay = 0): void {
    if (!this.ctx || !this.sfxBus) return
    const ctx = this.ctx
    const t = ctx.currentTime + delay
    const osc = ctx.createOscillator()
    const gain = ctx.createGain()
    osc.type = type
    osc.frequency.value = freq
    gain.gain.setValueAtTime(0.0001, t)
    gain.gain.exponentialRampToValueAtTime(gainValue, t + 0.006)
    gain.gain.exponentialRampToValueAtTime(0.0001, t + duration)
    osc.connect(gain)
    gain.connect(this.sfxBus)
    osc.start(t)
    osc.stop(t + duration + 0.02)
  }

  private crankCue(ctx: AudioContext): void {
    if (!this.sfxBus) return
    const t = ctx.currentTime
    const osc = ctx.createOscillator()
    const gain = ctx.createGain()
    osc.type = 'sawtooth'
    osc.frequency.setValueAtTime(52, t)
    osc.frequency.linearRampToValueAtTime(140, t + 0.45)
    gain.gain.setValueAtTime(0.0001, t)
    gain.gain.exponentialRampToValueAtTime(0.05, t + 0.04)
    gain.gain.exponentialRampToValueAtTime(0.0001, t + 0.7)
    const filter = ctx.createBiquadFilter()
    filter.type = 'lowpass'
    filter.frequency.value = 500
    osc.connect(filter)
    filter.connect(gain)
    gain.connect(this.sfxBus)
    osc.start(t)
    osc.stop(t + 0.75)
    for (let i = 0; i < 4; i += 1) {
      const source = ctx.createBufferSource()
      source.buffer = this.noiseBuffer
      const g = ctx.createGain()
      const when = t + i * 0.11
      g.gain.setValueAtTime(0.0001, when)
      g.gain.exponentialRampToValueAtTime(0.03, when + 0.01)
      g.gain.exponentialRampToValueAtTime(0.0001, when + 0.06)
      source.connect(g)
      g.connect(this.sfxBus)
      source.start(when)
      source.stop(when + 0.07)
    }
  }

  private startAmbient(): void {
    if (!this.ctx || !this.ambientBus) return
    const ctx = this.ctx
    const gain = this.ambientBus
    const low = ctx.createOscillator()
    low.type = 'sine'
    low.frequency.value = 48
    const lowGain = ctx.createGain()
    lowGain.gain.value = 0.12
    low.connect(lowGain)
    lowGain.connect(gain)
    const high = ctx.createOscillator()
    high.type = 'triangle'
    high.frequency.value = 96.3
    const highGain = ctx.createGain()
    highGain.gain.value = 0.025
    high.connect(highGain)
    highGain.connect(gain)
    const noise = ctx.createBufferSource()
    noise.buffer = this.noiseBuffer
    noise.loop = true
    const filter = ctx.createBiquadFilter()
    filter.type = 'lowpass'
    filter.frequency.value = 220
    const nGain = ctx.createGain()
    nGain.gain.value = 0.02
    noise.connect(filter)
    filter.connect(nGain)
    nGain.connect(gain)
    low.start()
    high.start()
    noise.start()
  }

  private makeNoise(ctx: AudioContext, seconds: number): AudioBuffer {
    const length = Math.floor(ctx.sampleRate * seconds)
    const buffer = ctx.createBuffer(1, length, ctx.sampleRate)
    const data = buffer.getChannelData(0)
    let last = 0
    for (let i = 0; i < length; i += 1) {
      const white = Math.random() * 2 - 1
      last = last * 0.15 + white * 0.85
      data[i] = last * 0.5
    }
    return buffer
  }

  private makeFiringWave(ctx: AudioContext, config: EngineConfig): PeriodicWave {
    const layout = LAYOUTS[config.layout]
    const pulses = layout.pulseAngles.map((angle, index) => ({
      angle,
      amp: config.layout === 'v8' ? (index % 2 === 0 ? 1 : 0.82) : config.layout === 'flat4' ? (index % 2 === 0 ? 1 : 0.9) : 1,
    }))
    const harmonics = 64
    const real = new Float32Array(harmonics + 1)
    const imag = new Float32Array(harmonics + 1)
    let magnitude = 0
    for (let n = 1; n <= harmonics; n += 1) {
      let re = 0
      let im = 0
      for (const pulse of pulses) {
        const phase = (-2 * Math.PI * n * pulse.angle) / layout.cycleDeg
        re += Math.cos(phase) * pulse.amp
        im += Math.sin(phase) * pulse.amp
      }
      const roll = 1 / Math.pow(n, 1.06)
      real[n] = re * roll
      imag[n] = im * roll
      magnitude = Math.max(magnitude, Math.hypot(real[n], imag[n]))
    }
    if (magnitude > 0) {
      for (let n = 1; n <= harmonics; n += 1) {
        real[n] /= magnitude
        imag[n] /= magnitude
      }
    }
    return ctx.createPeriodicWave(real, imag, { disableNormalization: false })
  }

  private makeBodyWave(ctx: AudioContext, config: EngineConfig): PeriodicWave {
    const harmonics = 18
    const real = new Float32Array(harmonics + 1)
    const imag = new Float32Array(harmonics + 1)
    for (let n = 1; n <= harmonics; n += 1) {
      imag[n] = (1 / Math.pow(n, 1.5)) * (n % 2 === 0 ? 0.7 : 1)
    }
    if (FUELS[config.fuel].id === 'e85') imag[1] *= 1.08
    return ctx.createPeriodicWave(real, imag, { disableNormalization: false })
  }

  dispose(): void {
    for (const timer of this.timers) window.clearTimeout(timer)
    this.timers = []
    this.stopVoice(0.05)
    try {
      this.ctx?.close()
    } catch {
      // ignore
    }
    this.ctx = null
    this.unlocked = false
  }
}
