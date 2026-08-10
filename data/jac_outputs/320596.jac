"""Serializes odml style tuples to a string representation."""
def tuple_set(value: list[str] | tuple[str, ...] | None) -> str | None {
    if not value {
        return None;
    }
    return "(%s)" % ";".join(value);
}