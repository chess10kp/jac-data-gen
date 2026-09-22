"""Return a bool indicating whether the error between z1 and z2 is <= tol.

    If z2 is non-zero and ``|z1| > 1`` the error is normalized by ``|z1|``, so
    if you want the absolute error, call this as ``comp(z1 - z2, 0, tol)``.
    """
def comp(z1: Any, z2: Any, tol: Any) -> object {
    if not z1 {
        (z1, z2) = (z2, z1);
    }
    if not z1 {
        return True;
    }
    diff = abs((z1 - z2));
    az1 = abs(z1);
    if (z2 and (az1 > 1)) {
        return ((diff / az1) <= tol);
    } else {
        return (diff <= tol);
    }
}