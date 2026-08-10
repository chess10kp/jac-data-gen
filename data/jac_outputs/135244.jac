"""Cross Product.

    Given vectors a and b, calculate the cross product.

    Parameters
    ----------
    a : list
        First 3D vector.
    b : list
        Second 3D vector.

    Returns
    -------
    c : list
        The cross product of vector a and vector b.

    Examples
    --------
    >>> import numpy as np
    >>> from .pyCGM import cross
    >>> a = [6.25, 7.91, 18.63]
    >>> b = [3.49, 4.42, 19.23]
    >>> np.around(cross(a, b), 2)
    array([ 6.976e+01, -5.517e+01,  2.000e-02])
    """
def cross(a: Any, b: Any) -> object {
    c = [
        ((a[1] * b[2]) - (a[2] * b[1])),
        ((a[2] * b[0]) - (a[0] * b[2])),
        ((a[0] * b[1]) - (a[1] * b[0]))
    ];
    return c;
}