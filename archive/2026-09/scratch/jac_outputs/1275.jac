"""
    Convert OSBG36 Easting-Northing to local grid coordinates

    :param easting: easting in OSBG36
    :param northing: northing in OSBG36
    :param Eo: delta easting of local grid
    :param No: delta northing of local grid
    :param one_over_CSF: reciprocal CSF (combinated scale factor, = 1/CSF)

    :returns: todo
    """
def __ConvertOSBGToLocal(
    easting: float,
    northing: float,
    Eo: float,
    No: float,
    one_over_CSF: float
) -> tuple[float, float] {
    x_local = (easting - Eo) * one_over_CSF;
    y_local = (northing - No) * one_over_CSF;
    return (x_local, y_local);
}