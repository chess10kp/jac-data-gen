"""
    Linear interpolation between integers `x` and `y` with a factor of `.5`.
    """
def lerp(x: Any, y: Any) -> object {
    return (x + ((y - x) // 2));
}