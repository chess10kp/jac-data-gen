"""The reflection coefficient. Equation 8.15."""
def double_layer_cover_reflection_coefficient(
    tau_1: float, rho_1: float, rho_2: float
) -> float {
    rho_1 + (tau_1 * tau_1 * rho_2) / (1 - rho_1 * rho_2)
}