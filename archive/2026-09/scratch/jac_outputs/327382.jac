"""Return internal pressure [Pa] for thick-walled pipe (PD8010-2 Eq. 5)."""
def hoop_pressure_thick(t: float, D_o: float, P_o: float, sig: float) -> float {
    inner_d = D_o - 2 * t;
    return sig * (D_o ** 2 - inner_d ** 2) / (D_o ** 2 + inner_d ** 2) + P_o;
}