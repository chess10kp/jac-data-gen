# Calibration run — 1,000 records, Claude Sonnet idiomize

**Date:** 2026-08-08
**Idiomize model:** Claude Sonnet (`claude-sonnet-5`) via Claude Code subagents
**Concurrency:** 94 batches × 10 records, 14 concurrent (workflow cap)
**Guard:** `jac check` (static) + `jac test` (runtime) + timeout → keep-or-floor

## Yield ladder

| stage | count |
|-------|------:|
| requested | 1000 |
| py2jac_fail (drop) | 24 |
| test_fail floor guard (drop) | 38 |
| floor_pass → idiomize | 937 |
| dedup dropped | 1 |
| **final dataset** | **936** |

## Idiomatic keep-rate (headline)

| source | count | share |
|--------|------:|------:|
| **idiomatic** (Sonnet rewrite kept) | 741 | **79.2%** |
| floor (fallback) | 195 | 20.8% |

Of the 195 floored: ~70% behavior-drift caught by `jac test`, ~30% static `jac check`
failures, 1 non-terminating rewrite caught by timeout. All correctly guarded — a
floored record is still a valid, correct sample.

## Rubric quality (idiomatic rewrites only, n=741)

Mean score **2.30 / 3.0**. Band distribution:

| band | count | share |
|------|------:|------:|
| A (strong idiomatic) | 53 | 7.2% |
| B (acceptable) | 668 | 90.1% |
| C (weak) | 20 | 2.7% |
| D (reject) | 0 | 0% |

vs. free-gateway baseline (`deepseek-v4-flash-free`): all Band B, 0 Band A, idiom 0.53.
**Sonnet lifts quality meaningfully** (7% Band A, mean 2.30) under a stricter 3-gate guard.

## Throughput & cost

| phase | wall | notes |
|-------|-----:|-------|
| prep (py2jac + floor guard) | 611s | deterministic, 8 workers |
| idiomize (94 Sonnet agents) | 398s | 6.78M tokens, 14 concurrent |
| guard (check+test+fmt+dedup) | 498s | 12 workers |
| **end-to-end** | **~25 min** | stages sequential; ~7.2k tokens/record |

## Extrapolation to full scale (~125k floor-pass of 133,668)

- **Tokens:** ~125k × 7.2k ≈ **~900M Sonnet tokens** (subscription-billed).
- **Idiomize wall:** ~2.35 rec/s at 14 concurrent → **~15h agent time**, longer on
  calendar if subscription rate limits throttle sustained load.
- **Expected yield:** ~79% idiomatic (~99k idiomatic + ~26k floor), ~7% Band A.

## Verdict

Pipeline is production-ready: prep → Sonnet idiomize → 3-gate guard → dataset, fully
parallel and subscription-billed. Quality is solidly Band B with a Band-A tail.
Full-scale is a ~900M-token / ~day-of-compute commitment — the go/no-go decision.
