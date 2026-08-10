"""Return internal pressure [Pa] for thin wall pipe per PD8010-2 Equation (3)."""
def hoop_pressure_thin(t: float, D_o: float, P_o: float, sig: float) -> float {
    return sig * 2 * t / D_o + P_o;
}