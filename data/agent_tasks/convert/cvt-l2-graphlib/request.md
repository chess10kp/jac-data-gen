Can you port `python/graphlib.py` (CPython's topological sorter; its tests are in `python/test_graphlib.py`) to Jac? Put it in `topo_sort.jac` at the project root.

What I need:
- `TopologicalSorter` as a Jac `obj`. Since `graph` is a keyword in Jac, the optional constructor argument should be a field called `deps` (a dict mapping each node to an iterable of its predecessors), so `TopologicalSorter(deps={...})` or just `TopologicalSorter()`.
- Methods `add(n, *predecessors)`, `prepare()`, `get_ready()` (returns a tuple), `is_active()`, `done(*nodes)` and `static_order()` (a list is fine instead of a generator). Truthiness should follow `is_active()`.
- `CycleError` must still be a `ValueError` subclass with the cycle as `args[1]`.

Keep every behavior of the original: same ordering, the same ValueError messages ("prepare() must be called first", "cannot prepare() more than once", "node X was not added using add()", etc.), and `get_ready()` still usable after a CycleError. Don't import `graphlib` — this should be a real port, and `jac check` has to pass.
