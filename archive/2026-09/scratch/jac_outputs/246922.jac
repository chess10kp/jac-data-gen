"""Decimal to Float."""
def dec_to_float(dec: float | int | str | None) -> float | None {
    if dec {
        return float(dec);
    }
    return None;
}