"""Walks a data structure composed of nested lists/tuples/dicts, and
    creates a new (equivalent) structure in which the leaves of the data
    structure (i.e the non-list/tuple/dict data structures in the tree) have
    been mapped through f."""
def modify_leaves(f: Callable[[object], object], ds: object) -> object {
    if isinstance(ds, list) {
        return [modify_leaves(f, sds) for sds in ds];
    }
    if isinstance(ds, tuple) {
        return tuple(modify_leaves(f, sds) for sds in ds);
    }
    if isinstance(ds, dict) {
        return {k: modify_leaves(f, sds) for (k, sds) in ds.items()};
    }
    return f(ds);
}