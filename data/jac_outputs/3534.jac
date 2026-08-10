"""Flips a longitude across the antimeridian if needed."""
def maybe_flip_x_across_antimeridian(x: float) -> float {
    if x > 90 {
        return -360 + x;
    }
    return x;
}