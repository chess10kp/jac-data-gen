# OSP Idiomize Task — lifting hand-rolled graph machinery to native Jac

**Status:** draft v1 — task spec for the graph-target pipeline (Path A).
**Review:** gpt-5.6-sol found 5 fatal flaws — see
[`OSP_IDIOMIZE_SOL_REVIEW.md`](OSP_IDIOMIZE_SOL_REVIEW.md). Key ones: (1) the
catalog assumes walker semantics that are unproven (probe §10 is blocking, and
C3/C8 depend on it); (2) fallback floors are negative SFT labels if kept as
positive pairs; (3) C4/C8–C12 are not semantics-preserving lifts as written.
**Do not implement against this draft** until the review's ranked edits are
triaged.
**Depends on:** `scripts/graph_targets/issue_miner.py` (targeting),
`scripts/lib/idiomize_seam.py` (system-prompt assembly, zen transport),
`jac test` guard (v0.36+), `jac-idiomatic` skill Tier 3.

---

## 1. Why this doc exists

The function-level pipeline (`docs/PLAN.md`) trains on MultiPL-T pure
functions and — deliberately — never emits OSP, because pure functions have
no relationships to model. The result: the dataset has near-zero coverage of
`node`/`edge`/`walker`, the constructs that make Jac *Jac*.

Meanwhile, thousands of real projects hand-roll graph machinery in Python and
TypeScript: `parent_id` columns + recursive CTEs, visited sets, cascade
deletes that walk children with per-node queries, permission hierarchies
resolved by N+1 joins. The issue miner (`data/graph_targets/`, 7,974 issues /
244 enriched repos) finds exactly these. This doc defines what the model must
**do** to convert such code into idiomatic OSP Jac, and how we verify it.

**The thesis restated as a task:** when the source's pain is hand-rolled
traversal state, the idiomatic Jac version must **eliminate that machinery**,
not transcribe it. A conversion that keeps a dict-of-lists adjacency map and a
manual visited set — merely re-spelled in Jac syntax — has failed, even if it
passes tests.

---

## 2. Pipeline position

```
issue miner                    harvest                     conversion (this doc)
────────────                  ─────────                   ──────────────────────
graph-signal queries  →  clone repo, extract the   →  py2jac floor  →  OSP lift
jac_fit gate (LLM)        graph-bearing module          (deterministic)  (model task)
                         + its tests                  ↓                    ↓
                                                      jac test guard  →  jac test guard
                                                      (same hidden-test
                                                       contract as step 3)
```

Two source tracks feed the same converter:

- **Track R (real):** module lifted from a mined repo (Path A). Tests come
  from the repo's own suite, or are synthesized against the source module's
  observable behavior (oracle-synth pass) when upstream has none.
- **Track S (synthetic):** issue text distilled to a spec (Entities / Edges /
  traversal), LLM writes the "before" implementation faithfully to the issue
  description, oracle synthesizes tests, then the same conversion runs.
  Weaker provenance; use only for pattern classes Track R can't reach.

Both tracks produce identical **records** (§4) and pass the same guard.

---

## 3. Input contract — when a module is convertible

A candidate module qualifies only if **all** hold:

1. **Entities exist** — ≥2 kinds of objects with persistent identity (rows,
   instances, records), not transient values.
2. **Relationships are load-bearing** — the module *traverses* them at
   runtime (recursion, joins, walks), not merely stores FKs it never follows.
3. **Machinery is hand-rolled** — the traversal state lives in *user code*:
   visited sets, recursion + memo, adjacency dicts, CTEs, queue walks.
   A module that already delegates to NetworkX/neo4j has nothing to lift.
4. **Observable behavior is testable** — the module's public API can be
   exercised without a live network/DB, via fakes or SQLite-embedded state.
5. **jac_fit_score ≥ 7** from the targeting gate (issue-miner prompt), or an
   equivalent human/LLM judgment for Track R harvests without an issue.

**Non-goals.** We do not convert: algorithmic graph exercises (LeetCode-style
`findMinHeightTrees` clones — the graph *is* the task, nothing is eliminated);
SQL-only pain with no host-language code (demo material, not dataset);
one-shot DAG configs already handled by a library call.

---

## 4. Record schema

One JSONL record per conversion unit (a module or a coherent cluster of
functions/classes):

```jsonc
{
  "id": "osp__<repo>__<module-stem>__<hash8>",
  "track": "R" | "S",
  "source": {
    "repo": "owner/name", "issue": 4544,           // optional, Track R
    "language": "python" | "typescript",
    "files": ["internal/graph/dep.py"],
    "code": "...original module text...",
    "spec": "..."                                   // Track S only
  },
  "floor_jac": "...py2jac mechanical output...",    // deterministic baseline
  "tests": "...jac test suite (hidden from model)...",
  "osp_jac": "...model output (this task)...",
  "signals": ["visited_set", "recursive_cte", "cascade"],  // miner vocabulary
  "meta": { "machinery_loc_removed": 0, "jac_fit_score": 0 }
}
```

`floor_jac` for Track R is `jac tool py2jac` on the module (class → `obj`
mechanical mapping). It is the correctness floor for fallback, exactly as in
`docs/PLAN.md`.

---

## 5. The model task (system-prompt contract)

> You are given a real Python/TypeScript module that maintains relationships
> between entities and hand-rolls the machinery to traverse them, plus its
> behavior tests exist but are **hidden** — you will not see them; your output
> is executed against them.
>
> **Rewrite the module in idiomatic Jac such that:**
>
> 1. **Entities become archetypes.** `node` for entities with graph identity;
>    `obj`/`edge` per the catalog below. Preserve public names and behavior.
> 2. **Relationships become typed edges.** `parent_id`, FK columns, adjacency
>    entries, and dict-of-lists maps become `edge` archetypes with the
>    relationship's name and any edge payload (since, weight, kind).
> 3. **Traversal becomes language traversal.** Manual recursion, visited
>    sets, BFS queues, and iterative walks become `walker`s with `visit`,
>    connection expressions, and built-in cycle tolerance where semantics
>    allow. Do not re-implement a visited set.
> 4. **State-management scaffolding dies.** Invalidation flags, dirty bits,
>    memo caches keyed by node id, and re-entrancy guards that exist only to
>    support the manual walk are **deleted**, not translated.
> 5. **Behavior is preserved exactly.** Same public API surface, same results,
>    same error behavior on cycles/missing refs where the source defined one.
> 6. **It still compiles and runs.** Full Jac syntax floor (Tier 0), concrete
>    types (Tier 1), and the OSP idioms of the `jac-idiomatic` skill Tier 3.
>
> When the source's semantics require strict once-only visiting (e.g.
  cycle = error, or accumulate-once), use walker `disallow`/`skip`/`take`
> semantics or explicit guard checks **inside** the ability — that is domain
> logic, not machinery, and must survive.

The model never sees: tests, the scoring rubric, or other records.

---

## 6. Conversion catalog (the lift table)

The core of the task. Every lift must be **semantics-preserving**, and each
row names what gets deleted.

| # | Hand-rolled pattern | OSP lift | Deleted machinery |
|---|---------------------|----------|-------------------|
| C1 | `parent_id` column / `parent` FK + upward recursion | `node` + typed edge `ChildOf`/`ParentOf`; walker `visit [->:ChildOf:]` | FK field, recursion function, depth guards |
| C2 | Adjacency dict `{id: [ids]}` + BFS/DFS | `node` + edges; `walker` with `visit [-->]` / `[<--]` | the dict, the queue/stack, the loop |
| C3 | `visited: set` in a recursive walk | walker built-in once-only visitation (`disallow` for re-entry control) | the set, its bookkeeping |
| C4 | Recursive CTE / `WITH RECURSIVE` / closure table / nested set / materialized path | native edges — the query *is* traversal: `root spawns walker`, collect via `report` | the SQL, closure rows, path strings, rebuild triggers |
| C5 | Cascade delete/invalidate walking descendants | `walker Cascade` over `-->` edges, dropping nodes / setting flags | manual walk, orphan sweeper |
| C6 | Permission/role inheritance via repeated joins | reachability walker over `HasRole`/`Inherits` edges; result = reached set | join ladder, level column, cache |
| C7 | N+1 per-node queries in a loop | single spawn; gather in one pass (`report`, typed `has` accumulation) | the query loop, batching workarounds |
| C8 | Memo cache `dict[id, result]` guarding exponential re-walk | walker's natural once-per-node | the cache, invalidation hooks |
| C9 | Topological order via Kahn/tarjan in user code | walker over dependency edges yielding `report` order; cycle surfaces as incomplete visit | the algorithm body, in-degree table |
| C10 | Dirty flags + downstream recompute propagation | state-propagating walker sweeping dependents | dirty bookkeeping |
| C11 | Duplicate/cluster detection via union-find in maps | connected reachability over `SameAs` edges | union-find, find/merge plumbing |
| C12 | TS: object graph with `Map<id, Node>` + `links: string[]` | same as C2 — `node` + typed edges replace the registry map | the Map registry, id strings |

**Rule of application:** lift the *minimum complete set* of rows the module
needs; do not introduce rows for structure the module doesn't traverse. If a
row's "deleted machinery" column cannot be honestly filled, that row doesn't
apply.

---

## 7. Guard & metrics

### 7.1 Behavioral guard (hard gate)

Identical contract to the function pipeline: the record's `tests` (upstream
suite re-targeted to Jac, or oracle-synthesized against source behavior) run
against `osp_jac` via `jac test`. **Fail → fall back to `floor_jac`, tag the
record `floor_fallback`, keep both** (the pair itself is DPO-grade signal,
mirroring the farm's floor-fallback capture).

Tests must cover at minimum, per record:
- happy-path traversal outcome (order/content of collected results),
- **cycle present** (source behavior preserved: error, skip, or once-only),
- **missing/dangling reference** (source behavior preserved),
- mutation path if the module mutates the graph (add/remove cascade).

### 7.2 Machinery-eliminated metric (soft, reported)

The thesis metric. Computed mechanically per record:

```
machinery_loc_removed =  LOC(hand-rolled traversal/state code in source)
                       - LOC(graph plumbing remaining in osp_jac:
                              explicit id-maps, visited sets, memo caches,
                              manual recursion, queue loops)
```

Heuristic extraction (regex/symbol pass over source + output, same signal
families as the miner): counted categories = adjacency containers, visited
sets, memo/invalidation, recursive descent functions, queue/stack walks,
CTE/closure-table strings, N+1 loops. A record with
`machinery_loc_removed <= 0` **passed tests but failed the thesis** — keep it,
but flag `machinery_neutral: true` and exclude from the OSP-premium slice.

### 7.3 Idiomaticity review (sampled)

Every Nth record (and every `machinery_neutral`) gets the rubric pass
(`jac-idiomatic` skill `rubric.md`, Tier 3 focus): wrong-context OSP
(walkers that visit nothing, nodes for value objects), per-node `report`s,
untyped channels — the anti-patterns the skill already names.

---

## 8. Anti-patterns (reject/fallback even when tests pass)

1. **Transcription.** Jac syntax over the same dict/visited/recursion
   structure — the C3/C8 deletions didn't happen.
2. **Graph maximalism.** Turning every value object into a node, every
   function call into an edge. OSP only where §3 conditions held.
3. **Walker abuse.** A walker that visits nothing (should be `def:pub`), or
   per-node `report`s instead of one exit `report` from accumulated `has`.
4. **Semantic drift on cycles.** Source raised `CycleError`; output silently
   stops. Or source allowed diamond re-visit; output visits once. The hidden
   cycle tests exist for this.
5. **Lost API surface.** Public functions/exports removed or renamed; the
   module's callers (and tests) must be unaffected.
6. **Silent floor.** Reporting success when the record actually fell back.

---

## 8b. Difficulty tiers (for dataset slicing)

| Tier | Content | Expected share |
|------|---------|----------------|
| G1 | single row of catalog, one entity pair, tests upstream | ~60% |
| G2 | 2–3 rows combined (e.g. C1+C5 cascade tree, C6+C7 inheritance) | ~30% |
| G3 | full subsystem: ordering + propagation + mutation, cycle-error semantics | ~10% |

Track S may synthesize G1/G2 freely; G3 requires a Track R issue for
grounding.

---

## 9. Open questions (blocking v1 freeze)

1. **Test retargeting cost.** Upstream pytest/vitest suites import the module
   under test by path; the Jac record is self-contained. Do we hand-port a
   minimal slice (preferred, quality) or oracle-synthesize everything
   (scale)? Current lean: upstream tests for G3, synthesized for G1/G2.
2. **py2jac floor quality on class-heavy modules.** Floor was built for
   functions; `obj` mapping of real ORM-ish classes is unvalidated. If the
   floor doesn't run, fallback = source-equivalent minimal Jac port written
   once by the strongest model, then guarded — must be marked `floor: ported`.
3. **TS→Jac floor path.** No deterministic transpiler exists (js2jac uses
   converters + behavioral gates). For TS records the floor may be empty;
   guard then compares against oracle behavior only. Decide whether that
   weakens the fallback contract enough to require Track R python-only for
   v1.
4. **Walker cycle semantics.** Confirm exact built-in re-visit semantics of
   current jac (0.36.1) for `visit [-->]` on cyclic graphs — once-per-node vs
   edge-once — and pin the catalog wording to it. (Action: run the probe
   snippet in §10 before freezing.)
5. **`machinery_loc_removed` extractor precision.** Regex families will
   miscount (e.g. a `dict` that is a cache vs a lookup table). Accept
   approximation, or add a cheap LLM tally pass?

## 10. Probe snippet (answers Q4; run before freeze)

```jac
node A;
edge E;
with entry {
    root ++> (a1: A, a2: A, a3: A);
    a1 +>:E:+> a2; a2 +>:E:+> a3; a3 +>:E:+> a1;   # cycle
    result = root spawn walker {
        has count: int = 0;
        can `with A entry` with `A entry` { self.count += 1; }
        ...
    };
    # observe: count == 3 (once-per-node) vs >3 (edge-once)
}
```

(Exact walker syntax per skill Tier 3; the point is measuring built-in
visited-ness, not the snippet's form.)

---

## 11. Acceptance criteria for the pipeline stage

- [ ] Converter emits records per §4; every record carries floor, tests,
      osp_jac, signals, meta.
- [ ] `jac test` runs headless per record; outcomes: `pass`, `floor_fallback`,
      `reject` (anti-pattern), with rates reported.
- [ ] Cycle + dangling-ref tests present in 100% of records.
- [ ] `machinery_loc_removed` computed for 100%; premium slice =
      pass ∧ removed > 0 ∧ G-tier assigned.
- [ ] Sampled rubric review on ≥5% of premium slice; feedback loop into the
      system prompt (same cadence as function-pipeline repairs).

---

*Authored for the jac_llm_data graph-target pipeline. Task contract aligned
with `jac-idiomatic` skill Tier 3 as of jac 0.36.1; re-pin on minor bumps.*
