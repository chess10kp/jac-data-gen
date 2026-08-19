# Step 2 report: test translation via py2jac

**Date:** 2026-08-05  
**Dataset:** `nuprl/stack-dedup-python-testgen-starcoder-filter-v2` (Python source for MultiPL-T)  
**Samples:** 5 records from `data/samples/python_source_examples.json`

## Question

Can we turn MultiPL-T's Python `assert` test cases into runnable Jac tests at scale by
concatenating `content + tests` into one `.py` and running `jac tool py2jac`?

## Answer

**Yes, with two small mechanical transforms.** The core path works on all 5 samples.

| ID | entrypoint | tests | py2jac | jac test | notes |
|----|------------|-------|--------|----------|-------|
| 147075 | `_isIPv4Addr` | 6 | pass | 6/6 pass | |
| 295211 | `pysiphash` | 23 | pass | 23/23 pass | |
| 377941 | `csim_to_scamp5` | 20 | pass | 20/20 pass | |
| 313569 | `_extract_url_and_sha_from_deps_entry` | 37 | pass | 37/37 pass | |
| 207145 | `isFrozen` | 53 | pass* | 53/53 pass | *needs `u''` strip |

## What py2jac does

1. Transpiles the function body to Jac.
2. Puts module-level `assert` statements into a trailing `with entry { ... }` block.

Example (`147075`):

```jac
def _isIPv4Addr(strIPv4Addr: Any) -> object { ... }

with entry {
    assert (_isIPv4Addr('192.0.2.1') == True);
    ...
}
```

- `jac run` executes `with entry` asserts (works as a guard).
- `jac test` does **not** collect `with entry` blocks — it needs `test "name" { assert ... }`.

## Required transforms (not optional for the harness)

### 1. Strip Python 2 `u''` prefixes (~6.8% of rows in a 5k sample)

`py2jac` fails on `u'foo'` / `u"bar"` string literals. A regex
`re.sub(r"\bu(['\"])", r"\1", src)` fixes this. On 5,000 streamed rows:

- 0.7% in `content`
- 6.6% in `tests`
- 6.8% in either field

### 2. Convert `with entry` → `test` blocks (for `jac test`)

Split each assert in the `with entry` block into:

```jac
test "t0" {
    assert (f(1) == 2);
}
```

After both transforms, all 139 asserts across 5 samples pass `jac test`.

## Implication for the batch harness (step 4)

The pipeline is **mechanical**, not a custom assertion compiler:

```
record → normalize u-prefix
       → concat content + tests → .py
       → jac tool py2jac
       → with_entry_to_tests()
       → jac test (guard for idiomize step)
```

No hand-written Python-assert→Jac compiler is needed. The only new code is ~40 lines
of preprocessing/postprocessing around `py2jac`.

## Artifacts

| Path | Description |
|------|-------------|
| `data/step2/work/*.py` | Concatenated Python (function + asserts) |
| `data/step2/jac/*.jac` | Raw py2jac output (`with entry`) |
| `data/step2/jac_testfmt/*.jac` | Converted to `test` blocks |
| `data/step2/results.json` | First pass (before test-block conversion) |
| `data/step2/results_testfmt.json` | After conversion — all pass |
| `scripts/step2_translate_tests.py` | Reproducible script |

## Open items for step 4

- Measure py2jac failure rate on a larger slice (not just `u''`; other syntax edge cases may exist).
- Decide guard command: `jac run` (simpler, uses `with entry` as-is) vs `jac test` (needs conversion, better pytest reporting).
- Log and skip records that fail py2jac; do not silently drop without metrics.
