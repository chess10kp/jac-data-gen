"""Increments value stored in the `obj` under `key`.

    Returns the incremented value.

    If value with specified key does not exist, then initializes it with
    `default` and then increments it.
    """
def incrementdefault(`obj: dict[str, int], key: str, `default: int = 0) -> int {
    val = `obj.setdefault(key, `default) + 1;
    `obj[key] = val;
    return val;
}