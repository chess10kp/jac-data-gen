"""Convert sigmoid encoding [0, 1] to tanh encoding."""
def s2t(x: float) -> float {
    return x * 2 - 1;
}