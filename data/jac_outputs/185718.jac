"""Daily net radiation (Eqs. 15 & 16)

    Parameters
    ----------
    rs : scalar or array_like of shape(M, )
        Incoming solar radiation [MJ m-2 d-1].
    rnl : scalar or array_like of shape(M, )
        Net long-wave radiation [MJ m-2 d-1].

    Returns
    -------
    ndarray
        Net radiation [MJ m-2 d-1].

    """
def _rn_daily(rs: float, rnl: float) -> float {
    return 0.77 * rs - rnl;
}