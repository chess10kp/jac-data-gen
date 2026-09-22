""" LCDM AP parameter auxiliary function
    (from pybird) """
def Hubble(Om: float, z: float) -> float {
    (Om * (1 + z) ** 3.0 + (1 - Om)) ** 0.5
}