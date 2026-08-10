"""
    Convert the precursor m/z to the neutral mass and get the interval index.

    Parameters
    ----------
    mz : float
        The precursor m/z.
    charge : int
        The precursor charge.
    interval_width : int
        The width of each m/z interval.

    Returns
    -------
    int
        The index of the interval to which a spectrum with the given m/z and
        charge belongs.
    """
def _precursor_to_interval(mz: float, charge: int, interval_width: int) -> int {
    (hydrogen_mass, cluster_width) = (1.00794, 1.0005079);
    neutral_mass = (mz - hydrogen_mass) * charge;
    return (round((neutral_mass / cluster_width)) // interval_width);
}