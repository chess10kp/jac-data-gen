## FATAL flaws

1. **Behavior and API preservation are underspecified and often incompatible with the lift.** Replacing ORM rows, IDs, constructors, and public classes with graph nodes changes object identity, creation, serialization, persistence, and caller-visible types. Hidden tests cannot resolve this without a required compatibility façade and explicit state bootstrap/teardown contract.

2. **The thesis is not hard-guarded.** `jac test` checks behavior, while machinery elimination is a regex-based soft metric and idiomaticity is sampled. A transcription can pass and enter the dataset; renaming a visited set or moving traversal into helpers games the metric. This contradicts “reject/fallback even when tests pass.”

3. **Fallback semantics are contradictory.** `floor_jac` will normally retain exactly the machinery declared unacceptable. Falling back after an anti-pattern creates a passing but negative-quality SFT label unless fallback records are strictly excluded. The schema also has no field for the failed candidate, so the claimed DPO pair is not retained.

4. **Several catalog rows are not semantics-preserving transformations.**
   - **C9:** generic walker visitation is not topological sorting or Tarjan; order and cycle detection require algorithmic state.
   - **C11:** reachability is not equivalent to mutable union-find APIs, canonical representatives, or complexity guarantees.
   - **C8:** memoization may be path/context-sensitive; once-per-node visitation is not equivalent.
   - **C4:** replacing database structures with edges discards transactions, persistence, constraints, concurrency, and query semantics.
   - **C10:** dirty flags may encode observable lazy recomputation, not plumbing.

## Gaps / failure modes

- No contract for graph construction from source fixtures, returned graph persistence, isolation between tests, deterministic IDs, edge uniqueness, parallel edges, transaction rollback, or cascade atomicity.
- No policy for traversal order. BFS, DFS, SQL ordering, and adjacency insertion order can be observable; native traversal order is not promised here.
- Mandatory cycle and dangling-reference tests are invalid for schemas that prohibit cycles or represent missing references as absence of an edge. Require applicable negative cases instead.
- C1 deletes “depth guards” even when maximum depth is domain behavior.
- C5 does not define deletion during traversal, incoming-edge cleanup, shared descendants, or partial failure.
- C6 ignores deny precedence, nearest-role precedence, and path-dependent permissions.
- C7 promises “one pass” without defining backend/query-count observability.
- C12 cannot always delete the registry: it may be the public lookup API or enforce canonical identity.
- The `≥2 kinds` gate wrongly excludes traversed homogeneous graphs.
- No dependency/import boundary: “module or coherent cluster” is not reproducible.

## Jac accuracy

The high-level Tier 3 direction is aligned: context-gated OSP, typed edges, walkers that actually visit, typed accumulation, and one exit report.

Specific claims are unsupported or wrong:

- The skill does **not** establish automatic once-per-node traversal. Q4 is therefore blocking, yet C3/C8 already depend on it.
- `disallow` and `take` are not documented by the supplied authority; `skip` is, but does not imply deduplication.
- C1’s `visit [->:ChildOf:]` is inconsistent with the skill’s graph-reference forms and must be validated.
- Untyped `[-->]` risks traversing root attachment and unrelated relationships; catalog lifts should use typed edges.
- The probe is knowingly non-compilable and cannot answer the question reliably.
- “Built-in cycle tolerance” must not appear until version-pinned semantics are proven.

## Dataset quality risks

- Track S uses correlated LLM generation for spec, before-code, tests, and conversion: severe shared-bug oracle noise.
- Retargeted tests may encode the chosen Jac representation rather than source behavior.
- Repository leakage across train/eval through forks, repeated issues, modules, and synthesized variants is unaddressed.
- Storing hidden tests in the same JSONL artifact invites accidental prompt leakage.
- G1-heavy synthetic distribution will teach toy trees, not ORM/persistence migrations.
- Failed idiomatic candidates versus passing floors are not valid preference pairs without separate correctness and style labels.

## Ranked concrete edits

1. **Freeze v1 to Python, in-memory modules, and proven C1/C2/C5 subsets. Remove C4/C8–C12 pending semantic contracts.**
2. Add a required compatibility adapter, fixture-to-graph loader, state lifecycle, ordering, identity, and mutation/atomicity contract.
3. Make elimination a hard AST/symbol/data-flow gate; manually audit all accepted templates initially. Never emit fallback as positive SFT.
4. Extend schema with `candidate_osp_jac`, guard results, rejection reasons, provenance, test hash, split group, and floor status.
5. Replace universal cycle/dangling requirements with source-derived behavioral obligations and mutation invariants.
6. Run compiling version-pinned Jac probes before specifying revisit, edge-filter, deletion, and report semantics.
7. Split by repository/fork lineage before synthesis; cap Track S and require independently authored/metamorphic tests.
---
Reviewer: gpt-5.6-sol (via chatgpt.com/backend-api/codex, 2026-08-26)
Inputs reviewed: docs/OSP_IDIOMIZE_TASK.md (draft v1) + jac-idiomatic SKILL.md (Tier 3)
Verdict: v1 has 5 fatal flaws; freeze to Python + in-memory + C1/C2/C5 recommended.
