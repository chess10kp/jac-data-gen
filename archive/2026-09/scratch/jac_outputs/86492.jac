"""Merge dicts by key."""
def merge_dict[V](this: dict[str, V], other: dict[str, V], cb: Callable[[V, V], V]) -> dict[str, V] {
    result = {};
    result.update(this);
    result.update(other);
    for key in this.keys() & other {
        result[key] = cb(this[key], other[key]);
    }
    return result;
}