---
name: mobile-viewport
description: Mobile viewport, safe-area, aspect-ratio and sizing rules for the Rental Wrangler SPA. Use when making any screen work on phones — full-height surfaces, the notch/home-indicator, the 100vh bug, dvh/svh/lvh units, orientation, or auditing touch-target sizes.
---

# Mobile Viewport & Ratio

Rules for making Rental Wrangler (`index.html` / `app.js` / `style.css`) sit correctly
inside a phone's *actual* usable rectangle — not the lie that is `100vh`.

## The viewport meta (do this first)
`index.html` must declare:
```html
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
```
`viewport-fit=cover` is required or `env(safe-area-inset-*)` is always `0`. Check it's
present before touching CSS.

## Height: never `100vh` on mobile
Mobile browser toolbars expand/collapse, so `100vh` is taller than the visible area —
fixed/full-height surfaces get clipped under the URL bar.
- Full-height surfaces (login, overlays, the chat dock sheet, the winpicker): use
  **`100dvh`** (dynamic viewport height).
- `svh` (smallest) for things that must never be hidden by chrome; `lvh` (largest)
  rarely. Pattern: `min-height: 100svh;` for a hero, `height: 100dvh;` for a sheet.
- Provide a fallback: `height: 100vh; height: 100dvh;` (older engines take the first).

## Safe-area insets (notch + home indicator)
Anything pinned to an edge must pad by the inset or it lands under the notch / home bar.
- Bottom bar (`.bottombar`), chat dock (`.chat-dock`), drop pad (`.chat-drop`),
  cancel-arc: add `padding-bottom: max(<base>, env(safe-area-inset-bottom));` and offset
  `bottom:` by the inset.
- Use `max()` so desktop (inset 0) keeps the base padding.
- Top sticky headers: `padding-top: env(safe-area-inset-top)`.

## Aspect-ratio (kill layout shift)
Use the `aspect-ratio` property for any media/thumbnail/avatar box so it reserves space
before content loads — never hard-code height that breaks at another width. Example:
`.cav { aspect-ratio: 1; }` (already square via width/height — prefer `aspect-ratio`
when only one dimension is known).

## Orientation
Landscape phones are *short*. Anything capped by height (the chat dock uses
`max-height: min(74vh,660px)`) should use `dvh` and stay scrollable. Don't lock
orientation. Test both.

## No horizontal overflow
The 3-column `.grid` cannot fit a phone — it MUST reflow to one column (see the
`mobile-navigation` skill). Until it does, a phone shows a sideways-scrolling mess.
Guard fl/grid children with `min-width: 0` so long text/pills wrap instead of pushing
width. Add a debug check: nothing should make `document.scrollingElement.scrollWidth >
clientWidth`.

## Touch-target floor
Interactive elements need ≥ **44×44 px** (Apple) / 48 (Material) hit area, even if the
glyph is smaller (use padding or a `::before` expander). Audit on phone: `.iconbtn`,
`.pill.gate`, `.row .rbtn`, the chat `.rtab`, tag `×` buttons, the `.cmt-dot` pickers.

## Verify
Drive the `webapp-testing` skill at a phone context, e.g.
`browser.newPage({ viewport:{width:390,height:844}, deviceScaleFactor:3, isMobile:true,
hasTouch:true })`, then assert no horizontal scroll, screenshot portrait + landscape,
and confirm the bottom bar clears the home indicator.

## Don't
- Don't use `vh` for sheets/overlays. Don't pin to an edge without a safe-area pad.
- Don't gate actions behind `:hover` (no hover on touch — see `mobile-touch`).
- Keep the yard data-plate language; mobile is a reflow, not a re-theme.
