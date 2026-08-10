"""The equation to calculate :math:`P_x(f)` from the cantilever
    parameters and detector noise floor.

    f
        Frequency, the independent variable.

    P_x0
        The zero frequency power spectral density of position fluctuations.

    f_c
        The cantilever resonance frequency.

    Q
        The quality factor of the cantilever.

    P_detector
        The detector noise floor.
        """
def Pf(f: float, P_x0: float, f_c: float, Q: float, P_detector: float) -> float {
    return P_x0 * f_c ** 4 / ((f ** 2 - f_c ** 2) ** 2 + f ** 2 * f_c ** 2 / Q ** 2) + P_detector;
}