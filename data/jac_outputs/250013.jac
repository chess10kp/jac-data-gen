"""
    Subtract two vectors or a vector and a scalar element-wise

    Parameters
    ----------
    a: list[]
        A vector of scalar values
    b: list[]
        A vector of scalar values or a scalar value.

    Returns
    -------
    list[]
        A vector difference of a and b

    """
def vec_sub(a: list[float], b: float | list[float]) -> list[float] {
    if type(b) is list {
        assert len(a) == len(b as list[float]);
        return [*map(lambda (ai: float, bi: float) { ai - bi; }, a, b as list[float])];
    }
    return [*map(lambda (ai: float) { ai - b as float; }, a)];
}