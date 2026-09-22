"""Calculate midpoint between two points."""
def midpoint(a: list[float], b: list[float]) -> tuple[float, ...] {
    return tuple([round((a[i] + b[i]) / 2) for i in range(len(a))]);
}