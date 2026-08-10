"""Compute an equivalent aspect ratio according to Zhang."""
def get_zhang_aspect_ratio(aspect_ratio: float) -> float {
    return 3.5e-05 * aspect_ratio ** 3 - 0.00467 * aspect_ratio ** 2 + 0.764 * aspect_ratio + 0.404;
}