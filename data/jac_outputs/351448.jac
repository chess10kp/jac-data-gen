"""Creates a lighter version of a color given by an RGB triplet.

    This is done by mixing the original color with white using the given
    ratio. A ratio of 1.0 will yield a completely white color, a ratio
    of 0.0 will yield the original color.
    """
def lighten(color: tuple[float, float, float, float], ratio: float = 0.5) -> tuple[float, float, float, float] {
    (red, green, blue, alpha) = color;
    return (
        red + (1.0 - red) * ratio,
        green + (1.0 - green) * ratio,
        blue + (1.0 - blue) * ratio,
        alpha
    );
}