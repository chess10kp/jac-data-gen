"""new build-up index"""
def nbi_calci(red: float, nir: float, swir: float) -> float {
    return (swir * red) / nir;
}