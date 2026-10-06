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

## 2026-10-04 finding: completion track 0% is a grader artifact

`eval_jac.py:assemble_source` prepends the problem `prefix` only when the
sample dict carries a `completion` key — but the harness stores generations
under `output`, so every completion sample was checked as a standalone
fragment (unparseable by construction: `unexpected token 'return'` at the
continuation). Translation (whole-file outputs) was unaffected. Evidence:
re-checking `prefix+output` for all 1944 completion samples gives
**check_pass 91.8% (1785/1944; 476/486 problems >=1, 404 4/4)** vs the
recorded 0.0%.

Behavioral regrade of a 117-sample spread subset (30 problems, 300s cap):
45 pass / 63 test_fail / 8 timeout / 1 infra → **38.8% behavioral among
completed** (n=116, 95% CI ~±9pt) — far below translation's 97.6%, so
completion semantics, not syntax, is the real gap. Implied completion
pass@1 ≈ 0.92 × 0.39 ≈ **0.36** and overall pass@1 ≈ (0.88 + 0.36)/2 ≈
**0.62** (vs 0.44 recorded). Pending: fix the assembly dispatch and regrade
the full completion track.

Fix: dispatch `assemble_source` on `problem["task"] == "completion"`
(prepend prefix/suffix regardless of sample key), or have the harness emit
the `completion` key for completion-task rows.

## 2026-10-06 partial behavioral regrade of the completion track

Full-grader regrade with the assembly fix (`assemble_source` dispatches on
`problem["task"]`, `scripts/eval/eval_jac.py` this commit; frozen
`fn_eval_preds` copy untouched). Same jac 0.36.1 binary, 300s cap, graded on
clarity2. Stopped at user request with 1526/1944 completion samples graded
(485/486 problems touched; zero infra errors). Supersedes the 0.36 estimate
above — the subset was slightly pessimistic.

| pass@k (unbiased estimator) | translation (486) | completion (partial) | combined |
|---|---|---|---|
| k=1 | 88.3% | **39.0%** (485 elig.) | **63.6%** |
| k=2 | 92.2% | 46.6% (473 elig.) | 69.4% |
| k=4 | 94.2% | 50.0% (172 elig.) | 72.1% |

Completion sample statuses: 590 pass / 786 test_fail / 135 check_fail /
15 timeout. check_rate 91.2% (vs 91.8% check-only projection); behavioral
pass among check-clean 42.4% (vs 38.8% on the 117 subset). Translation
figures reproduce the recorded regrade exactly (1716/1944 samples, 458
problems >=1 pass, 387 4/4, 97.6% behavioral|check).

Caveats: completion pass@4 rests on the 172 problems with all four samples
graded; k=1/2 on 485/473. Extrapolating the graded 78.5% to full coverage
would move combined pass@1 by <1pt (the one untouched problem and 418
missing sample slots are spread ~uniformly). The completion-vs-translation
gap is behavioral, not syntactic: 91% of completions parse and typecheck,
only 42% of those pass hidden tests.

## Files

| file | sha256 |
|---|---|
| summary.json (corrected merged) | f305c91af858d6d574a1bc3d638eb945e08de479235890c27317e8a0654dde22 |
| results.jsonl (3888 merged per-sample grades) | 5446cb6f92c6cdafbc9b3c800635bf1ec3f24bc5803bfeef9c3f13b0aac3d175 |
| regrade-completion-partial/results.jsonl (1526 fixed-grader completion grades) | c06629098a6084d1f8dd803937c4e3aa70859585fbee3fe33733fcdd58196ea2 |
| samples_suite.jsonl (raw generations) | 06e5956700894448b12574e5b3df20367ced8a7c625f08270f2f40017e3c621c |
| original-120s/summary.json (pre-regrade headline) | df17e638cc5767e3b903ce620d3e694fd0e6061c1c74890b93a0cce5f1eeab7c |

Untracked full-resolution sources: `runs/qlora-v1-eval/graded-merged/`
(merged), `runs/qlora-v1-eval/rerun_c3/` (raw regrade chunks),
`runs/stock-sft-qlora-v1/manifest.json` (run manifest incl. md5s of the
original graded files and trainer_state.json pointer on clarity2).
