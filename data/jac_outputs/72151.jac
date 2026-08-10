"""Return a new dict from a list of dicts by repeated calls to update(). Keys in later
    dicts will override those in earlier ones. *deleted_keys* is a list of keys which should be
    deleted from the resulting dict.
    """
def merge_dicts[K, V](*dicts: dict[K, V], deleted_keys: list[K] = []) -> dict[K, V] {
    rv = {};
    for d in dicts {
        rv.update(d);
    }
    for k in deleted_keys {
        delete(rv[k],);
    }
    return rv;
}