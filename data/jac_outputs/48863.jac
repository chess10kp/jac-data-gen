"""Determine whether or not *name* is an "__internal" name."""
def _is_internal_name(name: str) -> bool {
    return name.startswith("__") and not name.endswith("__");
}