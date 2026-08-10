"""Gives the derivative of S, I, R, and D with respect to time at some t

    Parameters:
    t - The time at which the derivative is to be calculated
    y - Value of S, I, R, and D at t
    b - Parameter beta in the ODEs
    g - Parameter gamma in the ODEs
    l - Parameter lambda in the ODEs (see Q3 pdf)
    N - Size of the population

    Returns:
    List of derivatives at time t for S, I, R, and D (in that order)
    """
def SIRD_model(t: float, y: list[float], b: float, g: float, l: float, N: float) -> list[float] {
    (s, i, r, d) = y;
    return [
        -b * s * i / N,
        b * s * i / N - g * i - l * i,
        g * i,
        l * i
    ];
}