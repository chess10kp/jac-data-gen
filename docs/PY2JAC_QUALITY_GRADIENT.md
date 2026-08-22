# py2jac idiomatic corpus — hidden quality gradient (audit note, 2026-08-19)

Pinned file: `data/py2jac_dataset_idiomatic.jsonl` @ 11fa3f45 (9,367 rows; +4 later → 9,371 @ eb61bf8c).
Conclusion: the second half is not a random half — it is the weak tail of the source pipeline.

## Composition (verified against `data/composer_dataset.jsonl`, 15,144 rows)

| Slice | Idiomatic rows | Origin |
|---|---:|---|
| First half (chunk=None) | 6,424 | step4b–e composer waves — exactly the `dataset_composer.jsonl` idiomatic sets (1608+1583+1614+1619, verified equal by id) |
| rec_9000 | 1,321 | recovery chunk, source offset 9000 |
| rec_11000 | 551 | offset 11000 |
| rec_13000 | 456 | offset 13000 |
| rec_15000 | 551 | offset 15000 |
| rec_17000 | 67 | offset 17000 |
| rec_repair | 1 | |

2,947 of the 4,684 second-half rows are recovery rows. `agent_idiomize_prep.py` walks the
source dataset (`nuprl/stack-dedup-python-testgen-starcoder-filter-v2`) sequentially after
`coverage >= 90`; no shuffle, no ranking — production order became positional order.

## The oracle gets weaker with offset

| Metric | First half | Second half |
|---|---:|---:|
| Mean hidden tests | 29.1 | 19.7 |
| Median hidden tests | 21 | 14 |
| Median tests / est. complexity | 8.8 | 6.0 |
| rec_15000 median | | 9 |
| rec_17000 median | | 7 |

Source size/complexity ~unchanged. Late waves are weakly *supervised*, not smaller.
`data/chunks/feeder.log` (chunk_17000): ~68% of coverage>=90 records fail the floor guard —
survivors are enriched for suites too weak to catch anything.

Known survivors of the weak oracle (pass `jac check` + their own happy-path tests):
- id=18787 `find_one_possible_value` — declares `dict[int,int]`, tests pass `list[str]`
- id=68775 `filterClusterByDis` — string keys declared, integer keys tested
- id=46797 `parse_categorised_lists` — single empty-data test; callbacks never exercised

Not a syntax collapse: parse-check 100% both halves; full type-check failures 20 vs 13.
No generator-model switch: same composer-2.5 seam (`cursor_composer_batch.py`) for both halves.

## What changed in the pipeline (root cause chain)

1. **Designed method** — `scripts/step4_full_loop.py` step 2b **mutation gate**
   (`_MUTATION_GATE = 0.80`, `scripts/step4_mutation.py`): before any idiomize swap,
   inject semantics-breaking mutants into the floor and require the hidden suite to kill
   ≥80%; weak-oracle records are kept as floor and never swapped. Validated on only a
   20-record calibration run (`data/step4/full_results.jsonl`: mean 0.915, 2 weak).

2. **Scale-up silently dropped it.** The mass-production rewrite
   (`scripts/agent_idiomize_prep.py` → `scripts/cursor_composer_batch.py` →
   `scripts/agent_idiomize_guard.py`) ported only: coverage≥90 → py2jac → floor passes
   hidden tests → candidate passes `jac check` + **the same** hidden tests → keep.
   No mutation score, no test-count/diversity floor, no independent semantic oracle.
   ALL 9,371 idiomatic rows (both halves) came from this un-gated path. The quality
   gradient then tracks source-offset test weakness.

3. **Recovery prep was further weakened** — `scripts/prep_for_candidates_fast.py`
   (Aug 12–13, chunks 9000/11000/15000): rebuilt purged `work/` dirs with py2jac ONLY,
   skipping the floor `jac test` (benign for idiomatic rows — the guard re-tests the
   candidate — but it re-admits records whose floor can no longer pass, and the floor
   fallback rows in those chunks are unverified).

4. **Guard itself never weakened between halves.** Diff vs frozen commit 3e249607 is
   robustness-only (embedded-PG socket fix, DPO rejected-side retention). Semantics
   identical: `jac check` + `jac test` on hidden tests.

5. **Export erased provenance.** `scripts/reguard_paid.py` exports the `source=="idiomatic"`
   subset of the master but drops the `chunk` field — the positional gradient became
   invisible downstream (07 SFT run consumed the blended file).

Also: js2jac's later gates (`fidelity_gate.py` 4996abc8, `behavioral_gate.py`) were never
applied to the py2jac path. Sonnet-seam rows (`dataset_sonnet.jsonl`) were never merged
into the master — first half is composer-only.

## Consequences

- "9,367 idiomatic records" overstated effective data: late rows are happy-path dominated,
  overconfidently typed, accepted by an oracle that cannot see those errors.
- 07 trailing 06 despite more rows is consistent with dilution of the strong first 6,424.

## Clean causal ablation (proposed)

1. Export A: first 6,424 only.
2. Export B: all rows (status quo).
3. Export C: all rows, filtered by test count/diversity + mutation strength
   (re-derive with the mutation gate that was designed but never wired in).

Work dirs with `floor_fn` + `test_blocks` survive for all bad chunks
(chunk_9000: 1927, chunk_11000: 1921, chunk_13000: 718, chunk_15000: 1573,
chunk_17000: 500), so a mutation-gated re-derivation needs **no new model calls**.
