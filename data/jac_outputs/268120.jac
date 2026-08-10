"""dict.pop(key) where `key` is a `.`-delimited list of nested keys."""
def pop_recursive(d: dict[str, object] | object, key: str, `default: object = None) -> object {
    if not isinstance(d, dict) {
        return `default;
    }
    if key in d {
        return d.pop(key, `default);
    }
    if '.' not in key {
        return `default;
    }
    (key_head, key_tail) = key.split('.', maxsplit=1);
    if key_head in d {
        return pop_recursive(d[key_head], key_tail, `default);
    }
    return `default;
}