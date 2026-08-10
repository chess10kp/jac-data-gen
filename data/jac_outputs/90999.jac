"""
    Calculates the intensity of a given cell in the stellar surface using a
    square-root limb-darkening law.
    """
def square_root(mu: float, c: list[float], i0: float = 1.0) -> float {
    (c1, c2) = c;
    attenuation = 1 - c1 * (1 - mu) - c2 * (1 - mu ** 0.5);
    return i0 * attenuation;
}