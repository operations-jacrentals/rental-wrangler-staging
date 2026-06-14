---
name: mobile-navigation
description: Mobile layout reflow and navigation patterns for the Rental Wrangler SPA. Use when adapting the 3-column yard grid, bottom bar, overlays, chat dock, or winpicker to phones — single-column reflow, column switching, bottom sheets, and back/dismiss behavior.
---

# Mobile Navigation & Reflow

How the desktop "yard" reshapes onto one narrow screen without losing the model.

## The core problem: 3 columns → 1
Desktop shows `COLUMNS` (left/middle/right) side by side, each painting one active
member card (`columnEl`). A phone fits **one column at a time**.

**Recommended model — single active column + a switcher** (reuses the existing
column-member concept, so the engine/anchor/cascade stay untouched):
- Render only the active column on phones; the other two collapse.
- Add a top **segmented switcher** (Left · Middle · Right, or icons:
  Yard · Rentals · Office) that sets which column is visible. State lives next to
  `activeSession().cols`.
- A link pill that targets another column switches to it (the `revealCol` path already
  exists — extend it to also flip the visible column on mobile).
- Keep within-column tabs (the `.js-tab` strip) for switching the member/record.

Avoid a long vertical stack of all three columns — it buries the middle/right work and
loses the "three workstations" mental model.

## Bottom bar (`.bottombar`)
Stays a bottom nav. On phone: icon-only (drop the labels on the left actions), allow it
to wrap or horizontally scroll if it overflows, and pad it by
`env(safe-area-inset-bottom)` (see `mobile-viewport`). The chat launcher + badge stay.

## Overlays, winpicker, chat dock → sheets
Floating popups don't work at 360px. On phones:
- **Overlays** (`.popup` in `.overlay`): become a full-screen or bottom sheet
  (`height: 100dvh` or `max-height: 92dvh; border-radius: 18px 18px 0 0`). The comment
  color-flood card can stay a centered card (it's small).
- **Winpicker** (calendar): full-screen sheet — the day grid needs the width.
- **Chat dock** (`.chat-dock`): already goes near-full-width under 560px; on phones make
  it a **bottom sheet** that slides up to ~92dvh, with the tag rail pinned top and the
  role tab-bar + compose pinned bottom. The drop-pad / cancel-arc already live at the
  bottom — keep them above the safe-area inset.

## Back / dismiss behavior
One predictable "back" affordance. The Esc/back chain should close in order:
overlay → winpicker → open sheet/dock → (then a browser back leaves). Wire the Android
back gesture / a top-left chevron to the same chain. Don't trap the user in a sheet with
no visible close.

## Scroll discipline
- One primary scroll region per screen (the active card body). Avoid nested scrollers
  that fight; if a sheet scrolls, the page behind must not (`overflow:hidden` on body
  while a sheet is open).
- Sticky section headers inside long cards so context survives scrolling.

## Quality floor
Responsive down to 320px, visible focus, reduced-motion respected, every action
reachable by tap (nothing hover-only). Run the reflow through the `frontend` skill to
keep the data-plate language, and verify with `webapp-testing` at 390×844 + 320px.
