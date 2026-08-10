"""Rescale bins in histogram."""
def Scale(h: list[tuple[float, float]], scale: float = 1.0) -> list[tuple[float, float]] {
    return [(b * scale, v) for (b, v) in h];
}