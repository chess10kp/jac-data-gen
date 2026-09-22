"""Defines the sign for the multiplication."""
def _sign(num: int | float) -> int {
    if not num {
        return 0;
    }
    return 1 if num > 0 else -1;
}