"""
    Compute x0_mult element-wise
    Arguments:
        guess (np.array)
        slip (np.array)
    """
def x0_mult(guess: Any, slip: Any) -> object {
    return ((slip * (1.0 + guess)) / (1.0 + slip));
}