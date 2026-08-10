"""Calculate number of effective, i.e. independent samples
for a given lag-one autocorrelation."""
def calc_ar_neff(phi: float, n: int = 1) -> float {
    n * (1 - phi) / (1 + phi)
}