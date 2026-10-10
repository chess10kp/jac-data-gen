I pulled `NormalDist` out of the stdlib `statistics` module into `python/normal_dist.py` (tests in `python/test_normal_dist.py`). I want the same thing natively in Jac, as `normal_dist.jac`.

Requirements:
- `NormalDist` should be a Jac `obj` with fields `mu` (default 0.0) and `sigma` (default 1.0), constructible positionally like `NormalDist(100, 15)`; negative sigma raises `StatisticsError` (a `ValueError` subclass, also exported from the module). Store both as floats.
- Read-only properties `mean`, `median`, `mode`, `stdev`, `variance`.
- Methods `pdf`, `cdf`, `inv_cdf`, `quantiles(n=4)`, `overlap(other)`, `zscore(x)` and a static `from_samples(data)`, with the same error behavior as the Python (`StatisticsError` for zero sigma / bad p, `TypeError` when `overlap` gets a non-NormalDist).
- The arithmetic operators (`+`, `-`, `*`, `/` with constants or another NormalDist, unary `+`/`-`, reflected versions where Python has them), equality, hashing and the `NormalDist(mu=..., sigma=...)` repr.

Use the same Wichura AS241 approximation for `inv_cdf` so results match to full precision. No importing `statistics` or the Python file; `jac check` must be clean.
