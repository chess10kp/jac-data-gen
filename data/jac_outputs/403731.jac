"""Convert string to float, but also handles None and 'null'."""
def to_float(val: str | int | float | None) -> float | None {
    if val is None {
        return None;
    }
    if str(val) == "null" {
        return None;
    }
    return float(val);
}