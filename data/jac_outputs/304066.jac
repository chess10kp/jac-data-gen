"""return dictionary with given keys"""
def slice[V](d: dict[str, V], keys: Iterable[str]) -> dict[str, V] {
    result: dict[str, V] = {};
    for k in keys {
        if k in d {
            result[k] = d[k];
        }
    }
    return result;
}