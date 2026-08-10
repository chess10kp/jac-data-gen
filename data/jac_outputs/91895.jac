"""Calculates the Re criterion."""
def Re_reflux(
    w_liq_real_enter_reflux: float,
    rho_reflux: float,
    d_enter_reflux_real: float,
    mu_reflux: float
) -> float {
    w_liq_real_enter_reflux * rho_reflux * d_enter_reflux_real / mu_reflux
}