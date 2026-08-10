"""Returns a dimmer version of a color. If multiplier > 1, a lighter color
    can be produced as well."""
def dim(rgb: tuple[int, ...], mul: float = 0.6) -> tuple[int, ...] {
    return tuple(map(lambda (x: int) { min(1000, round(x * mul)); }, rgb));
}