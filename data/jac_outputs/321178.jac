"""Determines the length of L.

Uses either cardinality or __len__ as appropriate."""
def _len(L: list[int] | str) -> int | float {
    try {
        return getattr(L, "cardinality")();
    } except AttributeError {
        return len(L);
    }
}