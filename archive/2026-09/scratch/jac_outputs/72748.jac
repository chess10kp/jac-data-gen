"""
molWeight is kDa
concentration in mM
density g/ml
"""
def volumeFraction(
    concentration: float = 1,
    molWeight: float = 17,
    density: float = 1.347
) -> float {
    concentration_mg_ml = concentration * molWeight;
    return concentration_mg_ml / density / 1000.0;
}