"""Helper function for a map call."""
def ChangeNegToDash(val: float) -> float | str {
    return '-' if val == -1.0 else val;
}