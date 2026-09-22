# Converter coverage fix plan — recover-most-first

## STATUS: all 6 fixes landed ✅ (2026-08-13)
Files converting (≥1 kept decl): **42 → 77 (+83%)** across the 203-record dataset.
Per-code eliminations: E7233 24→0, E7231 13→0, async(E7205) 23→0, E7201 48→0, TSEnum 4→0, E7208 17→0.
E7232 26→6 (rest/nested kept fail-closed). E7221 (ComponentProps) intentionally left rejected — needs real field names.
Full suite: **`jac test tests/compiler/js2jac/` → 231 passed.** 3 pre-existing v1 tests updated to the new
(intended) behavior; 1 real latent soundness bug fixed en route (computed member access on a lowered-away
React namespace emitted a dangling `React` ref → now E7214). See git diff for the test deltas.

---


Source of numbers: re-ran all 203 dataset records through `parser_bridge` + `convertEnvelope(failOpen)`
and tallied `skipReasons` / `skipDetails`. 200 parsed, 3 parse-fails. **284 declaration-drops total.**
File under work: `jaseci/jac/jaclang/compiler/js2jac/convert_bridge.mjs`.

Guiding rule: most loss is a narrow whitelist + all-or-nothing blast radius (one unknown node sinks the
whole declaration). Widen the whitelist; do NOT chase the CSS-in-JS ceiling.

## Order (recover-most-first, risk-weighted)

### Fix 1 — Helper return-type inference (E7233, 24 drops / 14 files) — ✅ DONE
Change landed @2748–2754: `retType = inferReturnTypeFromBody(...) ?? "any"`. E7233 removed from histogram
(24→0 drops); files converting rose 42→50. Tests added to `tests/compiler/js2jac/test_emit_v2.jac`
(non-inferable helper → `-> any`, exported call-return → `-> any`, literal-inference guard). `jac test`: 25 passed.

Original detail:
- Site: `parseHelperFunction` @ 2712; reject @ **2751** (`Helper '…' needs a return type annotation`).
- Today: a plain helper `function f(x){...}` with no explicit return type → dropped.
- Change: when no annotation and no literal/JSX return to infer from, default the return type to `any`
  instead of rejecting. Gate behind fail-open so strict mode stays byte-identical.
- Risk: low. Effort: ~1 fn. Recovers helper/util modules wholesale.

### Fix 2 — Destructuring lowering (E7231+E7232+E7204, 39 drops / ~30 files)
- Sites:
  - Var decls `const {a}=…` / `const [a,b]=…`: reject @ **1448** (E7231).
  - Helper params `({id}) =>`: `parseHelperFunction` param loop, reject @ **2730** (E7232 ObjectPattern), rest @ 2727.
  - Component props destructure: `parseComponentParam` @ 1069; E7204 cluster @ **897–990** (nested/rename/rest still hard).
- Change: lower object/array patterns to explicit binds (`{a,b}=e` → `a=e.a; b=e.b`; `[x,y]=e` → indexed).
  Start with the flat, non-rename, non-nested case — that is the bulk of the 39.
- Risk: medium (name-collision + eval-order). Effort: one shared `lowerPattern` helper reused by all 3 sites.
- Note: this is also the mechanism the hooks slice needs for `const [pop,{stop}]=useSound()`.

### Fix 3 — Async functions (E7205 · async, ~23 drops)
- Sites: `parseHelperFunction` reject @ **2786**; `parseArrowComponent` reject @ **2987**. (Expression-level
  async/await also blocked @ 1773 — separate, deeper; leave for later.)
- Change: allow `async` on top-level function/arrow decls and emit the Jac async form; keep `await`
  handling scoped to what the expression emitter already supports, else fail-open just that statement.
- Value: highest — this is the server-route / data-fetch logic. Risk: medium (needs await lowering).

### Fix 4 — TS type coverage (E7201 + E7221, 78 drops / ~40 files) — biggest count, highest blast radius
- Sites: `tsTypeToJac` @ 348 (E7201 unsupported types @ **423–450**: `any`, generic refs `T`, `AbortSignal`);
  `resolvePropsTypeAnnotation` @ 266 + `formatTsTypeRefName` @ 150 (E7221: `React.ComponentProps<…>` @ 28,
  intersection types @ ~5).
- Change, staged:
  - `TSAnyKeyword` → Jac `any` (6, trivial).
  - Bare type references / generics → `any` fallback under fail-open instead of hard reject (recovers most).
  - `React.ComponentProps<T>` → resolve to `any`/props object when the ref can't be modeled (28).
- Risk: low-medium if the fallback is `any`; do NOT try to fully model generics. Effort: largest surface.

### Fix 5 — Non-arrow const initializers (E7205 · object/enum, ~16 drops)
- Site: export-const handler / `parseArrowComponent` guard, reject @ **2983** (`must initialize to arrow/forwardRef/memo`).
- Change: allow `export const X = {…}` (ObjectExpression, 12) → emit as a `glob` dict; allow top-level
  `enum` (TSEnumDeclaration, 4) → the enum path that already works for imported enums.
- Skip the factory-call inits (`z(...)`, `atom()`, `cva()`, ~21) — those are library-specific, case-by-case.
- Risk: low. Effort: small.

### Fix 6 — Third-party hooks (E7208, 14 drops) — known, separate slice
- Sites: `SUPPORTED_HOOKS`/`INTEROP_HOOKS` @ 107–108; catch-all bug @ **2104** (`/^use[A-Z]/` treats every
  `useX` as React-core); reject @ 2438–2452.
- Change: provenance-aware classification (react vs npm vs local); non-React `useX` → pass through as a
  normal interop call. Depends on Fix 2 for `const [a,{b}]=useSound()`.
- Risk: medium. Covered in `runs/richer_jac_input_brief.md` §3A.

## Leave alone (ceiling)
- CSS-in-JS `styled`/`css`/`keyframes` (~56, E7205 tagged) + tagged templates (E7215). Tailwind `className`
  already survives verbatim. Not worth converter work.
- 3 parse-fails (`states/*State.ts`) — experimental syntax (likely decorators) needs a babel plugin flag in
  `parser_bridge.mjs:108`, not converter work. Cheap if wanted.

## Expected recovery
Fixes 1–4 ≈ **160 / 284 drops (~56%)**, and they recover the non-trivial code (typed components, async data
logic, destructured handlers) — i.e. they raise training-data *value*, not just quantity.

## Cross-cutting: shrink the blast radius — ✅ DONE (2026-08-13, statement-level fail-open)
Today one unsupported node dropped the whole top-level declaration. Added a **statement-level fail-open**
(helpers only, opt-in via `payload.stmtFailOpen`, defaults to `failOpen`): drop the one bad statement, keep
the rest of the function, record it in a ledger.

Where: `emitBlockFailOpen()` in `convert_bridge.mjs`, wired into the `emitStatement` BlockStatement branch and
the `parseHelperFunction` body loop; `failOpen` threaded through `parseFunction`/`parseArrowComponent`.
Component bodies (`parseComponentBody`) stay fail-closed — their ctx never sets `failOpen`.

Soundness (the whole point — must not flip a jac-check-PASSING file to failing):
- A kept statement referencing a dropped binding is dropped transitively (fixpoint over the block), so no
  emitted Jac dangles. Over-approximated refs (`collectReferencedNames`) only ever err toward dropping.
- Dropping a statement that carries a `return` would leave a typed fn without a return on that path → **bail**
  to the coarser decl-level drop (`containsReturn`).
- A body that *had* statements but ends up fully emptied → bail (a hollow husk is misleading). A genuinely
  empty body (`export async function POST(){}`) is valid Jac and emitted as-is (matching strict mode).
- Only helpers; block-scoped binds inside nested if/loop bodies never escape, so `boundSiblingNames` only
  tracks top-level `const`/`let`/fn-decl names.

Ledger: kept decls carry `droppedStatements`; the envelope reports `stmtDrops`/`stmtDropCount` and emits a
`js.stmt.fail-open.v1` (`rejected`) mapping per drop (registered in `mapping_rules.json`).

Measured on the 203-record dataset via **whole-file `jac check`** (the real validate.py gate), fail-open both
modes, A/B on `stmtFailOpen`:
- Files passing the jac-check gate: **67 → 69 (+2)**, **0 regressions**.
- 8 statements dropped across 6 files (E7215×5, E7214, E7230, transitive×1); 2 of those files newly pass the
  gate (`useHotRecipes`, `useParticipants`), the rest were already passing (drop just enriched the body) or
  fail for pre-existing undiagnosed-expression reasons (`.toFixed`/`.toLocaleString` → E1030, `-> None`
  returning str) that the downstream gate correctly filters — those were never passing, so not regressions.
- Full suite `jac test tests/compiler/js2jac/`: still green (strict mode is byte-identical — `stmtFailOpen`
  is inert unless `failOpen` is on).

Probe: `scripts/js2jac_dataset/source/dataset_probe.mjs` (fast, no cloning — runs the real bridge over the
dataset jsonl; `STMT=0` toggles the feature off for A/B).

Honest ceiling: the +2 gate metric undercounts value — statement drops also enrich bodies inside
already-passing files (more faithful content for the LLM idiomize pass), which the file-pass count can't see.
The remaining ON-mode jac-check failures are pre-existing expression-emission gaps (`.toFixed` et al.
emitted without a diagnostic), independent of this change.

## Round 2: the bigger decl/signature-level levers — ✅ DONE (2026-08-13)
Statement fail-open turned out to be a NARROW slice: on 41 real cloned React repos it recovered only +52
declarations, because the mass of loss is decl/signature-level, not statement-level. Probing `decl_wall_detail`
on the cloned corpus (wall_probe, 2068 files) showed the true wall ranking:
`E7205 ExpressionStatement top-level 557 · E7221 ComponentProps/HTMLAttributes/intersection/qualified ~700 ·
re-export/export-* ~540 · "Components must be exported" 180 · export-const non-arrow inits ~250`.

Two of those are cheap and sound, both **gated behind fail-open** (strict mode byte-identical):

### Lever A — non-exported (local) components → private `def`
`emitComponent` already handled `exported===false` (rule `js.function.component.v2`); the two guards at
`parseFunction`/`parseArrowComponent` just blocked it. Under fail-open they now emit a private
`def NAME -> JsxElement`. Recovers the local component AND un-drops helpers/components referencing it.

### Lever B — unmodelable props types → `any` (E7221 widening)
`React.ComponentProps<...>` / `HTMLAttributes` / intersection / qualified props refs can't resolve to field
names. Under fail-open: an identifier props bag widens to `props: any` (`.field` on `any` type-checks — verified
against `jac check`); a *flat* (no-rest) destructure takes its prop names from the pattern and widens their types
to `any` (`namedParamsFromPattern`). Rest-spread (`{...props}`) still fails closed — it can't be decomposed
(the existing Stage-B boundary test still holds).

**Cumulative measured on 41 real cloned React repos (wall_probe, `stmtFailOpen` on):**
- kept declarations **1,134 → 1,267 (+133, +11.7%)** — stmt fail-open +52, non-exported +66, E7221 widen +15.
- files converting (≥1 decl) **619 → 658 (+39)**; files yielding zero **1,411 → 1,372**.
- E7221 walls **806 → 649 (−177)**; ComponentProps detail 422 → 364 (remainder = rest-spread, correctly kept).

**Curated 203-set whole-file `jac check` gate: 67 (decl-level baseline) → 72 passing, 0 regressions.**
Full suite `jac test tests/compiler/js2jac/` green (+5 new fail-open tests: stmt recovery + return-bail,
non-exported private def, ComponentProps→`any` bag, flat-destructure→named-`any`).

Next levers (unaddressed, by count): re-export/`export *` barrel lowering (~540), `export const` non-arrow
factory inits minus CSS-in-JS (~250), and the undiagnosed expression-emission gaps (`.toFixed`/`.length` emit
invalid Jac silently) that cap several still-failing files.

## Round 3 — Lever C: re-export / barrel-file lowering — ✅ DONE (2026-08-13)
Barrel files (`export { A } from './m'`, `export * from './m'`, `export * as ns`, `export { default as X }`)
carried NO local declaration, so every re-export sank on E7205 and a pure barrel `index.ts` yielded zero
declarations (E7200, whole file lost). These lower cleanly to Jac imports:
- `export { A, B as C } from './m'` → `import from "./m" { A, B as C }`
- `export * from './m'` → `import from "./m" { * }`  ·  `export * as ns from './m'` → `import from "./m" { * as ns }`
- `export { default as X } from './m'` → `import from "./m" { default as X }`

Where: `lowerReExport()` in `convert_bridge.mjs`; wired into the ExportNamedDeclaration-no-decl branch and a new
ExportAllDeclaration branch of the main loop; lines collected in `reExportLines`, appended to `importLines`.
The `!kept.length` guard now also succeeds when `reExportLines.length` (a pure barrel emits an import-only
file). Re-exported names are added to `publicNames` so cross-file importers still resolve them. All **gated
behind fail-open** — strict keeps E7205 byte-identical. Rule `js.module.reexport.v1` (`interop`) registered.

Soundness verified END-TO-END (not just convertEnvelope ok): a real-repo gate (`gate_barrel.mjs`) clones repos,
emits every pure-barrel file, and runs actual `jac check` — **16/16 pure barrels PASS, 0 fail**. All five
specifier shapes + duplicate-source imports (`export {A} from './x'; export {B} from './x'`) + a re-export name
colliding with a local decl all pass `jac check` manually.

Measured on 28 real cloned React repos (wall_probe): **308 re-exports lowered across 93 files; all 93 were
pure barrels that previously yielded ZERO declarations** — i.e. **+93 whole files newly converting** (they move
from `files_no_decl` into `files_clean`). This is the largest single file-count recovery so far (statement
fail-open +2 files, non-exported/E7221 +39 files on 41 repos; this +93 files on 28 repos).

Tests: 4 new in `test_emit_v2.jac` (mixed barrel with all 5 forms + co-located local decl; pure zero-decl
barrel; strict still rejects with E7205). Full v2 file **51 passed**.

## Round 3 — Lever D: factory-call const globals — ❌ TRIED, REVERTED as UNSOUND (2026-08-13)
Attempted to loosen `isModuleGlobalInit` under fail-open to allow `export const x = factory(...)`
(`z.object(...)`, `cva(...)`, `createContext(...)`) → `glob x = ...`, keeping CSS-in-JS
(`styled.div`...`` = TaggedTemplate) rejected. wall_probe looked spectacular: **+297 kept declarations,
−290 E7205 walls, +99 files converting on 28 repos** — the biggest count lever by far.

It was a MIRAGE. wall_probe never runs `jac check`. A real end-to-end gate (`gate_all.mjs`: clone → emit →
actual `jac check`) showed **31 / 88 factory-const emissions FAIL jac check (35%)**:
- E1032 / E1030 — member access on an Unknown-typed base (`React.createContext` where the React namespace
  is lowered away, `window.require`, `import.meta.env`). emitExpr yields valid *syntax*; the type checker
  rejects it. The `probe.length===0` guard in `parseModuleGlobal` cannot see this — it only catches emit-time
  diags, not checker-time type errors.
- E0105 `$` — an emitExpr template-literal bug this lever newly exposed.
- E0024 — a glob named `root`/`window` colliding with a Jac builtin.

Because the gate is WHOLE-FILE, each unsound glob sinks the entire file — including files that converted fine
before (factory const previously dropped, other decls kept). So the lever causes **whole-file regressions**;
the +297 is negative once measured honestly. A sound version needs the Jac type checker in the emit loop, not
a static shape gate — out of scope. Reverted `isModuleGlobalInit`/`parseModuleGlobal` to byte-identical;
kept one test asserting factory-call consts stay rejected in BOTH modes.

Lesson (recorded): wall_probe's kept-decl count is an UPPER BOUND, not yield. Any new emit lever must be gated
on real `jac check`, not `convertEnvelope.ok`. Lever C (re-export) passed that bar (16/16); Lever D did not.

## Round 3 — Lever E: expression-emission soundness (`.length`/`.toString`/no-Jac methods) — ✅ DONE (2026-08-13)
The undiagnosed-expression gaps: emitExpr silently produced Jac the type checker then rejects, sinking whole
files. Fixed the concrete ones (apply in BOTH modes — genuine emit correctness, not a fail-open feature):
- **`.length` → `len(...)`** in `emitMemberAccess` — raw `.length` is E1030 (list/str has no attribute length);
  `.length` is never a JS method call, so the read-only rewrite is unambiguous (verified `len()` passes, raw
  fails). Works in statement and JSX-interpolation contexts.
- **`x.toString()` → `str(x)`** (no-arg form only; a radix arg falls through to diagnose) in
  `tryEmitJacNativeCall`. Verified `str()` passes jac check.
- **No-Jac-equivalent number/locale methods DIAGNOSED** (`toFixed`/`toPrecision`/`toExponential`/
  `toLocaleString`/`toLocaleDateString`/`toLocaleTimeString`) — set `JS_UNSUPPORTED_NUMBER_METHODS`; push
  E7215 so fail-open drops just that expression/statement instead of emitting checker-failing Jac. In a helper
  body under statement fail-open the bad statement drops and the rest is kept; in a component body (fail-closed)
  the decl drops — either way no more silently-broken whole-file emission.

The `template-$` case turned out to be a non-issue (a plain `$` in a Jac f-string passes; the earlier E0105 was
tied to the reverted factory lever's tagged templates).

Measured **whole-file `jac check` gate on the 203-set: 72 → 73 (+1, 0 regressions)** — the curated set has few
`.length`/`.toFixed` blockers so the file-count move is small, but it is strictly sound-positive. On 28 cloned
repos: 29 statement-drops now enrich 18 files, and wall_probe kept-decls dipped 719→712 (−7) — those 7 were
components emitting broken `.toFixed` Jac that wall_probe counted as "kept" but would fail `jac check`; they now
gate correctly (wall_probe over-counts broken emissions — the whole-file gate is the truth). Full suite green
(+2 tests: len/str lowering, toFixed statement-drop).

Still-failing 203-set files (12) are the remaining expr gap: **JS type-coercing `+`** (`str + int`, E1055) that
Jac rejects — a real semantic gap, separate lever. Next: model `+` coercion (wrap numeric operands in `str()`
when either side is a string) or diagnose it; then a checker-gated factory-const retry.

## Round 4 — hole-emission mode for an LLM-cleanup pass — ✅ PROTOTYPE LANDED (2026-08-13)
Strategy shift: stop trying to *soundly lower* every construct (CSS-in-JS, arbitrary factory calls, cross-file
value sharing are genuine CEILINGS). Instead, for the unmodelable ones, emit a HOLE instead of dropping — the
converter does the structural heavy lifting (imports, signatures, control flow, `len()`/`str()` lowering) and a
downstream LLM patches the marked gaps. The gate stays: `convert (lossy, holes) -> LLM patch -> jac check ->
keep only passing`. The LLM raises pre-gate yield; the jac-check gate still guarantees corpus quality.

Impl (`convert_bridge.mjs`, gated behind new `emitHoles` payload flag; needs `source` to slice node ranges):
- module-scoped `HOLE_CTX` (per-file reset, mirrors `REACT_NAMESPACE_LOCALS`); helpers `holeSourceOf`
  (slice by `node.range`) + `holeCommentLines` (`# JS2JAC-HOLE[code] msg:` + `# | <original js>` gutter).
- **statement holes** — `emitBlockFailOpen` leaves the dropped stmt's JS inline as a comment (binds nothing,
  so transitive-drop of dependents is unchanged; file soundness unaffected — comments never parse-break).
- **decl holes** — skipped top-level decls collected in `declHoles`, appended as a trailing
  `# ===== JS2JAC UNCONVERTED (N decl(s), needs LLM) =====` block so the LLM sees whole-file intent.
- Threaded through the Jac pipeline: `ConversionConfig.emit_holes` -> `convert_envelope` -> payload
  `{emitHoles, source}`. Default off -> byte-identical (verified `off === default`, hole output passes
  `jac check`).

Measured (10 cloned repos, 447 files): of **138 files that convert, 78 (57%) carry ≥1 hole** — i.e. more than
half of converting files are PARTIAL (scaffold + inline original-JS holes), the high-value LLM-patchable class.
The other 43% convert clean (no holes); the ~309 zero-decl files still return ok:false (no scaffold -> hole mode
deliberately doesn't help them; those would be full LLM translation, low converter value). Full suite green
(+3 tests: stmt+decl holes present, scaffold kept, holes inert when off).

Next: wire `strip_policy.json` `faithful_mode` to flip drop->hole per E-code; feed the ledger
(`skipDetails`/`droppedStatements`) to the LLM prompt; re-gate LLM output. Then the `+`-coercion expr lever.

## Round 4b — LLM patch-and-regate loop, RUN (2026-08-13)
Built `scripts/js2jac_holepatch.py` (+ `holeconvert.mjs` bun driver): convert with holes -> `opencode run -m
<model>` fills the holes from the original JS -> `jac check` re-gate, keep only passing. Model:
`opencode/deepseek-v4-flash-free`. Two pilots, both measured by whole-file `jac check`:

**Pilot A — enrichment (curated 203-set, holes in otherwise-passing files, base=True):** 12 hole-carrying files,
LLM produced output for 11, **all 11 completions re-gate GREEN (100%)**; 1 timeout (an 8-hole file, 240s cap).
So on easy holes the loop reliably ADDS the dropped content back and stays sound.

**Pilot B — rescue (raw-repo files that FAIL jac-check as-is, base=False):** 12 candidates -> **only 1/12
rescued** to passing; 9 still-fail, 2 timeout. Failure codes dominated by **E1032 (15) + E1030 (4) = member
access on Unknown-typed unresolved imports** (`node:fs`, `process`, third-party libs) — the SAME wall the
factory-const lever hit, a Jac type-system property the LLM cannot write around. Plus E0002 ×4 (free-model Jac
syntax slips) and 2 timeouts.

**Decisive finding: LLM cleanup is an ENRICHMENT multiplier, not a RESCUE multiplier.** It reliably improves the
faithfulness of files that ALREADY gate (adds back dropped statements/decls -> better training pairs), but it
does NOT lift the mass of non-gating files over the bar, because their blocker is unresolved-import Unknown
types, not missing code the model can supply. The jac-check gate correctly rejected every bad LLM emission (0
unsound files entered the corpus). Levers to raise rescue: (a) stronger/faster model than deepseek-flash-free
(would fix the E0002 syntax + timeouts, maybe some E1032 via `any`-cast discipline); (b) ambient/stub `any`
typings for common Node/lib imports so member access resolves — this attacks E1032 at the root and would ALSO
unblock a checker-gated factory-const retry. Artifacts: `archive/2026-09/scratch/holepatch_pilot.jsonl` (enrichment),
`archive/2026-09/scratch/holepatch_rescue.jsonl` (rescue).
