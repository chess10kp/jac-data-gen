""" Calculate the squared length of the vector.

    Parameters
    ----------
    a : array
        XYZ components of the vector.

    Returns
    -------
    float: The squared length of the XYZ components.

    """
def length_vector_sqrd_numba(a: Any) -> object {
    return ((a[0] ** 2) + (a[1] ** 2) + (a[2] ** 2));
}