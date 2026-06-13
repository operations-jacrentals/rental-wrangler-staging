# JacTec / Rental Wrangler — SPEC v8
**v8 — reconciled to code 2026-06-13 after the remote session · supersedes v7
(frozen 2026-06-12 morning) · lives in `JacTec-handoff/` (gitignored — repo is public)**

> ⚠ **Why v8 exists:** a remote session (phone/other desktop) shipped ~38 commits
> WITHOUT this gitignored doc, so v7 went stale and started CONTRADICTING the code.
> v8 is reconciled cell-by-cell against the live source. Where v7 and the code
> disagreed, **the code won** and v8 now says what the code says.

### How this stays true
**The CODE is the source of truth. This document is its committed mirror.** Every
rule here was read out of `const RULE_META` (app.js:1344), `const CLASS_RULE`
(app.js:1373), the R0 lint CSS (style.css:985), and the live `data-r` stamps —
not from memory. Drift is guarded mechanically: `ci/gen-rule-usage.mjs --check`
fails CI if a builder's call sites change but `rule-usage.js` (the per-rule field
catalog) wasn't regenerated, and `ci/logic-test.mjs` (22 `ok()` checks via the
`#local`-only `window.__rw` seam) locks the money + multi-unit invariants as
executable tests. **Commit this doc** so it travels with the repo — the whole
reason v7 went stale is that it didn't. When the code changes a rule, change this
file in the SAME commit.

---

## 0 · How to debug with this spec

1. **The flash-lint (R0)** is the alarm. Toggle = the eye icon in the bottom bar
   (admin-gated now — see Admin Gate), per-device via `localStorage jactec.lint`.
   Anything that pulses red bypassed the UI builders. A finished app shows ZERO
   flashing. The lint family is the CSS selector list at style.css:988-997.
2. **Name the rule, not the pixel.** Every builder stamps `data-r="Rn"`. Inspect
   any element (Design Inspector, admin-gated) and read which rule built it.
3. **One fix per rule.** All builders live in app.js **§5 UI BUILDERS**
   (app.js:1099-1340). Styling lives in style.css with each block's R-number.

---

## 1 · THE RULEBOOK (R0–R24)

This is the FULL current table, **exactly as `RULE_META` defines it** (app.js:1344),
with the **R22 collision resolved**: R22 = Date picker (it shipped wired into
`CLASS_RULE .datefield` + the lint selector), and **closeX is renumbered to R24**
(a code fix to apply — patch returned separately). The collision is in TWO places,
not one: (a) `RULE_META` literally double-defines the `R22:` key (app.js:1368-1369)
so the closeX row is silently shadowed by dateField, AND (b) the **builders
themselves both stamp `data-r="R22"`** — `closeX` at app.js:1214 and `dateField` at
app.js:1245 — so the fix must retarget closeX's STAMP too, not just the metadata
key. R19/R20 exist as builders/behaviors but were never in `RULE_META` and carry no
`data-r` stamp; v8 documents them as real rules.

| R | Name | Builder (app.js §5) | What it is (one line, as in code) |
|---|------|--------------------|-----------------------------------|
| **R0** | Flash-lint | `body.rw-lint` CSS (style.css:988) | Un-stamped pill/add/flag/link/req/seg/file-drop/datefield pulses red — it bypassed the builders. Also flags any native `title` attr (R23 violation). |
| **R1** | Gate pill | `gatePill` / `gatePillRaw` / `funnelPill` (+`masterGate` / `unitStatusGate`) | A status **DROPDOWN** that moves the record forward — big shape + chevron. |
| **R2** | Linked pill | `refPill` / `unitPill` | Orange outline + DESTINATION-card icon — opens a record; optional ✕. |
| **R3** | Status badge | `statusPill` | Informational STATUS: registry color, parent-card icon, hover underline — never an action. |
| **R3b** | Data chip | `badge` | A plain FACT (480 HRS, No GPS): gray, no icon, no hover — independent of R3. |
| **R4** | Derived pill | `dPill` | Rides another pill: no bg/border, ink+icon only — sits RIGHT of its parent (LEFT when the parent is right-aligned). |
| **R5** | _(retired → R5b)_ | `addBtn({link})` | **RETIRED (Jac 2026-06-13)** — record-linking adds now wear R5b. Tombstone row only; NOTHING stamps `data-r="R5"`. |
| **R5b** | Blue add | `addBtn({link\|line\|anchor})` | BLUE dashed “+Thing” — links/creates a record (Customer/Invoice/Unit/WO/Card/Col) **OR** adds a line item (+Part/Task). One blue add language. |
| **R5c** | Empty field | `addBtn()` / efld empty state | GRAY dashed “+Thing” — a normal empty field (+Serial, +Email, +PO). |
| **R6** | Required | `reqBtn` / `.req` | White + dark ink until entered/captured — stays loud. |
| **R7** | Hyperlink | `linkName` / `.inv-line-link` | Blue · italic · NOT bold · permanent underline. |
| **R8** | Derived value | `kv({derived})` / `.derived` | Italic = the app computed it; you don’t type it. (No builder fn — `.derived` CLASS_RULE fallback.) |
| **R9** | Title flags | `flagEl` / `flagsStack` | ≤2 stacked 14px mini-flags beside a title — no backgrounds. `alert` pulses; `sect` scrolls to a section. |
| **R10** | S1 title chip | `.c-titlecard` (`cardEl`) | Dark chip · white bold label · plain orange icon · permanent orange border. |
| **R11** | Section | `.section` + `sec-green/yellow/red` | Centered header; header+border follow the LIVE status. |
| **R12** | Notes line | `notesSection` (app.js:1976) | Boxless, label-less; filled→top of the card, empty→bottom above history. |
| **R13** | History | `historySection` (app.js:2886) | Count chips above the search bar filter inline; record-backed links only. |
| **R14** | Seg toggle | `segCtl` | 3-state segmented control (condition · wash). |
| **R15** | Journey | `yardToolHtml` (2023) / `miniJourneyHtml` (2129) | Yard +Start/+FC/+End + Jac─Site─Jac transport; white = video owed. **Per-unit** now (reads/writes THIS unit's captures). |
| **R16** | Day timeline | the rentals `timeline` in DETAIL.rentals (app.js:2212) | The rental window in day cells; centered gate + naked price·rate. Cells tint by status via `--tint`. |
| **R17** | Action pill | `actionPill` | commit = blue · money = green · danger = solid red; `.locked` = gated. |
| **R18** | Ghost | `ghostPill` | The ONE quiet action — Cancel / Close / Exit / Clear. |
| **R19** | Attention flash | `attnFlash(sel)` / `flashOr(sel,msg)` (app.js:1254) | A glow that points AT the fix instead of an error message. **Flash is 2×** now (was 3×). |
| **R20** | Wrangler menu | `openCtxMenu` / `runCtxAction` (app.js:1268) | Right-click any **real control** → Cut/Copy/Paste/Clear/Search/Replace/Add Comment/Ask Mr. Wrangler. NEVER fires on bare `.row`/dead space. |
| **R21** | File drop | `fileDrop` (app.js:1235) | The MASSIVE popup add-file zone — R5b blue dashed at full size. |
| **R22** | Date picker | `dateField` (app.js:1242) | The ONE app-styled calendar for a single date/time (NOT the rental-window timeline). Class `.datefield`; toggles `datePickerInline()`. |
| **R23** | Tooltip | `data-tip` → the one styled tip | Every hover hint goes through `data-tip` — a native `title` attribute is a violation (caught by `body.rw-lint [title]` at style.css:996). |
| **R24** | Close ✕ | `closeX` (app.js:1213) | Red circle · white ✕ — the deliberate close/remove; hover-reveal variant on tabs. **Renumbered from R22** (collision fix — patch separate). |

**Placement laws:** derived pills sit right of their parent (R4, left when the
parent is right-aligned) · left side of a section = actions, right side = derived ·
Section 0 = Notes · Section 1(–2) = high-action zone · then Details, then Data ·
STACK LAW: line-row pills share min-width 88px + centered label so the column edge
aligns down a stack; everything else keeps intrinsic width (only height/font/
padding/radius are uniform) · body-wide `tabular-nums`.

> **Structural-only rules** (no `data-r` stamp; resolved by `CLASS_RULE` at
> app.js:1373): R5 (retired), R8, R10, R11, R16, R23. All others carry a live stamp.

---

## 2 · Color = meaning (one orange, one meaning)

- **Solid orange + dark ink** — the ONE selected thing (active tab). Never else.
- **Orange outline + orange ink** — a linked record (R2). **Orange add is GONE**
  except ONE survivor: **“Select rental window”** stays orange because orange now
  means a **REQUIRED GATE**, not an optional add (ce0c2e4). Every other +X is blue.
- **Blue** — commit (R17), hyperlinks (R7), blue statuses. **Neon blue #18b6ff** —
  the single blue **add** language (R5b: record-linking AND line-items) + anchor ring.
- **Green** — money actions, good/ready/complete.
- **Yellow** — waiting/caution (ETA, End Rent, Not Ready, Returned node).
- **Red** — alert/needed; solid red = destructive confirm (R17 danger); +FC node;
  the close/remove ✕ (R24).
- **Purple** — scheduled/member (Reserved).
- **White + dark ink** — required-until-entered (R6).
- **Italic** — derived/computed (R8).

**Toasts** are now CENTER-screen, **solid orange, near-black ink** (was a small
bottom pill). **Titles are READ-ONLY** across Rentals + Units + Invoices +
Categories — no inline title edit anywhere.

---

## 3 · Boards (standard views) — refreshed to code

### Units card (the mechanic's home — unit QR codes land here)
1. **Yard journey tool** (R15, boxless, top) — now reads/writes the unit's OWN
   start/end/FC captures; a unit shows its OWN status (`unitStatus`), not the
   rental's roll-up.
2. **Inspection** (R11 colored by condition; R14 segs; condition LIVE but locked
   while an open WO needs it).
3. **Open WO sections** (R11 bottleneck-colored; "WO: name" + R9 type/date flags;
   +Part/Task = R5b blue; R1 line gates with ETA-as-status; wofoot R8 totals →
   +Invoice (R5b) → **Complete WO**). **A WO line going Complete NO LONGER
   completes the WO** — lines only drive the displayed bottleneck; when all lines
   are done the WO reads **“Ready to complete”** (green) but STAYS OPEN. The blue
   **Complete WO** button (`completeWOAttempt`→`setWoPhase`) is the ONLY completer.
4. **Specs | GPS · Investment** (left entry / right derived; ROI%).
5. **Notes** (R12) · **History** (R13).
- Footer chips follow R4 (ink only, no bg/border/icon).

### Rentals card — now a MULTI-UNIT EVENT (see §New Systems)
1. **Notes** line (R12, above the timeline when filled).
2. **Headerless RENTAL section** (R11, colored by `rentalStatusDisplay`):
   - Name is **DERIVED** — `rentalDisplayName` → “Window: Unit, Unit” (else units-
     only / window-only / **“Quote”** — NOT “draft”). Customer rides as a header
     **FLAG**, never in the name. Title is read-only.
   - **Timeline** (R16) → the **master gate** (`masterGate`, R1) bulk-sets all
     units while uniform; the moment statuses diverge it LOCKS to a read-only,
     lifecycle-ordered **MIX** label (e.g. “Today/On Rent”, neutral color) and
     unlocks when they re-converge. Each unit chip gets its OWN gate
     (`unitStatusGate`, R1) when the rental holds >1 unit.
   - **Invoice rentals · transport**: each unit bills its OWN rental line
     (`rentalLineItems`, priced by its own category) AND its OWN transport line
     (`transportLineItems`), all sharing `ref=rentalId` but identified by
     `li.unitId`. Each line = R7 link + **ITEM BALANCE** + its mini journey (R15).
   - **Complete Rental** gate (R17) is locked until `allUnitsTerminal` (every unit
     Returned/Cancelled/No Show); a unit-less rental says **“drag a unit / cancel.”**
3. **History** (R13).
- No invoice → the combined **+Invoice/+Transport** add (R5b blue now).

### Customers / Categories / Invoices / Shop / Vendors / Expenses
Conform to the same rules. **Invoices = one merged ledger** (line-kind badges R3,
per-unit rental+transport lines, +adds R5b). **Shop** = merged Work Orders +
Service Orders + Inspections (app.js:3254). Customers head: account type + pay
status = R9 flags, account gate = R1 `gatePillRaw` noChev in the title row.
**Vendors** + **Expenses** cards are full v2 detail-in-board-popup renderers (the
receipt popup reconciles an expense against parts + links a vendor).

---

## NEW SYSTEMS (added by the remote session — what + where it lives)

### A · Drag & Drop link engine (§15c, app.js:4750→)
Custom **pointer** engine (native HTML5 DnD rejected — a mid-drag column swap
re-renders the source row). `const DRAG` state (4760); `DRAG_SOURCES =
{units,rentals,customers,invoices}` (4761; shop/categories are NOT sources).
`DROP_MATRIX` (4767) is a cheap VISUAL gate (glows `.drop-ok`); the HARD
money/safety gates re-fire in §16 mutations. `initDrag()` (4790) builds a
singleton `#drag-layer` on `document.body` OUTSIDE `#app` so `render()` mid-drag
is safe; wires document-level pointer events + Esc + blur and swallows one click on
release. Drops dispatch into the **DROP-CALLABLE LINK WRAPPERS** (app.js:6941),
e.g. `linkUnitToRental` (7003). **Drag IS the link path** — pick mode is dead.
Full contract: `JacTec-handoff/DRAGDROP-DESIGN.md`.

### B · Multi-unit rentals — the EVENT model (§20, threaded through §3/§16)
**A rental is an EVENT, not a single machine.** It holds `r.units[]` (canonical);
`r.unitId`/`r.status` are MIRRORS of the PRIMARY unit (`units[0]`) kept synced by
`syncRentalPrimary` for backward compat. `migrateRentals()`/`reconcile` (96-104)
folds legacy single-unit fields into `units[0]`.
- **Accessors:** `rentalUnits` (108), `rentalUnitIds` (112), `primaryUnit` (113),
  `unitEntry(r,unitId)` (117, replaced ~9 inline finds), `isPrimaryUnit` (120).
- **Names:** `rentalUnitsLabel` (123), `rentalDisplayName` (127).
- **Per-unit status:** `unitStatus(r,eu)` (138; derives No-Show/Today/Tomorrow off
  the shared window), `rentalUnitStatuses` (144), `unitsUniform` (147),
  `rentalStatusDisplay` (150; single status when uniform else gray “X/Y” mix),
  `allUnitsTerminal`. Gates: `masterGate` (1158) / `unitStatusGate` (1167);
  `setUnitStatus` (~5619), `setRentalStatus` (bulk).
- **“SPLIT”** — there is **NO split-to-own-rental mutation**. The model GROWS/
  SHRINKS: `addUnitToRental` (6975, a unit-drop ADDS, never swaps), 
  `removeUnitFromRental` (6997), `linkUnitToRental` (7003, fires §9 fleet +
  already-on + §10 overbooking gates per unit), per-unit remove handler
  `kind==='unit-remove'` (5443, blocks pulling an On-Rent unit with a logged
  capture). “Split” in the brief = (a) per-unit BILLING split and (b) the
  partial-payment allocation split — both below.
- **Per-unit billing:** `rentalLineItems` (407) + `transportLineItems` (428),
  one line per unit, pushed in `createInvoiceForRental` (~6626) and on link (451);
  per-unit removal `removeUnitInvoiceLine` (5648, stable-lid keyed).
- **Per-unit captures/transport:** `addUnitToRental` seeds start/end/fc captures +
  transportType/delivery/recovery/sitePin per unit (~6986); per-unit transport
  write (5783); dispatch board iterates units (3681).
- **Voided units** (No-Show/Cancelled only) STAY on the record (sales signal) but
  render struck-through (`.unitchip.voided`) and are SKIPPED by
  `rentalLineItems`/`transportLineItems` so they never re-bill. Returned units are
  terminal-but-billed (NOT struck). **“No Show” is DERIVED** for any Reserved
  rental whose start date has passed (stored status stays Reserved).
- **Demo:** `R-MU` (data.js:117) — 2 excavators (Moto Moto On-Rent+capture, Eileen
  Reserved/Today), derived name, locked mix gate, invoice `04i13Ju26` billed per
  unit (Moto paid, Eileen due).

### C · Partial-payment allocation popup (§19, inside §17, app.js:6334-6383)
`allocSectionHtml(lines,o)` (6338) renders one pre-tax $-input per balance-carrying
line; **“Pay in full”** auto-fill is an R5b add (6346). `setupPayAlloc()` (6354)
recomputes live in the DOM (no re-render, keeps focus): clamps each input to its
line remaining, sums taxable vs plain, adds tax on taxable lines, shows
pre-tax+tax=gross + “Balance after”, builds the charge total FROM the inputs so no
dollar is unassigned. **CRITICAL invariant:** allocations are keyed by a STABLE
per-line `li.lid` — NEVER array index (index keys orphaned payments and broke the
§7.4 refund-before-unlink lock when splice/No-Show/transport re-push shifted
indices). `lineKey(li)` (2098) assigns lazily; `migrateInvoiceLines` remaps legacy
`"idx:kind:ref"` keys at load (data.js:220-232). `itemPaid(inv,li)`/`allocLines`
read by lid. A full refund releases all line assignments. **PAY lives BOTTOM-RIGHT**
of the Invoice section, under Due (71a1f63) — not the left actions column.

### D · Views — company-wide saved searches (§5.5, app.js:4586-4660)
A View just drops a saved `search` + pinned `filterTerms` chips into the card's
**visible, clearable** search bar — there are **NO hidden filter modes**. ONE
shared set `VIEWS_LS_ALL='jactec.views.all'` (4594), backend-synced
(`loadGlobalViews` 4613 / `pushViewsToBackend` 4617) with a localStorage mirror +
one-time per-card-key migration. `VIEW_CARDS` = units/categories/rentals/customers/
invoices/shop/expenses. `openViewMenu` (4644) = +Add-view (admin, only when the
current filter isn't already a view) + Views list (delete ✕ admin-only) + Sort.
**Anyone can apply; create/delete is ADMIN.** (Backend Apps Script `getViews`/
`setViews` handlers are still TODO — falls back to per-device until then.)

### E · Admin gate (app.js:5554-5581)
Client-side **obfuscated-hash** gate for DEV/DESIGN tools ONLY (Rulebook, Inspector,
Lint) — **explicitly NOT crypto, NOT for securing secrets**. `ADMIN_HASH=
'xy16gqtfz0'` + `_cyrb53`; `adminUnlocked()` = local unlock OR Admin/Owner role;
`toggleAdminLock()` prompts + hashes, persists in `localStorage 'jactec.admin'`.
Header `js-adminlock` gates `js-lint`/`js-inspect`/`js-rulebook` (5136).
**Settings is intentionally NOT gated.** A separate `requireAdmin(reason,onOk)`
(5574) verifies a REAL Admin password against the backend for money/safety
overrides (e.g. no-card booking, 5582).

### F · Preview-eye / Inspector + Rulebook system
The **R0 lint eye** (bottom bar, admin-gated) pulses un-stamped UI. The **Design
Inspector** (`onInspectMove` 1394, `ruleOf` 1378, `refPath` 1388) shows the rule
behind any element on hover + the `CARD › SECTION › "text"` path Jac pastes to
debug. The **Rulebook overlay** lists every rule with its app-wide field catalog
from `rule-usage.js`, a collapsible live “N on screen” index, and an
**orphan/un-ruled** list (`unruledElements` 1199 — a live DOM scan).

### G · Availability calendar (two pieces)
(a) The Office **Dispatch Time Grid** / “Calendar” column-member card —
`calendarCardEl` (3125) → `dispatchGridBody`, member id `'calendar'`.
(b) The rental-**WINDOW** range picker (winpicker): a 2-click start→end calendar
(`state.winpicker`/`availWin` 517), opened from the timeline bar (5325), drives §10
availability tinting. `'available'`/`'unavailable'` are LIVE search TOKENS scoped to
`state.availWin` (not a bespoke mode); entering a window auto-fills `'available'`
per card. The picker greys/strikes unavailable days for an anchored subject and
honors the overbooking flag (off = hard-block; on = struck-but-pickable warning).
The inline `datePickerInline()` single-date calendar (6759-6804) is the R22
`dateField` popup and is explicitly NOT the window timeline.

### H · Gamification KPI score pops (§11, app.js:3561-3598)
When an action raises a ring's metric, pop the raw delta over that ring + flash it
green ×3. `kpiRaw(roleId)` (3566) mirrors `kpiFor` numerators; `scoreTick()` (3583)
diffs each render (covers every action, no per-action hooks); `scorePop` (3590)
floats a `.score-pop` (“+$X” money / “+N” counts), removed after 760ms. Team KPI =
one ring per ROLE + a single “Sulphur Team” combined-score row.

---

## 4 · Money & data invariants (unchanged truths + the new ones)

- **STABLE-LID allocation** (invariant #13): allocations key on `li.lid`, never
  index. `itemPaid(inv, li)`, pre-tax, charge total built from inputs, full refund
  releases all. Locked by `ci/logic-test.mjs` checks 1-2, 9.
- **Invoice unlink lock (§7.4):** the rental's invoice ✕ exists only while nothing
  is paid against it (`rentalAllocated`); now multi-unit aware.
- **§9 gates rule everything**, PER UNIT now: On Rent requires an invoice; bookings
  require a valid card (Admin override); blacklist blocks; §10 overbooking checks
  every unit (`rentalOverbooked`).
- **Capture media NEVER rides a record** (Sheets cell caps ~50k chars): stamp
  `{date,clock,video:url}` persists; the file uploads via backend `uploadCapture`
  → Drive → only the URL lands on the stamp. Demo mode skips storage.
- Schema-less persisted fields stay schema-less (no Code.gs change for allocations,
  units[], lids, transport — all JSON-in-a-cell).

---

## 5 · Backend (Code.gs)
Storage SCHEMA-LESS (one tab/entity, row `[id, json]`). Actions: `auth · load ·
seed · sync · uploadCapture · feedback · getConfig/setConfig · stripe*`.
**`backend/` is now .gitignored** (f3215a9 — Apps Script worked locally, was never
published by Pages). **TODO:** `getViews`/`setViews` handlers for true cross-device
Views are NOT yet implemented.

---

## 6 · Code map (current §banners in app.js)

§1 Utilities (27) · §2 Indexes/search (40) · §3 Derivations (359; §20 accessors +
OVERBOOKED 529 + ROI 678) · §4 State/sessions (695) · §5a Icons (1040) ·
**§5 UI BUILDERS — the rulebook (1099; RULE_META 1344, CLASS_RULE 1373)** ·
§6 List rows (1410) · §6b Per-card rows (1458) · §7 Column registry + footer
totals (1670) · §8 DETAIL renderers (1942) · §9 Cards & grid (2932) · §10 Shop
card — WO+SO+Inspections merged (3254) · §11 Header/KPI/bottom bar (3442;
GAMIFICATION 3561; Dispatch Time Grid 3673) · §12 Overlays & boards (3737) ·
§13 Dropdowns (4498) · §14 Render pipeline + toast (4671) · §15 Event handlers
(4747; ⚠ §16 interleaves from 4748) · **§5.5 Views (4586) · §15c DRAG ENGINE
(4751)** · §16 Actions/mutations (5684; DROP-CALLABLE LINK WRAPPERS 6941) ·
§17 Stripe/payments (6271; §19 ALLOCATION POPUP 6334) · §18 Persistence & boot
(7121) · §18b Backend sync (7124).

> Numbering is non-contiguous: §19 (allocation) lives under §17; §20 (multi-unit)
> is threaded through §3/§16 via inline `// §20` comments (no own banner); §5.5 and
> §5a are lettered sub-banners. `exposeTestApi` (7407, offlineBoot-only) is the
> `window.__rw` CI test seam.

---

## 7 · TODO

**DONE since v7:**
- ✅ **#19 Partial-payment allocation** — built (014a29c), hardened to per-line
  lid keys (793c1c1, 4180c7a), demo seeded (1d4d7d2), CI-locked.
- ✅ **#20 Multi-unit rentals** — DONE end-to-end (Phases 1-3, 4a, slices 1-5) +
  9-bug audit + lid fix + helper consolidation + demo R-MU. (Was the drag&drop
  prereq — now unblocked, and drag IS shipped.)

**Carry forward (real remaining work):**
1. **APPLY the R22→R24 collision fix** — `closeX` must get its own number (patch
   returned separately). The only known live bug. It has TWO sites: the duplicate
   `R22:` key in `RULE_META` (app.js:1368-1369) AND the `data-r="R22"` stamp inside
   the `closeX` builder itself (app.js:1214). The patch retargets both to R24 and
   adds the R24 row to `RULE_META`; `dateField` (app.js:1245) keeps R22.
2. **Backend `getViews`/`setViews`** Apps Script handlers — Views are per-device
   until these land (true cross-device sync pending).
3. **Real Google Maps embed** in the site popup (placeholder grid now).
4. **“Ask Mr. Wrangler” = Claude inside Rental Wrangler** — the context-menu entry
   + Part/Task AI-fill + photo review are its first surfaces; needs a backend
   endpoint to the Claude API (key in Script Properties), an `aiPending` queue, and
   a chat/ask surface. Scope with Jac first.
5. **Shop-trio detail renderers** — standalone Inspections/WO renderers behind
   hidden tabs are retirement candidates as deep links re-route to the Unit card.
6. **Tomorrow-3 “update the other cards”** — advanced (per-unit Units displays, KPI
   rework, PAY relocation) but still open.

---

## 8 · Changelog v7 → v8 (38 commits, 575e237..HEAD, 2026-06-12→13)

**Rules:** R5 RETIRED → one blue add (R5b) for BOTH record-links and line-items
(f73e12d); orange survives ONLY as “Select rental window” = a required gate
(ce0c2e4); `.bigbtn` restyled to transparent/dashed/blue (31c9de5). NEW closeX
(6274ede) — ⚠ collided on R22 with dateField (resolve = closeX→R24). Toasts
center-screen solid-orange (ce0c2e4); flash 3×→2× (57cc5dd); R20 dropped bare
`.row` targets (b4ce7d8). Titles read-only across Rentals+Units.

**Multi-unit (#20, the big arc):** rental = EVENT with `r.units[]` (11ef9d5);
unit-drop ADDS not swaps (e0244b6); name DERIVED, customer = flag (4f7dabc);
per-unit invoice lines (45573fb); per-unit status engine (f379455); master + per-
unit gates (a3a821d); per-unit displays/lookups (ca8c8bb); per-unit captures +
terminal gating (6b33037); per-unit transport (121b0d5); voided units stay struck
(42770ec); `unitEntry`/`isPrimaryUnit` consolidation (046e69c); No-Show derived +
day-timeline status tint (10fdc6f); demo R-MU (f738105).

**Money (#19):** allocation popup (014a29c); per-line keys (793c1c1); STABLE-LID
audit fix (4180c7a); 9-bug audit (ecf5a17); deferred follow-ups (d7e0a79); PAY
moved bottom-right (71a1f63).

**Work orders:** WO-line Complete no longer completes the WO; “Ready to complete”
green; blue Complete-WO is the only completer (cb951a3).

**Views:** Sort→View menu (8b6dc74); pinned chips captured (566e901); company-wide
global views (3142398).

**Admin/availability:** admin-gated Rulebook/Inspector/Lint (04e1b98);
`available`/`unavailable` live tokens (e7f1f0b); window picker blocks unavailable
days + honors overbooking (bffde57, 54c9849).

**KPI:** +X score pops (4d1ea19); Team KPI one-ring-per-role + Sulphur Team row
(57cc5dd).

**CI:** `ci/logic-test.mjs` (c62ff16, now 22 `ok()` checks); `ci/gen-rule-usage.mjs` +
`rule-usage.js` drift guard (fbb3ee7); boot smoke hardened (a5999da); `backend/`
gitignored (f3215a9).

---

## 9 · HOW WE STAY IN SYNC (the anti-drift process)

1. **Code is truth. This SPEC is its committed mirror.** v7 went stale precisely
   because it was gitignored and didn't travel with the 38 remote commits. When you
   change a rule in the code, change §1 of this file in the SAME commit, and
   **commit this doc** (do not leave it only in `JacTec-handoff/` on one machine).
2. **`rule-usage.js --check`** (`ci/gen-rule-usage.mjs`) fails CI if a builder's
   call sites changed but the per-rule field catalog wasn't regenerated — it is the
   mechanical drift alarm for the rulebook's CONTENTS.
3. **`ci/logic-test.mjs`** (22 `ok()` checks via the `#local`-only `window.__rw` seam) is
   the executable spec for the money + multi-unit invariants (#13-#15 above).
   Treat those assertions as canonical behavior.
4. **NEW recommended guard — DUPLICATE rule-number check.** The current CI does NOT
   catch the R22 double-key (it only checks usage-catalog drift, not metadata
   uniqueness), which is exactly why the collision passed CI silently. Add a tiny
   check that parses `RULE_META`'s keys from app.js source and fails on ANY repeat
   (see the patch payload for the exact guard). This makes “two rules, one number”
   impossible to ship again.
