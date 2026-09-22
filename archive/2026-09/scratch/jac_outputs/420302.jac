"""Strips entries of dict with no value, but allow zero."""
def _strip_empty(d: dict[str, object]) -> dict[str, object] {
    return {
        k: v
        for (k, v) in d.items()
        if v or (type(v) == int and v == 0) or (type(v) == str and v == "")
    };
}