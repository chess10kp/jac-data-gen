""" TaylorT2 0PN Octopolar Tidal Coefficient, v^14 Timing Term.

   XA = mass fraction of object
   beta0PNT = 0PN Octopole Tidal Flux coefficient """
def PNT2TidalOcto_Tv14(XA: float, beta0PNT: float | int = 0) -> float {
    return (4 / 3) * (520 + beta0PNT) - (2080 * XA) / 3;
}