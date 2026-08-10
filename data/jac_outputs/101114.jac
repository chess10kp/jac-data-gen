"""Return a flat list of key tuples from a nested sequence."""
def _flatten_keys(key_seq: list[object]) -> list[tuple[object, ...]] {
    flat_keys: list[tuple[object, ...]] = [];
    for key in key_seq {
        if not isinstance(key, tuple) {
            flat_keys += _flatten_keys(key as list[object]);
        } else {
            flat_keys.append(key);
        }
    }
    return flat_keys;
}