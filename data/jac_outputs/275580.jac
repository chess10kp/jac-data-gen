"""Returns a new dictionary containing only the given keys."""
def only_keys[K, V](d: dict[K, V], *keys: K) -> dict[K, V] {
    result: dict[K, V] = {};
    for key in keys {
        if key in d {
            result[key] = d[key];
        }
    }
    return result;
}