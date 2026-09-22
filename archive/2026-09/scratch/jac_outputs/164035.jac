"""
    get a vector of zeros with a one in the i-th position

    Parameters
    ----------
    n: vector length
    i: position

    Returns
    -------
    an array with zeros and 1 in the i-th position

    """
def e_vect(n: int, i: int) -> list[int] {
    zeros = [0 for _ in range(n)];
    zeros[i] = 1;
    return zeros;
}