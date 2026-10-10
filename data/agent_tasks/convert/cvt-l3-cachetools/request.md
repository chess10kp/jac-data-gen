hey — we vendor a cut-down copy of `cachetools` (in `python/cachetools/`: `__init__.py` with Cache/FIFOCache/LFUCache/LRUCache/TTLCache, plus `keys.py`). I'd like a native Jac version of it split over a few modules:

- `basecache.jac` — `Cache`: a size-bounded mutable mapping. `Cache(maxsize=..., getsizeof=None)`, `maxsize` field, read-only `currsize`, `[]`/`del`/`in`/`len`/iteration, `get`, `pop`, `setdefault`, `clear`, `popitem`, the `__missing__` hook, plus the usual `update()`/`keys()` mapping helpers. Same `ValueError`s as upstream (negative maxsize, negative or too-large value size).
- `policies.jac` — `FIFOCache`, `LRUCache`, `LFUCache`, all subclasses of `Cache` with the upstream eviction order.
- `ttl.jac` — `TTLCache(maxsize=..., ttl=..., timer=...)` (LRU + per-item expiry, `timer` defaults to `time.monotonic`), including `expire()` returning the expired `(key, value)` pairs and the `KeyError` when you delete an expired key.
- `cachekeys.jac` — `hashkey`, `typedkey`, `methodkey`.

Keep the behaviour identical to the Python (eviction order, size accounting, which errors are raised). Use Jac `obj`s rather than Python-style classes, and obviously no importing cachetools itself. Make sure `jac check` passes on all four files.
