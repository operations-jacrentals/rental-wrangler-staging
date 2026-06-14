# Mobile (Adaptive Reflow) — Design Spec

**Date:** 2026-06-14
**Topic:** Make the Rental Wrangler SPA field-ready on phones
**Status:** Approved design → ready for implementation planning

## Goal

Make the app **work well on a phone** — no horizontal scroll, everything tappable and
reachable, readable at ~390px — without chasing a native-feeling rebuild. Desktop stays
the primary ("real") experience and is **untouched**.

## Approach

**Adaptive reflow (Approach A):** one set of width breakpoints + a thin JS layer for
gestures. Reuse the existing column model and drag engine; no separate mobile render
path, no second layout to maintain.

## Scope priorities

Mobile users are **yard/field hands** (Units · Inspections · Service — the left column)
and the **internal team chat**. Rentals/dispatch and Customers/Invoices must stay
*un-broken* but get no first-class polish in this effort.

## Non-goals (explicitly out)

- Bottom-sheet conversions of overlays/winpicker, per-screen visual polish passes.
- A segmented "switcher" control (navigation is **swipe**), a dedicated mobile mode,
  haptics, and advanced gestures (swipe-to-dismiss, etc.).
- Touch-target/safe-area exhaustive audits beyond what M0 needs to not break.

## Design

### Responsive columns by width
The `.grid` shows a different number of `COLUMNS` by viewport width:

| Width | Columns | Bottom strip | Navigation |
|---|---|---|---|
| Desktop (≥ ~1024px) | 3 (all) | today's single global bottom bar | none (all visible) |
| Tablet (~640–1024px) | 2 | today's single global bottom bar | swipe to reach the 3rd |
| Phone (< 640px) | 1 | **per-column** (see below) | swipe between all 3 |

Breakpoints above are starting values to tune during M0. A `body.is-phone` class (set via
`matchMedia`) lets both CSS and the gesture layer key off the phone state.

### Per-column bottom strips (phone only)
On phones, the bottom of the screen is **contextual to the visible column**. As you swipe,
the docked strip changes:

| Column | Bottom strip |
|---|---|
| Left — Yard (units/inspections/service) | **Internal team chat** (the §17 dock) |
| Middle — Rentals (home) | **Tool bar** (today's global utilities) |
| Right — Customers/Invoices | **External chats** (customer/vendor messaging) |

The **external-chats strip is a shell** on mobile — the slot and UI exist, but live
customer/vendor SMS/email depends on the (still-blocked) backend messaging integration.
It lights up when that lands. Tablet and desktop keep today's single global bottom bar
(this contextual behavior is phone-only).

### Gesture model (phone)
The crux. One touch on the grid resolves to exactly one of: scroll, column-swipe,
item-drag, element-action, or context-menu. Proposed disambiguation rule:

- **Vertical move first → native scroll** (the column body scrolls; no drag).
- **Horizontal move on the column background → column swipe** (switch column).
- **Horizontal move on a draggable element** (`.row`, standard card, `[data-chat-el]`,
  etc.) **→ drag that element.** While dragging, the screen edges become drop actions
  (consistent left/right/bottom):
  - **holding at the left/right edge → switch to the next column** (carry the item across
    columns).
  - **holding at the bottom edge → trigger a chat** — on a phone the bottom edge *is* the
    contextual chat strip, so this is the drop-pad concept relocated to the bottom edge.
- **Press-and-hold still (≥ ~500ms, no move) → context menu** (the right-click menu).
- **Quick tap (no move) → the element's normal action** (open / cycle a gate / etc.).

This replaces today's touch model (where a 400ms long-press *starts a drag*): now
**move = drag, hold-still = menu, tap = action.** It composes cleanly with the column
layout because dragging an item is inherently a horizontal gesture, scrolling is
vertical, and a column-swipe is horizontal-on-background.

## Phases

Each phase is independently shippable. M2 and M3 both rewire the pointer engine's touch
path and **share the gesture-disambiguation design** — design them together even if
shipped separately.

- **M0 — Responsive columns by width.** `.grid` reflows 3 → 2 → 1 across breakpoints;
  viewport meta present; **zero horizontal overflow** at one column; `body.is-phone`.
  *Done when:* at 390×844 there's no horizontal scroll and one column fills the screen.
- **M1 — Swipe nav + per-column bottom strips.** Horizontal swipe switches the visible
  column (1-col phone; also reaching the 3rd column at 2-col), with a minimal position
  indicator. Phone docks the mapped bottom strip per column (Yard→internal chat,
  Rentals→tool bar, Customers→external-chats shell).
  *Done when:* you can swipe through all three columns on a phone and each shows its
  correct bottom strip; desktop/tablet bottom bar unchanged.
- **M2 — Mobile drag: edge column-switch + chat trigger.** Drag works on touch; holding
  at the L/R edge mid-drag switches columns; holding at the bottom edge (chat strip)
  starts a chat.
  *Done when:* an item can be dragged across columns on a phone and into a chat via the
  bottom edge.
- **M3 — Long-press = context menu.** Press-and-hold-still opens the context menu; the
  tap/move/hold disambiguation above is in effect.
  *Done when:* tap = action, move = drag, hold-still = menu, on a real touch context.

## Testing

Every phase is verified with the `webapp-testing` skill at a phone context
(`isMobile:true, hasTouch:true`, e.g. 390×844): assert no horizontal scroll, drive
swipes/drags/long-press, screenshot portrait + landscape. New/changed UI runs through
the `frontend` skill to keep the yard data-plate language.

## Dependencies & risks

- **Risk:** the gesture disambiguation (scroll vs swipe vs drag vs menu) is the one hard
  problem; prototype it early in M2/M3 before committing the rest of those phases.
- **Dependency:** the external-chats strip (M1) is a shell until the backend messaging
  integration exists.
