# JacRentals — Build List (phased) — live tracker

Master queue. Status flags: 🆕 new · 🔧 partial/refine (some shipped) ·
✅ shipped last session (verify, don't rebuild) · ❓ decision/define needed.
We walk this **task by task via poll**; decisions get recorded inline.

## Phase 0 — Carry-over ("cute items")
- 🆕 **Ask Mr. Wrangler** — Claude-API proxy so the app can call Claude (e.g. auto-suggest WO parts; the "Mr. Wrangler will add the parts for you" hook is already wired in copy).
- 🔧 **#9/#10 drag bugs** — awaiting Jac's repro (what was grabbed, where dropped, what happened). Overlaps Phase 3.

## Phase 1 — Navigation & Tabs
- 🆕 **Back buttons** — a way to retreat through navigation.
- 🔧 **Right-click → list view when anchored** — return cascaded cards to list view on right-click, even in anchored-cascade mode.
- 🆕 **Anchoring creates a new item tab** — only the tab's "X" overrides/clears it; no click/selection/nav silently replaces or closes it. (Following new tabs keeps the cards' searches.)
- 🆕 **Global Search + select opens a new tab.**
- 🆕 **Overtaking an open card → new tab** — clicking an element whose standard view is already open freezes that session and opens a new item tab duplicating the session with the new card in standard view. Includes +Rental (new). (Same principle as anchoring.)

## Phase 2 — Rental Window & picker
- 🔧✅ **Click-away should not force Save** — shipped `rentalFragile` (force-save only when billed/On Rent/End/Off/Returned). VERIFY it matches "remove forced save except fragile," make fragile feel deliberate.
- 🆕 **Clear vs Save buttons** — show "Clear" (R17) until something changes; once changed, show "Save" just left of "Clear."
- 🔧 **"Available" entry behavior** — make "available" a REAL availability entry (through the Rental Window's lens), not plain text. [Open Q: does the picker still need to stay open given the search-bar "available" entry + drag engine? Does click-away-close break Rental Mode?]
- 🆕 **Center the picker pill** — "Select a rental window" pill is left-aligned; center it.
- 🆕 **Can't drag while the Rental Picker is open** — should be able to.

## Phase 3 — Drag-to-link engine
- 🔧 **Dragging Customers/Rentals resets/closes the source card** — it shouldn't. (Units→buildable-rentals already fixed; this is the customers/rentals case = #9/#10.)
- 🆕 **Link by dragging empty space on a Standard View.**
- 🆕 **Drag the WO section onto an Invoice** (to link).

## Phase 4 — Invoices & Work Orders
- ✅ **+Invoice/+Transport opens the new invoice on the Invoice card** — shipped (`createInvoiceForRental`). VERIFY.
- ✅ **Delete empty records on click-away** — shipped (`sweepEmptyDrafts`, invoices + rentals). VERIFY.
- ✅ **(PAY) bottom-right of the Invoice section** — shipped. VERIFY.
- 🆕 **+WO from an Invoice opens the linked unit** — opens that invoice's currently-linked unit in standard view.

## Phase 5 — Search & filters
- ✅ **Replace persisting footer filters with search entries** — shipped ("dropped the modes"). VERIFY.
- 🆕 **Persist the orange glow behind Search while it's in use.**

## Phase 6 — Indicators (flags, flashes, comments, status)
- ✅ **Rulebook R4b + R9b** (which elements flash) — shipped. VERIFY.
- ✅ **Two flashes on linking** (was 3 → 2) — shipped. VERIFY.
- 🆕 **Comment feature: flash until toggled.**
- 🆕 **Active bar = tiered messages** — change the text per activity-% tier, not just "Active 92%."
- ✅ **Team KPI → one "Sulphur Team" row + ring layout matches role count** — shipped (Team KPI redesign + N-ring). VERIFY.

## Phase 7 — Layout, entry & open decisions
- 🆕 **Move Notes above the Funnel sections** (currently above account).
- ✅ **Equal-width +X buttons** — shipped (#12). VERIFY.
- 🆕 **Tabbed message convos, bottom-right.**
- 🔧 **History / logging audit** — Clear Unit + draft date now logged; review EVERY action type that should log and add what's missing.
- 🔧 **+Customer = Quick Add** — shipped (name + phone). Confirm it matches the "speed up logging a new rental" intent.
- 🆕 **Logins** — passwords managed in Settings (today: single shared password + admin gate).
- ❓ **DECISION:** Membership billing — monthly vs yearly.
- ❓ **DEFINE:** "Schedule Actions → Schedule?" — needs a spec.
