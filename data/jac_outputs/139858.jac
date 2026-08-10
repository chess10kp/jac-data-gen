"""
    Calculate N-wave overpressure amplitude

    Parameters
    ----------
    M -- Mach number
    bulletDiam -- bullet diameter in m
    bulletLen -- bullet length in m
    xmiss -- miss distance in m
    patm -- atmosperic pressure in Pa

    Returns
    -------
    pmax -- N-wave overpressure amplitude in Pa
    """
def nWaveAmplitude(
    M: Any, bulletDiam: Any, bulletLen: Any, xmiss: Any, patm: Any = 101000.0
) -> object {
    pmax = (
        (0.53 * patm * bulletDiam * (((M ** 2) - 1) ** 0.125))
        / ((xmiss ** 0.75) * (bulletLen ** 0.25))
    );
    return pmax;
}