## 1. V1 fatal flaws

1. **API/behavior preservation — FIXED.** Mandatory façade, deterministic fixture loading, fresh-state lifecycle, ID lookup allowance, ordering policy, and mutation obligations now provide a workable compatibility contract.

2. **Thesis enforcement — ONLY PARTLY FIXED.** The AST gate is hard, but scanning only the “traversal zone” remains gameable by moving machinery into helpers; it also lacks the requested symbol/data-flow or whole-candidate call-graph analysis.

3. **Fallback/DPO contradiction — FIXED.** Floors are excluded from SFT, failed candidates are retained, and DPO is restricted to equal-correctness pairs.

4. **Unsound catalog transformations — FIXED.** C4/C8–C12 are deferred with accurate blockers; active scope is appropriately narrowed to C1/C2/C5.

5. **Incorrect Jac traversal assumptions — FIXED.** Version-pinned syntax, non-deduplication, explicit guards, typed traversal, and dead-end behavior are now stated accurately.

## 2. New fatal flaw

**No wholly new fatal flaw, but the attempted C2 ordering solution creates a contradiction:** observable BFS/DFS order cannot generally be reconstructed by sorting or post-collection level partitioning. Exact DFS/path order may require precisely the frontier/stack state the elimination gate prohibits. Either exclude order-observable C2 records or explicitly permit and gate a semantics-preserving ordering mechanism.

## 3. Remaining weaknesses

### Must fix now

- **C5 is still under-specified and insufficiently probed.** The probe establishes disconnect syntax, not node removal, deletion during walker execution, all incoming-edge cleanup, root attachment cleanup, hook ordering, or rollback after hook failure. Require a version-pinned two-phase collect/disconnect/delete probe and an explicit failure protocol.
- **Repo-lineage splitting is internally inconsistent.** `split_group = owner/name` does not group forks under different owners. Use a canonical upstream/fork-lineage identifier, with duplicate/mirror detection.
- **Close the elimination escape hatch.** Scan the entire candidate and reachable helpers, not merely façade + walkers; retain ongoing sampled audits after the first 50.
- **Fix cycle-policy wording.** `else { disengage; }` handles dead ends, not cycles; it must not be listed as a cycle policy.
- **Repair schema consistency.** `floor_status` is described but absent, and fallback records do not clearly define whether `osp_jac` contains the floor or is null.

### Acceptable v2 tradeoffs

AST detector false positives, reviewed `py2jac` ports, test-retargeting cost, source-derived negative cases, and the 20% synthetic cap are reasonable for this frozen scope.

**Verdict: FIX FIRST — C2 observable ordering, C5 deletion semantics, canonical fork-lineage splits, whole-candidate elimination scanning, cycle wording, and schema consistency.**
---
Reviewer: gpt-5.6-sol (round 2, 2026-08-26). Verdict was FIX FIRST (6 items);
all 6 applied in v2.1: §2 cycle/dead-end wording split, §5.3 order-observable
C2 scope-out, §5.5 two-phase mutation + deletion-probe blocker, §8.2
whole-record scan + permanent 10% sampling, §8.4 floor_status + osp_jac:null,
§8.5 canonical fork-lineage split_group.
