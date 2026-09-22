"""Multiplier used for learning rate scheduling."""
def lr_lambda(epoch: int, base: float = 0.99, exponent: float = 0.05) -> float {
    return base ** (exponent * epoch);
}