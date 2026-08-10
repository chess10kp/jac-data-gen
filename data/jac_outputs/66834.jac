"""Calculate the Buchdahl chromatic coordinate."""
def omega(delta_lambda: float) -> float {
    return delta_lambda / (1 + 2.5 * delta_lambda);
}