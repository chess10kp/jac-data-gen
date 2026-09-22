"""Extracts first element of pandas Series s, or returns s if not a series."""
def first_elem(s: object) -> object {
    try {
        accessor = getattr(s, "iloc");
        return accessor[0];
    } except AttributeError {
        return s;
    }
}