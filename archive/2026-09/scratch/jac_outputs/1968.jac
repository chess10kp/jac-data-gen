"""
Calculates dynamic gas viscosity in kg*m-1*s-1.

Parameters
----------
T : float
    Temperature (K)
Tr : float
    Reference Temperature (K)
S : float
    Sutherland constant (K)
nr : float
    Reference dynamic viscosity

Returns
-------
eta : float
    Dynamic gas viscosity in kg*m-1*s-1
"""
def etaCalc(
    T: float, Tr: float = 296.15, S: float = 110.4, nr: float = 1.83245 * (10 ** -5)
) -> float {
    return nr * ((Tr + S) / (T + S)) * ((T / Tr) ** (3 / 2));
}