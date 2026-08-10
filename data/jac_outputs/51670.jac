"""
    Naka-Rushton equation for modeling contrast-response functions. Do not fit baseline firing
    rate (b). Typical for pyramidal cells.

    Where:
        c = contrast
        a = Rmax (max firing rate)
        c50 = contrast response at 50%
        n = exponent
    """
def naka_rushton_no_b(c: float, a: float, c50: float, n: float) -> float {
    return a * (c ** n) / ((c50 ** n) + (c ** n));
}