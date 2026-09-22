"""Returns a dictionary containing None for all keys."""
def _makeDefValues(keys: list[str]) -> dict[str, None] {
    return {k: None for k in keys};
}