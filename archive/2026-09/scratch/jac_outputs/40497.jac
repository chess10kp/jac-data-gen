"""Gets the limits for a coordinate q."""
def _get_lim(q: list[float], qlim: str | tuple[float, float]) -> tuple[float, float] {
    if qlim == 'range' {
        return (min(q), max(q));
    }
    return qlim as tuple[float, float];
}