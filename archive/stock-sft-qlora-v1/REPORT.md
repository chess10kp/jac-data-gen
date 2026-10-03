# stock SFT qlora-v1 — function-eval-v1 test split (corrected)

Single-stage QLoRA SFT of `ornith-ai/Ornith-1.5-9B` on the gated
translation+OSP corpus, graded on the frozen `evals/function/v1` test suite
(972 problems x 4 samples). Final numbers merge the original 120s-cap grading
with a 300s-cap regrade of every timeout/infra sample (same jac 0.36.1
binary, clarity3).

## Headline (corrected, 2026-10-03)

| metric | value |
|---|---|
| problems / samples           | 972 / 3888 |
| pass@1                       | **44.16%** (0.441615) |
| pass@2                       | 46.09% (0.460905) |
| pass@4                       | 47.06% (0.470649, 971 eligible) |
| task_success_rate            | 44.15% |
| check_rate                   | 45.24% |
| statuses                     | 1716 pass / 37 test_fail / 2129 check_fail / 5 timeout / 1 infra_error |

## The 120s-cap artifact (why the first headline was 7.19%)

The original grading run capped sample execution at 120s and produced pass@1
7.19% (269 pass / 1360 timeout / 106 infra). All 1466 timeout/infra samples
were regraded at a 300s cap: **1447 now pass**. 620 of the recovered passes
execute in >120s (median 111s, p90 176s) — the 120s cap, not the model, caused
the original headline. check_rate is unchanged at 45.2% (static checks are
unaffected by the cap). Rule of thumb going forward: grade this suite at
>=300s, or report both caps.

## Provenance

| field | value |
|---|---|
| base model | ornith-ai/Ornith-1.5-9B (stock, no Jac CPT stage) |
| adapter | runs/qlora-v1 (clarity3, TRAIN_EXIT=0, 4050/4050 steps, 2 epochs, train_loss 0.2032) |
| recipe | QLoRA NF4, r=32/alpha=64, all linear projections, lr 1e-4 cosine, global bs 32, 4k ctx — see training/README.md |
| eval suite | evals/function/v1 (problems_sha256 357ccd1c7d41b231f275bfd2b4c91c35403abfdd28bf67c32b27daea851a45c3) |
| samples_sha256 | 06e5956700894448b12574e5b3df20367ced8a7c625f08270f2f40017e3c621c |
| grader | eval_jac.py, jac 0.36.1, graded 2026-09-30T23:46:01Z; regrade 2026-10-02/03 on clarity3 (19 chunks, 300s cap) |
| training data | 2026-09-28 build: 64,794 train / 1,234 val, OSP ~10.3% (--upsample-osp 3) |

## Static diagnostics (merged set)

| metric | value |
|---|---|
| typed_def rate              | 49.7% |
| no_dynamic_types            | 95.8% |
| no_python_syntax residue    | 100% |
| no import py / no test blocks | 100% / 100% |
| mean source lines           | 8.63 |

Reported independently; no aggregate idiomaticity score.

## Files

| file | sha256 |
|---|---|
| summary.json (corrected merged) | f305c91af858d6d574a1bc3d638eb945e08de479235890c27317e8a0654dde22 |
| results.jsonl (3888 merged per-sample grades) | 5446cb6f92c6cdafbc9b3c800635bf1ec3f24bc5803bfeef9c3f13b0aac3d175 |
| samples_suite.jsonl (raw generations) | 06e5956700894448b12574e5b3df20367ced8a7c625f08270f2f40017e3c621c |
| original-120s/summary.json (pre-regrade headline) | df17e638cc5767e3b903ce620d3e694fd0e6061c1c74890b93a0cce5f1eeab7c |

Untracked full-resolution sources: `runs/qlora-v1-eval/graded-merged/`
(merged), `runs/qlora-v1-eval/rerun_c3/` (raw regrade chunks),
`runs/stock-sft-qlora-v1/manifest.json` (run manifest incl. md5s of the
original graded files and trainer_state.json pointer on clarity2).
