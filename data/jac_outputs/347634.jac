"""Get a value from nested dictionaries by dotted key path or key list."""
def rget(source: dict[str, str | dict[str, str]], keys: str | list[str]) -> str | dict[str, str] | None {
    if not keys or not source {
        return;
    }
    if isinstance(keys, str) {
        keys = keys.split(".");
    }
    this_key = keys.pop(0);
    if len(keys) {
        return rget(source.get(this_key, {}) as dict[str, str | dict[str, str]], keys);
    }
    return source.get(this_key);
}