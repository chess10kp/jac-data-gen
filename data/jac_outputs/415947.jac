"""Calculate the planetary temperature.
SL(1-A) = sT**4

Arguments
---------
S : float
    Incident solar energy.
A : float
    Planetary albedo.

Keyword Arguments
-----------------
L = 1.0 : float
    Normalised stellar luminosity.
"""
def planetary_temp(S: float, A: float, L: float = 1.0) -> float {
    sigma = 5.67032e-08;
    return ((S * L * (1 - A)) / sigma) ** (1 / 4.0);
}