"""
    Upper frequency of frequency band given a center frequency and order.

    :param centr: Center frequencies.
    :param order: Fraction of octave.

    .. math:: f_u = f_c \cdot 2^{\\frac{+1}{2N}}

    """
def upper_frequency(center: float, order: int = 1) -> float {
    return center * (2.0 ** (1.0 / (2.0 * order)));
}