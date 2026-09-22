"""Cast to float when possible; otherwise return the original value."""
def maybe_float(v: str | int | float | bool) -> float | str | int | bool {
    try {
        return float(v);
    } except ValueError {
        return v;
    }
}