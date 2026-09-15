# OSP Idiomize Task v2 — lifting hand-rolled graph machinery to native Jac

**Status:** v2.1 (sol-verified: 4/5 v1 fatals fixed, punch list of 6 applied —
cycle wording, whole-record elimination scan, C2 ordering scope-out, C5
two-phase mutation + deletion probe blocker, fork-lineage splits, schema
consistency). Scope frozen to: **Python · in-memory · C1/C2/C5.**
Reviews: v1 [`OSP_IDIOMIZE_SOL_REVIEW.md`](OSP_IDIOMIZE_SOL_REVIEW.md),
v2 [`OSP_IDIOMIZE_SOL_REVIEW_V2.md`](OSP_IDIOMIZE_SOL_REVIEW_V2.md).
**Depends on:** `scripts/graph_targets/` (targeting), `scripts/lib/idiomize_seam.py`
(prompt assembly), jac **0.36.1** semantics pinned by probe
(`scripts/graph_targets/probe_walker_cycle.jac`), `jac-idiomatic` skill Tier 3.

---

## 1. Why this doc exists

The function pipeline (`docs/PLAN.md`) trains on MultiPL-T pure functions and
never emits OSP — pure functions have no relationships. The dataset therefore
has near-zero `node`/`edge`/`walker` coverage. Meanwhile real projects
hand-roll graph machinery: `parent_id` recursion, adjacency dicts + BFS,
cascade deletes that walk children. The issue miner (7,974 issues / 244 repos
in `data/graph_targets/`) finds them.

**Thesis, restated after the review:** idiomatic Jac conversion must eliminate
the **representation and traversal plumbing** (id-keyed maps, manual recursion,
queue/stack loops, N+1 query loops) by moving relationships into typed edges
and traversal into walkers. It must **preserve**, not delete, domain logic —
including cycle guards, depth limits, and invalidation rules that are
observable behavior. In jac 0.36.1 walkers have **no built-in once-per-node
visitation** (probe result, §2), so cycle safety remains explicit code. What
dies is the *scaffolding*, never the *semantics*.

## 2. Pinned Jac 0.36.1 semantics (probe-verified)

Run `jac run scripts/graph_targets/probe_walker_cycle.jac` (30s timeout):

| Question | Result |
|---|---|
| Does `visit [-->]` dedupe nodes on cyclic graphs? | **No — it hangs.** A→B→C→A loops forever. |
| Built-in visited set? | **None.** No `disallow`/`take` visitation primitives exist (`disallow_root` is permissions-only). |
| Dead-end handling | `visit [...] else { ... }` fires when nothing to visit; `disengage;` stops the walker. |
| Typed-edge traversal | `visit [->:EdgeType:->]` / `visit [here->:Door:->]` (NOT `[->:T:]`). |
| Node-type filter | `visit [-->[?:Foo]]` (also `(-->(?:Foo))` forms). |
| Attach / create | `root ++> (a := Node(...));` — grouped creation uses `:=`. Typed edge creation: `a +>:Link:+> b;`. Typed disconnect: `a del ->:Link:-> b;`. |
| Node **deletion** | Verified: `a del --> b;` disconnect works; `del b;` destroys the node AND auto-purges its remaining edges. Probe: `data/osp_lifts/probe_deletion.jac`. |
| Docstrings | Module-level and ability-body docstrings parse; a docstring as first statement of a plain `def` body fails (`Expected 'else', got '{'`) — use `#` comments inside `def`s. |
| `pass` statement | **Does not exist** (NameError); empty except-blocks need a comment or real statement. |
| Native test engine | `jac test` defaults to codespace `native`; records whose imports don't lower cleanly abort in `invoke_native_test`. Pin `[build] default_codespace = "server"` per record dir's `jac.toml` (NOT the legacy `[placement]` section) and clear stale `.jac/` build dirs after config changes. |
| Optional narrowing at connections | Connection operands must be definite node instances: narrow `x = resolve(...)` with `if x is None { continue; }` before `+>:E:+> x`. |

**Consequences:** every lift must carry an explicit cycle policy (guard set /
depth cap / error — `visit ... else { disengage; }` is **dead-end** handling,
not a cycle policy); traversal order is **unspecified** → tests assert
order-insensitively unless the source order is domain-observable and
reproduced by the adapter (§5.3).

## 3. Pipeline position

```
issue miner → jac_fit gate        harvest (clone, extract module+tests)
                                 │
                                 ▼
                    py2jac floor (deterministic; class→obj port fallback)
                                 │
                                 ▼
                    model: OSP lift (this doc's §6 contract)
                                 │
                                 ▼
                    hidden-test guard  ── fail ─► record kept, sft_excluded
                                 │ pass              (analysis-only, §8.3)
                                 ▼
                    hard elimination gate (AST) + manual audit (first 50)
                                 │
                                 ▼
                    dataset record (SFT slice)
```

Tracks: **R** (real repo module + upstream tests), **S** (synthetic
before-code from an issue spec — capped ≤ 20% of any release, §8.5).

## 4. Input gate (a module is convertible when ALL hold)

1. **Entities with identity** — objects/rows the code refers to *by reference
   across calls* (heterogeneous **or** homogeneous; a singly-typed tree is
   fine — the criterion is traversal, not type variety).
2. **Load-bearing relationships** — the module *traverses* them at runtime
   (recursion over parents/children/dependents, joins followed in loops).
3. **Hand-rolled machinery present** — id-keyed maps, adjacency containers,
   visited sets, recursive descent functions, queue/stack walks, N+1 query
   loops, in *user code*. Delegation to NetworkX/neo4j = nothing to lift.
4. **Python, in-memory** (v1 freeze). No DB/ORM/network services. SQL and TS
   sources are deferred (§7).
5. **Closed import boundary** — the unit is the module plus its pure-local
   imports; anything importing I/O, frameworks, or the world disqualifies.
   Recorded as the explicit file list in provenance.
6. **Testable without external state** — public API exercisable via plain
   values/objects.
7. **jac_fit_score ≥ 7** (targeting gate) or equivalent human judgment.

**Non-goals (unchanged):** algorithmic graph exercises; SQL-only pain;
one-shot DAG configs already delegated to a library.

## 5. Contracts the lift must satisfy

### 5.1 Compatibility adapter (mandatory)

Object identity, constructors, and public types change when entities become
nodes. Every record ships a ** façade**: the source module's public functions
re-expressed as `def`s over the graph (same names, same signatures, same
return shapes). Callers — and the hidden tests — see the original API.
Inside, they build/attach nodes and spawn walkers. The façade is part of
`osp_jac`, not optional.

### 5.2 State lifecycle

- Each test run starts from a **fresh graph**: `load_graph(fixtures)` builds
  nodes/edges deterministically (creation order = fixture order) and returns
  the populated root. No module-level mutable state; no leakage between tests.
- Node references, not IDs, are the module's currency. If the source API is
  ID-based (`get_descendants(id)`), the façade keeps ID parameters and
  resolves them via a lookup `has` map on the loader object — a lookup table
  is domain API, not traversal machinery, and is allowed.

### 5.3 Traversal-order policy

Walker visit order is unspecified in 0.36.1. Tests therefore compare
**sorted/multiset** results by default. **C2 records whose source ordering is
caller-observable (e.g. exact DFS pre/post order) are out of scope for v2** —
reconstructing them may require precisely the frontier/stack state the
elimination gate bans, and `sort()`-after-collection cannot reproduce path
orders. BFS *level* order is admissible only when the source exposes levels
semantically; the façade reproduces it via level-partitioned walker state
(a `has levels: list[list]` accumulator is semantics, not machinery) and a
test pins it. Order-observable C2 re-enters the catalog when an
order-producing walker contract exists (C9 blocker).

### 5.4 Cycle & dangling policy (source-derived, not universal)

Mandatory negative tests only when the source defines the behavior:
- source raises on cycle → test expects same error (façade re-raises);
- source allows revisit (diamond) → test asserts multiset result;
- source tolerates missing refs → test asserts source's convention
  (skip / KeyError / None), preserved by the façade.
When the source's graph is acyclic-by-construction, an invariant replaces the
negative test: *after any mutation through the API, the graph contains no
cycle* (checked by an explicit walk in the test harness, not by the module).

### 5.5 Mutation contract (for C5)

Two-phase protocol — never mutate during a walk:
1. **Collect:** walker gathers the deletion set (with once-only guard for
   shared descendants) and exits.
2. **Apply:** façade disconnects (`a del ->:T:-> b`) and deletes nodes
   outside the walk; root-attachment edges included.

Partial failure semantics = source's (typically: none defined →
whole-graph consistency is the postcondition, asserted by the test
invariant: no cycle, no orphaned references to removed nodes).
**Activation blocker:** a version-pinned deletion probe (disconnect + node
removal + root cleanup round-trip) must pass on 0.36.1 before the first C5
record is accepted; re-run per §11 version bump.

## 6. The model task (system-prompt contract)

> You are given a real Python module that maintains relationships between
> entities and hand-rolls the machinery to traverse them, and a behavioral
> description of its public API. Hidden tests exercise the API; you will not
> see them.
>
> Rewrite it in idiomatic Jac:
>
> 1. **Entities → archetypes.** `node` for entities with graph identity.
>    Public names and behavior are preserved by a compatibility façade of
>    `def`s with the original signatures.
> 2. **Relationships → typed edges.** `parent_id` fields, adjacency entries,
>    and id-pair lists become typed `edge` archetypes (payload fields kept).
>    Id-keyed registries that are part of the public API stay as lookup
>    state; id-keyed maps that only serve traversal die.
> 3. **Traversal → walkers.** Recursive descent and queue/stack walks become
>    `walker`s over **typed** edges (`visit [->:T:->]`), accumulating on
>    typed `has` fields with one exit `report`. Cycle policy of the source
>    (guard set, depth cap, or error) is **domain logic and must survive** —
>    keep it explicit in the ability; `visit ... else { disengage; }` ends
>    dead-end walks.
> 4. **Scaffolding dies; semantics don't.** Deleted: adjacency containers,
>    manual recursion plumbing, queue/stack loops, per-node query loops,
>    memo caches that exist only to tame the manual walk. Kept: depth
>    limits, cycle errors, invalidation rules, and any caching that is
>    observable to callers.
> 5. **Behavior preserved exactly** — §5 contracts all hold.
> 6. **Jac floor + Tier 3 idioms** — syntax floor, concrete types, typed
>    edges, single exit `report`, walkers that actually visit.

## 7. Conversion catalog

### 7.1 Active lifts (v2 scope — Python, in-memory)

| # | Hand-rolled pattern | OSP lift | Machinery deleted | Semantics kept |
|---|---------------------|----------|-------------------|----------------|
| C1 | `parent`/`children` refs + recursive ascent/descent | `node` + typed edge (`ChildOf`); façade walks `visit [->:ChildOf:->]` / reverse | parent/child pointer fields, recursion functions | depth limits (domain), cycle policy, order if observable |
| C2 | adjacency dict + BFS/DFS queue/stack | nodes + typed edges; `walker` with typed visits | the dict, queue/stack loops, frontier bookkeeping | visit strategy (BFS level order etc.) reproduced in façade when observable; cycle guard | \<!-- order-observable C2 excluded per §5.3 -->
| C5 | cascade delete/invalidate walking descendants | `walker Cascade` over typed edges; `del ->:T:->` disconnect + removal per §5.5 | manual walk, orphan sweeper pass | once-only deletion (guard), atomicity postcondition, external hooks |

Combos (G-tiers, §9): C1+C2, C1+C5, C2+C5. Single-lift records are G1.

### 7.2 Deferred lifts (named blocker per row)

| # | Pattern | Blocker (must be resolved by probe/contract before activation) |
|---|---------|----------------------------------------------------------------|
| C3 | visited set → "built-in once-only visitation" | **Disproved by probe** — no built-in dedup. Survives only as part of C1/C2/C5 cycle policy (explicit guard). |
| C4 | recursive CTE / closure table / nested set | persistence & transaction semantics; requires a storage-backed Jac contract |
| C6 | permission inheritance joins | deny precedence, nearest-role precedence, path-dependent grants |
| C7 | N+1 query loops → "one pass" | query-count observability needs a persistence backend to even measure |
| C8 | memo cache → once-per-node walk | **Disproved** (same probe); path/context-sensitive memoization ≠ visitation. Re-enter only with an explicit equivalence contract. |
| C9 | Kahn/Tarjan toposort → walker | visitation order ≠ topological order; needs an order-producing walker contract |
| C10 | dirty flags + downstream recompute | lazy vs eager recompute is caller-observable; needs an evaluation-semantics contract |
| C11 | union-find clustering → reachability | mutable union-find API, canonical representatives, complexity guarantees |
| C12 | TS `Map<id,Node>` + `links: string[]` | TS floor path (no deterministic transpiler); revisit with js2jac gates |

## 8. Guard, gates, and dataset policy

### 8.1 Behavioral guard (hard)

`jac test` against `tests` (upstream suite retargeted to the façade, or
oracle-synthesized against source behavior). Tests never shown to the model.
Minimum per record: happy-path traversal outcome (multiset), applicable
negative cases per §5.4, mutation invariants per §5.5 when the module mutates.

### 8.2 Elimination gate (hard, AST-based)

A transcription that passes tests still enters nothing. Detector (Python AST
+ Jaclang AST) scans both sides for the machinery families:
adjacency containers (`dict[id, list]`), visited sets (`.add(` guarded by
`in`), memo caches, self-recursive functions, explicit `deque`/`list`-as-
queue/stack walks, per-item query calls. **Accept iff**: source hits ≥ 1
family AND candidate hits **0 across the entire record** — façade, walkers,
and every helper `def`/ability reachable from them (moving machinery into
helpers does not escape the gate), with cycle-policy guards exempt (they are
semantics). First 50 accepted records are **manually audited**, then **10%
sampled forever**; detector patches land from audit findings.

### 8.3 Fallback & label policy (review flaw #3 fix)

- Guard-fail → record kept with `floor_status: fallback`, **excluded from
  SFT** (`sft_excluded: true`). Floors transcribe machinery; they are
  negative examples at best.
- DPO/preference pairs: only when **both** sides pass hidden tests (equal
  correctness) and differ on the elimination/idiom axis — the style axis is
  then the legitimate preference dimension. Fallback-vs-passing pairs are
  correctness-confounded and prohibited.

### 8.4 Record schema (v2)

```jsonc
{
  "id": "osp__<repo>__<module>__<hash8>",
  "track": "R" | "S",
  "provenance": { "repo": "owner/name", "issue": 4544, "commit": "<sha>",
                  "files": ["..."],
                  "split_group": "<canonical upstream lineage id>" },
  "source": { "language": "python", "code": "...", "spec": "..." },
  "floor_jac": "...",            // always present
  "floor_status": "generated" | "ported",   // py2jac output vs reviewed port
  "candidate_osp_jac": "...",    // model output under test (always kept)
  "osp_jac": "..." | null,       // accepted candidate; null on fallback
  "tests": "...", "test_hash": "<sha8>",
  "signals": ["adjacency", "visited_set", "cascade"],
  "lifts": ["C1", "C5"],
  "guard_result": "pass" | "floor_fallback",
  "elimination": { "source_hits": [...], "candidate_hits": [...],
                   "removed_loc": 0, "machinery_neutral": false },
  "audit": { "reviewed": false, "reviewer": null, "notes": null },
  "sft_excluded": false,          // true on fallback (§8.3)
  "g_tier": 1
}
```

### 8.5 Leakage & distribution

- **Split by `split_group` = canonical upstream lineage** — resolve each repo
to its ultimate source (GitHub fork network / `source` field), so forks and
mirrors under different owners share one group; no module, sibling issue, or
synthesized variant of a lineage crosses the train/eval boundary.
- **Track S ≤ 20%** of any release; its tests must be independently authored
  (metamorphic properties preferred: e.g. descendants(A∪B) ⊇ union) rather
  than generated by the same model/prompt lineage that wrote the before-code.
- Hidden tests live in the record but are stripped from any prompt-assembly
  path mechanically (`tests`/`test_hash` fields never enter prompt builders;
  enforced by the harness allowlist).

## 9. Difficulty tiers

| Tier | Content | Expected share |
|------|---------|----------------|
| G1 | single active lift | ~60% |
| G2 | two lifts combined (C1+C5 cascade tree; C2+C5 invalidation sweep) | ~30% |
| G3 | three lifts + mutation invariants + observable ordering | ~10% (Track R only) |

## 10. Open questions

1. **Test retargeting cost** — upstream pytest slice vs full oracle-synth.
   Lean: upstream for G3, synthesized for G1/G2 (unchanged from v1).
2. **py2jac floor on class-heavy modules** — `obj` mapping unvalidated; port
   fallback must be marked `floor_status: ported` and reviewed (unchanged).
3. **Detector precision** — AST families still misclassify (lookup table vs
   cache). Manual audit phase (8.2) is the correctness net; promote audit
   rules into the detector as they emerge.

## 11. Acceptance criteria

- [ ] Records per §8.4; façade present in 100%; cycle policy explicit in
      100% of cyclic-domain records.
- [ ] Guard outcomes reported; fallbacks `sft_excluded`.
- [ ] Elimination gate wired (AST detector); first 50 accepted manually
      audited; audit → detector patch loop documented.
- [ ] §5.4/§5.5 obligations derived per record from source semantics.
- [ ] Split respects repo lineage; Track S ≤ 20%; test fields never in
      prompts (harness-enforced).
- [ ] Probe re-run and semantics table re-pinned on every jac version bump.

---

*v2 supersedes draft v1 (git history). Aligned with `jac-idiomatic` skill
Tier 3 and jac 0.36.1 probe results; walker semantics re-verified per §11.*
