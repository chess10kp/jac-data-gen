# OSP Repair Traces v1

Harvested repair dataset for Jac OSP (object-spatial) code generation, packed by
`scripts/gen/pack_repair_traces.py` from the existing OSP gate/test ledgers.
Every "fixed" side is gate-verified upstream (`jac check` + `jac test` PASS);
zero generation cost — this is a harvest, not a new synthesis run.

## Splits

| file | rows | what it is |
|---|---|---|
| `code_fix.jsonl` | 1,004 | broken attempt (code + real compiler error) → verified passing version of the same task |
| `test_fix.jsonl` | 1,449 | broken testgen attempt (tests + failure) → test-verified passing tests |
| `trajectory.jsonl` | 745 | full multi-attempt minimax repair sequences (gate fails with per-step error codes → final pass) |
| `broken_pool.jsonl` | 6,788 | broken code + real error, no known fix yet — the gate-in-the-loop (Tier A) generation feed |

## Provenance

- Broken side: `osp_{minimax,composer,glm,gpt,luna,muse}_failures.jsonl` (gate-stage
  attempts, earliest row carrying code per id) and `osp_testgen_failures.jsonl`.
- Fixed side: `data/osp_dataset_pass.jsonl` (exact-id match, latest record per id;
  `test_verdict=PASS`) and `osp_test_results.jsonl` (`verdict=PASS`).
- Pairing key: exact record id (`<task>__<generator>`), so a broken minimax attempt
  pairs with the verified pass of the same id.
- Generator versions: minimax-m3, composer-2.5, glm, gpt, luna, muse; validator jac 0.36.1.

## Schema (per split)

`code_fix`: `{id, split, target_id, source:"natural", verification, prompt,
broken:{generator, attempt, stage, error, error_code, code, ts},
fixed:{generator, generator_model_id, code, jac_tests, test_verdict, test_detail, gate_class, ts}}`

`test_fix`: `{id, split, target_id, source, verification, broken_tests:{stage, error, tests, ts},
fixed_tests:{tests, detail, run_tag, ts}, program_code}`

`trajectory`: `{id, split, target_id, source:"natural_harvest", prompt, n_attempts,
steps:[{attempt, stage, status:"fail", error, error_code, code, ts}],
final:{code, jac_tests, test_verdict, status:"pass"}}`

`broken_pool`: `{id, split, target_id, generator, n_attempts, error, error_code, code, ts,
fault_class:"unlabeled"}`

## Broken-pool error-code histogram (top)

E1030 611 · E0013 572 · E0002 556 · E0001 394 · E0048 375 · E0076 272 · E0004 234 ·
E1001 225 · E1099 135 · E1117 116 · E0034 106 · unparsed 2423

Not an E1032 wall — the pool is a broad mix of syntax (E0001/E0002) and
graph-semantics (E1030, E0048) faults; ~2.4k errors carry no `error[Exxxx]` code
(runtime/harness failures) and need their own classifier.
