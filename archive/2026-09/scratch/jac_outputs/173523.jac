"""Calculate kappa1 in the PWP equation (cm/s) at temperature T_K (Kelvin)."""
def calc_kappa1(T_K: float) -> float {
    10.0 ** (0.198 - 444.0 / T_K)
}