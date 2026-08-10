""" Blends images by averaging pixels.
    """
def blend_average(*args: int | float) -> float {
    s = 0.0;
    for i in args {
        s += i;
    }
    return s / len(args);
}