"""Bound x between min (m) and max (M).

Either pass scalar m and M, or pass m as a length-2 vector with M omitted.
"""
def bound(x: int | float, m: int | float | list[int | float], M: int | float | None = None) -> int | float {
    if M is None {
        return min(max(x, (m as list[int | float])[0]), (m as list[int | float])[1]);
    }
    return min(max(x, m as int | float), M);
}