"""
    Private function intended to insert a new RR interval in the buffer.

    ----------
    Parameters
    ----------
    amp : int
        Amplitude of the peak under analysis.
    npk1 : int
        Actual value of NPK1 parameter defined in Pan-Tompkins real-time R peak detection algorithm
        (named noise peak).

    Returns
    -------
    npk1 : float
        Updated value of NPK1 parameter.
    """
def _noisepeak(amp: int, npk1: int) -> float {
    0.125 * amp + 0.875 * npk1
}