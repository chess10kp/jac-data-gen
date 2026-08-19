# Step 4 full-loop report

**Date:** 2026-08-12  
**Idiomize mode:** `zen` (mock = returns floor)  
**Dedup:** ROUGE-L @ 0.9 (minhash-LSH blocked)  
**Throughput:** 0.04 rec/s

## Yield ladder (cov>=90 records)

| stage | count |
|-------|------:|
| processed | 40 |
| py2jac_fail (drop) | 1 |
| test_fail (drop) | 1 |
| floor_pass | 14 |
| kept (idiomatic or floor) | 14 |
| **final after dedup** | **14** |

## Source split of final

- idiomatic: 1
- floor: 13
- dedup dropped: 0

## Notes

- With idiomize=mock, source split is 100% floor and idiomatic=0. The idiomatic ratio becomes the headline quality metric once the real model is wired into `idiomize()`.
- This run validates the full plumbing (idiomize seam + keep/fallback + jac fmt + ROUGE-L dedup) end to end.

## Artifacts

- `dataset.jsonl` — final deduped dataset ({id, entrypoint, source, jac})
- `full_results.jsonl` — per-record stage + source
- `manifest.json` — this yield ladder
