"""Transforms value to number."""
def to_number(mapping: dict[str, str], bind: str, value: str | int | float | bool | None) -> float | None {
    if value {
        return float(value);
    }
    return None;
}