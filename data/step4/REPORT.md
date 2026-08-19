# Step 4 report: mechanical floor yield (batch, parallel)

**Date:** 2026-08-06  
**Dataset:** `nuprl/stack-dedup-python-testgen-starcoder-filter-v2` (coverage >= 90)  
**Slice:** processed 1000  
**Throughput:** 2.13 rec/s  

## Headline

- **Floor yield: 936/1000 = 93.6% (95% CI ±1.5pp)**  
- py2jac_fail: 24  
- test_fail (py2jac ok, floor/tests wrong — incl. bad source data): 40  
- Extrapolated floor-pass over the 133,668 cov>=90 set: ~125,113  
- py2jac p50/p95: 701.8 / 1575.0 ms  

## Top py2jac failure signatures

| count | signature |
|------:|-----------|
| ✖ Error: Error executing 'tool': Internal Compiler Error: Pass PyastBu | 20 |
| ✖ Error: /tmp/j4_120544_vxz554ez/120544.py, line 1, col 74: Unterminat | 1 |
| ✖ Error: /tmp/j4_308598_giiwisox/308598.py, line 1, col 74: Unterminat | 1 |
| ✖ Error: /tmp/j4_435430_lvurtjod/435430.py, line 10, col 555: Missing  | 1 |
| ✖ Error: /tmp/j4_33584_b5p1p253/33584.py, line 1, col 74: Unterminated | 1 |

## Top test_fail signatures

| count | signature |
|------:|-----------|
| note: /tmp/j4_415993_rvs4h6k7/415993.jac preferred native but did not  | 1 |
| note: /tmp/j4_66194_mdarv7ro/66194.jac preferred native but did not lo | 1 |
| note: /tmp/j4_428396_3zvqflmu/428396.jac preferred native but did not  | 1 |
| note: /tmp/j4_399021_g9bcse4k/399021.jac preferred native but did not  | 1 |
| E   AssertionError: assertion failed at /tmp/j4_86106_cuzbynev/86106.j | 1 |
| note: /tmp/j4_129424_5coyje9x/129424.jac preferred native but did not  | 1 |
| note: /tmp/j4_6675_s0f0j83n/6675.jac preferred native but did not lowe | 1 |
| note: /tmp/j4_149181_iqier0zg/149181.jac preferred native but did not  | 1 |
| note: /tmp/j4_252490_1vbctd9u/252490.jac preferred native but did not  | 1 |
| collected 0 items / 1 error | 1 |
| assert (ensure_path("/a/b/c/d") == "/a/b/c/d");; | 1 |
| Fatal Python error: Segmentation fault | 1 |
| note: /tmp/j4_34192_gf5zse5c/34192.jac preferred native but did not lo | 1 |
| note: /tmp/j4_159959_2mmj_shk/159959.jac preferred native but did not  | 1 |
| E   AssertionError: assertion failed at /tmp/j4_336477_q2bp3vez/336477 | 1 |

## Interpretation

Floor yield is the candidate pool for the idiomize step. test_fail records are dropped (one confirmed case, mergesort 415993, fails in pure Python — bad source data, not a py2jac bug). py2jac_fail records are dropped too. Multiply floor yield by the idiomatic-keep ratio (step 3: 5/5 on the hand sample) for the expected idiomatic dataset size, then subtract jac fmt + ROUGE-L dedup losses.

## Artifacts

- `floor_results.jsonl` — per-record outcome
- `floor_stats.json` — this aggregate
- `failures/{py2jac_fail,test_fail}/<id>.{py,jac,err}` — persisted failure samples
