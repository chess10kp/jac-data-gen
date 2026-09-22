"""Compares two dictionaries and returns list of keys where values are different"""
def changed_keys(a: dict[str, object] | None, b: dict[str, object] | None) -> list[str] {
    if a is not None and b is not None {
        return [k for (k, _) in b.items() if k in a and a[k] != b[k]];
    }
    return [];
}