"""Normalize an array to have the given total sum."""
def normalize(arr: list[int | float], total: float = 1.0) -> list[float] {
    try {
        fac = total / float(sum([abs(v) for v in arr]));
    } except ZeroDivisionError {
        fac = 1.0;
    }
    return [v * fac for v in arr];
}