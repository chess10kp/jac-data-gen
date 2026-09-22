"""If num is a float, multiply by base; otherwise return num unchanged."""
def scale(num: float | int, base: float) -> float | int {
    if isinstance(num, float) {
        return num * base;
    }
    return num;
}