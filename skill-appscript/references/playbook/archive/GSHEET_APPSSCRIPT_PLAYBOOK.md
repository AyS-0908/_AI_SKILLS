# GSheet_AppsScript — Google Sheets-Led AI Tools: DO / DO NOT Playbook

> **ARCHIVED SOURCE — do not load as standing guidance.** It preserves project evidence, including over-broad reuse claims and an unfinished workflow-engine specification. Use `../CORE.md` and its topic references for the audited candidate. This archive is not externally validated and must not be edited into a second active playbook.

> **Skill reference.** Concrete, grounded practices for building **Google Sheets + Apps Script + external-API** tools for a **non-technical founder**. Every rule is mined from real code / real workbooks, not generic advice. Assembled from three reference implementations at three maturity rungs:
> - **GoViral** — shipped **v1** coded single-tool (code writes every cell, one frozen `SCHEMA`, strict tenancy, one provider in code).
> - **AIssistant** — **v2** generic data-driven AI **workflow builder/runner** engine (`Config-workflow` sheet + `utility.gs`/builder/processor).
> - **aiStrategy** — **v0** formula-driven WIP prototype (new sheet patterns + live anti-pattern evidence).
> 
> **Part I** = the GoViral shipped-tool baseline. **Part II** = the workflow engine, multi-provider registry, maturity ladder, and cross-project decision rules.

---

# Part I — GoViral shipped-tool baseline

A drop-in rules file for a NEW **Google Sheets + Apps Script + external-API** project built by an **AI coder for a non-technical founder**. Every row is a hard rule mined from a shipped project (GoViral). One rule per row, one mechanism per rule.

`Reuse` legend: **[LIFT]** copy the file ~80% as-is · **[PATTERN]** copy the technique · **[SKIP]** project-specific, ignore unless it maps.

> **[LIFT]/[PATTERN] rows can still carry [SKIP] *specifics*** — GoViral-only details that will NOT transfer verbatim; copy the technique, not the specifics: TikTok privacy/legal flags, GBP-routed-through-Zernio, SerpApi review import, the Meta/Instagram direct-media host denylist. Ticket codes were stripped from this file; provenance lives in the source repo.

---

## 0. Reusable assets — what transfers to a new project

| Asset (file / tab) | What it gives you | Reuse |
|---|---|---|
| `00_Constants.gs` — one `SCHEMA` object + derivation loop | SSOT for tabs/fields/lists/status/UI; deep-frozen | **[LIFT]** rewrite only the `SCHEMA` contents |
| `SheetIO.gs` — header-name I/O, ID mint, tenant filter | Sheets-as-DB layer (read/write/append/update by key) | **[LIFT]** near-verbatim |
| `Bootstrap.gs` — idempotent per-tab build pipeline | ensureSheet→headers→formats→dropdowns→notes→protect→seed | **[LIFT]** manifest changes, engine stays |
| `Config.gs` — `setup_app` (EAV) + `setup_business` (wide) accessors | global settings + per-tenant config, secret-by-name | **[LIFT]** |
| `Log.gs` — retained audit writer + fixed row schema | one ring-buffered `logs` row per state-change/external-call; source for counters, reconcile, debugging; secret-redaction net | **[LIFT]** |
| `ux_form.html` + `Ui.formSpec` switch | ONE HTML dialog rendering server-supplied field specs | **[LIFT]** HTML; add server cases |
| `ux_style.html` | design-token CSS partial for all dialogs | **[LIFT]** |
| `ux_confirm.html` | confirm-before-send modal for irreversible actions | **[LIFT]** |
| `tools/gas_mock_run.js` | offline Node harness that runs REAL `.gs` in a vm sandbox | **[LIFT]** edit the fakes |
| `Entitlements.gs` | pure `check()→{allowed,reason}` predicate + tier catalog | **[PATTERN]** |
| Adapter template (`AI.gs`/`Zernio.gs`/`ReviewSource.gs`) | one `var X={}` namespace per external boundary | **[PATTERN]** |
| Tabs: `setup_app`, `setup_business`, `setup_channels`, `logs`, `dev_*` | global config, tenant config, per-channel switch, audit trail, hidden catalogs | **[LIFT]** |

---

## 1. Discovery & Spec (do BEFORE any code)

| DO | DO NOT | Mechanism | Reuse |
|---|---|---|---|
| Produce founder artifacts first: **User-story → Features table → per-tab layout (header + 2 example rows, mark auto vs user-input) → ASCII form mockups**. | Start coding before the founder has seen the tabs and forms as concrete tables. | Every tab becomes a `SCHEMA.tabs` entry; every mockup becomes a `formSpec` case. | **[PATTERN]** |
| Write each task as **what's wrong → what to change → how to prove it**, with `file:line` anchors and an explicit `Test:`/`Prove:` line. | Write vague tasks with no acceptance test. | Plan tasks pair a concrete target (`Ui.gs:1020`) with a closing `Prove:` clause. | **[PATTERN]** |
| Tag canonical facts with stable anchors (`[SSOT-*]`) and **link, don't copy** across docs/code. | Paste a schema/contract into a second doc where it goes stale. | AGENTS router `Anchors` column; code cites `file:line`, not restated content. | **[PATTERN]** |

---

## 2. Schema & Constants (the SSOT)

| DO | DO NOT | Mechanism | Reuse |
|---|---|---|---|
| Declare **ONE `SCHEMA = {tabs, lists}`** and DERIVE every downstream map (`HEADERS`/`EDITABLE`/`DROPDOWNS`/`ISO_DATE_COLUMNS`/`LISTS`) by looping over it once at load. | Hand-maintain parallel HEADERS/DROPDOWNS/EDITABLE tables that must be kept in sync. | `SCHEMA` then `Object.keys(SCHEMA.tabs).forEach(...)` derivation. | **[LIFT]** |
| Give every field a **stable machine KEY** (`BusinessID`,`status`) that all code references + a separate `header` label the UI shows; `header` falls back to key. | Ever let business logic compare against or key on a friendly header/dropdown label. | `headerFor(tab,key)=f.header||key`; `internalForHeader`/`headerToKey` bridge. | **[LIFT]** |
| Encode translation by shape: **Array** when the cell value IS the label; **Object `{code:'Label'}`** when the cell stores a stable code but shows a friendly label; flag column `coded:true`. | Store friendly labels as the canonical value for anything code branches on (status/locale). | `SCHEMA.lists` mixes arrays + objects; `valueToLabel`/`labelToValue`/`codedColumns`. | **[PATTERN]** |
| Make every accessor **tolerant**: unknown tab/field/value passes through unchanged, never throws. | Throw or drop data on an unrecognized column — the founder WILL add columns. | `headerFor/commentFor/fieldVisible/valueToLabel` all guard and return input on miss. | **[LIFT]** |
| Use **safe implicit defaults**: visible unless `visible:false`, read-only unless `editable:true`, label=key, non-coded unless `coded:true`. Empty `{}` = visible read-only column. | Force every field to spell out every attribute (invites copy-paste errors). | `fieldVisible=!(f.visible===false)`; `EDITABLE=keys.filter(k=>f.editable)`. | **[LIFT]** |
| Generate **repetitive/variable-width headers in code** with documented headroom. | Hand-type `option_1..option_15` families — they drift and mis-widen. | `for(i=1..15) listOptionCols.push('option_'+i)`. | **[PATTERN]** |
| Model **status as data**: named code constants + a `TRANSITIONS` whitelist of legal next-states; validate every change centrally; add states additively; reach a terminal `archived` from all. | Scatter `if status=='x'` literals or allow arbitrary jumps. | `C.STATUS` + `C.TRANSITIONS` adjacency map; new states PREPENDED additively. | **[PATTERN]** |
| Give a **second entity its own STATUS+TRANSITIONS pair** even if some codes collide. | Wire a second lifecycle into the primary TRANSITIONS map. | `MISSION_STATUS`/`MISSION_TRANSITIONS` explicitly never wired into `TRANSITIONS`. | **[PATTERN]** |
| Keep **all "what to do next" strings in ONE map** keyed by status; code writes the line into a non-editable `next_step` column; reuse for popups + Home. | Hard-code guidance in the popup, the writer, and the dashboard separately. | `C.NEXT_STEP` — edit one line, popup + column + Home all update. | **[PATTERN]** |
| Put **all visual config in one `UI` block**; key status colors by the **stable CODE**, translate code→label at render. | Hard-code colors in render code or key color maps by friendly labels. | `C.UI` (HEADER_BG/BAND_BG/WRAP_FIELDS/TAB_COLOR/STATUS_COLORS keyed by code). | **[LIFT]** |
| Keep the **real FK hidden** + add a **code-written display-name snapshot** ("written by code — do not edit"). | Make humans read raw IDs, or let them hand-edit the snapshot column. | `BusinessID {visible:false}` + `name_business` re-stamped on rename. | **[PATTERN]** |
| **Deep-freeze** the exported namespace before returning it. | Return a mutable config object a consumer could rewrite. | `deepFreeze(raw)` recursing `getOwnPropertyNames`. | **[LIFT]** |
| Store only config-key **NAMES** and secret-ref **NAMES** in constants; values never in a sheet. | Put API keys in a cell or sprinkle raw config-key strings across modules. | `CONFIG_KEYS`, `PROPS` ("names only; values never live in a tab"), `DEFAULT_KEY_REFS`. | **[LIFT]** |
| **Comment every non-obvious field** with WHY/precedence/default/who-writes-it. | Leave hidden/write-only/load-bearing quirks unexplained. | `drive_folder_id` precedence; `auto_publish` "blank = yes"; `status` "load-bearing (=== active)". | **[PATTERN]** |
| For a **drifting external option set**, offer a curated short list with exactly ONE `default:true` + a validated paste escape-hatch. | Hard-gate users to the list, or bake provider logic into the data block. | `AI.RECOMMENDED_MODELS` `{slug,label,default}` + `dev_models` live cache. | **[PATTERN]** |
| **Prune or mark inert declared metadata** and keep the schema's own doc-comment in sync with the flags actually used. | Leave fields that imply unimplemented behavior, or a flag list that omits a real flag. | `title`/`order` kept but "not applied"; header comment must name the real `coded` flag. | **[PATTERN]** |

---

## 3. Sheet UI, Bootstrap & Formatting (idempotent, self-repairing)

| DO | DO NOT | Mechanism | Reuse |
|---|---|---|---|
| Drive the whole build from **one `run()`** looping a manifest, applying the SAME fixed step sequence per tab; make every step create-if-absent / set-and-verify so re-running is a no-op. | Write one-shot setup that assumes a fresh workbook or re-seeds destructively. | `Bootstrap.run()` → ensureSheet→headers→formatHeader→ISO→dropdowns→notes→visibility→protect→seed (each step is its own row below). | **[LIFT]** |
| **Seed only when the tab is empty**; store the seed builder inline in the manifest. | Re-seed unconditionally (blows away owner edits) or keep a drifting separate seed list. | `if(spec.seed && readObjects(tab).length===0) writeObjects(...)`. | **[LIFT]** |
| Declare the tab list **once** as ordered `[{tab,seed}]`; reuse it to build, style, and seed the schema registry. | Maintain tab order, seed list, and styling list as three separate arrays. | `manifest()` consumed by `run()`, styling loop, and `_seedDevSchema()`. | **[LIFT]** |
| **Non-destructive header repair**: blank row → write labels; else verify each key resolves once; missing-only → APPEND; missing **AND** unknown → THROW (suspected rename); duplicate → THROW. | Silently rename, blind-append when an unknown header exists, or tolerate duplicates. | `_ensureHeaders()` — `missing.length && unknown.length` throws a rename error. | **[PATTERN]** |
| Pick the **right backfill strategy**: (a) blank-fill-only defaults; (b) version-gated content update (`seed.version > live.version`); (c) one-time rewrite guarded by a script-property done-flag. | Blanket-overwrite for all three (clobbers owner choices) or re-flip a real value each run. | `_backfillAutoPublish` / `_syncSeedPrompts` / `_backfillTiktokEnabled`. | **[PATTERN]** |
| Force **ISO date columns to text format `@`** so code-written ISO strings round-trip losslessly; wrap `setNumberFormat` in try/catch. | Leave date columns on default (Sheets coerces `2026-07-13` to a serial) or let one typed column abort the build. | `_applyIsoFormats()` loops `C.ISO_DATE_COLUMNS`, `try{setNumberFormat('@')}catch{}`. | **[LIFT]** |
| Attach a **header NOTE** stating ownership (system / editable / do-not-rename) + field help; place by header NAME via a header→index map; leave owner columns note-free. | Rely on the founder's memory, or address columns by fixed index (breaks on reorder). | `_applyOwnershipNotes()` from `C.EDITABLE` + `dev_` test + `commentFor`. | **[PATTERN]** |
| Attach **dropdowns by field key** with `requireValueInList(...).setAllowInvalid(false)`, feeding the SAME values the write path stores (labels for coded, codes otherwise). | Hardcode dropdown ranges by column letter, or let the accepted set diverge from what you save. | `_applyDropdowns()` branches `coded[key]?listLabels:LISTS[key]`. | **[PATTERN]** |
| **Idempotent status-color CF**: one rule per status label (colors from `C.UI`); identify YOUR rules by their label-text on the status column, drop-and-re-add only those. | Clear ALL CF rules (kills operator rules) or match by color (GAS normalizes hex → duplicates stack). | `_applyStatusColors()` keeps rules whose text isn't one of `ourLabels`. | **[PATTERN]** |
| **Hide dev sheets by name prefix**; order visible tabs in operator mental order (Home→setup→operational→logs); land on Home. | Leave dev/config sheets visible, or rely on physical creation order. | `_applyTabLayout()` hides `dev_*`, explicit `order` array, `setActiveSheet(home)`. | **[LIFT]** |
| On every run **both hide `visible:false` AND re-show `visible:true`** columns by name. | Only hide — a false→true flip stays hidden on old workbooks, forcing manual migration. | `_applyVisibility()` — the `showColumns` branch makes flips migration-free. | **[PATTERN]** |
| Apply banding **only if none exists**; trim the grid to exactly ONE trailing empty column by deleting/inserting **columns only**. | Re-apply overlapping banding (GAS throws) or delete trailing ROWS (strips dropdowns/formats from future append rows). | `_applyBanding()` guard + `_applyColumnLayout()` columns-only trim. | **[LIFT]** |
| Create **Home as a 2-line stub** outside the data manifest; let a separate reporting fn own/rewrite its top block under protection later; leave rows below as free notes. | Rebuild/overwrite Home every run, or leave it blank. | `_ensureHomeSheet()` create-if-absent stub; `Report.updateHome` owns the block. | **[PATTERN]** |
| Delete the auto-created leftover sheet (`Sheet1`/`Feuille 1`/…) via locale-aware regex, only when empty and not the last sheet. | Delete arbitrary/named or non-empty default sheets, or risk the only sheet. | `_removeEmptyDefaultSheets()` `_DEFAULT_SHEET_RE`, guard `getLastRow===0 && length>1`. | **[LIFT]** |
| Install a time-trigger **once** (scan existing handlers) inside try/catch; on missing scope, LOG the gap and finish the build. | Create the trigger unconditionally (stacks daily triggers) or let a missing scope abort. | `_ensureAutoPublishTrigger()` `getProjectTriggers().some(handler)` + catch→`Log.append`. | **[LIFT]** |
| Ship **one self-contained CSS partial** with design tokens (CSS vars) + semantic `.card/.err/.ok/.muted/.req`; document the JS-contract selectors in a header comment. | Fetch a CSS framework from a CDN at dialog boot, or rename contract ids/classes silently. | `ux_style.html` `:root{--gv-*}`; header freezes `#root/#msg/#submit`, `f_<name>`. | **[LIFT]** |

---

## 4. UX & Forms (menu, dialogs, next_step)

| DO | DO NOT | Mechanism | Reuse |
|---|---|---|---|
| Declare the **menu as a nested data tree**; `onOpen` just recurses. Group leaves by real workflow with emoji + numbered steps. | Hand-wire `addItem`/`addSubMenu` imperatively or scatter labels across handlers. | `Ui._menuTree(isOwner)` + `_buildMenu` recursion; the tree is DATA (unit-testable). | **[LIFT]** |
| **Re-verify owner identity on the SERVER entrypoint** of every privileged (Developer) action — menu-hiding is cosmetic (globals stay callable from the macro dialog / script editor). Make the gate **bootstrap-safe**: fail OPEN when the owner record is unreadable so the function that CREATES it can still run. | Gate a privileged action on a hidden menu item alone, or let the owner check brick a never-bootstrapped workbook. | `Ui._requireOwner()` compares `setup_app.owner_email` vs `Session.getActiveUser()`, throws `Owner-only action.`; a blank/unreadable owner allows the call (`try{…}catch{owner=''}`). | **[PATTERN]** |
| Start **every form** with a required dropdown of business **NAMES→IDs**; re-resolve the ID server-side. | Ask the user to "select the active row" or type/paste an internal id; trust the submitted id. | `_clientList()`/`_clientField()` first field; `_submittedBusinessId()` re-resolves via `Config.business()`. | **[PATTERN]** |
| Ship **ONE generic HTML form** that renders a server field-spec; add each new form as a server `formSpec` case returning `{title,fields,submit,note}`. | Write a new `.html` per feature, or put field/option lists/labels in the client. | `ux_form.html` fetches `formSpec(action,businessId)`; `Ui.formSpec` is a switch. "UI only: no business logic." | **[LIFT]** |
| **Server re-resolves and re-derives everything the client submits**: re-resolve the tenant from the submitted NAME/id, re-derive the actionable id-set from that tenant, re-verify ownership. | Let the client decide what gets written, or pass an id-list the server blindly acts on. | `_submittedBusinessId`→`Config.business`; `publishReady`/`_releaseDuePosts` re-derive from `BusinessID` and NEVER trust a caller id list. | **[PATTERN]** |
| Route irreversible external actions through a **separate confirm modal** showing a plain-language count; carry only `{action, businessId, count}` — server re-derives the set. | Publish directly from the action form, or put the item-list/free-text in the confirm payload. | `openConfirm()` builds the summary (no ids); `ux_confirm.html` red `danger` button; `confirmSubmit→publishReady`. | **[LIFT]** |
| Give a **write-in-cell long-text editor** (menu → active cell in a big textarea → save back same cell) with a **PURE guard** refusing header row / protected / system columns; require a checkbox to overwrite a formula. | Make users edit long text in the cramped cell, or let them clobber a formula/system column. | `ux_text_in_sheet.html` + `UxViews._textGuard` (unit-tested, returns reason `'formula'`). | **[LIFT]** |
| Mirror `next_step` from the **single `C.NEXT_STEP` map** on both code writes and manual edits (`onEdit→onStatusEdit`, swallowing all errors). | Hard-code next-step strings in handlers or a formula; let popup/column/dashboard drift. | `_runAction` reads `C.NEXT_STEP[...]`; `onEdit` restamps; onEdit never raises a dialog. | **[PATTERN]** |
| Each action returns `{message,nextStep,openTab}`: show **exactly one alert** (summary + one `Next:` line) then jump to the tab; falsy return shows nothing; navigate **only on success**. | Emit multiple dialogs, or leave the user on an unrelated sheet; navigate after an errored save. | `_runAction(fn)` alert-then-`setActiveSheet`; `_jumpTo` is success-only. | **[LIFT]** |
| **Never auto-close the generic action-result form (`ux_form`)**; disable Submit after success (re-enable only for re-runnable reports). Deliberate exceptions: the confirm modal (`ux_confirm`, ~1.4s) and save-to-cell dialog (`ux_text_in_sheet`, ~1.2s) auto-close on success by design. | Auto-close a result form on a timer (a flash reads as "no output"), or leave Submit live for double-runs. | `submit.disabled=!(SPEC.keepOpen)`; the two exception dialogs `setTimeout(host.close)`. | **[LIFT]** |
| On error surface **only `err.message`**; map a `not_implemented` sentinel to a friendly "lands in a later phase". | Show a stack, secret, key, or raw Google error; render unbuilt features as crashes. | `_runAction`/`guard` catch→`_banner(message)`; global wrappers rethrow `Error(_banner(message))`. | **[LIFT]** |
| When a global test/mock mode is on, **prefix every result** with a loud banner (naming the mode + how to turn it off) at the shared chokepoints. | Let a simulated run read as real, or add the banner per-action. | `_banner()` wired into BOTH menu-alert and form paths; success AND error. "burned an hour on fake bugs." | **[PATTERN]** |
| Save secrets with **snapshot→write→cheap-validate→rollback-on-failure**; never echo them; placeholder reveals only whether a key EXISTS. | Let a bad paste clobber a working key; echo a stored key; validate by spending real credits. | `_applyZernioKey`/`_applyAiKeyAndModel` restore `prevKey` on throw; placeholder `•••• already saved`. | **[LIFT]** |
| Build all business/AI/result text with **DOM nodes (`textContent`/`createElement`)**, never `innerHTML`; only inject a controlled server key. | Concatenate service output into `innerHTML`, or render user/AI text as HTML. | `ux_form.html renderResult()` splits URLs into `<a>` text-nodes — "NEVER innerHTML". | **[LIFT]** |
| Send **all prefills in the initial spec**, re-render locally on picker change; prefetch siblings; invalidate cached specs after any write (`SPECS={}; GEN++`). | Hit the server on every dropdown change, or reuse a cached spec after a state-changing submit. | `applyPrefills(bid)` with no `google.script.run`; generation guard on stale responses. | **[PATTERN]** |
| **Explain data-caused empty states** ("No clients yet — use 🏪 Client ▸ 1…"); render ⚠ overwrite warnings as conditional notes that hide when empty and never submit. | Render a silent blank (reads as broken), or block a clean first-run with an empty warning. | `_needClientSpec()`, `_NO_CHANNEL_NOTE`; `type:'note'` fields skipped by `collect()`. | **[PATTERN]** |

---

## 5. Tenancy & Data (SheetIO, IDs, multi-tenant)

| DO | DO NOT | Mechanism | Reuse |
|---|---|---|---|
| Address columns by **header NAME** via a runtime `{key→index}` map rebuilt from row 1 on each access; even find the ID column by name. | Hardcode column numbers (`getRange(r,3)`) or assume the ID is column A. | `SheetIO.headerMap()`; `_idIndex()` finds ID by `C.HEADERS[tab][0]`. | **[LIFT]** |
| Resolve every stored header to its **stable key** (`internalForHeader`) so code never depends on displayed header text; owner columns pass through. | Compare or branch on the literal header string shown to the user. | `headerMap`/`readObjects` call `C.internalForHeader(tab,text)`. | **[LIFT]** |
| **Coded columns**: store the LABEL in the cell (matches dropdown), move the CODE in logic, translate at exactly **one read seam + one write seam**. | Scatter label↔code conversions through feature code, or write raw codes into cells users read. | `readObjects→labelToValue`; `writeObjects/appendObject/updateRowById→valueToLabel`; `_codedMap(tab)`. | **[LIFT]** |
| Mint IDs as **`prefix + slice(uuid,12)`** — globally unique, self-describing, safe in batch loops. | Use `max(existing)+1` or row-count ids (collide when appending many rows before re-read). | `SheetIO.nextId(prefix)`, prefixes from `C.ID_PREFIX.*`. | **[LIFT]** |
| Mint a **trace/idempotency id (`nextId('req_')`) BEFORE every external call** and thread it into BOTH the sheet row AND the log; send it as the provider's dedup header. | Call out with no correlatable id (an ambiguous send becomes untraceable and un-dedupable). | `SheetIO.nextId('req_')` in `draftReviews`/`publish`; Zernio sets `x-request-id`; `Log.append({request_id})`. | **[PATTERN]** |
| **Batch full-tab I/O**: ONE `getValues()`, mutate in memory, ONE `setValues()`. | Call `getValue()/setValue()` per cell. | `readObjects` reads once; `writeObjects` writes once. | **[LIFT]** |
| **Resolve the header→index map ONCE before the row loop** (never inside it); a single-row edit = read the row → patch named cells → write once. | Rebuild the header map per row, or read-modify-write per cell. | `updateRowById` patches `rowVals[map[key]]` after a single `headerMap`. | **[LIFT]** |
| **No spreadsheet formulas** — code writes every derived cell (timestamps, `next_step`), including on manual edits via a simple `onEdit`. | Put `=NOW()`/`=VLOOKUP`/status-mirror formulas in cells (recalc unpredictably, break id-keyed reads). | `nowIso()`; `_stampNextStep`; `onStatusEdit(e)` restamps on manual change. | **[PATTERN]** |
| **Date-gate by lexicographic compare of ISO `YYYY-MM-DD` strings** in the WORKBOOK timezone (no Date math, no UTC/local midnight off-by-one); derive today from an injectable clock honoring a test override ONLY in test mode. | Compare Date objects / UTC midnights, or read a live clock tests can't pin. | `_isDue/_scheduledDate` slice to 10 chars + `<=`; `_today()` honors `C.PROPS.TODAY_OVERRIDE` only when `isTestMode()`. | **[PATTERN]** |
| **Partition the actionable set ONCE server-side** (ready vs held) and reuse that single split for BOTH the confirm-count and the send — so the number shown and the number sent can't diverge. | Count with one query and send with another (they drift). | `readySplit(businessId)→{ready,held}`; the confirm summary and `publishReady` read the same partition. | **[PATTERN]** |
| **Preserve owner-added columns**: full-tab rewrite maps across ALL live headers; single-row ops touch only named keys. | Rebuild rows from the schema field list alone (erases columns the founder added). | `writeObjects` uses `Object.keys(headerMap)`; `appendObject` assigns only patched keys. | **[LIFT]** |
| **Guard degenerate states** (empty/header-only/blank rows) and enforce ID uniqueness at write time (exactly one match, else throw); every error tells the user the fix. | Assume a data range has rows, or let a duplicate id update the wrong/multiple rows. | `readObjects` returns `[]` on `<2` rows; `updateRowById` throws on 0 and `>1`; `getSheet` "run bootstrap". | **[LIFT]** |
| Store the **stable tenant `BusinessID` on every row** and begin EVERY read with `filter(r=>String(r.BusinessID)===String(id))`. | Separate per-client tabs/files, or rely on row grouping for tenant separation. | Every append writes `BusinessID`; every consumer filters with `String()===String()` (type-tolerant). | **[LIFT]** |
| Pair the id with a **denormalized name snapshot** resolved at write time so raw rows read without lookups; code still joins on the id. | Force humans to read opaque ids, or join code on the mutable name. | `appendObject` stamps `name_business: Config.businessName(id)`. | **[PATTERN]** |
| For any side effect, **recompute the eligible id-set server-side from the tenant id**; the client echoes back only a `BusinessID`. | Publish/delete/mutate whatever ids the confirm payload / active-row / UI state hands you. | `publishReady`/`_releaseDuePosts` derive via `readyPostIds()`→`readySplit`. | **[PATTERN]** |
| **Re-validate at a single chokepoint** before any external call: re-resolve deps from the sheet, re-verify tenant ownership + platform + active + capability, throw before minting a request id. | Assume a FK column still points at a row this tenant owns just because it was valid when written. | `_channelRef(row)` re-reads `setup_channels`, throws unless `ch.BusinessID===row.BusinessID`. | **[PATTERN]** |
| **Fail CLOSED** on tenancy guards — a guard whose verifying datum is missing must throw. | Let an opt-in guard silently pass when the verifying datum is absent. | `registerChannel`: pinned `zernio_profile_id` with no returned profile → throws. | **[PATTERN]** |
| **Two-pass all-or-nothing batches**: PREFLIGHT every id (read+gate+legal-transition, no writes); APPLY only if all pass. Tenant-wide gates are batch-fatal; one bad row degrades. | Write as you iterate (a mid-batch throw leaves a half-applied set). | `_transition` preflights vs `C.TRANSITIONS`; `_releaseDuePosts` per-row `_channelRef` try/catch. | **[PATTERN]** |
| **Gate before work**, then serialize the outward path with a **document lock**. | Do work before checking gates, or rely on external idempotency alone against concurrent runs. | `_gate`/`_missionGate` log+throw before work; `LockService.getDocumentLock().waitLock(30000)`. | **[PATTERN]** |
| Make re-runs **idempotent on stable/external ids**; return the existing row instead of appending dupes; **deactivate (status flip), never delete**. | Hard-delete tenant rows or re-perform a completed external action on re-run. | `_ingestRows` dedupes on `external_review_id`; `deactivateChannel` sets `status='inactive'` (rows kept). | **[PATTERN]** |

---

## 6. Setup, Config, Secrets & Audit Log

| DO | DO NOT | Mechanism | Reuse |
|---|---|---|---|
| Store only the **Script-Property NAME** in a config cell; resolve the actual secret via `PropertiesService.getScriptProperties().getProperty(name)` at call time. All BYO keys (AI/Zernio/SerpApi) live in **script** properties. | Put a key/token in a cell, or pass/persist the resolved secret. | `Config.secret(refKey)`; `setAiKey` returns the NAME, never the value. | **[LIFT]** |
| Cache only **NON-secret** per-workbook data (e.g. the aggregator-accounts list) in **document scope** (`CacheService.getDocumentCache()`). Keep dev flags (`TEST_MODE`) script-level. | Put secrets in a cache, or per-tenant caches in script scope. | Accounts cache uses `getDocumentCache()`; secrets stay in script properties. | **[PATTERN]** |
| If you later move to a **shared central-Library deploy** serving many workbooks, migrate per-workbook secrets to **document scope FIRST** — mark it a documented seam until then. | Ship a shared-Library deploy while secrets still resolve from script scope (leaks across operators). | Current build is container-bound (`script.container.ui`, no library dep) so script scope is correct; the document-scope secret bucket is a **planned migration, not shipped**. | **[PATTERN]** |
| Make secret-missing errors **steer the operator** (name the key + exact menu path) and keep a **stable code prefix** for pattern-matching. | Mention "Script Properties" to the operator, or echo the secret (even masked). | `Config.secret:` prefix preserved because `Zernio._isMissingKey` matches it. | **[PATTERN]** |
| Use **two config shapes**: key/value (EAV) tab for global settings (`setup_app`), wide 1-row-per-client tab for tenant config (`setup_business`); read via different accessors. | Cram per-client fields into the global tab or global settings into the client table. | `Config.getAll/get` vs `Config.business(id)`; `C.CONFIG_KEYS` enumerates legal keys. | **[LIFT]** |
| **Fail-fast, duplicate-guarded accessors**: `get()`→null, `getRequired()`→throws clear msg, loader throws on duplicate keys. | Let callers proceed on a missing required setting, or let two same-key rows coexist. | `getAll()` throws `duplicate setup_app key`; `getRequired()` throws on blank. | **[LIFT]** |
| **Tenant-key discipline**: throwing `business(id)` for critical lookups; a never-throw `businessName(id)→''` for hot-path snapshot/log stampers. | Call the throwing lookup from code that runs on every append (a typo takes down logs). | `businessName` returns `''`, called from `Log.append`. | **[PATTERN]** |
| Separate **capability** (`supports_api`, system) from **operator switch** (`api_enabled`, per-channel); default the switch **OFF**. | Drive live external calls off a single capability flag. | `dev_platforms.supports_api` + `setup_channels.api_enabled` (list `bool`, default off). | **[LIFT]** |
| Make feature-gating a **pure predicate** `check()→{allowed,reason}`; the single call-site logs+throws. | Log or throw inside the check function (scatters enforcement, untestable). | `Entitlements.check()`; `Workflow._gate` logs `entitlement_denied` and throws. | **[PATTERN]** |
| **Structured, retained audit row** — write ONE fixed-shape `logs` row for every state change AND every external call: `{LogID, timestamp, BusinessID, name_business, object_type, object_id, action, actor, status_before, status_after, request_id, external_ref, result, error_code, details}`; counters, reconcile, and debugging all read from it. | Scatter ad-hoc log formats, or log only failures. | `Log.append(event)` defaults missing fields, stamps `name_business`, mints `LogID`. | **[LIFT]** |
| **Cap the audit tab as a rolling ring buffer** — after each append delete overflow so only header + latest N (1000) rows survive; size N ABOVE the busiest month's write volume. | Let the log grow unbounded, or set N below what a counter/report must scan. | `Log.append` → `deleteRows(2, lastRow-1001)`. | **[LIFT]** |
| **Redact at the log seam** — recursively replace any object key matching `/key\|token\|secret\|authorization\|password\|apikey\|credential\|bearer/i` with `[redacted]` before stringifying `details` (defense in depth even when callers scrub). | Trust every caller to pre-scrub, or stringify raw objects into the log. | `Log._redact`; pass structured (not bare-string) details so the net can catch them. | **[LIFT]** |
| Derive usage/billing counters from **success rows in the log** (keyed tenant+month) — but ONLY if that source is uncapped OR the ring-buffer cap exceeds the busiest month, else it undercounts. Surface caps read-only; enforce only when billing says so. | Count live row state (edits/re-imports/deletes skew it), or scan a capped log that can drop a high-volume month's rows. | `Entitlements.usage()` scans `logs`; `caps()` for dashboard only, marked seam for enforcement. | **[PATTERN]** |
| Model **plans as a hidden catalog tab** of boolean feature + numeric cap columns; tolerant boolean parse (`true`/`'true'`). | Hardcode plan→feature mappings in code. | `dev_tiers` + `_isTrue(v)`; `C.FEATURES` maps names→`feat_*` keys. | **[LIFT]** |
| Resolve settings through **provider-default fallback chains** (`app-override \|\| catalog-default \|\| ''`); make config writes **upsert**. | Require the operator to fill every field, or append a duplicate row for an existing key. | `Config.resolveAi()`; `Config.set()` updates-in-place-or-appends. | **[LIFT]** |
| Bind **every value code compares with `===`** to a strict dropdown; never free text. Leave safety-critical fields (privacy) with **NO default** so they block until chosen. | Leave a `=== 'active'`-checked field as free text (`'Active'`/`'oui'` silently break logic). | `setup_channels.status` list `channel_status`; `tt_privacy` has no default. | **[LIFT]** [SKIP] tt_privacy is TikTok-specific |

---

## 7. External Adapters & Boundaries

| DO | DO NOT | Mechanism | Reuse |
|---|---|---|---|
| **One thin adapter object per external boundary** (`var X={}`) with a doc header listing endpoints, auth, response→status mapping, and a `Calls:` line; cross-refs only inside function bodies. | Spread one provider's HTTP across files, or build a shared generic HTTP layer everyone funnels through. | `AI.gs`/`Zernio.gs`/`ReviewSource.gs`/`Gbp.gs`/`Orchestrator.gs` each one namespace. | **[PATTERN]** |
| Target **one concrete provider's native wire format**; resolve baseUrl/model/keyRef from config so swaps are config edits. | Build provider-abstraction interfaces/strategy classes/plugin registries for hypothetical providers. | `AI._fetchCompletion` posts raw OpenAI shape; `Config.resolveAi()→{baseUrl,model,keyRef}`. | **[PATTERN]** |
| **Keep third-party OAuth OUT of the app** — proxy social/GBP publishing through an aggregator holding the OAuth; store only its single Bearer token. | Implement Google/Meta/LinkedIn/TikTok OAuth, consent, refresh in Apps Script; call googleapis directly. | `Gbp` adds NO GBP scope; `Zernio._auth()` one Bearer token for all platforms. | **[PATTERN]** [SKIP] GBP-via-Zernio is GoViral-specific |
| **Validate external media URLs are direct raw bytes** (`https://`, not a share PAGE) BEFORE handing them to the aggregator — a Drive/Docs/Dropbox/OneDrive/SharePoint/iCloud share link returns HTML and fails platform-side, so drop it. | Forward whatever URL the operator pasted (a "share" link silently fails downstream). | `Workflow._isDirectMediaUrl` (https + host denylist); `_mediaItems` filters then maps; Instagram then fails closed locally. | **[PATTERN]** [SKIP] host denylist is GoViral-specific |
| Represent an unbuilt/async integration as a **stub that throws**; the adapter's try/catch turns it into a typed fail-closed error. | Build polling/webhook clients in Apps Script, or let an unbuilt path silently no-op/fake success. | `Orchestrator.call(){throw 'not_implemented'}`; `Gbp.reply` → `external_service_error`. | **[PATTERN]** |
| **Config-select the transport** and gate whole integrations behind an enable flag defaulting to the safe manual path. | Hardcode which backend a boundary uses, or ship a new external path enabled-by-default. | `Gbp._realReply` reads `GBP_TRANSPORT` (`zernio`\|`n8n`); `api_enabled` seeds false. | **[PATTERN]** |
| **Mock ONLY the innermost transport** in test mode; run all payload-build + response-mapping unchanged in prod/test. | Branch business logic on test mode, or mock at the public-method level (leaves mapping untested). | `Zernio._post`/`AI._fetchCompletion` isolate `isTestMode()`; mocks accept `__mockHttpCode` etc. | **[LIFT]** |
| **Fail closed**: on any external error return an `ok:false` typed fallback in the caller's expected shape; leave the row at its pre-call status. | Let an external failure throw up the stack, or advance the workflow past draft/unpublished. | `AI.run` try/catch → `_aiFailure(task)` "never advance past draft"; `Gbp.reply` keeps review unpublished. | **[PATTERN]** |
| **No blind retry on non-idempotent writes**: an ambiguous post-send timeout → mark `needs_reconcile`; resolve later by list+match requiring exactly one match. | Blind-retry a create that may have succeeded (double-posts). | `Zernio.publish` → `PUBLISH_UNCONFIRMED`; `reconcile` matches `accountId`+content, only `hits===1`. | **[PATTERN]** |
| Send your **own `x-request-id` idempotency header**; treat provider "duplicate" (409 / duplicate-422) as reconcile, capturing the existing id. | Depend on your own retry bookkeeping for dedup, or treat a duplicate as fresh/hard-fail. | `Zernio._post` sets `x-request-id`; `publish` branches 409/dup → `_existingPostId`. | **[PATTERN]** |
| **Rate-limited WRITE boundary**: retry ONLY 429 with exponential backoff (few tries) then surface a re-queueable failure; return 5xx and every other code to the caller immediately; never hardcode the provider's limit. | Retry a non-idempotent write on 5xx (may double-post), or hardcode a per-hour cap, or retry forever. | `Zernio._post` sleeps `2^attempt*500` on 429 only, ≤4 tries, returns any non-429 at once. | **[PATTERN]** |
| **Read/idempotent GET boundary**: retry ONLY 5xx (transient) with a few short sleeps; BAIL immediately on 429 and every other 4xx (bad key / out of credits — waiting won't help); also retry a thrown network error. | Retry a 4xx, or retry forever. | `ReviewSource._fetch` breaks on `code<500`, sleeps only on 5xx (1.5s,3s), ≤3 tries. | **[LIFT]** |
| **Never leak secrets in errors**: sanitize fetch exceptions embedding key-URLs; report only HTTP status on key rejection; truncate/redact debug dumps. | Surface raw provider bodies / fetch exceptions that echo `api_key=…` or `Authorization`. | `ReviewSource._fetch` → generic msg; `validateKey` "(HTTP code)"; `debugRaw` truncates 1500, no key. | **[LIFT]** |
| **Validate a key cheaply BEFORE expensive work** (zero-cost authenticated GET), validate-then-write so a bad key leaves all tabs untouched. | Discover a bad key mid-batch after partial writes, or spend paid credit to test a key. | `AI.validateKey` GET `/key` before `Config.cacheModels`; `ReviewSource.validateKey` GET `/account.json`. | **[LIFT]** |
| **Resilient AI-output validation**: strict on the load-bearing field (non-empty/length/locale/forbidden), lenient on missing metadata, **clamp** off-vocab to `''`, **drop-not-fail** bad list rows (count them). | Reject a usable reply for a missing tag, write an off-dropdown value, or sink a batch for one bad row. | `AI._validateReviewReply` strict; `_validateCalendar` `inList()` clamps, drops rows, returns `{posts,dropped}`. | **[PATTERN]** |
| Read each external field through a **tiny tolerant helper** (field-name/envelope variants); slice JSON out of chatty/fenced text before parsing. | Reach straight into `resp.post._id` or assume a clean JSON body. | `Zernio._postId/_existingPostId/_asList`; `AI._extractJson` slices first `{`…last `}`. | **[PATTERN]** |
| **Additive-only extension** for new channels/features — when unused the payload is byte-for-byte identical to before. | Restructure a shared payload builder to accommodate one new channel. | `Zernio._buildBody` adds `platformSpecificData` only `if(platform==='tiktok')`. | **[PATTERN]** |

---

## 8. Built-then-retired — keep the left column, drop the right

Every row is a design we shipped, then removed. The **Keep** column is the alternative that survived; the **Retired** column is what it replaced and the price we paid.

| Keep (survived) | Retired (removed) | Cost paid when we shipped the retired way | Reuse |
|---|---|---|---|
| One modal form per action, first field = a NAME `<select>`. | Chained `ui.prompt()` dialogs making the operator TYPE an entity ID. | `ui.prompt` can't render a select; a single-client auto-pick masked it until client #2 broke live — 11 prompt fns deleted. | **[PATTERN]** |
| Modal action forms + a modal confirm gate. | A persistent `showSidebar` as the primary work surface. | Fixed ~300px width, non-modal staleness, forced `script.container.ui` scope — removed. | **[PATTERN]** |
| Compute the actionable set server-side (status + due-date). | A checkbox/bulk-selection HTML view. | `ux_bulk.html` duplicated the server re-derivation for zero safety gain — removed. | **[PATTERN]** |
| Model approval as a **sheet status flip**. | An in-tool Gmail approval loop (send/parse replies, `validation_requests` tab). | Cost 2 broad Gmail scopes; orphaned `validation_requests` data lingered on the live workbook and needed hand-deletion; tests 354→315. | **[PATTERN]** |
| Add a scope only for a shipped feature; freeze the list; route new capability through an existing integration. | Speculative scopes, or scopes left after cutting the feature. | Every scope forces a re-consent on every workbook; dead-feature scopes are pure liability. GBP routed through the aggregator to add NO scope. | **[LIFT]** |
| Ship **fresh-workbook-only**; repair APPENDS missing headers, hard-stops on rename ambiguity. | In-place migration (key renames, label migration, backfill, seed upserts) before you have users to migrate. | Migration removed (tests 373→349); dead refs leaked into a user-facing error still naming a deleted menu. | **[PATTERN]** |
| Delete no-function UI shells; fold their one help string into a real field. | A `Setup ▸ Advanced` tab that only displays a paragraph. | `setupAdvanced` (submit:null, fields:[]) deleted; help moved to the `model_advanced` field. | **[PATTERN]** |
| Put related sub-data on the parent form. | A separate tab for client↔account channel mapping. | Churned twice (moved, then deleted); the block vanished on stale workbooks and read as a regression. | **[PATTERN]** |
| Rewrite system blocks from a **fixed anchor (row 1) + protection**. | An idempotent rewrite anchored by searching for an operator-editable heading string. | An edit to the marker made the next run APPEND a second dashboard. | **[PATTERN]** |
| One writer per surface; seed a 2-line stub pointing at it. | Full static guidance seeded in Bootstrap AND regenerated in the updater. | Two writers drifted into two voices on the same tab. | **[PATTERN]** |
| Keep automation output at proposed/validated; require a manual flip to advance. | Auto-flip a business-state as a side effect of a technical action (rendering a Doc). | Generating a proposal Doc auto-flipped the mission — corrupted pipeline state. | **[PATTERN]** |
| Queue batch work via a **status column**, action drains it with just a client selector. | A per-item picker dropdown to choose one row. | Picker added, then removed — a per-call decision that doesn't scale past a handful. | **[PATTERN]** |
| Move a Drive file with `file.moveTo(...)`. | The deprecated `Folder.addFile`+`removeFile` pair. | Silently fails on single-parent Drive — "the first proposal Doc disappeared into My Drive". | **[LIFT]** |
| Expose only a **single-suite** self-check live; run the full suite offline. | A "Run ALL self-checks" menu button. | The full run exceeds the Apps Script 6-min limit — a guaranteed timeout. | **[LIFT]** |

---

## 9. Testing

| DO | DO NOT | Mechanism | Reuse |
|---|---|---|---|
| Write **one Node script** faking just enough of the platform in a `vm` sandbox, load your REAL `.gs` unmodified (`00_Constants` first), run bootstrap + full suite in one command. | Rely only on the cloud editor / live runs to know if the code is green. | `tools/gas_mock_run.js`: `vm.createContext` + `readdirSync().sort()` → `Bootstrap.run()` + `Test.runAll()`. | **[LIFT]** |
| **Model platform quirks/failures in the mock** so guards are actually exercised offline. | Stub every platform call as a silent no-op success (guards look tested, never ran). | `FakeRange.applyRowBanding` throws on overlap so the create-if-absent guard runs; `getProtections(type)` filters like live GAS. | **[PATTERN]** |
| **Isolate test fixtures by a reserved id prefix** (`biz_test` BusinessID), EXCLUDE them from every operator-facing list, and provide a one-click reset that sweeps them from the operational tabs — so the harness exercises the live schema without polluting operator views. | Seed fixtures into the same id space operators see, or leave them behind after a run. | `Ui._clientList()`/`Report` filter out `biz_test`; `Test.resetFixtures()` + 🧹 Reset test data menu. | **[PATTERN]** |
| Run a **second independent verification** that re-derives a core invariant a different way with its own pass count. | Trust a single green signal whose fixtures could mask drift. | Harness re-reads every tab's row-1 headers → keys → asserts present once: "Manifest tabs correct: 15/15" (distinct from the 600/600 suite). | **[PATTERN]** |
| Expose a **single-suite `runSuite(name)`** for live smoke tests under the time ceiling; full suite only offline. | Try to run the full harness live and hit the 6-min kill. | `runSuite`→`Test.runSuite`; full run only via `node tools/gas_mock_run.js`. | **[LIFT]** |
| **Add a test for every new behavior; never loosen a guard/assert to pass.** A deliberate contract change UPDATES the assert and is declared in CHANGELOG. | Edit the test to match a bug, or relax an assertion to reach green. | "label asserts update = DECLARED pinned-contract change". | **[LIFT]** |

---

## 10. Docs & Process

| DO | DO NOT | Mechanism | Reuse |
|---|---|---|---|
| Keep **all source in git under `src/`**; deploy with one thin push; the cloud container is a deploy target, never the source of truth. | Edit code in the bound script editor as the canonical copy. | `.clasp.json rootDir:src`; `clasp push -f`; same files the Node harness loads. | **[LIFT]** |
| Expose each module as **one namespace object; no load-time cross-module reads** (cross-refs live inside functions). | Reference another module at top level (forces a fragile load order). | GAS concatenates all files into one global scope; deferring cross-refs makes any load order valid. | **[LIFT]** |
| Put **one routing table** at the top of AGENTS.md: each doc gets a single role, a "read when" trigger, a numeric Authority rank, an anchor; a Conflict rule row on top. | Let docs overlap in purpose or leave precedence implicit. | AGENTS router (1=AGENTS…6=vision); project docs override global except safety rules. | **[LIFT]** |
| **One concern per doc** (PROGRESS=live state, PLAN=to-do SSOT, PRD=spec, ARCHITECTURE=boundaries, CHANGELOG=history) with a "Do not put here" redirect block. | Let PROGRESS hold a to-do the plan lacks, or PRD hold status. | Each doc's redirect block routes off-topic content to its owning doc. | **[LIFT]** |
| Structure the plan as **NOW / LATER / CHECK**; each task self-contained (`what's wrong→change→prove`, `file:line`, `Test:`). | Interleave parked ideas into the active queue, or write untestable tasks. | Plan "How to read" header + CHECK runlist (harness green w/ count, `git diff --check`). | **[LIFT]** |
| Codify a **one-objective ritual**: read AGENTS→PROGRESS→owning docs → do ONE objective → verify → update PROGRESS only if state changed → emit auditor prompt + next-step prompt → STOP for owner validation. | Take multiple objectives per pass or self-approve and continue without a human gate. | AGENTS "Agent Ritual" 8 steps. | **[LIFT]** |
| **Done = owner-validated.** Keep tasks in NOW until implemented AND validated; deferral to LATER needs explicit owner decision; mark BUILT / AUDIT-GREENLIT short of done. | Mark a task done at code-complete or quietly drop it into a parked list. | "stays in NOW until pushed + owner-validated". | **[LIFT]** |
| Keep a **recorded no-fix graveyard** (investigated-and-declined items with anchor + reason). | Silently reject a finding and let the next audit re-surface it. | Plan "Recorded no-fix decisions (don't re-flag)" + "Known limitations (accepted)". | **[LIFT]** |
| **Gate "done" on checkable UX contracts, not vibes**: exactly ONE alert per action then a SUCCESS-ONLY tab jump; every empty state names the menu path that fixes it; the result form never auto-closes and disables Submit after success. Green tests + a broken contract = NOT done; when a UX contract is unclear, ask the owner in handoff. | Declare done on harness-green alone, or invent UX the owner never specified. | `Ui._runAction`/`_jumpTo` (jump only on success); `_needClientSpec`/`_NO_CHANNEL_NOTE` name the fix; `ux_form` Submit disables post-success. | **[LIFT]** |
| Mark future reversal points with a greppable seam comment (`// ponytail: unenrolled=allowed … flip to default-deny when V2 ships`). | Leave a lenient-V1 assumption or future enforcement point undocumented. | `Entitlements.check` lenient-default seam. | **[PATTERN]** |

---

## 11. Kickoff checklist (ordered)

**Founder-facing artifacts first (produce and get sign-off BEFORE code):**

1. **User story + Features table** — one row per feature: `Feature | Trigger (menu path) | Input | Output | Irreversible?`.
2. **Per-tab representation** — for each tab, a table with the header row + **2 example rows**, and each column tagged `[auto]` (code-written) or `[input]` (operator-typed). This IS the future `SCHEMA.tabs`.
3. **ASCII form mockups** — one per menu action, first field always the client NAME dropdown; mark which fields are dropdowns and their option lists. These become `formSpec` cases.
4. **Status lifecycle sketch** — the codes + legal transitions (→ `C.STATUS` / `C.TRANSITIONS`) and the one-line `next_step` guidance per status (→ `C.NEXT_STEP`).

**Then scaffold (lift the reusable assets):**

5. `git init`, `src/` root, `.clasp.json` (`rootDir:src`, `parentId`), freeze the OAuth scope list.
6. Drop in `00_Constants.gs`; encode the artifacts from steps 2–4 into ONE `SCHEMA` + `lists` + `STATUS`/`TRANSITIONS`/`NEXT_STEP`/`UI`; `deepFreeze`. Every field: stable KEY + `header`, safe defaults, inline rationale comment.
7. Lift `SheetIO.gs`, `Bootstrap.gs`, `Config.gs`, `Log.gs`; wire `setup_app` (EAV) + `setup_business` (wide) + `setup_channels` + `logs` + hidden `dev_*` catalogs. Log writes go through the fixed audit-row schema (ring-buffered, redacted).
8. Lift `ux_style.html` + `ux_form.html` + `ux_confirm.html`; build `Ui._menuTree` (emoji + numbered groups) and one `formSpec`/`formSubmit` case per mockup. First field = NAME select, re-resolved server-side. Re-verify owner on every Developer entrypoint (`_requireOwner`, bootstrap-safe).
9. Secrets: store NAMES only in cells, values in **Script Properties** (container-bound deploy); document scope for NON-secret caches only; validate-cheap-before-write with rollback. (If a shared central-Library deploy is planned, migrate secrets to document scope first.)
10. For each external API: one `var X={}` adapter targeting the provider's native shape; `isTestMode()` mock at the innermost transport; fail-closed typed fallbacks; `x-request-id` idempotency + a `req_` trace id minted before every call and threaded into row + log; retry policy matched to the boundary (429-only backoff for writes, 5xx-only for reads); validate direct-media URLs before the aggregator; secret-free errors.
11. Lift `tools/gas_mock_run.js`; make fakes reproduce the failure modes your guards defend; isolate fixtures under a `biz_test` id and exclude them from operator lists; wire the independent header-verification pass. Target 100% green + `manifest tabs correct: N/N`.
12. Set up AGENTS.md router + NOW/LATER/CHECK plan + PROGRESS + CHANGELOG. Adopt the one-objective ritual; **done = owner-validated**.
13. Run `Bootstrap.run()` on a fresh workbook, confirm idempotence (run it twice — second run is a no-op), hand to the founder for live validation before the next objective.

---

# Part II — AI Workflow Engines, Multi-Provider Registries & the Maturity Ladder

*Part I above is the GoViral shipped-tool baseline (v1: code writes every cell, one frozen `SCHEMA` SSOT, menu-driven, strict per-tenant filtering, one provider hardcoded). Part II adds the two rungs GoViral deliberately did not build — the config-driven **workflow engine** (AIssistant) and the **multi-provider registry** (aiStrategy) — plus the decision rules for choosing between them.*

**Legend** — continues Part I's `[LIFT]` (copy the file ~80% as-is) · `[PATTERN]` (copy the technique) · `[SKIP]` (project-specific). Part II adds **`[AVOID]`** — a live anti-pattern mined from the aiStrategy formula prototype; copy the *sheet shape*, never the mechanism.

**Sourcing note (audit-finalized).** The AIssistant engine section is grounded in the **V2.1 SPECIFICATION** (design intent), by owner decision — it is *not* verified line-by-line against shipped code. The actual engine source exists and matches the spec's surface (`Config-workflow`, `columnType`, `callGemini`, `builder_*`, `workflow_Processor`, `generateSheetsByWorkflow` all confirmed present) in the Drive doc **`aissistant_refactoring- V2.1. CODE FILES`** + the **WORKFLOW GENERATOR** sheets (V2.2 / Prod-v1) — mine those if you later want to promote engine rows from *specified* to *code-verified*. **Every aiStrategy citation is workbook-observable** — visible in the shipped sheet itself (cell values, tab names, `[type]` tags); its own design Doc is out of scope and **not quoted**. The two "AyS Scripts" `:run` libraries are a **separate utility/launcher system**, not the engine — catalogued (names only) in the appendix, not mined for patterns.

---

## Three reference implementations

| Project | Maturity | Architecture in one line | Take from it | Do NOT copy |
|---|---|---|---|---|
| **GoViral** (Part I) | **v1 — shipped coded single-tool** | Code writes every derived cell; one deep-frozen `SCHEMA`; menu + generic `formSpec` dialogs; `BusinessID` tenancy filter on every read; one provider in code. | It *is* the Part I spine — nothing new to add here. Its only ceiling: **a new workflow = a code change + redeploy.** | — (baseline) |
| **AIssistant** | **v2 — generic data-driven workflow builder/runner** | One `Config-workflow` driver sheet (1 row/column) → two-phase BUILD then RUN; `columnType` dispatch; `HELPER_FUNCTIONS` registry; validator + guided authoring. | The engine: `Config-workflow` schema, validate-first/commit-last, `WORKFLOW_TYPE_HANDLERS` dispatch, `utility.gs` primitives, builder/processor split. | Shipping the whole engine for **one** workflow (engine overhead + a second SSOT to validate). The generated **`formula` columnType** — it re-imports the `#REF!` fragility Part I removed. |
| **aiStrategy** | **v0 — formula-driven WIP prototype** | Relational PK/FK tabs under a two-row `[type]` header; rules-as-data scoring; multi-provider `_settings_api`; prompts-as-config — but derived cells are **live cross-sheet formulas**. | The *sheet patterns*: `[type]` annotation row, `_options_list`, `_scoring_*`, `_settings_api`, `_settings_outputs`, numbered/`_`-prefixed tab taxonomy, composite readable IDs. | `[AVOID]` cross-sheet formulas in the schema/label row, `VLOOKUP` scoring sprawl, `__xludf.DUMMYFUNCTION` array-formula keys, `#REF!`/`#NA` cells feeding scoring/dropdowns/AI context — all **live-broken** in the workbook today. |

---

## Maturity ladder (altitude) — pick your rung

Pick by **(distinct workflows × edit frequency × who edits)**. The three reference projects *are* the three rungs.

| Rung | Grounded in | RIGHT rung when… | Ceiling (promote when you hit it) | Migration seam to next rung |
|---|---|---|---|---|
| **v0 — formula prototype** | aiStrategy | Throwaway, hand-scored tool; a single owner eyeballs the math; **no code reads back a derived cell**; you only need to prove a schema/DAG shape cheaply. | The instant *any* logic reads a derived cell (status/id/FK/score): formulas recalc unpredictably, rot to `#REF!`/`#NA`, break id-keyed reads; `__xludf.DUMMYFUNCTION` keys have **no portable at-rest value** (collapse to `'COMPUTED_VALUE'` on export). | Convert every derived column to a **code-written cell** (`nowIso()`/`_stampNextStep`-style). The `[type]` row's `[formula]`/`[AI call]`/`[gSheet-only helper]` tags **are the exact worklist** of cells to rewrite. Freeze the resulting `SCHEMA`. → **v1** |
| **v1 — coded single-tool** | GoViral | **One** stable production workflow; non-technical founder; tenancy matters; the provider is fixed; you can absorb a redeploy per change. | Every new workflow is a code change. When **workflow-count × churn** makes each new one a code edit the founder can't self-serve, the engine pays for itself. | Extract the hardcoded flow into `Config-workflow` rows + a `columnType` dispatch; the frozen `SCHEMA` becomes **generated** by `builder_Generator`; the hardcoded step order becomes `onSuccessTrigger` cells. → **v2** |
| **v2 — config-driven engine** | AIssistant | **Only** when the founder will author *and* edit **many similar AI-step workflows himself**, in the sheet, without you. | You now own a **second SSOT** (the config sheet) that itself needs a runtime validator + guided authoring, plus engine scaffolding. That is the tax. | Terminal rung for this family. **Demote/refuse** triggers: a single workflow → stay v1; formulas the moment code reads a derived cell → never drop to v0. |

**One-line rule:** *stay as low as the reads allow.* Code owns any cell logic reads; the config sheet earns a validator only when the founder edits workflows himself.

---

## AI Workflow Engine (data-driven builder/runner)

The single biggest capability absent from Part I. One `Config-workflow` sheet is the source of trust; **BUILD** generates sheets from it, **RUN** executes one step from it.

### The `Config-workflow` driver sheet — one row per target column

| DO | DO NOT | Mechanism (file · field) | Reuse |
|---|---|---|---|
| Define the whole workflow as **data rows, exactly ONE ROW PER TARGET COLUMN**; derive all runtime behavior from them. | Hardcode sheet structure, column lists, or step order in `.gs` a non-tech owner can't edit. | `Config-workflow` = SINGLE SOURCE OF TRUST; read by `builder_ConfigProvider`, `builder_Validator`, `builder_Generator`, `workflow_Processor`, `tool_Aissistant`. | `[PATTERN]` |
| **Module A — identity:** keep machine keys distinct from human labels. | Overload one field for both the UI label and the reference key. | `workflowId` (`sup_crea`, used by Generator/tool) vs `workflowTitle` (`Startup Creation`, UI) vs `workflowStep` (`1- Idea`, **ignored by scripts**); `columnName` (`idea_AIstatus`) is the stable key. | `[PATTERN]` |
| **Module B — structure:** give every row an explicit **`columnType`** and branch all engine logic on it. Give every row a **`columnOrder`** so BUILD lays columns left-to-right. | Infer a column's role from a name suffix (e.g. `_AIstatus`) — implicit conventions rename-break silently. | `columnType` ∈ the **8 valid types** `{text, dropdown, formula, ai_trigger, ai_response, script_output, transfer_trigger, script_trigger}` (nothing else validates); `columnOrder` (int) consumed by `builder_Generator`. Explicit-over-implicit. | `[PATTERN]` `[AVOID]` the suffix convention |
| **Module B — one polymorphic `columnParameter`** whose format is keyed by `columnType`. | Add a physical column per possible parameter. | `formula`→template string; `ai_trigger`→`{promptColumn,responseColumn,extractColumn,postProcessor}`; `transfer_trigger`→`{sourceColumn,targetSheet,transformFunction,deleteExistingKey}`; `script_trigger`→`{helperFunction,inputColumns[],outputColumn}`; blank for `text`/`dropdown`/`ai_response`/`script_output`. | `[PATTERN]` |
| **Module B — encode statuses in `dropdownValues`** with exactly ONE `\|\|`-prefixed terminal value. | Scatter status strings across code. | `dropdownValues` e.g. `Ask AI,Processing,\|\|Done,Error`; the trigger status is the FIRST value, the `\|\|` value marks success. Paired with `validateStatusValue(...,'Ask AI')`. | `[PATTERN]` |
| **Module C — chaining/gating as data**, not control flow. | Encode step order, preconditions, or token limits as branches in the processor. | `onSuccessTrigger` (= exactly ONE `columnName` of the next trigger row) · `requiredColumns` (`["idea_Problem","idea_Solution"]`) · `executionParameters` (`{maxTokens,maxRetries}`) · `jsonValidationFields` (`["primary_persona.title"]`) — all read by `workflow_Processor`. | `[PATTERN]` |

### Two phases, one config

| DO | DO NOT | Mechanism | Reuse |
|---|---|---|---|
| Split **PHASE 1 BUILD** (config → validate → generate) from **PHASE 2 RUN** (adapter reads config → engine executes the row). | Mix sheet-construction with step-execution in one path. | BUILD chain `ConfigProvider → builder_Validator → builder_Generator` (button "Generate/Update Sheet"); RUN chain `ConfigProvider → workflow_Processor → workflow_Helpers` (per-workflow sidebar button). | `[PATTERN]` |
| **Validate the entire definition before writing any sheet.** | Generate incrementally and discover a bad config half-built. | `builder_Generator.generateSheetsByWorkflow` calls `validateAll` first and throws the aggregated error before touching a sheet. | `[PATTERN]` |

### `utility.gs` API surface (the reusable primitives)

| DO | Mechanism (`utility.gs`) | Reuse |
|---|---|---|
| Wrap the AI call in **one retry/backoff** util reading the key from Script Properties. | `callGemini(prompt, maxRetries=3, retryDelay=2000, maxTokens=8192)`: `GEMINI_API_KEY` from `PropertiesService` (throws `…not found in Script Properties`); loops with `Utilities.sleep`; returns `candidates[0].content.parts[0].text`; final `API call failed after ${n} attempts`. One hardcoded Gemini endpoint. | `[LIFT]` |
| **Guard the 50,000-char Sheets cell limit** before writing any AI output to a cell; optionally truncate. | `validateCellContent(content, truncate=false, maxChars=50000)` → `{isValid, content, message}`; `isValid:false` when over limit and `!truncate`; when `truncate`, returns `content.substring(0,max) + '\n\n... [TRUNCATED] ...'`. Sheets-specific robustness primitive with **no Part I equivalent**. | `[LIFT]` |
| **Single-active-row guard** before executing a trigger. | `validateStatusValue(sheet, columnName, workflowName, targetStatus='Ask AI', allowMultiple=false)` → `{valid,row,rows,message}`; `valid:false` if header missing, sheet `<2` rows, zero matches, or `>1` match when `!allowMultiple`. | `[LIFT]` |
| **Header-name cell I/O**, resilient to column reorder; `''` on miss (not throw). | `getCellValue/setCellValue(sheet,row,columnName,…)`, `updateStatus` (alias); row numbers 2-based. *Not for bulk loops — batch instead.* | `[LIFT]` |
| **Sheet → row-objects** keyed by trimmed headers. | `parseSheetData(sheet)`: `[]` if `<2` rows; trims headers; skips blank rows; only keys on non-empty headers. Feeds `builder_ConfigProvider`. | `[LIFT]` |
| **Tolerant, non-throwing JSON parse** of AI text. | `parseJsonSafely(text, defaultValue=null)`: extracts a ```` ```json ```` fence, strips fences, normalizes smart→straight quotes, `JSON.parse` in try/catch → `defaultValue`. | `[LIFT]` |
| **Recover JSON from mixed prose** + **safe nested read**. | `extractJsonFromMixedText(text)` (regex series, returns first substring that `JSON.parse`s, else null); `getNestedProperty(obj,'a.b.c',def='')` dot-path reduce, bails to `def` on any missing level — pairs with `jsonValidationFields`. | `[LIFT]` |

### Builder layer (BUILD) — separation of concerns

| DO | DO NOT | Mechanism | Reuse |
|---|---|---|---|
| **Cached, read-only provider** with a fatal missing-sheet error. | Let each module read `SpreadsheetApp` for config, or fail silently when the sheet is absent. | `builder_ConfigProvider.getConfigWorkflow(forceRefresh=false)` → file-scoped `_configCache`; throws `Sheet 'Config-workflow' not found…` if absent, else `parseSheetData`. | `[LIFT]` |
| **Pure validators returning `string[]`, aggregated + deduped**; empty = valid; caller halts before any write. | Throw on first error, mutate state in validation, or return a bare boolean. | `builder_Validator.validateAll` = `[...new Set([..._validateCompleteness, ..._validateColumnUniqueness, ..._validateColumnParameters, ..._validateTriggerChains])]`. | `[LIFT]` |
| **Pinpoint the exact cell** in every error. | Emit generic `invalid config`. | `_validateCompleteness`: `rowNumber = index + 2` → `Config-workflow sheet Row ${n}: Missing required value for column '${field}'.` | `[LIFT]` |
| **Type-specific param validation + cross-column type check.** | Accept any JSON blob, or validate keys without confirming referenced columns exist with the right type. | `_validateColumnParameters` builds `columnName→columnType` map; e.g. `script_trigger` needs `helperFunction`/`inputColumns[]`/`outputColumn` AND `outputColumn`'s type must be `script_output`; `transfer_trigger` needs `sourceColumn` (**not** `sourceSheet`). | `[PATTERN]` |
| **Validate every chain reference resolves to a real trigger column.** | Let `onSuccessTrigger` point at a non-existent/non-trigger column and dead-end at runtime. | `_validateTriggerChains` requires the WHOLE `onSuccessTrigger` value to be a single `columnName` ∈ `allTriggerNames` (rows typed `ai_trigger`/`transfer_trigger`/`script_trigger`). A comma-list value is **rejected** — the shipped engine has no fan-out. | `[PATTERN]` |
| **Non-destructive regen: delete old backups → rename target → create fresh**; then batch headers, format+freeze row 1, sort by `columnOrder`, trim, `flush()`. | delete-then-create (loses data on a failed build), or let backups accumulate. | `builder_Generator.generateSheetsByWorkflow` renames to `${sheet}_backup_${dd-MM-yy_HH-mm}`; sorts columns by `columnOrder`; `flush()` between structural ops. | `[LIFT]` |
| **Template→formula: resolve `{{col}}` via headerMap, wrap in `=ARRAYFORMULA(IF(ISBLANK(dep),"",…))`, leave bad placeholders visible** (`#NAME?`). | Silently swallow an unknown placeholder. `[AVOID]` — a `formula` column re-imports Part I's `#REF!` fragility; use sparingly, deliberately. | `_generateWrappedFormula`: `/\{\{([a-zA-Z0-9_]+)(?::(range))?\}\}/g`, `{{col}}→A2:A`, `{{col:range}}→A:A`; static templates returned unwrapped. | `[PATTERN]` `[AVOID]` as default |
| **Guided authoring: safe `onEdit` + template injection on `columnType` change.** | Run guidance on multi-cell pastes, throw/alert in `onEdit`, or hand-maintain a drift-prone dropdown. | `builder_Guidance.onEdit`: bail unless single cell, sheet `Config-workflow`, edited header `columnType`; whole body try/catch→`Logger.log`. `_handleColumnTypeChange` pre-fills the type's JSON template + status template + a helper dropdown `requireValueInList(Object.keys(HELPER_FUNCTIONS)).setAllowInvalid(false)`; clears params/validation on the non-guided cases. | `[LIFT]` |

### Workflow processor (RUN) — orchestrator + atomic workers

| DO | DO NOT | Mechanism | Reuse |
|---|---|---|---|
| **Orchestrator owns the chain; each worker is self-contained** (validate inputs → do task → set its own status), blind to the chain. | Let a worker know/trigger the next step. | `processWorkflowStep(stepKey)` runs the while-loop; `_executeAiWorkflow`/`_executeDataTransferWorkflow`/`_executeScriptWorkflow` each write their own `config.statusCol`. | `[PATTERN]` |
| **Dispatch through a constant map**, not a switch on type. | Hardcode per-type branching in the orchestrator. | `WORKFLOW_TYPE_HANDLERS = { ai:_executeAiWorkflow, dataTransfer:…, script:… }`; new type = one map entry + one handler (Open/Closed). | `[PATTERN]` |
| **One adapter shapes a config row → typed object**; parse JSON columns defensively there. | Parse config JSON / branch on `columnType` scattered in workers. | `_buildConfigWorkflowFromSheet(stepKey)`: find row where `columnName===stepKey`, `parseJsonSafely` on the JSON cols, `switch(columnType)` builds `baseConfig` + type-specific fields; default throws `Unhandled columnType`. | `[PATTERN]` |
| **Chain via one config column, guarded by a visited-set.** | Hardcode next step, or follow pointers with no cycle detection. | while-loop follows `config.onSuccessTrigger` (single columnName); `visitedSteps` Set throws `circular dependency…check your onSuccessTrigger`; pre-sets the next step's status before continuing. | `[PATTERN]` |
| **Status vocabulary in a constant + inline `\|\|` success marker.** | Hardcode per-step success strings where the owner can't rename them. | `STATUS = {PROCESSING:'Processing', DONE:'\|\|Done', ERROR:'Error'}`; `_getSuccessStatus(config)` = `dropdownValues.split(',').find(v=>v.startsWith('\|\|'))` stripped, default `DONE`. | `[PATTERN]` |
| **Target derived from sheet STATE, never a client arg**; mark the one row `Processing` before dispatch. | Trust a client-passed row/id; run when multiple rows carry the trigger. | Initial trigger = FIRST `dropdownValues`; `validateStatusValue` → single `activeRow` → set `PROCESSING` → dispatch. Engine is scoped to **single-row user-triggered events**; a batch variant is unbuilt — `validateStatusValue`'s `allowMultiple` is the only latent hook, extend deliberately. | `[PATTERN]` |
| **Inject domain code by name from a registry**; fatal if absent. | Call project transforms directly, or `eval` a cell. | `HELPER_FUNCTIONS` injected into every handler; workers resolve `config.postProcessor`/`transformFunction`/`helperFunction`, `typeof===function` else throw. Declare the registry with **`var`** so tests can stub it. | `[PATTERN]` |
| **Multi-row deletes iterate LAST→FIRST**; the delete is a registry helper the transfer worker injects, never inlines. | Delete rows top-down (each removal shifts every lower index → corruption / skipped rows). | `_executeDataTransferWorkflow` resolves `helpers['deleteExistingRows']` (fatal if missing) and calls it when `config.deleteExistingKey` is set; the helper walks bottom-up. Spec flags backwards-iteration a **Critical Pattern**. | `[PATTERN]` |
| **Fail-fast: validate inputs before the API call, validate `jsonValidationFields` before writing derived cells; check cell size before write.** | Call the model on an incomplete row; write half-parsed or oversized output downstream. | `_executeAiWorkflow` checks `requiredInputs`, non-empty prompt, then all `expectedJsonFields` present, then `validateCellContent` before writing `responseCol`/running `postProcessor`. | `[PATTERN]` |
| **One central error handler writes feedback into the row.** | Surface errors only in the Apps Script console. | `handleWorkflowError(sheet,config,row,error)` logs stack, derives the error status from `dropdownValues` (`find(v=>v.toLowerCase().includes('error'))` — case-insensitive), writes `statusCol`, and for `ai` steps writes into `responseCol`; sets `currentStepKey=null` and re-throws to the UI. | `[PATTERN]` |

### Shell + UI + tool registration

| DO | DO NOT | Mechanism | Reuse |
|---|---|---|---|
| **Feature-agnostic shell**: iterate a registration constant, run each tool's registration in its own try/catch, aggregate only valid ones. | Let one tool's failure blank the sidebar; edit the shell to add a feature. | `app_Shell.showSidebar()` loops `TOOL_REGISTRATION_FUNCTIONS_`, validates via `_validateToolComponent` (title string, `buttons` array, each `{label,icon,onclick}`), pushes valid; `onOpen` builds the menu in try/catch. | `[PATTERN]` |
| **Thin HTML client — all work via `google.script.run`**; JSON command dispatch, not string-eval `onclick`. | Put logic/secrets in the sidebar; build `onclick` via string interpolation. | `app_Ui.html`: one delegated `#tools-container` listener reads `data-command` (a `JSON.stringify({func,args})`), `JSON.parse` in try/catch → switch; status via `textContent`; server values `escapeHtml`'d (layered XSS defense). | `[PATTERN]` |
| **Dynamic UI generated from config each open**, stable sort, fallback error-button. | Hardcode the button list; let a config-load failure blank the panel. | `tool_Aissistant_getUiComponents()` reads `getConfigWorkflow()`, builds Build buttons from unique `{workflowId,workflowTitle}`, Runner buttons from trigger rows sorted by `workflowTitle` then `columnName`; on error returns a single error-button component. | `[PATTERN]` |
| **Server wrappers re-throw user-friendly `Error`s** so `withFailureHandler` shows a readable message. | Let a raw stack reach the owner, or swallow the error. | `tool_Aissistant_runGenerator` wraps `generateSheetsByWorkflow` try/catch → success string or `throw new Error(friendly)`; client renders `'Error: '+error.message`. | `[PATTERN]` |
| **(v2.2) Auto-discover tools by naming convention** instead of a hand-edited list. | Maintain `TOOL_REGISTRATION_FUNCTIONS_` by hand for every new tool. | `utility_Reflection.getScriptFileNames()` finds `tool_*.gs` + their `getUiComponents`; Config-UI sheet (`uiLabel,uiIcon,uiGroup,uiOrder`) drives layout. Caveat: discovery must not pull unintended functions. | `[PATTERN]` |

---

## Multi-provider API registry (user-selectable providers)

aiStrategy's `_settings_api` tab externalizes provider/model/policy as one row per provider-model.

| DO | DO NOT | Mechanism (`_settings_api` columns) | Reuse |
|---|---|---|---|
| Store **each provider-model as a row keyed by `api_id`**; pick the live one with `is_active`. | Hardcode a single endpoint/model/retry policy in code *when the founder must switch it himself*. | Rows: `api_001` OpenAI/GPT (`is_active True`), `api_002` Anthropic/Opus (`False`), `api_003` Mistral, `api_004` LinkedIn. `4_mission_report.api_id` is an FK to the chosen row. | `[LIFT]` |
| Externalize **endpoint + auth** as data. | Bake one provider's request shape into util code. | `end_Point`, `auth_Type` (`OAuth 2.0` for LinkedIn). | `[LIFT]` |
| Externalize **response shape + I/O format** as data. | Reach into `resp.choices[0]…` inline per provider. | `format_Input`/`format_Output`; `response_mapping` holds **JSONPath**, e.g. `{"content":"$.choices[0].message.content"}` and `{"content":"$.response.text"}`. | `[PATTERN]` |
| Externalize **rate-limit + error/backoff policy** as JSON. | Hardcode a per-hour cap or retry count. | `rate_Limit`, `handling_rateLimit` (JSON), `handling_error` e.g. `{"retryCount":3,"fallback":"manual_entry"}`. | `[PATTERN]` |
| Externalize **model params per row**. | Recompile to change temperature/tokens. | `ai_model`, `ai_temperature`, `ai_max_tokens`. | `[LIFT]` |
| Keep **the key in `PropertiesService`; the registry row stores only a reference.** | Put the API key in a registry cell. | A resolver fetches the key from Script Properties by name; the row carries no secret. *Grounded in GoViral `Config.secret`/`resolveAi`* — aiStrategy is formula-only (no Apps Script ships), so this is the pattern to **build**, not a file to lift. | `[PATTERN]` |
| Put **ONE wire format behind the registry** — the registry supplies params, not parallel adapters. | Build a strategy-pattern multi-provider framework. | The workbook's `_settings_api` externalizes params behind a single request shape; no per-provider adapters exist in it. | `[PATTERN]` |

**DECISION RULE (hardcode vs registry).** *Single shipped app that always calls one model → hardcode one provider in code.* GoViral `Config.resolveAi()→{baseUrl,model,keyRef}` + a curated `AI.RECOMMENDED_MODELS` short-list (exactly one `default:true`, plus a validated-paste escape hatch) already delivers *"let the founder pick a model"* **without** a registry. *Build a `_settings_api` registry ONLY when* (a) the founder genuinely selects a provider/model **per run**, or (b) you ship a **generic engine** serving many workflows. Even then: **one wire format in code**, the registry supplies `model`/`temperature`/`tokens`/`endpoint`/`response_mapping`; **never** store the key in a registry cell. Provider genericity is orthogonal to workflow genericity — parallel adapters are dead flexibility.

---

## New sheet patterns (fold into Part I sections)

Each row extends a named Part I section — drop it in there, don't create a parallel doc.

| Pattern | Extends (Part I §) | DO / mechanism | Reuse |
|---|---|---|---|
| **Two-row `[type]` annotation header** | §2 Schema & Constants | R1 tags each column with a fixed vocabulary `[UUID-PK],[UUID-FK],[text],[datalist],[AI call],[formula],[date],[number],[gSheet-only helper]`; **R2 is the canonical field name; data starts R3.** All reads/writes resolve against R2 via a `{key→index}` map; discover variable-width columns by **regex on R2** (`crit_\d+`). R1 is non-authoritative. | `[PATTERN]` |
| **`_options_list` centralized dropdown source** | §2 / §3 dropdowns | One row per list keyed `id_option/title_option`, options spread `option_1..option_15`; consumers reference by cross-ref (`='_options_list'!B5`). *Decision:* code-frozen `SCHEMA.lists`/`CONSTANTS.STATUS` for anything `===`-compared; `_options_list` sheet for **founder-curated presentation** lists (industries, sectors). | `[PATTERN]` `[AVOID]` a `===` status set living in this sheet |
| **Rules-as-data scoring** | §2 (new: Scoring) | `_scoring_criteria`: `crit_01..` rows with `importance` + `fosters_ai` → `score_ai =average(F:G)`; **row order maps by POSITION to `crit_*` columns** (discover by regex so a column move can't mis-align). `_scoring_reco`: explicit `value_min/value_max × feasibility_min/feasibility_max` bands → tier (🎯/🏃/🛠️/⏸️). Use explicit bands, **not** one implicit split-range field. | `[PATTERN]` |
| **Prompt-templates-as-config** | §7 Adapters / §2 | `_settings_outputs`: `prompt_report_system` + `prompt_report_template` with `{{COMPANY_CONTEXT}}`/`{{MISSION_JSON}}` slots + a `json_template` scaffold + `output_folder_id` + `default_language`. Trades no-redeploy prompt edits for placeholder fragility — GoViral builds prompts in code. | `[LIFT]` `[AVOID]` formula-built prompt cells |
| **Composite readable IDs vs opaque uuid** | §5 Tenancy & Data | `mis_001_func_001_dpt_001` / `strat_01_01_01` self-describe lineage. *Decision:* **opaque** `prefix+slice(uuid,12)` for **minted** entities (uniqueness under concurrent minting); **deterministic** `{parentId}_{libId}` for **imported/junction** rows (id *is* the idempotency key — dedupe with no read-back). Both pair with a denormalized name snapshot. **Generate in code, never via `ARRAYFORMULA`.** | `[PATTERN]` `[AVOID]` array-formula key generation |
| **Numbered + `_`-prefixed tab taxonomy** | §3 Sheet UI / §2 | Ordinal-prefixed pipeline tabs (`1_company → 2_mission → 3_diag_* → 4_mission_report`) encode BUILD-then-RUN order and 1:N hierarchy; **`_`-prefixed** tabs (`_settings_api`, `_scoring_*`, `_options_list`, `_lib_*`) are backend/reference. | `[PATTERN]` |

---

## Advanced services (v2 maturity — from the AIssistant V2.2 plan)

Extract these only when the engine is real; each is a reusable seam, marked **advanced** (do not front-load into a v1).

| Service | DO / mechanism | Reuse |
|---|---|---|
| **Centralized constants** | One top-level `var CONSTANTS = {…}` in `constants.gs` (no funcs, no deps), nested by concern (`SHEET_NAMES`, `COLUMN_HEADERS`, `STATUS`, `DEFAULTS`, `REGEX`, `TEMPLATES`, `ERROR_MESSAGES`, `MESSAGES`, `PROPERTIES_SERVICE_KEYS`, `BACKUP`, `CELL_MAX_CHARS:50000`), `UPPER_SNAKE_CASE`. **Migrate then delete** old per-file blocks — a half-migration re-creates the drift. Secrets: constant is the **lookup key** (`GEMINI_API_KEY`), not the value. | `[LIFT]` advanced |
| **Standardized error handling** | One `error_Handler.handleError(error, context, options)`. `context={sheet,config,row,stepKey,userMessage}`; `options={showAlert,logToConsole,updateSheet,rethrow}` (defaults true/true/true/false). Two-tier: log stack+context for devs, show `context.userMessage` to the owner. Crash-proof: its own sheet-writes/alerts each in try/catch; `getUi().alert` guarded for `onEdit` (no UI session). Parameterized `%s` templates. Surface step failures **in the row**. Inline the sheet-status write to avoid a circular dep with `utility.gs`. | `[LIFT]` advanced |
| **Automated testing framework** | Three files: `tests_assertUtils.gs` (`assertEqual`/`assertThrows`/… + a custom `AssertionError` via `Object.create`), `tests_Runner.gs` (`var TEST_FUNCTIONS=[]`, explicit `.push(testX)`, `test*` naming; `_runTest` classifies `AssertionError`→FAIL vs other→ERROR, records duration; `runAllTests()` is the manual entry point), per-module `*_tests.gs`. AAA + edge cases; mock globals by assign-then-restore; treat `SpreadsheetApp`/`UrlFetchApp` as integration. | `[LIFT]` advanced |
| **Dev logger** | `dev_debugLogger.gs`: `LOG_LEVELS={NONE:0,ERROR:1,WARN:2,INFO:3,DEBUG:4}`, gated by `DEV_LOGGER_LEVEL` in Script Properties (default INFO); `error()` always emits; objects `JSON.stringify`'d. Toggle verbosity with no code edit. **Discipline:** remove trace logs, keep `console.error` for real failures routed through `handleError`; `onEdit` errors stay silent. | `[PATTERN]` advanced |
| **Performance profiler** | `dev_performanceProfiler.gs`: `Profiler.start(label)/stop(label)` over a `_timers` map, plus `Profiler.profile(func,label,...args)` HOF that times and re-throws on error. Synchronous only; run several times (Apps Script latency variance). | `[PATTERN]` advanced |
| **Reflection utility** | `utility_Reflection.gs`: `getGlobalFunctionNames()`, `getScriptFileNames()` → dispatch by convention, replacing hand-edited `HELPER_FUNCTIONS`/`WORKFLOW_TYPE_HANDLERS`. Caveat: Apps Script reflection is limited (global-scope inspection / source parsing, not true reflection). | `[PATTERN]` advanced |
| **Caching strategy** | `cache_Service.gs`: thin `get/put/remove` over `CacheService`, used by `config_Manager` to cache parsed config. **Invalidate on config-sheet edit or TTL** — a defined bust path is mandatory (stale config is worse than slow). | `[LIFT]` advanced |
| **Generic validation service** | `validation_Service.gs`: `validateJson(data,schema)` (simplified) + `validateRequiredFields`; schemas from a `Config-ValidationSchemas` sheet via `config_Manager.getValidationSchemas()`. Don't implement full JSON-Schema for an MVP. | `[PATTERN]` advanced |
| **Generic external-API service** | `api_Service.callExternalApi(url, options)` (`{method,headers,payload,muteHttpExceptions}`), keys from Script Properties — the multi-provider generalization of `callGemini`. Tradeoff: generality over a locked-in provider's simplicity. | `[PATTERN]` advanced |
| **Centralized config manager** | `config_Manager.gs`: cached typed getters `getConfigWorkflow/getPromptsTemplates/getValidationSchemas/getColumnTypesConfig/getUiConfig`; **delete scattered readers** (`builder_ConfigProvider` becomes obsolete). Single cached authority. | `[LIFT]` advanced |
| **Data-driven config definitions** | `Config-ColumnTypes`, `Config-ValidationSchemas`, `Prompts-Templates` (prompts by ID). **Canonical vs display:** `CANONICAL_NAMES` in `constants.gs` are internal ids; `DISPLAY_NAMES` live in `Config-ColumnTypes`; `config_Manager` maps canonical→current display — the founder renames labels with zero code change. | `[PATTERN]` advanced |
| **Config-sheet backup tool** | `backup_Utility.gs`: `createSheetBackup(name)` → `name_backup_YYYYMMDD_HHMMSS`; `cleanupOldBackups(prefix, daysToKeep)` prunes by age. `builder_Generator` calls this instead of inlining backup logic. | `[LIFT]` advanced |
| **(bonus) Self-doc generator** | `dev_docGenerator.gs`: enumerate own `.gs` via the script-export endpoint, regex-parse JSDoc + signatures, write Markdown to Drive. Decoupled from BUILD/RUN. | `[PATTERN]` advanced |

---

## Reconciliations — decision rules

Each tension gets **one** crisp decision rule. Evidence leads with the aiStrategy/AIssistant contrast; the GoViral anchor is named, not re-derived (see Part I).

| Tension | Naive extreme — DO NOT | Decision rule — DO | Evidence (contrast) |
|---|---|---|---|
| **Formulas vs code** | Put scores, `VLOOKUP` joins, status mirrors, or IDs in cell formulas because they're faster to type. | **Code writes every cell any logic reads back or branches on** (status/id/timestamp/FK/next_step/score). Formulas only for pure display aggregations no code reads — and scrub any `#`-error at the AI/read boundary. | **aiStrategy LIVE (workbook):** `3_diag_strategy` R4 `response_score=#NA`; `_options_list opt_002.option_1=#NA` poisons the function dropdown; `3_diag_process` col G `=vlookup(#REF!,#REF!,3,false)`; `id_diag_process` built by `__xludf.DUMMYFUNCTION` collapses to `'COMPUTED_VALUE'` on export. AIssistant keeps `formula` a distinct `columnType` wrapped in `ARRAYFORMULA(IF(ISBLANK…))`. GoViral: no formulas (Part I §5). |
| **Single provider vs registry** | Build parallel provider adapters / strategy classes for hypothetical providers. | **One wire format in code, always.** Add a `_settings_api` registry ONLY when the founder picks per run or you ship a generic engine; key in `PropertiesService`; registry supplies params, not adapters. | AIssistant `callGemini` targets one hardcoded Gemini endpoint; aiStrategy `_settings_api` externalizes params behind a single request shape (no per-provider adapters in the workbook). GoViral `AI._fetchCompletion` posts one raw OpenAI shape (Part I §7). |
| **Frozen constants vs `_options_list` sheet** | Put a `===`-checked status set in a founder-editable sheet (silently breaks logic), or hardcode a genuinely editorial list (forces a deploy for a wording change). | **Code owns what code compares; the founder owns what the founder curates.** Status codes/transitions → deep-frozen constants; presentation lists → a sheet. | AIssistant carries `dropdownValues` inline (`Ask AI,Processing,\|\|Done,Error`, `===`-compared) vs aiStrategy `_options_list` as a cross-ref dropdown source. GoViral: `SCHEMA.lists` deep-frozen + `AI.RECOMMENDED_MODELS` curated vs `dev_models` live cache (Part I §2/§6). |
| **Opaque uuid vs composite readable id** | Give imported/junction rows random ids (forces a read-back to dedupe), or `max(id)+1`/row-count ids (collide in batch appends), or make humans read raw uuids. | **`prefix+slice(uuid,12)` for minted entities; deterministic `{parentId}_{libId}` for imported/junction rows** (id is the idempotency key — dedupe with no read-back). Always pair with a name snapshot. | aiStrategy composite `{id_mission}_{lib_id_strat_question}` is visible in the workbook and self-describes lineage. GoViral mints via `SheetIO.nextId(prefix)` + name snapshot, dedupes on the external natural key (Part I §5). |
| **Menu-driven single-tool vs config-driven engine** | Ship a config engine for one workflow (engine overhead + second SSOT), or stay coded when the founder must author many. | **v1 hardcoded for one stable workflow; promote to v2 when workflow-count × churn makes each new one a code change.** A v2 engine MUST add a runtime `validateAll` gate + guided authoring — the config sheet is now code. | AIssistant gates every `generateSheetsByWorkflow` with `validateAll` + `builder_Guidance.onEdit` template injection; aiStrategy ships **no** runtime validator and pays with live `#REF!`. GoViral: hardcoded, new workflow = code change (Part I). |

---

## Use-case catalog (what the engine can build)

The six levels the `Config-workflow` engine covers (Appendix D) — map the founder's ask to a level, then lift that spine.

**⚠ Appendix D configs are illustrative capability sketches, NOT validator-conformant.** Several use keys/types the shipped V2.1 engine rejects: `functionName`→must be `helperFunction`; `sourceSheet`→must be `sourceColumn`; `timestamp`/`number`/`date` columnTypes are outside the 8 valid types; a comma-list `onSuccessTrigger` and a `triggerCondition` column do not exist in the engine. **Re-encode any lifted spine to the 8 valid `columnType`s + a single-columnName `onSuccessTrigger` before `validateAll`, or the build fails before a sheet is written.**

| Level | Example | What it needs from the engine |
|---|---|---|
| **1 · Atomic single-step** | Startup idea generator: `ai_prompt → ai_response`. | One `columnType` executor (`ai_trigger`); `Ask AI` status trigger; `parseJsonSafely`. |
| **2 · Linear pipeline** | Research → Summary; Content → Translation. | `onSuccessTrigger` chaining (one next columnName per step); the next step's prompt reads the prior step's response cell. |
| **3 · Branching / conditional** | Content Approval (`Approved`/`Needs Revision`/`Rejected`); Lead Qualification fan-out. | **Not shipped in V2.1** — `_validateTriggerChains` allows only ONE next columnName and there is no `triggerCondition` column. Achieve branching today with a **human dropdown as the branch selector** feeding distinct downstream trigger rows; true auto fan-out is an engine extension. |
| **4 · Multi-sheet** | Project Planner (`task_list → 2-Tasks` via `parseTasks → 3-Team`); Customer Journey (4 stage sheets). | `transfer_trigger` + `transformFunction` (one-to-many row explosion, `deleteExistingRows` bottom-up on rerun); one sheet per stage. Cross-sheet rollups carry `#REF!` risk — `[AVOID]` volatile funcs (`RANDBETWEEN`). |
| **5 · Orchestrated** | Campaign builder with analytics + ROI. | Chained AI + `script_trigger` helpers; **prototype-with-placeholders** (mock formula columns) then harden each to a real helper before shipping. |
| **6 · External integration** | CRM Sync: `sync_status` `script_trigger`. | A `script_trigger` whose `columnParameter` carries `helperFunction`+`inputColumns`+`outputColumn` (the endpoint lives inside the helper); a `transfer_trigger`-written **log sheet**; a **mirror sheet** for conflict detection; a change-detection column (typed `text`, not `timestamp`). |

---

## Kickoff addendum

Extra ordered steps that wrap Part I's 13-step checklist. **Step 0 precedes Part I step 1.**

0. **Decide the maturity rung FIRST** (Ladder triggers: distinct-workflows × edit-frequency × who-edits). This gates everything below.
1. **If v0 (formula prototype):** stop at Part I steps 1–4 (founder artifacts) to prove the schema/DAG — but **before shipping, convert every derived cell to code** and log the formula scaffold as tech debt with a code-writes-every-cell migration target. Never let code read a formula cell.
2. **If v1 (coded single-tool):** run Part I steps 1–13 verbatim; **hardcode the one provider** (`Config.resolveAi` + a curated model short-list — no registry).
3. **If v2 (config engine, and only if the founder authors many workflows himself):** after Part I step 6, additionally —
   a. Scaffold the **`Config-workflow`** driver sheet: `workflowId`, `workflowTitle`, `sheetName`, `columnName`, `columnType`, `columnOrder`, `columnParameter`, `dropdownValues`, `onSuccessTrigger`, `requiredColumns`, `executionParameters`, `jsonValidationFields`. (`columnOrder` is required — `builder_Generator` sorts columns by it.)
   b. Lift the **`utility.gs`** API (`callGemini`, `validateCellContent`, `validateStatusValue`, `getCellValue/setCellValue`, `parseSheetData`, `parseJsonSafely`, `extractJsonFromMixedText`, `getNestedProperty`).
   c. Split the **BUILD** layer (`builder_ConfigProvider` cached provider, `builder_Validator.validateAll`, `builder_Generator` backup-then-replace, `builder_Guidance` onEdit templates) from the **RUN** layer (`workflow_Processor` orchestrator + `WORKFLOW_TYPE_HANDLERS` + `_buildConfigWorkflowFromSheet` adapter + visited-set chain guard).
   d. Add the **`HELPER_FUNCTIONS`** registry (declared `var` for test stubbing; dropdown sourced from `Object.keys`; include `deleteExistingRows`/`insertRows` for transfers — delete bottom-up).
   e. Wire `app_Shell`/`app_Ui`/`tool_Aissistant` with the thin-client + JSON `data-command` dispatch (and, at v2.2, `utility_Reflection` auto-discovery).
   f. **Pay the second-SSOT tax:** `builder_Validator.validateAll` must gate every `generateSheetsByWorkflow`, and `builder_Guidance.onEdit` must inject the type templates + `Ask AI,Processing,\|\|Done,Error` status template.
4. **If providers are user-selectable per run:** scaffold **`_settings_api`**, keep the key in Script Properties, and keep **one wire format** behind it (params only, no parallel adapters).
5. **If the founder needs a field-type annotation or curated lists:** add the R1 **`[type]`** row (R2 canonical, discover variable-width by regex) and an **`_options_list`** tab — but keep every `===`-compared status set in frozen constants, never in the sheet.
6. **Reconfirm before first RUN:** on a fresh workbook, run the validator, then `generateSheetsByWorkflow` once and confirm idempotence; hand to the founder for live validation before the next objective (Part I *done = owner-validated*).

---

## Appendix — Available libraries (catalog only)

The two `:run` links resolve to the **"AyS Scripts" ecosystem** — a *general-purpose* reusable-scripts system, **separate from the AIssistant AI-workflow engine**. Catalogued here (names + one line) per owner decision; **not** mined for patterns. Reuse by adding the library (`AysLib`, id `1xBG8Ku98P4WYhAinaKtKbGal5d9cTgv0D0sC3VkmIGluv0DPZvaacQam`) or the add-on, then calling the function — do not re-implement.

**`ays_AllScripts` (`AysLib`) — 25-file personal utility library.** Signature hits confirm it is utility code (`UrlFetchApp`, `openai`, `Ask AI`), not the engine (no `Config-workflow`/`builder_*`/`workflow_Processor`).

| Function / file | One-line | Overlaps a Part I/II pattern? |
|---|---|---|
| `textInSheet_code` + `_UI` + `_Specification` | Write-in-cell long-text editor (menu → active cell in a textarea → save back). | = Part I §4 write-in-cell / AIssistant TextInSheet — a shipped implementation. |
| `dependant_validation` | Cascading / dependent dropdowns (child list narrows from parent choice). | **New** — not in Part I; worth lifting if you build hierarchical pickers. |
| `sheetAsApi_GET` / `sheetAsApi_POST` | Expose a sheet as a REST endpoint via `doGet`/`doPost`. | **New** — a v2 deployment surface Part I deliberately omits. |
| `askAi_anyPrompt` | Generic one-shot AI prompt call. | = utility.gs `callGemini`, provider-generic. |
| `uniqueId` | Generate a unique ID. | = `SheetIO.nextId` (Part I §5). |
| `json_import` | Import/parse JSON into the sheet. | supports the config-as-JSON patterns. |
| `url_findHyperlink` | Extract the hyperlink target behind a cell's display text. | niche sheet helper. |
| `namedRange_code` + `_sidebar` | Named-range manager (create/list/navigate) with a sidebar (largest module, ~60K). | niche; sidebar UI (contrast Part I's retired-sidebar note). |
| `exportWkbk_csvCode` + `_csvForm` | Export workbook tabs to CSV. | = Part II "config-sheet backup" cousin. |
| `profile_emailFormat` / `profile_emailDomainCheck` / `profile_linkedinUrl` / `profile_Gender` | Contact-data validators/normalizers (email format, domain check, LinkedIn URL, gender inference). | domain enrichment helpers. |
| `cy_sirenAllInfo` / `cy_functionsToInfo` | French company (SIREN) enrichment lookups. | `[SKIP]` FR-specific. |
| `n8n_icpVp` / `n8n_webhookScheduler` | n8n webhook callers (ICP/value-prop; scheduled webhook trigger). | = Part I "offload complexity to n8n" boundary. |
| `checkiFrame` | iframe embeddability check. | niche. |

**`AyS_AddOn_Library` / `scriptsKit- AddOn` — universal launcher add-on** (skeleton stage): detects host app (`SHEET`/`DOC`/`SLIDE` via `core_getHostApp`), shows a **checkbox sidebar** to pick which library scripts run, stores the selection in `DocumentProperties`, and installs an `onOpen` trigger to auto-run them. Depends on `AysLib`. *Note:* its checkbox-sidebar activation is the opposite of Part I §8's "compute the actionable set server-side, retire the checkbox UI" lesson — fine for a generic script launcher, **not** a model for an operator workflow tool.
