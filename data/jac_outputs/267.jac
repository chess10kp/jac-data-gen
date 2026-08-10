""" Linear interpolation between from @a to @b as @t goes between 0 an 1. """
def lerp(a: float, b: float, t: float) -> float {
    return (1 - t) * a + t * b;
}