"""Return the energy for given volume (V - it can be a vector) according to
the Birch Murnaghan function with parameters E0,V0,B0,B01.
"""
def birch_murnaghan(V: float, E0: float, V0: float, B0: float, B01: float) -> float {
    r = (V0 / V) ** (2.0 / 3.0);
    return E0 + 9.0 / 16.0 * B0 * V0 * ((r - 1.0) ** 3 * B01 + (r - 1.0) ** 2 * (6.0 - 4.0 * r));
}