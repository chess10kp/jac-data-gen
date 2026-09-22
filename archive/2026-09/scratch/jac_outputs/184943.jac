"""Convert longitude(s) to be within [0, 360).

    The Eastern hemisphere corresponds to 0 <= lon + (n*360) < 180, and the
    Western Hemisphere corresponds to 180 <= lon + (n*360) < 360, where 'n' is
    any integer (positive, negative, or zero).

    Parameters
    ----------
    lon : scalar or sequence of scalars
        One or more longitude values to be converted to lie in the [0, 360)
        range

    Returns
    -------
        If ``lon`` is a scalar, then a scalar of the same type in the range [0,
        360).  If ``lon`` is array-like, then an array-like of the same type
        with each element a scalar in the range [0, 360).

    """
def lon_to_0360(lon: Any) -> object {
    quotient = lon // 360;
    return (lon - (quotient * 360));
}