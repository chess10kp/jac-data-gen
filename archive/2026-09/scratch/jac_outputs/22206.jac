"""Calculate the Resistance of a parallel connection."""
def r1_p_r2(R1: float, R2: float) -> float {
    return R1 * R2 / (R1 + R2);
}