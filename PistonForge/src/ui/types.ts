import type { PartSlot } from '../sim/types'

export type ResultStat = {
  label: string
  value: string
  detail?: string
}

export type ResultAction = {
  label: string
  action: string
  primary?: boolean
}

export type ResultModal = {
  kind: 'dyno' | 'drag' | 'handling' | 'job' | 'confirm'
  eyebrow: string
  title: string
  subtitle?: string
  badge?: string
  tone: 'ok' | 'warn' | 'bad'
  stats: ResultStat[]
  note?: string
  actions: ResultAction[]
}

export type EngineTab = 'bottom' | 'head' | 'air' | 'boost'
export type ShopTab = 'engine' | 'chassis' | 'bodies'
export type MapKind = 'fuel' | 'ignition'

export type UiState = {
  engineTab: EngineTab
  shopTab: ShopTab
  mapKind: MapKind
  selectedRow: number
  selectedCol: number
  modal: ResultModal | null
  toast: { text: string; tone: 'ok' | 'warn' | 'bad'; nonce: number } | null
  showJobDetails: boolean
  enginePresetOpen: boolean
}

export type PartChoice = {
  slot: PartSlot
  index: number
  name: string
  short: string
  cost: number
  updated: number
  locked: boolean
}