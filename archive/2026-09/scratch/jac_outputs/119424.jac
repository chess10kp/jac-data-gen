"""Be careful """
def safe(val: str | int | float | None) -> float | None {
    if val is None {
        return None;
    }
    return float(val);
}