"""Creates a new dict with a union of the elements of the arguments."""
def _add_dicts[K, V](*dicts: dict[K, V]) -> dict[K, V] {
    result = {};
    for d in dicts {
        result.update(d);
    }
    return result;
}