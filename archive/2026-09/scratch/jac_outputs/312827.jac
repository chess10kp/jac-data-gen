"""
    Lorentizian function.

    Parameters
    -------------

    t : 'array'

    pars : 'array'
        Parameters used in the decomposition. E.g. heigh, center, width.

    Returns
    -------------
    function
    """
def asym_peak_L(t: Any, pars: Any) -> object {
    a0 = pars[0];
    a1 = pars[1];
    a2 = pars[2];
    f = a0 * ((a2 ** 2) / (((t - a1) ** 2) + ((1.0 * a2) ** 2)));
    return f;
}