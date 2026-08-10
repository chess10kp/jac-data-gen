"""Map theta from [-1, 1] to [0, 1]."""
def shift_scale_theta(theta: float) -> float {
    return (theta + 1) / 2;
}