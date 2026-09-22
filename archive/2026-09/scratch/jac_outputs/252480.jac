"""Determine if the potential has any values."""
def is_nonempty(pot: dict[str, object | None]) -> bool {
    return any(val is not None for val in pot.values());
}