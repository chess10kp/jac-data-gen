# Richer Jac Data Input — design brief (input for gpt-5.6-sol)

## 1. What we have today

Two-stage JS/TS → Jac translation pipeline:
1. **Deterministic converter** `jaclang/compiler/js2jac/convert_bridge.mjs` (rule-based AST translator, NOT an LLM) → emits a "FLOOR" Jac file.
2. **LLM cleanup pass** `js2jac_composer_batch.py` driven by `strip_policy.json` → final Jac or `REJECT`.

One knob switches datasets: `--faithful`.
- **SYNTAX mode** (default): strip lossy constructs, keep the file → surface-syntax dataset.
- **FAITHFUL mode** (`--faithful`): promote every `fidelity:"lossy"` policy entry to REJECT → round-trip dataset.

The file under review, `js2jac_dataset_idiom.jsonl` (195 records), is **SYNTAX-mode** output.

## 2. The measured problem (drop analysis on the 195-record file)

Dropped imported identifiers fall into three buckets:

| Bucket | Examples | Verdict |
|---|---|---|
| **By-design transform (CORRECT, not a drop)** | `useState`→`has`, `useRef`→`Ref`, `useEffect`→`can with entry`; `useMemo`/`useCallback` interop; `React` namespace consumed | Working as intended |
| **Documented ceiling (CSS-in-JS)** | `styled`, `media`, `pxToRem`, `css`, `makeStyles` | Stripped. **Tailwind `className` strings are already preserved verbatim** (see BuyQuantity.tsx). Jac has native Tailwind support. |
| **Genuine behavioral loss (~107/195 records)** | `prisma`/`db`, `eq`/`and` (Drizzle), `NextResponse`/`revalidatePath`, `useSound`/`useStore`, `authenticatedActionClient` | Real behavior vanishes |

Converter hook support (`convert_bridge.mjs:107-108`):
```js
const SUPPORTED_HOOKS = new Set(["useState","useRef","useEffect"]);   // native lowering
const INTEROP_HOOKS   = new Set(["useMemo","useCallback"]);           // preserved as call
// everything else -> E7208, fail-closed
```

## 3. Two policy reversals the user wants

### A. Keep third-party hooks (do NOT E7208-strip them)
Today any hook outside the 5 above is rejected (E7208 → strip in SYNTAX, reject in FAITHFUL). The user states **Jac supports third-party hooks** and wants them kept. Proposed mechanism: emit them through Jac client JS interop (`jac_read_jac_cl_js_interop`, the `new()` / npm-import idiom) rather than stripping.
**To verify:** the exact idiomatic Jac for calling a third-party React hook (e.g. `useSound` from `use-sound`, `useStore` from zustand) from client Jac. Use the `jac` MCP tool `jac_read_jac_cl_js_interop` if available; otherwise state the assumption clearly.

### B. Map the DB / ORM layer to Jac's graph model (do NOT strip)
**Confirmed from Jac source-of-truth** (`jac_read_jac_sv_persistence`, `jac_read_jac_node_edge_patterns`):
- **The graph IS the database.** Prisma `model User {…}` → Jac `node User { has … }`. Prisma relations → Jac typed `edge` archetypes. Prisma queries → graph traversals. Writes persist automatically.
- Concrete mappings:
  - `prisma.user.findUnique({where:{id}})` → `u = jobj(id); if isinstance(u, User) { … }` (O(1)) or `[root-->][?:User][?jid(self)==id]`.
  - `prisma.post.findMany({where:{author}})` → `[root-->][?:Post][?author==x]`.
  - Relations / `include` → typed-edge traversal `[u ->:Wrote:->][?:Post]`.
  - Aggregates → `len([root-->][?:Post])`.
- The **authoritative data-model source is `schema.prisma`** (or Drizzle table defs). Convert THAT into `node`/`edge` archetypes, then rewrite query call-sites against those archetypes.

## 4. Concrete records in the dataset

- `bitcraft3r__0xVenture-Capitalist::api/admin/reset/[requesterId]/route.ts` — Prisma `findUnique` + `NextResponse`. The current Jac output **dropped the entire admin check** and returned `{"status":"ok"}`. Prime DB→graph candidate.
- `bitcraft3r__0xVenture-Capitalist::(user)/game/BuyQuantity.tsx` — `useSound` (dropped via E7208), `useStore`/zustand (lowered to a `has` field), Tailwind `className` (preserved). One file showing all three behaviors.

## 5. What we want from gpt-5.6-sol

1. **Difficulty assessment** for a *dataset* (not production fidelity):
   - (A) keeping third-party hooks via interop,
   - (B) Prisma/Drizzle → Jac graph mapping.
   Where is the genuinely hard part, and where is it easy?
2. **Pipeline design for richer Jac input:**
   - Should DB-layer conversion be a new deterministic converter stage (`schema.prisma` → archetypes) + a query-rewrite pass, or an LLM step, or both? Trade-offs.
   - How do we **source richer inputs**? The current corpus is React-component-heavy; graph/server data is thin. Where do we harvest Prisma-schema-heavy / fullstack-Jac-shaped repos?
   - How does this interact with the SYNTAX/FAITHFUL split and `strip_policy.json`? (New `rewrite` rules vs new error codes vs new converter stages.)
3. **Phased plan:** what to do first, what to defer. Prefer concrete policy/converter deltas (file + line references) over prose.
4. Verify the third-party-hook interop idiom (section 3A).

## 6. Pointers

- Converter: `/home/jac/repos/jac_llm_data/jaseci/jac/jaclang/compiler/js2jac/convert_bridge.mjs` (hook sets at ~line 107)
- Policy: `scripts/js2jac_dataset/strip_policy.json`
- Datasets: `scripts/js2jac_dataset/js2jac_dataset_idiom.jsonl` (195, SYNTAX mode), `scripts/js2jac_dataset/js2jac_dataset.jsonl` (full)
- Hardening plan: `scripts/js2jac_dataset/CONVERTER_HARDENING_PLAN.md`
- Jac docs (via `jac` MCP tools, if available in this environment): `jac_read_jac_sv_persistence`, `jac_read_jac_node_edge_patterns`, `jac_read_jac_cl_js_interop`, `jac_read_jac_cl_styling`, `jac_read_tutorials_fullstack_state`, `jac_read_jac_cl_components`
