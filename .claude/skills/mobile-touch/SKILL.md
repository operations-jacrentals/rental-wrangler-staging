---
name: mobile-touch
description: Touch gestures and haptic feedback for the Rental Wrangler SPA. Use when wiring tap vs long-press vs drag vs swipe on phones, setting touch-action, avoiding the browser stealing a gesture, or adding Vibration-API haptic feedback to actions.
---

# Mobile Touch & Haptics

Input (gestures) and feedback (haptics) for the phone. The app already has a pointer-
based drag engine in `app.js` (§15) — extend its conventions, don't reinvent them.

## Gesture model (already in place — follow it)
- **Tap vs drag.** A press *arms* a drag; it only *starts* past a threshold:
  mouse = move > 6px (`dragMove`), touch = a **400ms long-press** (`dragDown` sets
  `armed.lp`). A tap (no move / released early) falls through to the element's click.
  So every interactive element is **tap = its action, long-press/drag = grab**. New
  draggables (`[data-chat-el]`, rows) inherit this for free.
- **`touch-action` is load-bearing.** Rows are `touch-action: pan-y` so vertical
  scrolling stays native and only a *lifted* row drags. Set `touch-action` deliberately:
  `pan-y` for vertical lists, `none` only on elements you fully own, `manipulation` on
  buttons to kill the 300ms double-tap-zoom delay.
- **Don't let the browser steal it.** A touch-scroll fires `pointercancel` → the drag
  must cancel cleanly (already wired in `initDrag`). The first `touchmove` after a
  long-press lift is `preventDefault`-ed (passive:false), gated on `DRAG.active`, so the
  page doesn't pan mid-drag. Preserve this when adding gestures.
- **Long-press also pops the native context menu** — it's suppressed during
  `DRAG.active || DRAG.armed` (`contextmenu` capture handler). Keep that.
- **No hover.** Touch has no hover. Never hide an action behind `:hover` (row actions,
  previews, the `×` on tags must be tap-visible). Hover previews are a desktop bonus.

## Swipe (optional, additive)
- Swipe left/right on the column area → the column switcher (see `mobile-navigation`).
- Swipe-down on a sheet/dock header → dismiss. Implement on top of the pointer stream
  (track dx/dy from `pointerdown`; commit past ~60px), and respect `touch-action` so it
  doesn't fight the scroll.

## Haptics (Vibration API)
Feedback for committing gestures. **Best-effort only** — `navigator.vibrate` works on
Android/Chrome; **iOS Safari does not support it**, so never rely on it for meaning.

Add one guarded helper to `app.js` and call it from action sites:
```js
// state.hapticsOff defaults to false; gate behind support + reduced-motion + setting
function haptic(p) {
  if (state.hapticsOff || !('vibrate' in navigator)) return;
  if (matchMedia('(prefers-reduced-motion: reduce)').matches) return;
  try { navigator.vibrate(p); } catch (e) {}
}
```
Vocabulary (keep it subtle — a tick, not a buzz):
- `haptic(8)` — light tap: ignition button press, status pill advance.
- `haptic([12, 30, 12])` — success: chat posted, record completed, drop accepted.
- `haptic([35, 25, 35])` — abort/danger: "release to cancel" on the cancel-arc.
- `haptic(10)` — drop-pad "release to start a chat" arm, tag added.

Hook points: `dragUp` (distinguish cancel vs drop vs new-chat), the cancel-arc/drop-pad
`hot` transition (a tick when it lights), `chatSend`, `Complete WO/Rental`, ignition
primary buttons. Give the user an off switch (a `state.hapticsOff` toggle in the bottom
bar or settings) and persist it.

## Don't
- Don't add a haptic to passive/scroll events or fire on every pointermove (annoying +
  battery). One pulse per committed action.
- Don't assume haptics fired (iOS) — they're reinforcement, never the only signal.
- Don't break the tap-vs-drag threshold; test that a quick tap still triggers the click.

## Verify
With `webapp-testing`, use a `hasTouch: true, isMobile: true` context and drive
`page.touchscreen` / pointer events: assert a tap fires the click, a long-press starts a
drag, and a scroll does NOT. Haptics can't be asserted headless — verify the `haptic()`
calls exist at the right sites and are guarded.
