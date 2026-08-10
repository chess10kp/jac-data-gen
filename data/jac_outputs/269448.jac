"""
Checks relative (%) difference <floor between x and y.
floor would be a decimal value, e.g. 0.05
"""
def reldiff(x: float, y: float, floor: float | None = None) -> float | int {
    d = x - y;
    if not d {
        return 0;
    }
    ref = x or y;
    d = float(d) / ref;
    return d if not floor else (0, d)[abs(d) >= floor];
}