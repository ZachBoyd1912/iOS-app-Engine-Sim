/**
 * App lifecycle: going to the background and coming back.
 *
 * On a phone the game is interrupted constantly (home swipe, a call, the lock button). When
 * that happens the progress must be saved and the engine sound must stop; when the player
 * returns the sound must be able to start again. The browser's page-visibility events fire in
 * the iOS web view as well, so one implementation serves both.
 */

export interface LifecycleTarget {
  /** Persist progress now. Called every time the app is hidden. */
  save(): void
  /** Silence and suspend audio. */
  suspendAudio(): void
  /** Bring audio back (best effort: iOS may still need a touch). */
  resumeAudio(): void
  /** Drop time that passed while hidden so the simulation does not jump. */
  resetClock(): void
}

type Listenable = Pick<Document, 'addEventListener' | 'removeEventListener'> & { readonly hidden: boolean }
type WindowLike = Pick<Window, 'addEventListener' | 'removeEventListener'>

/** Wire the target to visibility changes. Returns a function that removes the listeners. */
export function bindLifecycle(target: LifecycleTarget, doc: Listenable = document, win: WindowLike = window): () => void {
  let hidden = doc.hidden

  const goHidden = () => {
    // Save first: if anything after this throws, progress is already on disk.
    target.save()
    if (hidden) return
    hidden = true
    target.suspendAudio()
  }
  const goVisible = () => {
    if (!hidden) return
    hidden = false
    target.resetClock()
    target.resumeAudio()
  }
  const onVisibility = () => (doc.hidden ? goHidden() : goVisible())
  const onPageHide = () => goHidden()
  const onPageShow = () => goVisible()

  doc.addEventListener('visibilitychange', onVisibility)
  win.addEventListener('pagehide', onPageHide)
  win.addEventListener('pageshow', onPageShow)
  return () => {
    doc.removeEventListener('visibilitychange', onVisibility)
    win.removeEventListener('pagehide', onPageHide)
    win.removeEventListener('pageshow', onPageShow)
  }
}
