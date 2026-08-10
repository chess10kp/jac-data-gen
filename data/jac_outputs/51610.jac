"""
    The number of samples in an exponentially growing 1D quadrature rule of
    a given level.

    Parameters
    ----------
    level : integer
       The level of the quadrature rule

    Return
    ------
    num_samples_1d : integer
        The number of samples in the quadrature rule
    """
def exponential_growth(level: int, constant: int = 1) -> int {
    if level == 0 {
        return 1;
    }
    return constant * (2 ** (level + 1)) - 1;
}