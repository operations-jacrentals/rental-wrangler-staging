# DRAG & DROP ENGINE + MULTI-UNIT RENTALS — locked design (Jac, 2026-06-12)

> Jac's guidelines + answers, consolidated with the engine recon
> (`dragdrop-recon.json`). This is the build contract. Sequence: Expenses build
> lands → **multi-unit rentals refactor** → **drag engine** → quick-add/+New
> cleanup (orange pills become "+New X").

## 1 · Jac's rules (verbatim intent)

- List-view rows drag onto **other list rows or open standard-view cards**.
  ("mini" in the original dictation was a typo for main/many.)
- **Multiplicity table** (drag either direction, same link):

| Link | Limit |
|---|---|
| Units ↔ Rental | **MANY units per rental** (multi-unit rentals — see §2) |
| Rental ↔ Invoice | 1 invoice per rental · many rentals per invoice |
| Customer ↔ Rental | 1 customer per rental |
| Invoice ↔ Unit (WO billing) | a WO bills to 1 invoice |
| Customer ↔ Invoice | 1 customer per invoice · many invoices per customer |

- **Occupied one-only slots**: swap when safe; **money/safety gates BLOCK**
  (allocated payments, locked invoices, blacklist, Sold/Inactive units) with
  the R19 glow on the reason. Swaps say so in the completion message.
- **Overbooking**: allowed-but-FLAGGED (R9 `Overbooked` flag on the rental +
  unit) when the setting is ON; blocked when OFF. The toggle lives in a
  **Settings board** (doesn't exist yet — birth it with this build; recon:
  only login settings exist today, no behavior-settings store).
- **Stacked right column** (customers/invoices toggle): dragging a CUSTOMER
  hides the customers card to reveal invoices; dragging an INVOICE hides the
  invoices card to reveal customers. Restore the pre-drag member after
  drop/cancel.
- **Completion UX**: a message saying what just happened + the newly linked
  pill flashes ~2s (`attnFlash` is exactly 2s — R19 reuse).
- **Touch**: long-press (~400ms) lifts the row on phones so scrolling is never
  hijacked; mouse drags lift on a 6px movement threshold instantly.
- **CANCEL ZONE (Jac, confirmed)**: Esc cancels, AND on every drag a large
  BLACK HALF-CIRCLE expands from the bottom of the screen — above the toolbar,
  covering ~25–30% of the rental card's height at its apex, arcing off to the
  left and right — with a large "Cancel" message. Dropping the ghost on it
  cancels the drag (solves "just drop it back where it came from" being
  impossible when the customers/invoices card swapped mid-drag).
- **CONFIRMED by Jac**: invoice lines are PER UNIT on multi-unit rentals —
  each line carries its own transport journey + item balance (§2 reading is
  now binding, the ⚠ is resolved).

## 2 · MULTI-UNIT RENTALS (prerequisite refactor — Jac's design)

Jac, verbatim core: *"A Rental is an EVENT, nothing more."* Excavator + auger,
skid steer + trailer = ONE rental, several units.

- **What does NOT change** (Jac's own list): the Yard Journey and Inspection
  Status are hosted by the UNIT card — unchanged. Drivers still log captures
  **per unit**, despite one rental. Invoices keep line items with per-line
  transport.
- **Data**: `rental.unitIds[]` replaces `unitId` (runtime migration:
  `unitId → unitIds=[unitId]`; keep a `unitId` getter-style fallback where
  cheap; schema-less backend = no migration work server-side).
- **Captures/journeys re-key to rental+unit** (each unit owes its own
  start/end videos; the yard tool on each unit already scopes to that unit).
- **Invoice lines: one line per UNIT on the rental** (each with its own
  transport mini-journey + item balance). ⚠ THIS IS MY READING of "they still
  show up as line items with the ability to pick their transport" — CONFIRM
  WITH JAC before building.
- **Pricing**: rental price = Σ per-unit (category rate × window); each
  invoice line carries its unit's amount.
- **Status stays simple**: the EVENT is On Rent from the first +Start; the
  Complete Rental gate needs ALL units Returned. Partial return = **SPLIT**.
- **SPLIT (the new feature that makes this work)**: pull unit(s) out of a
  rental into a sibling rental (same customer/window/invoice link), moving
  their captures + invoice lines, logging both sides. Example: trailer comes
  back, skid steer stays out → split the trailer's rental, complete it, the
  skid steer's rental rolls on. UI placement TBD with Jac (likely on the
  rental's unit list / right-click).
- **Touch points** (refactor sweep): rentalsOverlappingUnit + availability
  (scan unitIds), unitRentalStatus derivation, IDX/searchBlob, transport map,
  yard tool rental lookup, calendar, KPI derivations, assignPick unit path,
  categoryId (derive per unit, drop the single field).

## 3 · Engine architecture (recon-settled — dragdrop-recon.json)

- **Custom pointer engine** (pointerdown/move/up + ghost clone +
  elementFromPoint hit-testing). Native HTML5 DnD REJECTED: the mid-drag
  customers↔invoices card swap re-renders the source node, which silently
  kills native drags in Chromium; draggable=true also breaks inline-edit
  text selection.
- **#drag-layer singleton on document.body** (outside #app) holds the ghost +
  pointer capture → render() during a drag is SAFE (the card swap IS a
  render). Same survives-render precedent as the hover preview/ctx menu.
- 6px movement threshold arms the drag (mouse); long-press arms it (touch);
  press-and-release without movement falls through to the existing click
  discriminator untouched. Once armed: clear pendingRowClick + swallow the
  trailing click capture-phase.
- **DROP_MATRIX** (declarative): payload type → acceptor entities +
  per-record validators; valid targets get a highlight class on dragstart
  (drop-glow aesthetic consistent with R0/R19), invalid fade. Auto-scroll
  card bodies near edges. Esc cancels.
- **Drops dispatch into EXISTING §16 mutations** — never reimplement gates:
  addRentalLineToInvoice / addWOToInvoice as-is; new thin wrappers
  linkUnitToRental / linkCustomerToRec extracted from assignPick's bodies
  (its gates: Sold/Inactive block, blacklist, category sync, logAction);
  invoice.customerId set guarded by paid>0 + locked checks.
- **Gaps to write** (recon): the two wrappers; the overlap gate + Overbooked
  flag in headFlagsHtml (rentals + units); the settings store + toggle; the
  paid/locked guard on customer-drop-to-invoice.

## 4 · After the engine

- Pick mode (beginPick/assignPick) retires from row-click linking — drag
  replaces it. Orange R5 pills become pure creates ("+New Customer") with
  QUICK ADD (First/Last/Phone only) per the 06-12 decision.
- Receipts/vendors stay popup-based (Jac: drag may not apply there).

## 5 · Post-review notes (Jac, 2026-06-12 evening)

- **Cancel arc height**: "a little too high imo. But let's try it anyway" —
  build it adjustable (a CSS var for the apex), start LOWER than the mockup
  (~20% of the rental card), tune live with Jac.
- **Rental item NAME (multi-unit world)**: `"<Rental Window>: Unit, Unit,
  Unit…"` — the window leads, then the unit list. **Customer rides as an R9
  title flag**, not in the name. Applies to list rows, tabs, and the card
  title. (Part of the multi-unit refactor.)

## 6 · WAVE 2 — THE MODES DIE (Jac, 2026-06-12: "This should obsolete the
Modes we had that ran Rental, Work Order, Invoice, etc.")

Immediately after the engine verifies, retire the guided mode machinery:
- **+Rental**: creates the draft + anchors it. NO pick mode — the side cards
  stay live; you DRAG a unit and a customer onto the draft (or quick-add the
  customer). The "Select rental window" trigger stays on the draft card.
- **+Invoice**: creates + anchors; drag the customer + rentals on.
- **+Work Order**: already mode-free (born on the Unit card, prefilled).
- **Inspections**: already inline (condition segs); Wash mode already deleted.
- **DELETE the machinery**: beginPick/assignPick/PICK_SRC/cancelPick, the
  pick bar + guide popup, revealPickList, the rental-mode card BLANKING
  (blankColEl/rentalDraft gating), pick-target row tinting/scoping. The
  drop-dispatch wrappers (linkUnitToRental/linkCustomerToRental/
  addRentalLineToInvoice) are the surviving link paths.
- Drafts stop being swept on mode-exit (no mode to exit) — a draft lives
  until completed or explicitly discarded (visible, resumable).
- THEN the R5 relabel: orange pills read "+New Customer" etc. (pure creates),
  per the standing decision.
