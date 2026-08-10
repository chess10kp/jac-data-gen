"""
    Safely get a value that may not exist.
    Raise LookupError on the name if the value doesn't exist.
    This is intended as a helper for getters.
    """
def deferred_value(name: str, val: int | float | str | bool) -> int | float | str | bool {
    if val {
        return val;
    }
    raise LookupError(f'{name} not ready');
}